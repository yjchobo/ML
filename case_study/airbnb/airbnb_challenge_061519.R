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

guestid <- unique(contacts$id_guest_anon)
hostid <- unique(contacts$id_host_anon)
listingid <- unique(listings$id_listing_anon)

###clean data

#create posix versions of timestamps for datetime calculations
datetimestamps = c("ts_interaction_first","ts_reply_at_first","ts_accepted_at_first","ts_booking_at")
datetimestamps.posix = c("ts_interaction_first_posix","ts_reply_at_first_posix","ts_accepted_at_first_posix","ts_booking_at_posix")
datestamps = c("ds_checkin_first","ds_checkout_first")
datestamps_posix = c("ds_checkin_first_posix","ds_checkout_first_posix")

contacts[datetimestamps] <- sapply(contacts[datetimestamps],as.character)
contacts[datestamps] <- sapply(contacts[datestamps],as.character)

contacts[datetimestamps.posix] <- sapply(contacts[datetimestamps],as.POSIXct,format="%Y-%m-%d%H:%M:%S")
contacts[datestamps.posix] <- sapply(contacts[datestamps],as.POSIXct,format="%Y-%m-%d")

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









