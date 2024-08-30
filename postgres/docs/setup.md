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

### Login

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

### Create databases & users

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
- Additionally, if we want to delete users
  - we cannot directly delete/drop them
  - we first need to revoke all its grants
    - this can be done either by issuing `revoke` for every grant (but this can be bothersome)
    - second is to reassign all its grants as `reassign owned BY {userName} TO postgres` (where postgres is the default admin user)
    - and then issusing `drop user {userName}`

---

### Create schemas

- We can create a new schema by `create schema {schemaname}`
  - be sure to be logged in with the correct user on the correct database
  - mostly it might mean logging in with `postgres` user to create the schema and grant all to a specific user
  - then logging in with the actual user and do everything else
  - you need not create a new schema if you want to continue using the default `public` schema
- We can create tables with `CREATE TABLE <tableName> (...)` command
  - this wil generally create the table in `public` schema
  - to create in a specific schema, we use `CREATE TABLE <schemaName>.<tableName>`
  - user must have access to this schema to do this

---
