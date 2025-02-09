-- get name and corresponding size of all tablespaces
select spcname, pg_size_pretty(pg_tablespace_size(spcname)) from pg_tablespace;

-- create new tablespace in custom data directory
create tablespace mytbspc owner postgres location '/var/lib/postgresql/data/custom_data_dir';

-- create new table in that tablespace (4kb at this point)
create table custom_space_table (id int, name varchar(10)) tablespace mytbspc;

-- insert data (12kb at this point)
insert into custom_space_table
select * from (
	select 1 , 'Alice'
	union
	select 2, 'Bob'
	union
	select 3, 'Jack'
);

-- query table
select* from custom_space_table;

-- change tablespace
alter table custom_space_table set tablespace pg_default;
alter table custom_space_table set tablespace mytbspc;

-- drop tablespace
drop tablespace mytbspc;
