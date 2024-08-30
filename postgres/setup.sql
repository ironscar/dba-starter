-- create database
create database student_tracker;

-- delete database
drop database student_tracker;

-- create user
create user springstudent with password 'springstudent';

-- delete user
reassign owned BY springstudent TO postgres;
drop user springstudent;

-- create schema (by postgres and grants added to springstudent)
create schema myschema;
grant all on schema myschema to springstudent;

-- delete schema
drop schema myschema cascade;

--------------------------------------------------------------------------
