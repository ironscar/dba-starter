-- this file is to try the most optimal version of table-wise bulk archiving

-- create
create table myschema.list (
	list_id int primary key,
	list_name varchar(10) not null,
	deleted_ts date
);
create table myschema.items (
	item_id int primary key,
	list_id int,
	part_number varchar(10),
	qty int,
	foreign key (list_id) references myschema.list(list_id)
);
create table myschema.archived_list (
	list_id int primary key,
	list_name varchar(10) not null,
	deleted_ts date,
	archived_ts date
);
create table myschema.archived_items (
	item_id int primary key,
	list_id int,
	part_number varchar(10),
	qty int
);

-- insert data
insert into myschema.list (list_id, list_name, deleted_ts)
	select 1, 'List 1', null::date
	union
	select 2, 'List 2', current_date::date
	union
	select 3, 'List 3', current_date::date
	union
	select 4, 'List 4', null::date
	union
	select 5, 'List 5', current_date::date;
insert into myschema.items (item_id, list_id, part_number, qty)
	select 1, 1, 'OPA1', 2
	union
	select 2,1,'OPA2', 3
	union
	select 3, 2, 'ADA1', 4
	union
	select 4, 3, 'TPS5', 5
	union
	select 5, 5, 'TPA3', 6
	union
	select 6, 5, 'TPA6', 8;

-- archiving job without limits per loop
do $$
declare
	list_ids int[];
begin

	-- get lists to be deleted
	list_ids = array(select list_id from myschema.list where deleted_ts is not null);

	-- if it was 1000 at a time, then we can loop through until list_ids is empty
	if array_length(list_ids, 1) > 0 then

		-- copy lists
		insert into myschema.archived_list (list_id, list_name, deleted_ts, archived_ts)
			select list_id, list_name, deleted_ts, current_date from myschema.list
			where list_id = any(list_ids);
		
		-- delete and insert items in one go
		with archived_items as (
			delete from myschema.items
			where list_id = any(list_ids)
			returning *
		) insert into myschema.archived_items
			select * from archived_items;
		
		-- delete lists
		delete from myschema.list where list_id = any(list_ids);
	else
		raise info 'no lists to archive';
	end if;
		
end $$;

-- archiving job with limits per loop
do $$
declare
	loop_limit int = 2;
	loop_counter int = 0;
	list_ids int[];
begin
loop

	-- increment counter and log
	loop_counter = loop_counter + 1;
	raise info 'loop count = %', loop_counter;

	-- get first x lists to be deleted
	list_ids = array(
		select list_id from myschema.list where deleted_ts is not null limit loop_limit
	);

	-- if it was 1000 at a time, then we can loop through until list_ids is empty
	if array_length(list_ids, 1) > 0 then

		-- copy lists
		insert into myschema.archived_list (list_id, list_name, deleted_ts, archived_ts)
			select list_id, list_name, deleted_ts, current_date from myschema.list
			where list_id = any(list_ids);
		
		-- delete and insert items in one go
		with archived_items as (
			delete from myschema.items
			where list_id = any(list_ids)
			returning *
		) insert into myschema.archived_items
			select * from archived_items;
		
		-- delete lists
		delete from myschema.list where list_id = any(list_ids);

	else
		raise info 'no lists to archive';
		exit;
	end if;

end loop;
end $$;

-- select
select* from myschema.list;
select* from myschema.items;
select* from myschema.archived_list;
select* from myschema.archived_items;

-- temp cleanup
truncate table myschema.items;
delete from myschema.list;
truncate table myschema.archived_list;
truncate table myschema.archived_items;

-- cleanup
drop table myschema.items;
drop table myschema.list;
drop table myschema.archived_list;
drop table myschema.archived_items;
