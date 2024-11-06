
-- check db links
select* from all_db_links where db_link like '%BDW%';

-- check triggers
select* from all_triggers where owner = 'MYTI_V1';

-----------------------------------------------------------------------------------------------------

-- trial create table with partitions and indexes (use myti_v1@ledticom user)
create table myti_v1.personal_tasks_trial (
    task_id number,
    task_title varchar(20),
    task_desc varchar(100),
    user_id varchar(20)
);


-- analyze and check index stats (height > 4 or del_lf_rows > 20% => rebuild)
analyze index myti_v1.personal_idx1 validate structure;
SELECT name, height,lf_rows,lf_blks,del_lf_rows FROM INDEX_STATS;

-- rebuild index
alter index myti_v1.personal_idx1 rebuild;

-- create and delete primary key
alter table myti_v1.personal_tasks_trial add constraint pk_task primary key(task_id, user_id);
alter table myti_v1.personal_tasks_trial drop constraint pk_task;

-- create and delete indexes
create index personal_idx1 on myti_v1.personal_tasks_trial (task_id, user_id);
create index personal_idx1 on myti_v1.personal_tasks_trial (task_id, lower(user_id)); --functional index
drop index personal_idx1;

-- describe table
desc myti_v1.personal_tasks_trial;
select* from myti_v1.personal_tasks_trial;

-------------------------------------------------------------------------------------------------------
-- Below costs are found from explain plan (and seem to be independent of number of rows ??)
-------------------------------------------------------------------------------------------------------

-- direct columns in index
    -- cost = 1 for unique index or pk
    -- cost = 2 for non-unique index
    -- cost = 3 for no index or pk
insert into myti_v1.personal_tasks_trial values (2, 'Task 2', 'The second task', 'abcd4@ti.com');

-- direct columns in index
    -- cost = 1 for unique index or pk even for 1 column in where clause
    -- cost = 2 for non-unique index
    -- cost = 3 for no index or no pk or other column condition
update myti_v1.personal_tasks_trial set
    task_title = 'Task #2'
where task_id = 2;

-------------------------------------------------------------------------------------------------------

-- direct columns in where clause
    -- cost = 0 when pk applied and all keyed columns in where clause
    -- cost = 1 when unique index applied and all keyed columns in where clause
    -- cost = 2 when non-unique index applied and all keyed columns in where clause
    -- cost = 3 when pk not applied and all keyed columns in where clause
    -- cost = 3 when only one column in where clause or no key/indexes 
select * from myti_v1.personal_tasks_trial 
where 
    task_id = 3 
    and 
    user_id = 'abcd@ti.com'
;

-- functional colums in where clause
    -- cost = 2 when non-functional pk 
    -- cost = 1 when unique functional index but cost = 2 if unique non-functional index
    -- cost = 2 when non-unique functional index or non-unique non-functional index
    -- cost = 3 when no pk or indexes
select * from myti_v1.personal_tasks_trial 
where 
    task_id = 3 
    and 
    lower(user_id) = 'abcd@ti.com'
;

-------------------------------------------------------------------------------------------------------
