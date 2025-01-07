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

-- disconnect persistent connections explicitly
select dblink_disconnect('dblink_local');
select dblink_disconnect('dblink_remote');

-- track connections [CHECK]
select* from pg_stat_activity;