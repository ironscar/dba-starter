create table myschema.index_trial_tasks (
	task_id int not null,
	task_title varchar(20),
	user_id int
);

-- insert
insert into myschema.index_trial_tasks values (4, 'Task4', 102);
insert into myschema.index_trial_tasks values (5, 'Task5', 102);
insert into myschema.index_trial_tasks values (6, 'Task6', 101);
insert into myschema.index_trial_tasks values (7, 'Task7', 102);
insert into myschema.index_trial_tasks values (8, 'Task8', 101);
insert into myschema.index_trial_tasks values (9, 'Task9', 101);
insert into myschema.index_trial_tasks values (10, 'Task10', 102);

-- find the pkey/unique constraints
select* from pg_constraint where conname like 'index_trial_tasks%';

-- add/drop pkey/unique constraint
alter table myschema.index_trial_tasks add primary key (task_id);
alter table myschema.index_trial_tasks drop constraint index_trial_tasks_pkey;
alter table myschema.index_trial_tasks add unique (task_id);
alter table myschema.index_trial_tasks drop constraint index_trial_tasks_task_id_key;

-- find the indexes
select* from pg_indexes where schemaname = 'myschema';

-- add/drop single column index
create index myschema_index1 on myschema.index_trial_tasks (user_id);
drop index myschema.myschema_index1;

-- add/drop multi column index
create index myschema_index2 on myschema.index_trial_tasks (task_id, user_id);
drop index myschema.myschema_index2;

-- add/drop functional index
create index myschema_index3 on myschema.index_trial_tasks (lower(task_title));
drop index myschema.myschema_index3;

-- add/drop partial index
create index myschema_index4 on myschema.index_trial_tasks (task_id) where task_id < 5;
drop index myschema.myschema_index4;

-- select trials with cost
select* from myschema.index_trial_tasks
where task_id < 5;
