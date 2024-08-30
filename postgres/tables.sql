-- create table in schema (by springstudent)
create table myschema.tasks (task_id int primary key, name varchar(20) not null);

-- alter table
alter table myschema.tasks add column task_desc varchar(20) not null;
alter table myschema.tasks rename column name to task_name;

-- describe table columns
select* from information_schema.columns where table_name = 'tasks';

-- delete table
drop table myschema.tasks;

-- insert one into table
insert into myschema.tasks (task_id, task_name, task_desc)
values (1, 'Task1', 'The first task');

-- insert multiple into table
insert into myschema.tasks (task_id, task_name, task_desc)
select t.id, t.name, t.desc from (
	select 2 id, 'Task2' name, 'The second task' desc
	union
	select 3 id, 'Task3' name, 'The third task' desc
	union
	select 4 id, 'Task4' name, 'The fourth task' desc
) t;

-- update table
update myschema.tasks set
	task_desc = 'The 2nd task'
where task_id = 2;

-- delete table
delete from myschema.tasks
where task_id = 2;

-- select from table
select* from myschema.tasks
where task_name like 'Task_'
order by task_id asc;
