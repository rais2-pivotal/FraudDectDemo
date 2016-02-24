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
drop table if exists POS_DEVICE cascade;
create table POS_DEVICE (	
	id	bigint ,
	location text,
	merchant_name	text
) distributed by (id);		
 

drop table if exists TRANSACTION cascade;
create table TRANSACTION (		
	id bigint,
	device_id	 bigint,
	transaction_value decimal(10,2),
	account_id bigint,
	ts_millis bigint
) distributed by (id);


drop table if exists ZIP_CODES cascade;
CREATE TABLE ZIP_CODES 
	(ZIP char(5), LATITUDE double precision, LONGITUDE double precision, 
	CITY varchar, STATE char(2), COUNTY varchar, NAME varchar);
	
COPY zip_codes FROM '/staging/FraudDectDemo/Server/scripts/zip_codes_states.csv' DELIMITER ',' CSV HEADER;

drop table if exists SUSPECT ;
create table SUSPECT (		
	transaction_id bigint,
	device_id	 bigint,	
	marked_suspect_ts_millis	 bigint,
	reason text,
	marked int
) distributed by (transaction_id);

---

create view suspect_view as (select t.*,marked_suspect_ts_millis,s.reason,s.marked 
from transaction t left join suspect s on t.id=s.transaction_id);


drop table if exists pos_data cascade;
create table pos_data as
with single_codes as (SELECT DISTINCT ON (z.county,z.state) z.latitude, z.longitude, z.county,z.name as state from zip_codes z where z.latitude is not null)
select p.*, z.latitude, z.longitude from pos_device p, single_codes z where 
split_part(p.location, ' ', 1) like z.county and trim(split_part(p.location, ',', 2)) like z.state;

