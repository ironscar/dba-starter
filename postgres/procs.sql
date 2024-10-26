-- anonymous block execution (if/case/loops)
do $$
declare
   counter      integer = 1;
   temp_counter integer = 1;
   first_name   varchar(50) = 'John';
   last_name    varchar(50) = 'Doe';
   payment      numeric(11,2) = 20.5;
begin
	-- get counter value
    select count(task_id) into counter from myschema.index_trial_tasks;

	-- simple loop
	loop

		-- exit condition
		exit when counter <= 0;

		-- ifelseif conditions
		if counter < 500 then
		    raise notice '% % % has been paid % USD',
		    	counter,
			   	first_name,
			   	last_name,
			   	payment;
		elsif counter < 1000 then
			raise notice '% % % has been paid % INR',
		    	counter,
			   	first_name,
			   	last_name,
			   	payment;
		else 
			raise notice '% % % has been paid % JPY',
		    	counter,
			   	first_name,
			   	last_name,
			   	payment;
		end if;
	
		-- case conditions
		case
			when counter < 500 then 
				raise notice '% % % has been paid % USD',
			    	counter,
				   	first_name,
				   	last_name,
				   	payment;
			when counter < 1000 then
				raise notice '% % % has been paid % INR',
			    	counter,
				   	first_name,
				   	last_name,
				   	payment;
			else
				raise notice '% % % has been paid % JPY',
			    	counter,
				   	first_name,
				   	last_name,
				   	payment;
		end case;

		-- nested labelled loop
		temp_counter = counter - 100;
		<<innerloop>> loop 
			exit innerloop when counter <= temp_counter; 
			raise info 'inner loop with %', counter;
			counter = counter - 30;
		end loop;

	end loop;
		   
	raise 'This is an error of code %', counter using hint = 'counter is beyond limit';
end $$;

-- other loops
do $$
declare
	counter1 int = 100;
	loop_record record;
begin

	-- while loop
	while counter1 > 0 loop
		raise info 'while counter = %', counter1;
		counter1 = counter1 - 5;
	end loop;

	-- for loop
	for loop_index in 1..10 by 2 loop
		raise info 'for counter = %', loop_index;
	end loop;

	-- reverse for loop
	for loop_index in reverse 10..1 by 2 loop
		raise info 'for_reverse counter = %', loop_index;
	end loop;

	-- row for loop
	for loop_record in select* from myschema.tasks loop
		raise info 'task record = %,%', loop_record.task_id, loop_record.task_name;
	end loop;

end $$;

-- proc exception handling
do $$
declare
	counter int = 1;
begin
	select* into strict counter from myschema.tasks where task_id > 8;
	raise info 'counter = %', counter;
exception
	when no_data_found then
		raise 'No data found';
	when too_many_rows then
		raise 'Too many rows';
	when others then
		raise;
end $$;

-------------------------------------------------------------------------------

-- optionally parametrized, non-void-return functions
create or replace function myschema.custom_subtract(
	a int default 1, 
	b int default 1
)
returns int as $$
begin
	return a - b;
end;
$$ language plpgsql;
select myschema.custom_subtract(b => 3);
drop routine myschema.custom_subtract(a int, b int);

-- return table in function
create or replace function myschema.table_fn()
returns table (id int, name varchar)
as $$
begin
	return query 
	select task_id, task_name from myschema.tasks where task_id <= 5;
end;
$$ language plpgsql;
select (myschema.table_fn()).name;
drop function myschema.table_fn;

-- return setof
create or replace function myschema.task_set()
returns setof myschema.tasks as $$
begin
	return query select* from myschema.tasks where task_id <= 5;
end;
$$ language plpgsql;
select (myschema.task_set()).*;
drop function myschema.task_set;

-------------------------------------------------------------------------------

-- table for indexes
create table myschema.index_trial_tasks (
	task_id int not null,
	task_title varchar(20),
	user_id int
);

-- insert by procedure
create or replace procedure myschema.inserter() 
as $$
begin
	truncate table myschema.index_trial_tasks;
	for i in 1..1000 loop
		insert into myschema.index_trial_tasks values (
			i, 'tt' || i, 100 + i
		);
	end loop;
	commit;
end
$$ language plpgsql;
call myschema.inserter();

-- insert by function
create or replace function myschema.inserter2() 
returns void as $$
begin
	truncate table myschema.index_trial_tasks;
	for i in 1..1000 loop
		insert into myschema.index_trial_tasks values (
			i, 'tt' || i, 100 + i
		);
	end loop;
end
$$ language plpgsql;
select myschema.inserter2();

-------------------------------------------------------------------------------

-- cursors
create or replace function myschema.cursor_trial()
returns table(p_id int, p_name varchar)
as $$
declare
	task_cursor cursor for
		select task_id, task_name from myschema.tasks where task_id <= 5;
	task_rec record;
begin
	open task_cursor;

	loop
		fetch next from task_cursor into task_rec;
		exit when not found;
		p_id = task_rec.task_id;
		p_name = task_rec.task_name;
		return next;
	end loop;

	close task_cursor;
end;
$$ language plpgsql;
select (myschema.cursor_trial()).*;
drop function myschema.cursor_trial;

-------------------------------------------------------------------------------

-- create audit table
create table myschema.task_audit (
	log_id serial primary key,
	task_id int not null,
	entry_date date,
	operation varchar(10)
);

-- trigger creation with implementation as function
create or replace function myschema.audit_log()
returns trigger as $$
begin
	insert into myschema.task_audit (task_id, entry_date, operation)
	values (new.task_id, current_date, 'INSERT');
	return new;
end; 
$$ language plpgsql;

create or replace trigger task_audit_insert_trigger 
after insert on myschema.tasks
for each row 
execute function myschema.audit_log();

-- trial insert into tasks
insert into myschema.tasks (task_id, task_name, task_desc, task_type, parent)
select t.id, t.name, t.desc, t.type, t.parent from (
	select 9 id, 'Task9' name, 'The ninth task' desc, 'T9' type, 8 parent
	union
	select 10 id, 'Task10' name, 'The tenth task' desc, 'T10' type, 8 parent
) t;

-- simple select
select* from myschema.task_audit;

-- delete trigger
drop trigger task_audit_insert_trigger on myschema.tasks;
drop function myschema.audit_log;

-------------------------------------------------------------------------------
