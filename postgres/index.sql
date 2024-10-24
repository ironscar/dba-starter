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
create index myschema_index1 on myschema.index_trial_tasks (task_id);
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

-- simple task_id select trial with cost
-- none (cost = 18.5)
-- pk/unique/index (cost = 8.29)
select* from myschema.index_trial_tasks
where task_id = 125;

-- task_title functional select trial with cost
-- none (cost = 21)
-- pk/unique/index on task_title (cost = 21)
-- functional index on task_title (cost = 10.59)
select* from myschema.index_trial_tasks
where lower(task_title) = 'tt100';

-- reindex
reindex (verbose,concurrently) index myschema.myschema_index3;
reindex table myschema.index_trial_tasks;
reindex schema myschema;
reindex database student_tracker;