-- create new tables in new schema in publisher & subscriber to be logically replicated to primary of streaming replication
create schema logrec;
create table logrec.tlr1 (
	id int primary key,
	name varchar(10) not null
);
create table logrec.tlr2 (
	id int primary key,
	name varchar(10) not null
);

-- insert only on publisher node
insert into logrec.tlr1 values (1, 'LogRec-1');
insert into logrec.tlr1 values (2, 'LogRec-2');
insert into logrec.tlr2 values (1, 'RecLog-1');
insert into logrec.tlr2 values (2, 'RecLog-2');

-- select data
select* from logrec.tlr1;
select* from logrec.tlr2;

-- create publications on publisher node after setting wal_level to logical
show wal_level;
create publication pub1 for table logrec.tlr1, logrec.tlr2;

-- create subscriptions on pgdb2 (primary of streaming setup / subscriber node) after setting wal_level to logical
create subscription mysub 
	connection 'host=172.26.144.1 port=5432 user=postgres dbname=postgres password=postgrespass' 
	publication pub1;

-- get all subscriptions and their stats on subscriber
select* from pg_subscription;
select* from pg_stat_subscription;

-- get all publications and replication slots on publisher
select* from pg_publication;
select* from pg_replication_slots;

-- insert additional data to both tables in publisher node
insert into logrec.tlr1 values (6, 'LogRec-6');
insert into logrec.tlr2 values (6, 'RecLog-6');

-- logical failover slots to consider on subscriber
SELECT subslotname FROM  pg_subscription
WHERE subfailover AND subslotname IS NOT NULL
;

-- logical failover slots replication status on promoted standby
SELECT slot_name, (synced AND NOT temporary AND invalidation_reason IS NULL) AS failover_ready
FROM pg_replication_slots
WHERE slot_name IN ('mysub');

-- cleanup
delete from logrec.tlr1 where id > 2;
delete from logrec.tlr2 where id > 2;
alter subscription mysub disable;
alter subscription mysub set (slot_name = NONE);
drop subscription mysub;
select pg_drop_replication_slot('mysub');
drop table logrec.tlr1,logrec.tlr2;
drop publication pub1;
drop schema logrec;
