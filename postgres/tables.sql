-- create table in schema (by springstudent)
create table myschema.tasks (task_id int primary key, name varchar(20) not null);
create table myschema.tasks_archive (
	task_id int primary key, 
	task_name varchar(20) not null,
	task_desc varchar(20) not null,
	task_type varchar(10) default null,
	parent int default null
);

-- alter table
alter table myschema.tasks add column task_desc varchar(20) not null;
alter table myschema.tasks add column task_type varchar(10) default null;
alter table myschema.tasks add column parent int default null;
alter table myschema.tasks rename column name to task_name;
alter table myschema.tasks drop constraint tasks_pkey;

-- delete table
drop table myschema.tasks;

-- insert one into table
insert into myschema.tasks (task_id, task_name, task_desc)
values (1, 'Task1', 'The first task');

-- insert multiple into table
insert into myschema.tasks (task_id, task_name, task_desc, task_type, parent)
select t.id, t.name, t.desc, t.type, t.parent from (
	select 2 id, 'Task2' name, 'The second task' desc, 'T2' type, 1 parent
	union
	select 3 id, 'Task3' name, 'The third task' desc, 'T1' type, 1 parent
	union
	select 4 id, 'Task4' name, 'The fourth task' desc, 'T1' type, 3 parent
) t;

insert into myschema.tasks (task_id, task_name, task_desc, task_type, parent)
select t.id, t.name, t.desc, t.type, t.parent from (
	select 5 id, 'Task5' name, 'The fifth task' desc, 'T3' type, null parent
	union
	select 6 id, 'Task6' name, 'The sixth task' desc, 'T3' type, 5 parent
	union
	select 7 id, 'Task7' name, 'The seventh task' desc, 'T3' type, 5 parent
) t;

-- update table
update myschema.tasks set
	task_desc = 'The 2nd task'
where task_id = 2;

-- delete table
delete from myschema.tasks
where task_id = 2
;

-- select with
with myta1 as (
	select* from myschema.tasks
	where task_id <= 3
	order by task_id asc
) 
select * from myta1
offset 1 limit 1;

-- aggregate select from table
select task_type, count(task_id) cnt 
from myschema.tasks
group by task_type
having count(task_id) > 1;

-- recursive select (to get a hierarchy of all tasks for example)
with recursive cte1 as (
	select 
		task_id,
		task_id::text hierarchy, 
		1 as depth,
		task_name, 
		task_desc,
		task_type,
		parent,
		task_id super_root
	from myschema.tasks 
	where parent is null
	union
	select 
		mst.task_id,
		mst.task_id || '->' || cte1.hierarchy, 
		cte1.depth + 1 depth,
		mst.task_name, 
		mst.task_desc, 
		mst.task_type, 
		mst.parent,
		cte1.super_root super_root
	from myschema.tasks mst
	join cte1
	on mst.parent = cte1.task_id
)
select* from cte1
order by task_id;

-- delete returning to insert
with archived_rows as (
	delete from myschema.tasks
	where task_id in (5,6,7)
	returning *
)
insert into myschema.tasks_archive
select * from archived_rows;

-- merge into
merge into myschema.tasks tgt
using (
	select 2 id, null name, null desc, 'TY' type, CAST(null as int) parent
	union
	select 3 id, null name, null desc, 'TX' type, CAST(null as int) parent
	union
	select 4 id, null name, null desc, 'TX' type, CAST(null as int) parent
	union
	select 5 id, 'Task 5' name, 'The fifth task' desc, 'TZ' type, CAST(null as int) parent
	union
	select 6 id, 'Task 6' name, 'The sixth task' desc, 'TZ' type, 5 parent
	union
	select 7 id, 'Task 7' name, 'The seventh task' desc, 'TZ' type, 5 parent
) src
on src.id = tgt.task_id
when matched and src.type = 'TY' then delete 
when matched and src.type = 'TX' then update set task_type = src.type
when not matched then insert (task_id, task_name, task_desc, task_type, parent)
values (src.id, src.name, src.desc, src.type, src.parent);

-- simple select
select* from myschema.tasks;
select* from myschema.tasks_archive;

-- utility tables
select* from information_schema.columns where table_name = 'tasks';
select* from pg_catalog.pg_constraint where conname like 'tasks%';
select* from pg_catalog.pg_database;
