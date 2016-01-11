
drop table if exists POS_DEVICE;
create table POS_DEVICE (	
	id	bigint primary key,
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
	transaction_id bigint primary key,
	device_id	 bigint,	
	marked_suspect_ts_millis	 bigint,
	reason text
) distributed by (transaction_id);












-- simulate some fake suspect markings

truncate table SUSPECT;

INSERT INTO SUSPECT (transaction_id, device_id, marked_suspect_ts_millis, text) values 
	(7044035274418018129, 969, 7933570586185119399,"test");

--
-- create a view containing the columns / rows for training the model

drop view TRANSACTION_SUSPECT_VIEW;

create or replace view TRANSACTION_SUSPECT_VIEW as
	   select 
			t.id, 
			t.device_id, 
			t.transaction_value, 
			t.account_id, 
			to_timestamp(t.ts_millis / 1000) as ts,  -- timestamp
			date_part('hour', to_timestamp(t.ts_millis / 1000)) as hour, -- hour  
			(s.marked_suspect_ts_millis IS NOT NULL)::int as possible_fraud
		from 
			TRANSACTION t LEFT OUTER JOIN SUSPECT s 			
			ON (t.id=s.transaction_id);

	
select * from TRANSACTION_SUSPECT_VIEW	
	
SELECT madlib.linregr_train( 'TRANSACTION_SUSPECT_VIEW',
                             'TRANSACTION_SUSPECT_linregr',
                             'possible_fraud',
                             'ARRAY[1, transaction_value, device_id]'
                           );















 8545394225727951003       347             85.21       3295 1450479768717    NULL


truncate table transaction;
truncate table SUSPECT;

insert into SUSPECT (transaction_id, device_id, marked_suspect_ts_millis) values ( 8545394225727951003, 347, 1449679774827)


