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
	select 2, 'List 2', null::date
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

-- select
with item_counts as (
	select list_id, count(item_id) item_count
	from myschema.items
	group by list_id
)
select
	a.list_id,
	a.list_name,
	coalesce(b.item_count, 0),
	a.deleted_ts
from myschema.list a
left join item_counts b
on a.list_id = b.list_id;

select* from myschema.items;

-- actual archiving job
do $$
declare
	loop_counter int = 0;
	list_ids int[];
begin
	-- log
	raise info 'run log %', loop_counter;

	-- get lists to be deleted
	list_ids = array(select list_id from myschema.list where deleted_ts is not null);

	-- if it was 1000 at a time, then we can loop through until list_ids is empty
	if array_length(list_ids,1) > 0 then

		-- copy list and items using unnest(array)
		
		-- delete items
		
		-- delete list
	
	end if;
		
end $$;

-- cleanup
drop table myschema.list;
drop table myschema.items;
drop table myschema.archived_list;
drop table myschema.archived_items;
