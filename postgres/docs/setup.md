# Postgres SQL Setup

## Introduction

- We can use `pgAdmin` as a GUI tool to manage Postgres DBs
- We can create connections on a per DB per user basis on this tool
- We generally begin with a admin user with all privileges defaulting to the name `postgres`
- There is also a default database called `postgres` with a default schema called `public`
- Each database can have multiple schemas and each schema can have multiple database objects
- Database objects include things like:
  - Tables
  - Materialized views
  - Functions
  - Procedures
  - Sequences
  - Triggers

---

## Setup

- To setup postgres using docker, do below:

```
docker run -d \
    -p 5432:5432
	--name postgresdb1 \
	-e POSTGRES_PASSWORD=******** \
	-e PGDATA=/var/lib/postgresql/data/pgdata \
	-v /datadir/postgresql:/var/lib/postgresql/data \
	postgres:16.4-alpine3.19
```

---

## Login

- On pgAdmin, we need to add a new server
  - Name: `{user}@{db}` (is the standard I have been using for now)
  - Hostname: the hostname of the database connection URL (could be localhost)
  - Post: 5432 (can leave it at default)
  - Maintenance database: the DB that you want to login with (default is `postgres`)
  - Username: the user that you want to login with (default is `postgres`)
  - Password: `{POSTGRES_PASSWORD}` (password that you entered in the docker run command)

- There are a few caveats:
  - we might want to login with some user and some db while being logged in with other active connections
  - sometimes this behaves weirdly so make sure the dropdown above the query tool specifies the right details
  - if not, click on the dropdown and select the correct one or make new connection

---

## Create databases & users

- By default, you want to login with `postgres@postgres`
- To create a new database, we can use `create database {db}`
- Now, you should creata a new connection for the admin user to the new database as specified in the `Login` section
- To create a new user, we can use `create user {username} with password '{password}'`
- To give this new user grants on all new things in the schema (default is public)
  - `grant all on schema {schemaName} to {username}`
- To take away this specific grant, we can do the following:
  - `revoke all on schema {schemaName} from {username}` (changing `grant` to `revoke` & `to` to `from`)
- This will not allow the new user to create database objects in this schema
  - the user will not have access to any pre-existing tables created by other users
  - for this we have to separately grant access to all tables like
  - `grant all privileges on all tables in schema {schemaName} to {username}`
- After this, you have to create a new connection for the new user to new database
  - Now you are ready to use that schema in the database
- If we want to delete a database
  - we can do `drop database {db}`
  - only owner of db can delete a db
  - a db can only be deleted if there are no open connections to this db including current connection
  - this will delete all objects inside the db
- Additionally, if we want to delete users
  - we cannot directly delete/drop them
  - we first need to revoke all its grants
    - this can be done either by issuing `revoke` for every grant (but this can be bothersome)
    - second is to reassign all its grants as `reassign owned BY {userName} TO postgres` (where postgres is the default admin user)
    - and then issusing `drop user {userName}`

---

## Create schemas

- We can create a new schema by `create schema {schemaname}`
  - be sure to be logged in with the correct user on the correct database
  - mostly it might mean logging in with `postgres` user to create the schema and grant all to a specific user
  - then logging in with the actual user and do everything else
  - you need not create a new schema if you want to continue using the default `public` schema
- We can create tables with `CREATE TABLE <tableName> (...)` command
  - this wil generally create the table in `public` schema
  - to create in a specific schema, we use `CREATE TABLE <schemaName>.<tableName>`
  - user must have access to this schema to do this
- To delete a schema
  - do a `drop schema {schemaName}`
  - this can only delete an empty schema
  - to delete everything inside a schema as well, we do `drop schema <schemaName> cascade`

---

## Transactions

- Transactions are a body of work that should either be done entirely or not at all
- Starts with `BEGIN` or `BEGIN TRANSACTION` or `BEGIN TRANSACTION ISOLATION LEVEL SERIALIZABLE`
- Ends with `COMMIT` or `END TRANSACTION`
- Undo changes via `ROLLBACK` in case of errors
- There are specific issues that can happen at different isolation levels
  - `dirty reads` where other non-committed transaction updates can affect current transaction
  - `non-repeatable reads` where update operations from other committed transactions can affect current transaction
  - `phantom reads` where insert/delete operations from other committed transactions can affect current transaction
  - `serialization anomalies` where execution order of concurrent transactions can affect the final result of all transactions
- There are different isolation levels for transactions
  - `Read-uncommitted` allows `dirty reads`, `non-repeatable reads`, `phantom reads` and `serialization anomalies`
  - `Read-commmitted` allows `non-repeatable reads`, `phantom reads` and `serialization anomalies`
  - `Read-repeatable` allows `phantom reads` and `serialization anomalies`
  - `Serializable` allows `serialization anomalies`
- In Postgres
  - `read-uncommitted` works similar to `read-committed` and doesn't allow `dirty reads`
  - `read-repeatable` works similar to `serializable` and doesn't allow `phantom reads`
- `Read-repeatable` and `Serializable` can have high degree of serialization error and rollbacks in high concurrency
  - this can have performance implications and code complexity
- `Read-committed` is the default isolation level of transactions in Postgres

---

## Locks

- Locks are made on table when there are insert/update/delete commands being executed
- Rows being inserted/updated/deleted are locked from other transactions editing them
- Selects queries are never blocked by default
- Details on locking modes are provided in `https://www.postgresql.org/docs/9.4/explicit-locking.html`
  - Explicit locking is susceptible to deadlocks
    - Even row-level locks as a result of regular update statements can cause deadlocks
    - Postgres detects deadlocks and aborts one of the transactions so as to resolve the deadlock
    - All objects should be locked in the same order so as to avoid deadlocks (like updating rows in the same order)
  - Advisory locks are locks made specific to applications
    - these can be emulated by a DB flag but are more performant and get cleaned up at the end of a session
    - we should use LIMIT and ORDER BY carefully with this as its uncertain when the lock is applied
      - we can solve this by doing those operations in an inner query
- All locks currently held by system can be found in `pg_locks`
- There is a limit to the number of locks that can be created (be it advisory or regular)

---
