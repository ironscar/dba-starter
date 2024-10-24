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

-- direct execution of anonymous block
do $$
declare
   counter    integer = 1;
   first_name varchar(50) = 'John';
   last_name  varchar(50) = 'Doe';
   payment    numeric(11,2) = 20.5;
begin
	-- get counter value
    select count(task_id) into counter from myschema.index_trial_tasks;

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
		   
	raise 'This is an error of code %', counter using hint = 'counter % is beyond limit';
end $$;



