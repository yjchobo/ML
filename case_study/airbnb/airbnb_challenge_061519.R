###setup
#setwd("C:/Users/yocho/Documents/young_cho_non_work/airbnb")
setwd("C:/Users/YC/portfolio/case_study/airbnb")
#setwd("C:/Users/yocho/portfolio/case_study/airbnb")


packages.required = c("sqldf","ggplot2","dplyr", "lubridate","corrplot","rpart","rpart.plot","party","randomForest","regclass","ggpubr","caret","e1071","cluster","tidyverse")
#install.packages(packages.required)
lapply(packages.required, library, character.only = TRUE)

###read data
users <- read.csv("users.csv")
listings <- read.csv("listings.csv")
contacts <- read.csv("contacts.csv")

#save entities
guestid <- unique(contacts$id_guest_anon)
hostid <- unique(contacts$id_host_anon)
listingid <- unique(listings$id_listing_anon)

###clean data

#create posix versions of timestamps for datetime calculations
datetimestamps = c("ts_interaction_first","ts_reply_at_first","ts_accepted_at_first","ts_booking_at")
datetimestamps.posix = c("ts_interaction_first_posix","ts_reply_at_first_posix","ts_accepted_at_first_posix","ts_booking_at_posix")
datestamps = c("ds_checkin_first","ds_checkout_first")
datestamps.posix = c("ds_checkin_first_posix","ds_checkout_first_posix")

contacts[datetimestamps] <- sapply(contacts[datetimestamps],as.character)
contacts[datestamps] <- sapply(contacts[datestamps],as.character)

contacts[datetimestamps.posix] <- sapply(contacts[datetimestamps],as.POSIXct,format="%Y-%m-%d%H:%M:%S")
contacts[datestamps.posix] <- sapply(contacts[datestamps],as.POSIXct,format="%Y-%m-%d")

#Day of the week for requested checkin date
contacts$dow_checkin = weekdays(contacts$ds_checkin_first_posix, abbreviate = T)

#Month of the year for requested checkin date
contacts$moy_checkin = month(as.factor(contacts$ds_checkin_first))

#calculating time attributes
contacts$days_duration_requested_stay <- difftime(as.POSIXct(contacts$ds_checkout_first), as.POSIXct(contacts$ds_checkin_first), units=c("days"))
contacts$days_from_first_contact_to_first_checkin <- difftime(as.POSIXct(contacts$ds_checkin_first), as.POSIXct(contacts$ts_interaction_first), units=c("days"))
contacts$minute_from_first_reply_to_accept <- difftime(as.POSIXct(contacts$ts_accepted_at_first,format="%Y-%m-%d%H:%M:%S"), as.POSIXct(contacts$ts_reply_at_first,format="%Y-%m-%d%H:%M:%S"), units=c("mins"))
contacts$minute_from_first_touch_to_reply <- difftime(as.POSIXct(contacts$ts_reply_at_first,format="%Y-%m-%d%H:%M:%S"), as.POSIXct(contacts$ts_interaction_first,format="%Y-%m-%d%H:%M:%S"), units=c("mins"))


#remove negative number of reviews
listings$total_reviews[listings$total_reviews < 0] <- 0






###Inquiry funnel Data exploration

t1 <- sqldf("select count(*) as count_all, count(distinct id_guest_anon) as count_uniq_guest_id, count(distinct id_host_anon)
             as count_uniq_host_id, count(distinct id_listing_anon) as count_uniq_listing_id from contacts")

t2 <- sqldf("select count(u.id_user_anon), count(distinct id_user_anon)  from users u")

#22566
t3 <- sqldf("select count(distinct id_user_anon)  from users u where u.id_user_anon in (select distinct id_guest_anon from contacts)")
#8959
t4 <- sqldf("select count(distinct id_user_anon)  from users u where u.id_user_anon in (select distinct id_host_anon from contacts)")

t5 <- sqldf("select contact_channel_first, count(distinct id_guest_anon) as count_uniq_guestid, count(*) as count_all
            from contacts
            group by contact_channel_first")

t6 <- sqldf("select guest_user_stage_first, count(*) as count_all, count(distinct id_guest_anon) as count_uniq_guestid from contacts group by guest_user_stage_first")

t7 <- sqldf("
            select avg(count_uniq_listing_id) from
            (select id_host_anon, count(distinct id_listing_anon) as count_uniq_listing_id from contacts group by id_host_anon) t1
            ")


t8 <- sqldf('select ts_interaction_first, ts_reply_at_first,
            ts_reply_at_first - ts_interaction_first as td1
            from contacts where id_guest_anon ="02d08d6f-a559-4803-b2f0-2310ff3edecd"')


t8 <- sqldf('select ts_interaction_first, ts_reply_at_first, ts_reply_at_first-ts_interaction_first as time_diff
            from contacts where id_guest_anon ="02d08d6f-a559-4803-b2f0-2310ff3edecd"')

t9 <- sqldf('select case when ts_reply_at_first_posix is null then "no_reply" else "replied" end as replied_flag,
            count(distinct id_host_anon) as unique_host_id, count(*) as count_all
            from contacts
            where contact_channel_first = "contact_me"
            group by case when ts_reply_at_first_posix is null then "no_reply" else "replied" end
            ')
t9

#pivot

#contact_me
t10 <- sqldf('select
              case when ts_reply_at_first_posix is null then "no_reply" else "replied" end as ts_reply_flag
              ,case when ts_accepted_at_first_posix is null then "no_accept" else "accepted" end as accepted_flag
              ,case when ts_booking_at_posix is null then "no_booking" else "booking" end as booking_flag
              ,count(distinct id_host_anon) as unique_host_id, count(*) as count_all
             from contacts
             where contact_channel_first = "contact_me"
             group by case when ts_reply_at_first_posix is null then "no_reply" else "replied" end
              ,case when ts_accepted_at_first_posix is null then "no_accept" else "accepted" end
              ,case when ts_booking_at_posix is null then "no_booking" else "booking" end
             ')
t10

#book_it
t11 <- sqldf('select
              case when ts_reply_at_first_posix is null then "no_reply" else "replied" end as ts_reply_flag
              ,case when ts_accepted_at_first_posix is null then "no_accept" else "accepted" end as accepted_flag
              ,case when ts_booking_at_posix is null then "no_booking" else "booking" end as booking_flag
              ,count(distinct id_host_anon) as unique_host_id, count(*) as count_all
             from contacts
             where contact_channel_first = "book_it"
             group by case when ts_reply_at_first_posix is null then "no_reply" else "replied" end
              ,case when ts_accepted_at_first_posix is null then "no_accept" else "accepted" end
              ,case when ts_booking_at_posix is null then "no_booking" else "booking" end
             ')
t11

#instant_book
t12 <- sqldf('select
              case when ts_reply_at_first_posix is null then "no_reply" else "replied" end as ts_reply_flag
              ,case when ts_accepted_at_first_posix is null then "no_accept" else "accepted" end as accepted_flag
              ,case when ts_booking_at_posix is null then "no_booking" else "booking" end as booking_flag
              ,count(distinct id_host_anon) as unique_host_id, count(*) as count_all
             from contacts
             where contact_channel_first = "instant_book"
             group by case when ts_reply_at_first_posix is null then "no_reply" else "replied" end
              ,case when ts_accepted_at_first_posix is null then "no_accept" else "accepted" end
              ,case when ts_booking_at_posix is null then "no_booking" else "booking" end
             ')
t12



#calculate attributes for classification model

p1 <- sqldf('select
              -- target variables
              (case when c.ts_booking_at_posix is null then 0 else 1 end) as Resulted_Successful_Booking,
              (case when c.ts_booking_at_posix is null then null else ts_booking_at_posix - ts_interaction_first_posix end) as target_num,              

              -- reservation related attributes
              c.days_duration_requested_stay,
              c.m_guests,
              c.days_from_first_contact_to_first_checkin,
              c.dow_checkin,
              c.moy_checkin,
              c.contact_channel_first,
              
              -- guest"s attribute
              g.country as guest_country,
              g.words_in_user_profile as guest_words_in_profile,
              c.guest_user_stage_first,
              
              -- guest"s attribute
              h.country as host_country,
              h.words_in_user_profile as host_words_in_profile,
              
              -- listing"s attribute
              l.room_type,
              l.listing_neighborhood,
              l.total_reviews,
              
              -- host and guest interaction attribute
              c.m_interactions,
              c.minute_from_first_reply_to_accept,
              c.minute_from_first_touch_to_reply
              
              
             from contacts c
             left join users g on g.id_user_anon = c.id_guest_anon            -- guests
             left join users h on h.id_user_anon = c.id_host_anon             -- hosts
             left join listings l on l.id_listing_anon = c.id_listing_anon    -- listing
            
             ', method = "name__class")

#turn discrete vars to factors
dis_vars = c("dow_checkin","moy_checkin","guest_country","guest_user_stage_first","host_country","room_type","listing_neighborhood", "Resulted_Successful_Booking","contact_channel_first")
p1[dis_vars] <- lapply(p1[dis_vars],as.factor)

#create separate dfs, one for classification and one for regression
p1_cl <- p1[, !(colnames(p1) %in% c("target_num","guest_country","host_country","listing_neighborhood"))]
#p1_reg <- p1[, !(colnames(p1) %in% c("Resulted_Successful_Booking","guest_country","host_country","listing_neighborhood"))]


#split dfs based on contact_channel_first: contact_me, book_it, instant_book
p1_cl_cm <- filter(p1_cl, contact_channel_first == "contact_me")
p1_cl_bi <- filter(p1_cl, contact_channel_first == "book_it")


# create training and test sets
set.seed(123)
inTrain <- caret::createDataPartition(y = p1_cl$Resulted_Successful_Booking, p = 0.8, list = FALSE)
p1_cl_training <- p1_cl[inTrain, ]
p1_cl_testing <- p1_cl[-inTrain, ]



#split dfs based on contact_channel_first: contact_me, book_it, instant_book
p1_cl_training_cm <- filter(p1_cl_training, contact_channel_first == "contact_me")
p1_cl_training_cm <- p1_cl_training_cm[, !(colnames(p1_cl_training_cm) %in% c("contact_channel_first"))]

p1_cl_training_bi <- filter(p1_cl_training, contact_channel_first == "book_it")
p1_cl_training_bi <- p1_cl_training_bi[, !(colnames(p1_cl_training_bi) %in% c("contact_channel_first"))]

p1_cl_testing_cm <- filter(p1_cl_testing, contact_channel_first == "contact_me")
p1_cl_testing_cm <- p1_cl_testing_cm[, !(colnames(p1_cl_testing_cm) %in% c("contact_channel_first"))]

p1_cl_testing_bi <- filter(p1_cl_testing, contact_channel_first == "book_it")
p1_cl_testing_bi <- p1_cl_testing_bi[, !(colnames(p1_cl_testing_bi) %in% c("contact_channel_first"))]




#######################################################################################################################################
###contact me channel
#EDA

#barplots for factor vars
ggplot(data = p1_cl_cm,aes(x=m_guests,fill=Resulted_Successful_Booking))+geom_bar()
ggplot(data = p1_cl_cm,aes(x=m_guests,fill=Resulted_Successful_Booking))+geom_bar(position = "fill")
ggplot(data = p1_cl_cm,aes(x=dow_checkin,fill=Resulted_Successful_Booking))+geom_bar()
ggplot(data = p1_cl_cm,aes(x=dow_checkin,fill=Resulted_Successful_Booking))+geom_bar(position = "fill")
ggplot(data = p1_cl_cm,aes(x=moy_checkin,fill=Resulted_Successful_Booking))+geom_bar()
ggplot(data = p1_cl_cm,aes(x=moy_checkin,fill=Resulted_Successful_Booking))+geom_bar(position = "fill")
ggplot(data = p1_cl_cm,aes(x=contact_channel_first,fill=Resulted_Successful_Booking))+geom_bar()
ggplot(data = p1_cl_cm,aes(x=contact_channel_first,fill=Resulted_Successful_Booking))+geom_bar(position = "fill")
ggplot(data = p1_cl_cm,aes(x=guest_user_stage_first,fill=Resulted_Successful_Booking))+geom_bar()
ggplot(data = p1_cl_cm,aes(x=guest_user_stage_first,fill=Resulted_Successful_Booking))+geom_bar(position = "fill")
#ggplot(data = p1_cl_cm,aes(x=host_country,fill=Resulted_Successful_Booking))+geom_bar()
#ggplot(data = p1_cl_cm,aes(x=host_country,fill=Resulted_Successful_Booking))+geom_bar(position = "fill")
ggplot(data = p1_cl_cm,aes(x=room_type,fill=Resulted_Successful_Booking))+geom_bar()
ggplot(data = p1_cl_cm,aes(x=room_type,fill=Resulted_Successful_Booking))+geom_bar(position = "fill")


#boxplots for numeric vars against target
ggplot(data = p1_cl_cm,aes(x=Resulted_Successful_Booking,y=days_duration_requested_stay,fill=Resulted_Successful_Booking))+geom_boxplot()+ylim(1,30)
ggplot(data = p1_cl_cm,aes(x=Resulted_Successful_Booking,y=m_guests,fill=Resulted_Successful_Booking))+geom_boxplot()+ylim(1,30)
ggplot(data = p1_cl_cm,aes(x=Resulted_Successful_Booking,y=days_from_first_contact_to_first_checkin,fill=Resulted_Successful_Booking))+geom_boxplot()
ggplot(data = p1_cl_cm,aes(x=Resulted_Successful_Booking,y=guest_words_in_profile,fill=Resulted_Successful_Booking))+geom_boxplot()+ylim(1,100)
ggplot(data = p1_cl_cm,aes(x=Resulted_Successful_Booking,y=host_words_in_profile,fill=Resulted_Successful_Booking))+geom_boxplot()+ylim(1,100)
ggplot(data = p1_cl_cm,aes(x=Resulted_Successful_Booking,y=total_reviews,fill=Resulted_Successful_Booking))+geom_boxplot()
ggplot(data = p1_cl_cm,aes(x=Resulted_Successful_Booking,y=m_interactions,fill=Resulted_Successful_Booking))+geom_boxplot()+ylim(1,100)
ggplot(data = p1_cl_cm,aes(x=Resulted_Successful_Booking,y=minute_from_first_reply_to_accept,fill=Resulted_Successful_Booking))+geom_boxplot()+ylim(1,10080) #7days
ggplot(data = p1_cl_cm,aes(x=Resulted_Successful_Booking,y=minute_from_first_touch_to_reply,fill=Resulted_Successful_Booking))+geom_boxplot()+ylim(1,5040)





### classification: 


#logistic regression
cl_m1 = glm(Resulted_Successful_Booking ~ .,  family = binomial(link = 'logit'), data = p1_cl_training_cm)
summary(cl_m1)

#top 10 by coeficients (increase in 1 unit's impact on the odds of an inquiry being a successful booking)
sort(exp(coef(cl_m1)),decreasing = T)[1:10]

#predict probability
cl_m1.prob = predict(cl_m1, p1_cl_testing_cm, type="response")
p1_cl_testing_cm.copy <- p1_cl_testing_cm
p1_cl_testing_cm.copy$log_reg_prob = cl_m1.prob

#predict class
cl_m1.pred_class <- ifelse(cl_m1.prob > 0.5,1,0)
p1_cl_testing_cm.copy$cl_m1.pred_class = cl_m1.pred_class


#model performance
#confusion matrix
cm = data.frame(confusion_matrix(cl_m1,p1_cl_testing_cm.copy))
TP = cm[2,2]
FP = cm[1,2]
FN = cm[2,1]
TN = cm[1,1]
TOTAL = cm[3,3]

(TP + TN) / TOTAL #overall accuracy 0.8832442
TP / (TP +FP) #precision 0.7589286
TP / (TP+FN) #recall 0.4497354
2*((TP / (TP +FP))*(TP / (TP+FN)))/((TP / (TP +FP))+(TP / (TP+FN)))#F1 Score 0.5647841

#predicted prob vs predictors
pl1 <- ggplot(p1_cl_testing_cm.copy,aes(x = days_duration_requested_stay, y = cl_m1.prob)) + geom_point(color = "#00AFBB", size = 2, shape = 23) + geom_smooth()
pl2 <- ggplot(p1_cl_testing_cm.copy,aes(x = m_guests, y = cl_m1.prob)) + geom_point(color = "#00AFBB", size = 2, shape = 23) + geom_smooth()
pl3 <- ggplot(p1_cl_testing_cm.copy,aes(x = days_from_first_contact_to_first_checkin, y = cl_m1.prob)) + geom_point(color = "#00AFBB", size = 2, shape = 23) + geom_smooth()
pl4 <- ggplot(p1_cl_testing_cm.copy,aes(x = dow_checkin, y = cl_m1.prob)) + geom_point(color = "#00AFBB", size = 2, shape = 23) + geom_smooth()
pl5 <- ggplot(p1_cl_testing_cm.copy,aes(x = moy_checkin, y = cl_m1.prob)) + geom_point(color = "#00AFBB", size = 2, shape = 23) + geom_smooth()
#pl6 <- ggplot(p1_cl_testing_cm.copy,aes(x = contact_channel_first, y = cl_m1.prob)) + geom_point(color = "#00AFBB", size = 2, shape = 23) + geom_smooth()
pl7 <- ggplot(p1_cl_testing_cm.copy,aes(x = guest_words_in_profile, y = cl_m1.prob)) + geom_point(color = "#00AFBB", size = 2, shape = 23) + geom_smooth()
pl8 <- ggplot(p1_cl_testing_cm.copy,aes(x = guest_user_stage_first, y = cl_m1.prob)) + geom_point(color = "#00AFBB", size = 2, shape = 23) + geom_smooth()
pl9 <- ggplot(p1_cl_testing_cm.copy,aes(x = host_words_in_profile, y = cl_m1.prob)) + geom_point(color = "#00AFBB", size = 2, shape = 23) + geom_smooth()
pl10 <- ggplot(p1_cl_testing_cm.copy,aes(x = room_type, y = cl_m1.prob)) + geom_point(color = "#00AFBB", size = 2, shape = 23) + geom_smooth()
pl11 <- ggplot(p1_cl_testing_cm.copy,aes(x = total_reviews, y = cl_m1.prob)) + geom_point(color = "#00AFBB", size = 2, shape = 23) + geom_smooth()
pl12 <- ggplot(p1_cl_testing_cm.copy,aes(x = m_interactions, y = cl_m1.prob)) + geom_point(color = "#00AFBB", size = 2, shape = 23) + geom_smooth()
pl13 <- ggplot(p1_cl_testing_cm.copy,aes(x = minute_from_first_reply_to_accept, y = cl_m1.prob)) + geom_point(color = "#00AFBB", size = 2, shape = 23) + geom_smooth()
pl14 <- ggplot(p1_cl_testing_cm.copy,aes(x = minute_from_first_touch_to_reply, y = cl_m1.prob)) + geom_point(color = "#00AFBB", size = 2, shape = 23) + geom_smooth()

fig <- ggarrange(pl1,pl2,pl3,pl4,pl5,pl7,pl8,pl9,pl10,pl11,pl12,pl13,pl14 + rremove("x.text"), label.y = "Prob of booking",
                 #labels = c("A", "B", "C"),
                 ncol = 2, nrow = 7)
annotate_figure(fig,
                top = text_grob("Predicted probability of successful booking from 'contact me' channel", color = "red", face = "bold", size = 25),
)






#decision tree
#with only a handful of predictors coming out significant from log reg above
cl_tree <- ctree(Resulted_Successful_Booking ~ ., data = p1_cl_training_cm[c("Resulted_Successful_Booking","days_duration_requested_stay","m_guests",
                                                                             "days_from_first_contact_to_first_checkin","dow_checkin",
                                                                             "moy_checkin","room_type","host_words_in_profile")])
plot(cl_tree)

#cl_tree2 <- ctree(Resulted_Successful_Booking ~ ., data = p1_cl[c("Resulted_Successful_Booking","days_duration_requested_stay","m_guests",
#                                                "days_from_first_contact_to_first_checkin")])
#plot(cl_tree2, gp = gpar(fontsize = 8))

#cl_tree2_rp <- rpart(Resulted_Successful_Booking ~ ., method="class", data = p1_cl[c("Resulted_Successful_Booking","days_duration_requested_stay","m_guests",
#                                                 "days_from_first_contact_to_first_checkin")])
#rpart.plot(cl_tree2_rp)
#printcp(cl_tree2_rp) # display the results 
#plotcp(cl_tree2_rp) # visualize cross-validation results 
#summary(cl_tree2_rp) # detailed summary of splits






# Random Forest
p1_cl_training_cm_rf <- p1_cl_training_cm[, colSums(is.na(p1_cl_training_cm)) == 0]
p1_cl_training_rf_fit <- randomForest(Resulted_Successful_Booking ~ .,  data=p1_cl_training_cm_rf)
print(p1_cl_training_rf_fit) # view results 
par(ps = 15, cex = 1, cex.main = 1)
varImpPlot(p1_cl_training_rf_fit, pch = 20, main = "Random Forest - Importance of Variables on succesful Booking - contact me")

# Predict rf
predictions.rf <- predict(p1_cl_training_rf_fit, newdata = p1_cl_testing_cm[, !(colnames(p1_cl_testing_cm) %in% c("Resulted_Successful_Booking"))])
real_cls <- p1_cl_testing_cm$Resulted_Successful_Booking
confusionMatrix(predictions.rf,real_cls)

#######################################################################################################################################




###book it channel
#EDA

#barplots for factor vars
ggplot(data = p1_cl_bi,aes(x=m_guests,fill=Resulted_Successful_Booking))+geom_bar()
#ggplot(data = p1_cl_bi,aes(x=m_guests,fill=Resulted_Successful_Booking))+geom_bar(position = "fill")
ggplot(data = p1_cl_bi,aes(x=dow_checkin,fill=Resulted_Successful_Booking))+geom_bar()
#ggplot(data = p1_cl_bi,aes(x=dow_checkin,fill=Resulted_Successful_Booking))+geom_bar(position = "fill")
ggplot(data = p1_cl_bi,aes(x=moy_checkin,fill=Resulted_Successful_Booking))+geom_bar()
#ggplot(data = p1_cl_bi,aes(x=moy_checkin,fill=Resulted_Successful_Booking))+geom_bar(position = "fill")
ggplot(data = p1_cl_bi,aes(x=contact_channel_first,fill=Resulted_Successful_Booking))+geom_bar()
#ggplot(data = p1_cl_bi,aes(x=contact_channel_first,fill=Resulted_Successful_Booking))+geom_bar(position = "fill")
ggplot(data = p1_cl_bi,aes(x=guest_user_stage_first,fill=Resulted_Successful_Booking))+geom_bar()
#ggplot(data = p1_cl_bi,aes(x=guest_user_stage_first,fill=Resulted_Successful_Booking))+geom_bar(position = "fill")
#ggplot(data = p1_cl_bi,aes(x=host_country,fill=Resulted_Successful_Booking))+geom_bar()
#ggplot(data = p1_cl_bi,aes(x=host_country,fill=Resulted_Successful_Booking))+geom_bar(position = "fill")
ggplot(data = p1_cl_bi,aes(x=room_type,fill=Resulted_Successful_Booking))+geom_bar()
#ggplot(data = p1_cl_bi,aes(x=room_type,fill=Resulted_Successful_Booking))+geom_bar(position = "fill")


#boxplots for numeric vars against target
ggplot(data = p1_cl_bi,aes(x=Resulted_Successful_Booking,y=days_duration_requested_stay,fill=Resulted_Successful_Booking))+geom_boxplot()+ylim(1,30)
ggplot(data = p1_cl_bi,aes(x=Resulted_Successful_Booking,y=m_guests,fill=Resulted_Successful_Booking))+geom_boxplot()+ylim(1,30)
ggplot(data = p1_cl_bi,aes(x=Resulted_Successful_Booking,y=days_from_first_contact_to_first_checkin,fill=Resulted_Successful_Booking))+geom_boxplot()
ggplot(data = p1_cl_bi,aes(x=Resulted_Successful_Booking,y=guest_words_in_profile,fill=Resulted_Successful_Booking))+geom_boxplot()+ylim(1,100)
ggplot(data = p1_cl_bi,aes(x=Resulted_Successful_Booking,y=host_words_in_profile,fill=Resulted_Successful_Booking))+geom_boxplot()+ylim(1,100)
ggplot(data = p1_cl_bi,aes(x=Resulted_Successful_Booking,y=total_reviews,fill=Resulted_Successful_Booking))+geom_boxplot()
ggplot(data = p1_cl_bi,aes(x=Resulted_Successful_Booking,y=m_interactions,fill=Resulted_Successful_Booking))+geom_boxplot()+ylim(1,100)
ggplot(data = p1_cl_bi,aes(x=Resulted_Successful_Booking,y=minute_from_first_reply_to_accept,fill=Resulted_Successful_Booking))+geom_boxplot()+ylim(1,10080) #7days
ggplot(data = p1_cl_bi,aes(x=Resulted_Successful_Booking,y=minute_from_first_touch_to_reply,fill=Resulted_Successful_Booking))+geom_boxplot()+ylim(1,5040)





### classification:


#logistic regression
cl_m1 = glm(Resulted_Successful_Booking ~ .,  family = binomial(link = 'logit'), data = p1_cl_training_bi)
summary(cl_m1)

#top 10 by coeficients (increase in 1 unit's impact on the odds of an inquiry being a successful booking)
sort(exp(coef(cl_m1)),decreasing = T)[1:10]

#predict probability
cl_m1.prob = predict(cl_m1, p1_cl_testing_bi, type="response")
p1_cl_testing_bi.copy <- p1_cl_testing_bi
p1_cl_testing_bi.copy$log_reg_prob = cl_m1.prob

#predict class
cl_m1.pred_class <- ifelse(cl_m1.prob > 0.5,1,0)
p1_cl_testing_bi.copy$cl_m1.pred_class = cl_m1.pred_class


#model performance
#confusion matrix
bi = data.frame(confusion_matrix(cl_m1,p1_cl_testing_bi.copy))
TP = bi[2,2]
FP = bi[1,2]
FN = bi[2,1]
TN = bi[1,1]
TOTAL = bi[3,3]

(TP + TN) / TOTAL #overall accuracy 0.9465909
TP / (TP +FP) #precision 0.9490683
TP / (TP+FN) #recall 0.99
2*((TP / (TP +FP))*(TP / (TP+FN)))/((TP / (TP +FP))+(TP / (TP+FN)))#F1 Score 0.97

#predicted prob vs predictors
pl1 <- ggplot(p1_cl_testing_bi.copy,aes(x = days_duration_requested_stay, y = cl_m1.prob)) + geom_point(color = "#00AFBB", size = 2, shape = 23) + geom_smooth()
pl2 <- ggplot(p1_cl_testing_bi.copy,aes(x = m_guests, y = cl_m1.prob)) + geom_point(color = "#00AFBB", size = 2, shape = 23) + geom_smooth()
pl3 <- ggplot(p1_cl_testing_bi.copy,aes(x = days_from_first_contact_to_first_checkin, y = cl_m1.prob)) + geom_point(color = "#00AFBB", size = 2, shape = 23) + geom_smooth()
pl4 <- ggplot(p1_cl_testing_bi.copy,aes(x = dow_checkin, y = cl_m1.prob)) + geom_point(color = "#00AFBB", size = 2, shape = 23) + geom_smooth()
pl5 <- ggplot(p1_cl_testing_bi.copy,aes(x = moy_checkin, y = cl_m1.prob)) + geom_point(color = "#00AFBB", size = 2, shape = 23) + geom_smooth()
#pl6 <- ggplot(p1_cl_testing_bi.copy,aes(x = contact_channel_first, y = cl_m1.prob)) + geom_point(color = "#00AFBB", size = 2, shape = 23) + geom_smooth()
pl7 <- ggplot(p1_cl_testing_bi.copy,aes(x = guest_words_in_profile, y = cl_m1.prob)) + geom_point(color = "#00AFBB", size = 2, shape = 23) + geom_smooth()
pl8 <- ggplot(p1_cl_testing_bi.copy,aes(x = guest_user_stage_first, y = cl_m1.prob)) + geom_point(color = "#00AFBB", size = 2, shape = 23) + geom_smooth()
pl9 <- ggplot(p1_cl_testing_bi.copy,aes(x = host_words_in_profile, y = cl_m1.prob)) + geom_point(color = "#00AFBB", size = 2, shape = 23) + geom_smooth()
pl10 <- ggplot(p1_cl_testing_bi.copy,aes(x = room_type, y = cl_m1.prob)) + geom_point(color = "#00AFBB", size = 2, shape = 23) + geom_smooth()
pl11 <- ggplot(p1_cl_testing_bi.copy,aes(x = total_reviews, y = cl_m1.prob)) + geom_point(color = "#00AFBB", size = 2, shape = 23) + geom_smooth()
pl12 <- ggplot(p1_cl_testing_bi.copy,aes(x = m_interactions, y = cl_m1.prob)) + geom_point(color = "#00AFBB", size = 2, shape = 23) + geom_smooth()
pl13 <- ggplot(p1_cl_testing_bi.copy,aes(x = minute_from_first_reply_to_accept, y = cl_m1.prob)) + geom_point(color = "#00AFBB", size = 2, shape = 23) + geom_smooth()
pl14 <- ggplot(p1_cl_testing_bi.copy,aes(x = minute_from_first_touch_to_reply, y = cl_m1.prob)) + geom_point(color = "#00AFBB", size = 2, shape = 23) + geom_smooth()

fig <- ggarrange(pl1,pl2,pl3,pl4,pl5,pl7,pl8,pl9,pl10,pl11,pl12,pl13,pl14 + rremove("x.text"), label.y = "Prob of booking",
                 #labels = c("A", "B", "C"),
                 ncol = 2, nrow = 7)
annotate_figure(fig,
                top = text_grob("Predicted probability of successful booking from 'book it' channel", color = "red", face = "bold", size = 25),
)






#decision tree
#with only a handful of predictors coming out significant from log reg above
cl_tree <- ctree(Resulted_Successful_Booking ~ ., data = p1_cl_training_bi[c("Resulted_Successful_Booking","days_duration_requested_stay","m_guests",
                                                                             "days_from_first_contact_to_first_checkin","dow_checkin",
                                                                             "moy_checkin","room_type","host_words_in_profile")])
plot(cl_tree)

#cl_tree2 <- ctree(Resulted_Successful_Booking ~ ., data = p1_cl[c("Resulted_Successful_Booking","days_duration_requested_stay","m_guests",
#                                                "days_from_first_contact_to_first_checkin")])
#plot(cl_tree2, gp = gpar(fontsize = 8))

#cl_tree2_rp <- rpart(Resulted_Successful_Booking ~ ., method="class", data = p1_cl[c("Resulted_Successful_Booking","days_duration_requested_stay","m_guests",
#                                                 "days_from_first_contact_to_first_checkin")])
#rpart.plot(cl_tree2_rp)
#printcp(cl_tree2_rp) # display the results 
#plotcp(cl_tree2_rp) # visualize cross-validation results 
#summary(cl_tree2_rp) # detailed summary of splits



# Random Forest
p1_cl_training_bi_rf <- p1_cl_training_bi[, colSums(is.na(p1_cl_training_bi)) == 0]
p1_cl_training_rf_fit <- randomForest(Resulted_Successful_Booking ~ .,  data=p1_cl_training_bi_rf)
print(p1_cl_training_rf_fit) # view results 
par(ps = 15, cex = 1, cex.main = 1)
varImpPlot(p1_cl_training_rf_fit, pch = 20, main = "Random Forest - Importance of Variables on succesful Booking - Book It channel")

# Predict rf
predictions.rf <- predict(p1_cl_training_rf_fit, newdata = p1_cl_testing_bi.copy[, !(colnames(p1_cl_testing_bi.copy) %in% c("Resulted_Successful_Booking"))])
real_cls <- p1_cl_testing_bi.copy$Resulted_Successful_Booking
confusionMatrix(predictions.rf,real_cls)









temp1<-data.frame(sqldf("select listing_neighborhood, count(*) as count_rows from p1 group by listing_neighborhood"))
temp1[order(temp1$count_rows),]

##################################################################################################################################################################

#Clustering for inquries in Rio de Janeiro
p1_clustering_pre <- filter(p1, listing_neighborhood == "Rio Comprido")
p1_clustering <- p1[, !(colnames(p1) %in% c("Resulted_Successful_Booking","target_num","host_country","listing_neighborhood",
                                            "dow_checkin","moy_checkin","contact_channel_first"))]
listing_neighborhood == "Rio Comprido"

dis_vars = c("dow_checkin","moy_checkin","guest_country","guest_user_stage_first","host_country","room_type","listing_neighborhood", "Resulted_Successful_Booking","contact_channel_first")
p1[dis_vars] <- lapply(p1[dis_vars],as.factor)

#create separate dfs, one for classification and one for regression
p1_cl <- p1[, !(colnames(p1) %in% c("target_num","guest_country","host_country","listing_neighborhood"))]

p1_cl_cm <- filter(p1_cl, contact_channel_first == "contact_me")