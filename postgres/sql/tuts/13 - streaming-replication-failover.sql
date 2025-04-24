--------------------------- STREAMING REPLICATION -------------------------

-- find the replication record on primary
select* from pg_stat_replication;

-- default is hot standby on
select* from current_setting('hot_standby');

-- find the WAL reciever record on standby
select* from pg_stat_wal_receiver;

-- current WAL on primary (0/57002740)
select* from pg_current_wal_lsn();

-- last WAL received on standby (0/57002740)
select* from pg_last_wal_receive_lsn();

-- check if server is primary (false) or standby (true)
select pg_is_in_recovery();

-- max wal senders on primary
select current_setting('max_wal_senders');

-- create replication slots on primary
select pg_create_physical_replication_slot('standby_1');
select pg_create_physical_replication_slot('standby_2');

-- replication slots on primary
select* from pg_replication_slots;

-- get cluster name and standby/primary connection details
select 
	current_setting('cluster_name') cluster_name,
	CASE
		WHEN pg_is_in_recovery() = false THEN null
		WHEN current_setting('primary_conninfo') LIKE '%192.168.196.2%' THEN 'pgdb4'
		WHEN current_setting('primary_conninfo') LIKE '%192.168.196.4%' THEN 'pgdb3'
		WHEN current_setting('primary_conninfo') LIKE '%192.168.196.3%' THEN 'pgdb2'
		WHEN current_setting('primary_conninfo') LIKE '%192.168.196.5%' THEN 'pgdb1'
	END primary_conninfo, 
	CASE
		WHEN pg_is_in_recovery() = true THEN null
		ELSE current_setting('synchronous_standby_names')
	END synchronous_standby_names;

-- max streaming delay
select current_Setting('max_standby_streaming_delay');

----------------------------- FAILOVER TRIAL ---------------------------

select current_setting('primary_conninfo');
select current_setting('synchronous_standby_names');
show wal_log_hints;
show cluster_name;
show recovery_target_timeline;
show wal_keep_size;

-- change replicated to standby
select* from student;

-- update data on primary
update student set first_name = 'Iron3' where id = 1;

-- to promote standby to primary
select pg_promote();

------------------------------- MULTI-DB REPLICATION ------------------------------------

-- change replicated to standby for corresponding user and table
select* from myschema.tasks_archive;

-- update data on primary on different table owned by different user
insert into myschema.tasks_archive values (2, 'Task2', 'The second task', 'T2', null);

------------------------------- VIEW / MATERIALIZED VIEW / FDW --------------------------

-- create a view on a table on primary
create or replace view myschema.task_view as
select
	b.task_id,
	b.task_title task_title1,
	a.task_name task_title2,
	b.user_id user_id,
	a.task_type task_type,
	a.parent parent_task
from myschema.index_trial_tasks b
join myschema.tasks a
on a.task_id = b.task_id
where b.task_id % 2 = 0;

-- select data from view from standby
select* from myschema.task_view;

-- update underlying data and check replication again
insert into myschema.tasks values (10, 'Task 10', 'The tenth task', 'T2', null);

-- create an MV on a table on primary
create materialized view if not exists myschema.task_mat_view as 
select
	b.task_id,
	b.task_title task_title1,
	a.task_name task_title2,
	b.user_id user_id,
	a.task_type task_type,
	a.parent parent_task
from myschema.index_trial_tasks b
join myschema.tasks a
on a.task_id = b.task_id
where b.task_id % 2 = 0;

-- select data from MV from standby
select* from myschema.task_mat_view;

-- update underlying data, check replicated data on standby before and after MV
delete from myschema.tasks where task_id = 10;
refresh materialized view myschema.task_mat_view;

-- create remote table in pgdb4 (not part of streaming replication setup)
create table remote_table (
	id int primary key,
	name varchar(10) not null
);
insert into remote_table values (1, 'Remote-1');
select* from remote_table;

-- create fdw for pgdb4 remote_table in primary
create server pgdb4_server foreign data wrapper postgres_fdw options (
	host '192.168.196.5', port '5432', dbname 'postgres'
);
create user mapping for postgres server pgdb4_server options (user 'postgres', password 'postgrespass');
import foreign schema public limit to (remote_table) from server pgdb4_server into public;

-- query remote table on standby
select* from remote_table;

-- cleanup
drop view myschema.task_view;
drop materialized view myschema.task_mat_view;
drop foreign table remote_table;
drop user mapping for postgres server pgdb4_server;
drop server pgdb4_server;

---------------------------------------------------------------------------------------





