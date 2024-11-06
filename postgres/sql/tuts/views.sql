select* from myschema.tasks;

select* from myschema.index_trial_tasks;

-- create view
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

-- view cost = 36.86
select* from myschema.task_view;

-- delete view
drop view myschema.task_view;

-- create materialized view
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

-- refresh materialized view
refresh materialized view myschema.task_mat_view;

-- materialized view cost = 14.2
select* from myschema.task_mat_view;

-- delete materialized view
drop materialized view myschema.task_mat_view;
