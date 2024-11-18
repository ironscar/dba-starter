-- display all roles
select* from pg_roles;

-- create role
create role new_role with 
	login
	password 'new_role_pass';

-- delete role
drop role new_role;
