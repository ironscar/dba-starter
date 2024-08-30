-- create database
create database student_tracker;

-- create user
create user springstudent with password 'springstudent';

-- delete user
reassign owned BY springstudent TO postgres;
drop user springstudent;

-- create schema (by postgres and grants added to springstudent)
create schema myschema;
grant all on schema myschema to springstudent;

--------------------------------------------------------------------------

-- create table in schema (by springstudent)
create table myschema.tasks (task_id int primary key, name varchar(20) not null);

--------------------------------------------------------------------------
