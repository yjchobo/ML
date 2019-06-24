

drop table if exists rba_ddl.yocho_ios;
create table rba_ddl.yocho_ios
(
Review VARCHAR(10000),
rating varchar(10),
week_start VARCHAR(50),
compound float,
positive float,
negative float
);
GRANT ALL ON rba_ddl.yocho_ios TO reml_rs_etl;

--read from s3
copy rba_ddl.yocho_ios (
Review,
rating,
week_start,
compound,
positive,
negative
)
from 's3://data-load-reader-ba-team/CORE_CX/ios_va_df.csv' --need to change
ignoreheader 1
access_key_id 'AKIAIWAO6SBHTVBPRV6A'
secret_access_key '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'
delimiter ','
region 'us-west-2';

select * from rba_ddl.yocho_ios;

drop table if exists rba_ddl.yocho_android;
create table rba_ddl.yocho_android
(
Review VARCHAR(10000),
rating varchar(10),
week_start VARCHAR(50),
compound float,
positive float,
negative float
);

copy rba_ddl.yocho_android (
Review,
rating,
week_start,
compound,
positive,
negative
)
from 's3://data-load-reader-ba-team/CORE_CX/android_va_df.csv' --need to change
ignoreheader 1
access_key_id 'AKIAIWAO6SBHTVBPRV6A'
secret_access_key '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'
delimiter ','
region 'us-west-2';

select * from rba_ddl.yocho_android

create table rba_ddl.yocho_kw
(
kw VARCHAR(1000)

);
