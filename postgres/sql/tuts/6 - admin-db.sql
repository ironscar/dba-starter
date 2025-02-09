select* from pg_database;

-- create an example template database
create database mytemplate;
alter database mytemplate with is_template true;
create table random_table (someId int, name varchar(10));
insert into random_table values (1, 'something');
select* from random_table;

-- create a database with the custom template (find random_table in it)
create database mydb with template mytemplate;

-- check connection stats table
select* from pg_stat_activity;

-- kill other sessions based on pid in stats table
select pg_terminate_backend(pid) from pg_stat_activity
where pid != pg_backend_pid() and datname = 'mydb';

-- cleanup other databases
drop database mydb;
alter database mytemplate with is_template false;
drop database mytemplate;

-- find config params for a DB
select* from pg_settings;

----------------------------------------------------------------------------------

-- get size of DB table (not including its indexes etc)
select* from pg_size_pretty(pg_relation_size('myschema.tasks'));

-- get size of DB table including indexes etc
select* from pg_size_pretty(pg_total_relation_size('myschema.tasks'));

-- get size of whole DB
select* from pg_size_pretty(pg_database_size('student_tracker'));

-- get size of indexes
select* from pg_size_pretty(pg_indexes_size('custom_users_pkey'));

-- get size of tablespace
select* from pg_size_pretty(pg_tablespace_size('pg_default'));
