#setup
setwd("C:/Users/yocho/Documents/young_cho_non_work/airbnb")

packages.required = c("sqldf","ggplot2","dplyr", "lubridate")
#install.packages(packages.required)
lapply(packages.required, library, character.only = TRUE)

#read data
users <- read.csv("users.csv")
listings <- read.csv("listings.csv")
contacts <- read.csv("contacts.csv")

guestid <- unique(contacts$id_guest_anon)
hostid <- unique(contacts$id_host_anon)
listingid <- unique(listings$id_listing_anon)

#clean data

#dates to strings
dates.factor = c("ts_interaction_first","ts_reply_at_first","ts_accepted_at_first","ts_booking_at","ds_checkin_first","ds_checkout_first")
contacts[dates.factor] <- sapply(contacts[dates.factor],ymd_hms())
#contacts[dates.factor] <- sapply(contacts[dates.factor],as.character)
#sapply(contacts, class)

contacts$ts_interaction_first_zzzzzzzzzzzzz <- ymd_hms(contacts$ts_interaction_first)


ymd_hms()

#remove negative number of reviews
listings$total_reviews[listings$total_reviews < 0] <- 0

#Data exploration

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


t8 <- sqldf('select ts_interaction_first, ts_reply_at_first,
            str_to_date(ts_reply_at_first,"%Y-%m-%d-%H-%i-%s")-str_to_date(ts_interaction_first,"%Y-%m-%d-%H-%i-%s") as td1
            from contacts where id_guest_anon ="02d08d6f-a559-4803-b2f0-2310ff3edecd"')
