# DB Administration: Managing users & roles

## Users vs Roles

- A `user` is a `role` with `login` permissions
  - Today `CREATE USER` or `CREATE GROUP` internally does `CREATE ROLE` and the former adds the login permission by default
  - When roles contain other roles, they are called group roles
  - Roles & Users have been combined since Postgres 8.1

## Create roles

- We can create roles using `create role <rolename> [with option]` and see them in `pg_roles`
  - All the `pg_` roles are system-created roles
  - Following options are available and `WITH` is optional
    - `LOGIN` gives the role login functionality making it a user
    - `PASSWORD` allows providing a password for the role (in single-quotes)
    - `CREATEDB` allows the role to create new databases
    - `CREATEROLE` allows the role to create new roles
    - `SUPERUSER` allows marking the role as a superuser (only a superuser can create another)
    - `VALID UNTIL` allows specifying a validity date (in single-quotes)
    - `CONNECTION LIMIT` allows specifying the number of concurrent connections the role can make

## Grant & Revoke

- Roles, once created, cannot do anything in the databases
  - they need to be granted privileges to do things in the database
- Tables have following grants:
  - `SELECT`, `INSERT`, `DELETE`, `UPDATE`, `TRUNCATE`, `TRIGGER` (there are some more)
  - specified as `GRANT <grant> ON <table> TO <role/user>`
  - we can specify multiple grants separated by commas
  - we can also specify grant as `ALL` which provides all of the above on tables
- We can provide grants to all tables in a schema by `GRANT ALL ON ALL TABLES IN SCHEMA <schema>`
  - or all objects in schema by `GRANT ALL ON SCHEMA <schema>`
- Revoke works the opposite way by just replace `GRANT` by `REVOKE` and `TO` by `FROM`
  - we can also use `REASSIGN` as specified in `setup.md`
- There are more grants and revokes
  - Refer https://www.postgresql.org/docs/current/sql-grant.html and https://www.postgresql.org/docs/current/sql-revoke.html
  - Databases have `CREATE`, `CONNECT` and `TEMPORARY` privileges
  - Foreign Data Wrappers have `USAGE` privileges
  - Functions/Procedures have `EXECUTE` privileges
  - Schema have `CREATE`, `USAGE` privileges
  - Tablespaces have `CREATE` privileges

## Alter roles

- [CONTINUE-HERE]

## Drop roles

- We can drop roles with `drop role <rolename>`

---
