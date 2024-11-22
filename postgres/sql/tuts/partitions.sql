-- create table for declarative partitioning
create table to_range_partition_tb (
	id int,
	name varchar(10),
	price int
) partition by range (price);

-- create range-partitioned tables
create table to_range_partition_tb_p100 partition of to_range_partition_tb for values from (0) to (100);
create table to_range_partition_tb_p200 partition of to_range_partition_tb for values from (100) to (200);
create table to_range_partition_tb_p300 partition of to_range_partition_tb for values from (200) to (300);

-- insert data
insert into to_range_partition_tb
	select * from (
	select 1 , 'Alice', 84
	union
	select 2, 'Bob', 145
	union
	select 3, 'Jack', 203
);

-- select data
select* from to_range_partition_tb;
select* from to_range_partition_tb_p100;
select* from to_range_partition_tb_p200;
select* from to_range_partition_tb_p300;
select* from to_range_partition_tb_p400;

-- create new partition after initial insert
create table to_range_partition_tb_p400 partition of to_range_partition_tb for values from (300) to (400);

-- later insert
insert into to_range_partition_tb values (4, 'Amy', 345);

-- to find all table partitions (relkind r implies tables, otherwise index inheritance also shows up)
select distinct pi.inhparent::regclass, pi.inhrelid::regclass 
from pg_inherits pi
join pg_class pc
on pi.inhrelid = pc.oid and pc.relkind = 'i';

-- check partition pruning config
select current_setting('enable_partition_pruning');

-- indexes for all partitions
create index on to_range_partition_tb (price);
select* from pg_indexes where tablename like 'to_range_partition_tb%';

-- detach/attach partitions
alter table to_range_partition_tb detach partition to_range_partition_tb_p400 concurrently;
alter table to_range_partition_tb attach partition to_range_partition_tb_p400 for values from (300) to (400);

-- example delete partition (not required if dropping parent table)
drop table to_range_partition_tb_p100;

-- cleanup above
drop index to_range_partition_tb_price_idx;
drop table to_range_partition_tb;

----------------------------------------------------------------

-- create table for inheritance partitioning






