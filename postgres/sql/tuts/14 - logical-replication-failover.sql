-- create new tables in new schema in pgdb4 & pgdb2 to be logically replicated to primary of streaming replication setup
create schema logrec;
create table logrec.tlr1 (
	id int primary key,
	name varchar(10) not null
);
create table logrec.tlr2 (
	id int primary key,
	name varchar(10) not null
);

-- insert only on pgdb4 (publisher node)
insert into logrec.tlr1 values (1, 'LogRec-1');
insert into logrec.tlr1 values (2, 'LogRec-2');
insert into logrec.tlr2 values (1, 'RecLog-1');
insert into logrec.tlr2 values (2, 'RecLog-2');

-- select data
select* from logrec.tlr1;
select* from logrec.tlr2;

-- create publications on pgdb4 (publisher node) after setting wal_level to logical
show wal_level;
create publication pub1 for table logrec.tlr1, logrec.tlr2;

-- create subscriptions on pgdb2 (primary of streaming setup / subscriber node) after setting wal_level to logical
create subscription mysub 
	connection 'host=172.26.144.1 port=5432 user=postgres dbname=postgres password=postgrespass' 
	publication pub1;

-- insert additional data to both tables in pgdb4 (publisher)
insert into logrec.tlr1 values (4, 'LogRec-4');
insert into logrec.tlr2 values (4, 'RecLog-4');

-- cleanup
drop table logrec.tlr1,logrec.tlr2;
drop subscription mysub;
drop publication pub1;
drop schema logrec;
