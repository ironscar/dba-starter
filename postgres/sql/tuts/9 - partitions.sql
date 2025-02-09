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

-- update record in partition
update to_range_partition_tb set
	price = 96
where id = 3;

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
create table inheritance_tb (
	id int,
	name varchar(10),
	price int
);

-- child tables
create table inheritance_tb_p100 (
	CHECK (price >= 0 and price < 100)
) INHERITS (inheritance_tb);

create table inheritance_tb_p200 (
	CHECK (price >= 100 and price < 200)
) INHERITS (inheritance_tb);

create table inheritance_tb_p300 (
	CHECK (price >= 200 and price < 300)
) INHERITS (inheritance_tb);

create table inheritance_tb_p400 (
	CHECK (price >= 300 and price < 400)
) INHERITS (inheritance_tb);

-- insert trigger
CREATE OR REPLACE FUNCTION inheritance_insert_trigger()
RETURNS TRIGGER AS $$
BEGIN
	CASE
		WHEN NEW.price >= 0 and NEW.price < 100 THEN INSERT INTO inheritance_tb_p100 VALUES (NEW.*);
		WHEN NEW.price >= 100 and NEW.price < 200 THEN INSERT INTO inheritance_tb_p200 VALUES (NEW.*);
		WHEN NEW.price >= 200 and NEW.price < 300 THEN INSERT INTO inheritance_tb_p300 VALUES (NEW.*);
		WHEN NEW.price >= 300 and NEW.price < 400 THEN INSERT INTO inheritance_tb_p400 VALUES (NEW.*);
		ELSE INSERT INTO inheritance_tb VALUES (NEW.*);
	END CASE;
    RETURN NULL;
END $$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER inheritance_insert_trigger
    BEFORE INSERT ON inheritance_tb
    FOR EACH ROW 
	WHEN (pg_trigger_depth() < 1)
	EXECUTE FUNCTION inheritance_insert_trigger();

-- insert data
insert into inheritance_tb
select* from (
	select 1 , 'Alice', 84
	union
	select 2, 'Bob', 145
	union
	select 3, 'Jack', 203
	union
	select 4, 'Mike', 438
);

-- delete data
delete from inheritance_tb where id = 1;

-- update data across children 
-- (also works for update within children but for that we can use normal update)
WITH to_update as (
	DELETE FROM inheritance_tb WHERE id = 2
	RETURNING *
)
INSERT INTO inheritance_tb
SELECT id, name, 240 from to_update;

-- display
select* from inheritance_tb;
select* from inheritance_tb_p100;
select* from inheritance_tb_p200;
select* from inheritance_tb_p300;
select* from inheritance_tb_p400;

-- cleanup
drop trigger inheritance_insert_trigger on inheritance_tb;
drop function inheritance_insert_trigger;
drop table inheritance_tb cascade;
