--
-- $ psql 
-- gpadmin=# CREATE USER pivotal WITH SUPERUSER LOGIN;
-- CREATE ROLE
-- gpadmin=# ALTER ROLE pivotal WITH PASSWORD 'pivotal';
-- ALTER ROLE
-- gpadmin=# CREATE DATABASE gemfire;
-- CREATE DATABASE
-- gpadmin=# GRANT ALL ON DATABASE gemfire TO pivotal;
-- GRANT
-- \q
--
--
--
drop table if exists POS_DEVICE;
create table POS_DEVICE (	
	id	bigint ,
	location text,
	merchant_name	text
) distributed by (id);		
 

drop table if exists TRANSACTION;
create table TRANSACTION (		
	id bigint,
	device_id	 bigint,
	transaction_value decimal(10,2),
	account_id bigint,
	ts_millis bigint
) distributed by (id);

drop table if exists SUSPECT;
create table SUSPECT (		
	transaction_id bigint,
	device_id	 bigint,	
	marked_suspect_ts_millis	 bigint,
	reason text
) distributed by (transaction_id);


CREATE TABLE zip_codes 
	(ZIP char(5), LATITUDE double precision, LONGITUDE double precision, 
	CITY varchar, STATE char(2), COUNTY varchar);


---



create or replace function average_value_percentage(accountId bigint, value decimal)
  returns DECIMAL AS '
	  select ($2-avg(transaction_value))/avg(transaction_value) as average_value_percentage 
	  	from TRANSACTION where account_id=$1 ' 
  
 language sql STABLE;

-- need to copy the zip_codes_states.csv files to GPDB master node before loading
	
COPY zip_codes FROM '/home/gpadmin/zip_codes_states.csv' DELIMITER ',' CSV HEADER;

create or replace function distance_in_meters(county1 text, county2 text)
  returns Integer AS '
 	SELECT
 	ROUND(AVG(
 		ACOS( 
 		SIN( radians(z1.latitude) ) * SIN( radians(z2.latitude) ) + 
		COS( radians(z1.latitude) )*COS( radians(z2.latitude) )*COS( radians(z2.longitude) - radians(z1.longitude) ) 
 		) * 6371000
 	)) :: integer
 	from zip_codes z1, zip_codes z2
 	where z1.county = $1 and z2.county = $2
  '
 language sql STABLE;

 
create or replace view home_location(accountId bigint)
  AS '
	  	
	select p.location 
		FROM POS_DEVICE p JOIN TRANSACTION t ON (p.id=t.device_id)
		WHERE t.account_id=$1
		GROUP BY p.location 
		ORDER BY count(p.location) desc LIMIT 1
 ' 
  
 language sql STABLE;


 create or replace function had_recent_fraud(deviceid bigint)
  returns INTEGER AS '
	  	
	select count(t.id) 
		FROM 
			TRANSACTION t JOIN SUSPECT s 			
			ON (t.id=s.transaction_id)
		WHERE t.device_id=$1
 '   
 language sql STABLE;
 
 
 
create or replace view TRANSACTION_SUSPECT_VIEW as
	   select 
	        average_value_percentage(t.account_id) as average_value_percentage,	   		
	   		distance_in_meters(
	   				split_part(p.location, ',', 1), split_part(home_location(t.account_id), ',', 1)
	   			) as distance_from_home_pos,
	   		had_recent_fraud(t.device_id) as had_recent_fraud,
			(s.marked_suspect_ts_millis IS NOT NULL)::int as possible_fraud
		from 
			TRANSACTION t LEFT OUTER JOIN SUSPECT s JOIN POS_DEVICE p			
			ON (t.id=s.transaction_id) AND (s.device_id=p.id);



	
SELECT madlib.linregr_train( 'TRANSACTION_SUSPECT_VIEW',
                             'TRANSACTION_SUSPECT_linregr',
                             'possible_fraud',
                             'ARRAY[1, transaction_value, device_id]'
                           );















 8545394225727951003       347             85.21       3295 1450479768717    NULL


truncate table transaction;
truncate table SUSPECT;

insert into SUSPECT (transaction_id, device_id, marked_suspect_ts_millis) values ( 8545394225727951003, 347, 1449679774827)


