###setup
#setwd("C:/Users/yocho/Documents/young_cho_non_work/airbnb")
setwd("C:/Users/YC/portfolio/case_study/airbnb")


packages.required = c("sqldf","ggplot2","dplyr", "lubridate")
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






###Data exploration

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
              -- target variable
              (case when c.ts_booking_at_posix is null then 0 else 1 end) as target,
              
              -- reservation related attributes
              c.days_duration_requested_stay,
              c.m_guests,
              c.days_from_first_contact_to_first_checkin,
              c.dow_checkin,
              c.moy_checkin,
              
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

#turn discrete vars to factors before running


#clustering on hosty and guests and show stats per cluster


