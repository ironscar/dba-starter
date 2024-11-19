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
- There is also a `pg_user` table which contains only custom login roles created

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

- We follow `ALTER ROLE <rolename> [WITH] OPTION` where `WITH` is optional and has following options:
  - `SUPERUSER` or `NOTSUPERUSER`
  - `CREATEDB` or `NOCREATEDB`
  - `CREATEROLE` or `NOCREATEROLE`
  - `INHERIT` or `NOINHERIT` (determine if role inherits privileges from roles of which it is member)
  - `LOGIN` or `NOLOGIN`
  - `REPLICATION` or `NOREPLICATION`
  - `BYPASSRLS` or `BYPASSRLS` (determine if role can bypass row-level security (RLS) policy)
  - `CONNECTION LIMIT limit`
  - `PASSWORD 'pass'` or `PASSWORD NULL` (to change password)
  - `VALID UNTIL '<TIME/DATE>'`
- We can also use `ALTER ROLE <rolename> RENAME TO <newrolename>`
  - superusers roles can rename any role
  - createrole roles can rename non-superuser roles
  - role cannot rename itself
- We can also set specific configuration parameters per role per database:
  - `ALTER ROLE <role>|CURRENT_USER|SESSION_USER|ALL [IN DATABASE <db>] SET <config_param> = <newvalue>`
  - Roles can do this for themselves while superusers and createrole roles follow more privileges as before

## Drop roles

- We can drop roles with `drop role <rolename>`
  - this throws error if it has DB objects it owns
  - So we should make some other role the owner for them before dropping this
  - `REASSIGN OWNED BY <role1> to <role2>` reassigns all owned objects to `role2` as owner
  - then we can safely delete `role1` as long as there were no policies to `role1`
    - reassign doesn't help with dropping roles with policies
    - its generally safe to make the superuser the owner to it
  - we can also choose to drop everything owned by the role by `DROP OWNED BY <role1>` but this is not safe
    - this can drop all policies to that role and can be used if we know nothing else is there
- If a group role has some privileges like grants and there are child roles in it
  - the child roles can be dropped before reassigning the grant but not the group role

---

## Set Role

- `SET ROLE <rolename>` can be used to temporarily update the role in the DB session
- It updates the `CURRENT_USER` but not the `SESSION_USER`
  - `SESSION_USER` is the one that originally connected to the database
- you cannot set role to session_user, you always have to be explicit with role name
  - You can use `RESET ROLE` to be more generic
- Sometimes trying to switch to superuser from nonsuperuser role can throw errors
  - If original role is superuser and new role is not, it seems to be possible to switch by name
  - if original is not superuser and we try to set it, it would fail

---

## Group roles

- We can create an initial role `group_role` and provide the privileges it needs
- Then `CREATE ROLE <role> WITH <options> IN ROLE <group_role>`
  - this will make a new role that by default inherits the privileges of `group_role`
  - unless the new role is marked as a `NOINHERIT`
- This is easier to maintain than privileges on individual roles
- To manage existing roles and add/remove them from group_roles
  - `GRANT group_role TO child_role` to assign to group role
  - `REVOKE group_role FROM child_role` to remove from group role

---

## Postgres Row-level security (RLS)

- RLS is a Postgres feature that allows restricting rows based on the role querying the data
- First we enable RLS on a table by `ALTER TABLE <table> ENABLE ROW LEVEL SECURITY`
- Then we create an RLS policy on the table by `CREATE POLICY <policy> ON <table> TO <role> USING <condition>`
  - determines which rows are visible based on the condition
- Superadmins and roles with `BYPASSRLS` can query all data regardless of RLS policies
- Additionally, table owners can bypass RLS by default
  - to avoid this, we can use `ALTER TABLE <table> FORCE ROW LEVEL SECURITY`
  - this disallows table owners from bypassing RLS
- More details on configuration for policies can be found at https://www.postgresql.org/docs/current/sql-createpolicy.html
- Conditions for these policies should somehow be tied to specific users or current_user
  - because otherwise all users will see the same data which defeats the purpose
- We can see all current policies in `pg_policy`
- Policies can be dropped by `DROP POLICY <policy> ON <table>`
  - `DROP OWNED BY <role>` drops any policies `TO` that role

---

## Reset forgotten password

- This is handy when you forget the password of a superuser and you cannot change its password directly
- We need to start at `pg_hba.conf` file
  - this can be found at `/var/lib/postgresql/data/pgdata` for Alpine (being used by current docker image)
    - you can run `show hba_file` in SQL to get its path for that instance of Postgres
  - backup the current file by naming it `pg_hba_bk.conf`
  - update the file's `method` column to `trust` (this allows to login to DB without password)
    - this is all set to `trust` already except the last `host all all all scram-sha-256` line
    - try it as is and if doesn't work, then update this to trust in this step and reset later
  - make sure during this time, DB is not being used and is not externally accessible over network
- After saving this file, restart Postgres by `pg_ctl -D restart`
  - stopping/starting docker container should also work in this case
- Set new password by `ALTER ROLE <role> WITH PASSWORD '<password>'`
- Delete the current `pg_hba.conf` file and rename the backup to `pg_hba.conf`
- Restart Postgres again (pg_ctl or docker whichever works)
- After this, it should have the updated password

---
