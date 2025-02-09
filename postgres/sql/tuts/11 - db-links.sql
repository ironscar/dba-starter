-------------------------------- DB LINKS -------------------------------------------

-- remove one row from tasks table in student_tracker with user springstudent
delete from myschema.tasks where task_id = 10;

-- switch to postgres user and get current user
select current_user;

-- install extension
create extension dblink;

-- create single persistent connection
select dblink_connect('dblink_local', 
	'dbname=student_tracker user=springstudent password=springstudent options=-csearch_path=');
select dblink_connect('dblink_remote', 
	'host=192.168.196.3 port=5432 dbname=student_tracker user=springstudent password=springstudent options=-csearch_path=');

-- dblink to other database on same container over dblink (no task 10 as deleted in container 1)
select* from dblink(
	'dbname=student_tracker user=springstudent password=springstudent options=-csearch_path=',
	'select* from myschema.tasks'
) as tasks(task_id int, task_name text, task_desc text, task_type text, parent int);

-- dblink to other database on same container over dblink with quotes in query
select* from dblink(
	'dblink_local',
	format('select* from myschema.tasks where task_type=%s', quote_literal('TX'))
) as tasks(task_id int, task_name text, task_desc text, task_type text, parent int);

-- dblink to other database on different container over dblink (returns task 10 which still exists in container 2)
select* from dblink(
	'host=192.168.196.3 port=5432 dbname=student_tracker user=springstudent password=springstudent options=-csearch_path=',
	'select* from myschema.tasks'
) as tasks(task_id int, task_name text, task_desc text, task_type text, parent int);

-- combined local + remote table join
select s.first_name, s.last_name, t.task_id, t.task_name, t.task_type 
from student s
join (
	select* from dblink(
		'dblink_remote',
		'select task_id, task_name, task_type, parent from myschema.tasks where parent is not null'		
	) as tasks (task_id int, task_name text, task_type text, parent int)
) t
on s.id = t.parent;

-- track dblinks within container
select* from pg_stat_activity;

-- track dblinks for container 1 to container 2
select* from dblink('dblink_remote', 'select datid, usename, application_name, client_addr from pg_stat_activity')
as t (datid int, usename text, application_name text, client_addr text);

-- disconnect persistent connections explicitly
select dblink_disconnect('dblink_local');
select dblink_disconnect('dblink_remote');

-------------------------------- FOREIGN DATA WRAPPERS ------------------------------------

-- install extension
create extension postgres_fdw;

-- create foreign server
create server pgdb2_server foreign data wrapper postgres_fdw options (
	host '192.168.196.3', port '5432', dbname 'student_tracker'
);

-- create user mapping
create user mapping for postgres server pgdb2_server options (user 'springstudent', password 'springstudent');

-- create foreign table
create foreign table fdw_tasks (
	task_id int, 
	task_name varchar(20),
	task_desc varchar(20),
	task_type varchar(10),
	parent int
) server pgdb2_server options (schema_name 'myschema', table_name 'tasks');
-- query data from foreign table (task 10 which is only in container 2 is visible)
select* from fdw_tasks;

-- import schema
import foreign schema myschema limit to (tasks) from server pgdb2_server into public;
-- query data from foreign table imported from schema (task 10 which is only in container 2 is visible)
select* from tasks;

-- list all foreign servers, foreign tables & user mappings
select* from pg_foreign_server;
select* from pg_user_mapping;
select* from pg_foreign_table;

-- list all open connections to foreign servers
select* from postgres_fdw_get_connections();

-- cleanup
-- remove foreign table
drop foreign table fdw_tasks;
drop foreign table tasks;
-- remove specific user mapping from a foreign server
drop user mapping for postgres server pgdb2_server;
-- remove foreign server
drop server pgdb2_server;
