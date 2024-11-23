-- create existing table to be partitioned
create table exist_tb (
	id int,
	name varchar(10),
	price int
);

-- insert data into existing table (more inserting might be going on during partitioning)
insert into exist_tb
	select * from (
	select 1 , 'Alice', 84
	union
	select 2, 'Bob', 145
	union
	select 3, 'Jack', 203
);

----------------------------------------------------------------------------------

-- create actual partition table 
-- have to mention columns explicitly and cannot use create as table because it doesn't allow to partition with that
-- hence cannot generalize this either so create this outside of function
create table exist_tb_partition(
	id int,
	name varchar(10),
	price int
) partition by range (price);

-- procedure to partition existing table by equal ranges
create or replace procedure range_partition_existing_table 
(tb_name text, new_tb_name text, tb_col text, range_limit int)
as $$
declare
	v_max int = 0;
	v_min int = 0;
	v_current int = 0;
	v_count int = 1;
	v_new_partition text;
	backup_tb text;
begin
	-- get min and max values
	-- use format where each entry is a new argument (even if same value is repeated, it comes twice in args)
	-- because the placeholders don't allow specifying position so once that arg is used, cannot use it again
	-- we could use `using` for that which allows placeholders like `$1` and `$2` but only works if select is used
	-- `using` also doesn't work for tables and columns etc
	-- table, column etc is %I, numbers are %L and strings are %S
	execute format('select min(%I), max(%I) from %I', tb_col, tb_col, tb_name) into v_min, v_max;
	v_count = ceil((v_max - v_min)/range_limit) + 1;
	v_current = v_min;
	raise info 'number of partitions = %', v_count;

	-- create all partitions and migrate data
	for partition_index in 1..v_count loop
		raise info 'partition_index = %', partition_index;

		v_new_partition = tb_name || '_' || partition_index;

		-- create the partition table if not exists with data for that partition
		execute format('create table if not exists %I as 
			( with migrows as (
				delete from %I where %I between %L and %L
				returning *
			) select* from migrows)', 
			v_new_partition, tb_name, tb_col, v_current, v_current + range_limit);

		-- add partition table to partitioned table
		execute format('alter table %I attach partition %I for values from (%L) to (%L)', 
			new_tb_name, v_new_partition, v_current, v_current + range_limit);

		-- update v_current
		v_current = v_current + range_limit;
	end loop;

	-- rename original table to backup and new table to original table to redirect all data
	backup_tb = tb_name || '_bk';
	execute format('alter table %I rename to %I', tb_name, backup_tb);
	execute format('alter table %I rename to %I', new_tb_name, tb_name);

	-- insert all remaining rows that came into old during process into new (will be small number now)
	execute format('insert into %I select * from %I', tb_name, backup_tb);

	-- drop old table
	execute format('drop table %I', backup_tb);
	commit;

end $$ language plpgsql;

-- call procedure
call range_partition_existing_table('exist_tb', 'exist_tb_partition', 'price', 50);

-- select
select* from exist_tb;
select* from exist_tb_1;
select* from exist_tb_2;
select* from exist_tb_3;
select* from exist_tb_bk;
select* from exist_tb_partition;

-- cleanup
drop routine range_partition_existing_table;
drop table exist_tb;

----------------------------------------------------------------------------------
