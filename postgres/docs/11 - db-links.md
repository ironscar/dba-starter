# DB links and Foreign Data Wrappers

## DB links

- DB links allow executing queries in a remote database
  - the remote database needs to have an entry for current database in its `pg_hba.conf`
- To use dblinks, we need to install an extension by `create extension dblink;`
  - this is needed only once and survives DB restarts
- Generally these queries are SELECT but it could be anything that returns rows
  - Like `delete returning *` etc
- The command looks as `dblink(<connname/connstr>, <sql> [, <failOnError>])`
  - `conname` is the connection name
    - you need to first issue a `dblink_connect(<conname>,<connstr>)` and then use that name
    - in a procedure/function where we might need to use the same link multiple times, we can do a `PERFORM dblink_connect` to get a name and then use that for all the `dblink(...)` calls
    - we can use `dblink_disconnect(<conname>)` to disconnect the link at the end
  - `connstr` is the connection string
    - example `'host=<host> port=<port> dbname=<db> user=<user> password=<pwd> options=<opts>'`
  - `sql` is the actual SQL that needs to be executed in the remote database
  - `failOnError` is a boolean (default true) specifying if current query should fail on error or ignore the error while returning no rows

### Single Container Link

- DB link frompostgres DB to student_tracker DB (get data from student_tracker to postgres) inside one container
  - we can see this connection entry in `pg_stat_activity` in container
- For this, the host and port parts of connection string can be skipped
- Use `dblink(dbname=student_tracker user=springstudent password=springstudent options=-csearch_path=)`
  - The `-csearch_path=` specifies postgres to begin each session by removing publicly-writable schemas from search_path so that untrusted uers cannot change behavior of other user's queries
  - Ideally, you would create a schema for each user and keep them constrained there, which is called the `secure schema usage pattern`
  - In case you don't have this pattern is when we need to set that option
- Since dblinks returns records, we need to cast the columns returned
  - `select* from dblink(...) as tb1(col type, ...)`
- Since the sql string is specified as text, adding quotes in the actual query becomes hard
  - We can use the `format` and `quote_literal` functions
  - `format('select * from table where col = %s', quote_literal('val'))` can be used

### Multi-Container Link

- DB link from postgres DB of first container to student_tracker DB of second container (get data from student_tracker of second container to postgres DB of first container)
  - we can see this connection entry in `pg_stat_activity` in second container
- Here we will have to specify the host and port as well
  - the host will be the container IP if both contaners on same host, else it will be the VM IPs
  - the port will be the container port (and not the mapped host port) if both containers on same host, else it will be the VM port which is mapped
  - Here, we will connect to `postgresdb2` whose Docker IP is `192.168.196.3` and container port `5432` (mapped to host port `5433`)
- we will remove one row from container 1 task table to demonstrate the differences

### Combining DB link and local queries

- We will attempt to join data from a local table and a remote table to get results
- We just need to specify the dblink query inside paranthesis and give this an alias to join with

### Considerations

- DB links include network latency which could have performance considerations
- Minimize the transfer of data over network so optimize the remote query
- For more complex scenarios, consider using foreign data wrappers
- A DB link remains open until the end of that session or the connection is specifically closed
  - A session is closed when a client application specifically disconnects from the database
- A `dblink(connstr)` creates a new temporary connection each time its called
  - when using queries in tool, it opens the connection, executes the query and immediately closes the link
- A `dblink(connname)` after an initial `dblink_connect()` creates a single connection and reuses it for same name
  - until it closes the connection due to closing the session or forcibly disconnecting it
  - we can forcibly close it using `dblink_disconnect`
- Create dedicated DB links for each usecase and close them once not needed anymore
- Find how many db link connections are open
  - when we open a dblink to same container, we can see a new record in `pg_stat_activity` of container
  - when we open a dblink to another container, we have to check the `pg_stat_activity` of that container
  - In pgAdmin, if you try to switch connections to check this, it will automatically close all dblinks
    - you could first check how many connections are there
    - then you can create the dblink and query the pg_stat_activity of other container over dblink
    - then you can see the additional record there from `192.168.196.2` and logged in user as `springstudent` (no application_name)

---

## Foreign data wrappers

- Foreign Data Wrappers (FDW) are a mechanism to access data from external servers
  - `postgres_fdw` is specifically for fetching data from Postgres servers
  - there are other FDWs like `oracle_fdw`, `mongo_fdw` and so on to access data from other kinds of DB servers
- This also needs an extension to be installed as `create extension postgres_fdw;`
  - this is needed only once and survives DB restarts
- Then, we have to create a `foreign server` for each remote database that we want to connect to
  - `create server <serverName> foreign data wrapper postgres_fdw options(host '<host/IP>', port '<port>', dbname '<dbname>')`
  - the remote database needs to have an entry for current database in its `pg_hba.conf`
- Next, we have to create a `user mapping` to specify which users can access remote data using the foreign server using which remote user
  - `create user mapping for <localUser> server <serverName> options (user '<foreignUser>', password 'foreignUserPassword')`
- After this, we can either create a `foreign table` or import `foreign schema`

### Create Foreign table

- Then, we can create a `foreign table` with the same column name and definitions as the remote table (this is manual)
  - `create foreign table <foreignTableName> (<colName> <colType>, ...) server <serverName> options (schema_name 'schemaName', table_name '<tableName>')`
  - it doesn't need you to specify defaults and constraints however, only name and type
  - since this is manual, it is often preferred to use `import foreign schema` (discussed later)
- For cleaning up FDWs
  - first, we drop the foreign table using `drop foreign table <name>`
  - second, we delete the user mapping using `drop user mapping for <localUser> server <serverName>`
  - third, we drop the server using `drop server <serverName>`
- We can view all servers at `pg_foreign_server`, all foreign tables in `pg_foreign_table` and all user mappings at `pg_user_mapping`
- When a foreign table is active, we can check the second container's `pg_stat_activity` to find yet another record
  - specifies application_name as `postgres_fdw` but other details are same as the dblink

### Import foreign schema

- `import foreign schema` creates foreign tables that exist on the remote schema
- this gets over the issue of manually matching the column definitions
- `import foreign schema <remoteSchema> [LIMIT TO|EXCEPT (<table, ...>)] from server <serverName> into <localSchema>`
  - it also takes options but the base requirement doesn't need any options
 
### Introduction

- Refer https://www.postgresql.org/docs/current/postgres-fdw.html for details on below sections
- `postgres_fdw` is similar to `dblinks` but can give better performance in many cases
- `postgres_fdw` currently cannot do `INSERT ON CONFLICT DO UPATE` but can do `INSERT ON CONFLICT DO NOTHING`
- `postgres_fdw` is able to update records across partitions
  - but cannot handle some cases where insert and update on same partition is happening in one command
- Matching of columns on foreign table to remote table is by name and not position
  - thus, we can declare fewer columns out of order as well

### Options

#### FDW options

- FDW options include some parameters but important one not already covered is
- `application_name` allows specifying an application name that will then show up in `pg_stat_activity` of remote DB

#### Cost estimation options

- There are some cost estimation options that can be specified on foreign server or foreign table
- specifies how the remote server `Explain` works over the FDW
- `use_remote_estimate` is a boolean (default false), which when true allows getting costs via `Explain Plan`
- `fdw_startup_cost` is a float value (default 100), which is the cost of establishing connection
- `fdw_tuple_cost` is also float value (default 0.2) which is the cost of data transfer over network
- the float params are user-defined or constant so doesn't seem very useful

#### Remote execution options

- `fetch_size` is a number (default 100) specifying the number of rows that are fetched in a single operation
- `batch_size` is a number (default 1) specifying number of rows inserted in each insert operation with each batch being one query
- both can be set for foreign table (precendence) and server
- `postgres_fdw` attempts to optimize remote queries by reducing number of rows transferred using the WHERE clause and limiting columns
  - WHERE clauses with built-in functions, operators and types are supported to do entirely on remote
  - columns that aren't used in query aren't transferred
  - if there are joins on foreign tables in same foreign server, it will attempt to do the entire join remotely
- `EXPLAIN VERBOSE` can show what exact query was sent to remote

#### Asynchronous execution options

- `async_capable` is boolean (default false) specifying whether foreign tables can be scanned concurrently for better performance
- can be set for foreign table (precendence) and server
- `postgres_fdw` will usually open one connection for a server and execute all queries serially even if different tables are involved

#### Transaction management options

- `postgres_fdw` will commit all remote transactions serially when local transaction gets committed, and same for aborts
- Performance for above can be improved by following options
- `parallel_commit` is boolean (default false) can be set on a foreign server and specifies whether all remote transactions can be committed in parallel
- `parallel_abort` is boolean (default false) can be set on a foreign server and specifies whether all remote transactions can be aborted in parallel

#### Connection management options

- By default, connections to foreign servers are only kept open for that session and then closed at the end of that session
- We can specify `keep_connections` boolean (defalt false) which can keep them open for subsequent queries in other sessions to use, if true
- A new connection is made for each new user mapping regardless of this parameter setting
- The remote transaction isolation reflects the local transaction isolation for now

### Functions

- `postgres_fdw_get_connections()` returns all open connections to foreign servers (only after a foreign table is created)
- `postgres_fdw_disconnect(<serverName>)` disconnects all open connections to specific foreign server if its not in the middle of a transaction
- `postgres_fdw_disconnect_all()` disconnects all open connections to all foreign servers if they not in the middle of a transaction

---
