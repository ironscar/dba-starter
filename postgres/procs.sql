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
select* from myschema.tasks;
select* from myschema.tasks_archive;
select* from myschema.task_audit;
