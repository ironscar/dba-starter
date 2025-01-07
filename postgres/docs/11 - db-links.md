# DB links, Foreign tables and CDC

## DB links

- DB links allow executing queries in a remote database
- To use dblinks, we need to install an extension by `create extension dblink;`
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

- DB link from student_tracker DB to postgres DB inside one container
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

- DB link from student_tracker DB of second container to postgres DB of first container
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
- Find how many db link connections are open [CHECK]
  - tried to use `pg_stat_activity` but it only added the local dblink record and not the remote one, even when using persistent connections with `dblink_connect`

---
