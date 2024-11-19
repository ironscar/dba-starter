-- display all roles
select* from pg_roles;
select* from pg_user;

-- create role
create role new_role with 
	login
	password 'new_role_pass';

-- delete role
drop role new_role;

-----------------------------------------

-- row-level security example
create table rlst as
select * from (
	select 1 id, 'Alice' name
	union
	select 2 id, 'Bob' name
	union
	select 3 id, 'Jack' name
);

-- enable rls
alter table rlst enable row level security;

-- create group role and assign select grant
create role managers;
grant select on rlst to managers;

-- create roles within group
create role alice with login password 'alicepass' in role managers;
create role bob with login password 'bobpass' in role managers;
create role jack with login password 'jackpass' in role managers;

-- create policy with user-based condition
create policy rlst_policy on rlst to managers using (lower(name) = current_user);
select* from pg_policy;

-- display only allowed rows
select* from rlst;

-- cleanup
drop role alice,bob,jack;
reassign owned by managers to postgres;
drop policy rlst_policy on rlst;
drop owned by mangers;
drop role managers;
drop table rlst;

-----------------------------------------

-- set and reset roles
select current_user, session_user;

select* from pg_user;

set role springstudent;

reset role;

-----------------------------------------

-- find where the hba configuration file is
show hba_file;
