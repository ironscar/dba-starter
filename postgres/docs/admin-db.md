# DB Administration: Managing databases

## Create Database

- You can specify the following additional things while creating a database using `create database <name> with ...`
  - `owner`: assign a role/user as owner for the database, default is the current role/user
  - `template`: specify a DB template where `template1` is the default
    - template1 and template0 databases are already created in the system
    - when we create a database normally, it actually copies everything from template1 DB
    - we can change template1 and as a result, all subsequent databases created will also inherit those changes (NOT RECOMMENDED)
    - instead, we ought to create our own template databases for those changes and use that as a template
    - more details below in the `Database template` section
  - `tablespace`: specify the tablespace name of new database, defaulting to the one used by the template db
  - `connection limit`: specify the max concurrent connections allowed to the database (default is -1 implying unlimited)
  - `is_template`: specifies a boolean for whether the database is a template or not
  - other less important ones are discussed at `https://neon.tech/postgresql/postgresql-administration/postgresql-create-database`

### Database template

- We can create a template DB using the following steps:
  - `CREATE DATABASE mytemplate;`
  - `ALTER DATABASE mytemplate WITH is_template TRUE;`
- To create a new db with this as template
  - `CREATE DATABASE db TEMPLATE mytemplate`
- Default template is `template1` and `template0` is a fallback in case something irreversible happens to `template1`
- To delete a template database, we cannot just directly delete it
  - `ALTER DATABASE mytemplate WITH is_template false;`
  - `DROP DATABASE mytemplate;`
- If we create any DB object (table etc) in the template and create a DB using that template, the new DB will also have those objects
- Due to switching between connections between databases, you cannot drop databases because other connection maybe active on it
  - we can refer to the `pg_stat_activity` to check the current database connections (includes pid (process Id) and datname (db name))
  - we will often see a few null records here but let's not worry about them
  - we can use the `pg_terminate_backend(pid)` function to terminate a connection for that pid (it returns a booolean)
  - we can avoid closing our own connection by making sure we check `WHERE pid != pg_backend_pid()`
- Creating databases is only allowed by superuser (in our case `postgres`)
- Creating databases from templates is often a way to quickly copy databases (though the source must have no connections while this happens)

---

## Alter Database

- Database options can only be changed by superuser
- You can update:
  - `alter database mydb with [is_template | connection limit | allow_connections] <value>` for DB options
  - `alter database mydb rename to mydb2` for name (cannot be done while being connected to mydb)
  - `alter database mydb owner to new_owner` for owner (cannot be done while being connected to mydb)
  - `alter database mydb set tablespace <tablespace>` for tablespace
  - `alter database mydb set <config_param> = <value>` for runtime config params
    - we can refer to the `pg_settings` table to see what params are there 
    - there are predefined configs and you cannot add your own using this
- Some of these require all active connections to be terminated (we cover this in the `Database templates` section)

---

## Drop Database

- `drop database [IF EXISTS] mydb [WITH (FORCE)]`
- `force` option will terminate all connections as well (needs the paranthesis around)
- you cannot drop a database while being connected to it or if you aren't the owner

---

## Copy Database

- One way is to use template databases
- Another is to use `pg_dump` to create a file, create the copy database and then restore it using `psql`
  - `pg_dump -U <user> -d <sourcedb> -f <file>.sql`
  - `psql -U <user> -d <targetdb> -f <file>.sql`
  - this will work even for remote copying where we can copy the dump file into the remote server
  - if the servers have faster network connections, we can use the pg_dump `-C` flag and `-h` flags for specifying the host addresses
  - `pg_dump` works even if the database is being used concurrently

---
