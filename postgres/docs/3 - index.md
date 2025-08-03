# Indexes

## Explain plan

- Beside `Run` settings, there are the `Explain Plan` settings on the query tool
  - there is `Explain Plan (F7)` and `Explain Analyze` followed by a dropdown
  - `Explain Plan` is the basic one which gives prediction on number of rows
  - `Explain Analyze` gives more accurate information but also executes your query so use carefully for non-SELECT queries
  - You can just write `explain` or `explain analyze` before the query and run it with `F5` to get the plan output
  - The dropdown shows additional configurations like how verbose and whether to include costs etc
    - we have to repeat these configs every time we open a new file
- Select a query in pgAdmin and press `F7`, to see:
  - A graphical output for the query in `Explain > Graphical` tab
  - An analysis showing startup (a) and total cost (b) as `cost=a..b` under `Explain > Analysis`
    - this shows up only if cost is checked in the dropdown for Explain settings
  - Plan `rows` is the number of rows expected to be returned
  - Plan `width` is the width in bytes of the output rows
- Comparing plans in tables with very less data are not the same as very large data
  - so when doing plans, fill table with realistic amounts of data to check
- It is not very straightforward to see plans for functions and procedures
  - the PL/SQL stuff causes errors and doesn't seem to be recognized

---

## Indexes

- Indexes can be created to make select queries faster but slow down updates and inserts
- Indexes use different algorithms based on the type of index created:
  - `BTREE` (default)
    - Creates a balanced tree and stores in sorted order, good for exact match & ranged queries
  - `HASH`
    - Maintains 32 bit hashes for the values and can only handle simple equality queries
  - `GIST`
    - Allows nearest neighbour and partial match search strategies
  - `SPGIST`
    - Useful for hierarchical data and complex structures
  - `GIN`
    - Inverted indexes that are suitable for composite data like arrays or full-text search
    - it stores each component of the composite value separately
  - `BRIN`
    - good for large table range queries
  - we can specify this as `CREATE INDEX <index_name> ON TABLE USING <algorithm> (<columns>)`
- Indexes should be avoided when
  - tables are too small
  - tables have frequent write operations
  - the indexed column has many null values
  - the indexed column is heavily manipulated
- Indexes are created without a schema name but are automatically assigned to the schema for the indexed table
  - while dropping, that schema needs to be specified before the name
- Indexes can be created as:
  - single column (usual)
  - multiple column (if a set of columns is directly and commonly used in where conditions)
  - functional (if a specific function is commonly used to format the columns in where conditions)
  - partial (if a specific subset of column values based on some condition is to be indexed due to most accesses)
- We can compare how well the indexes are doing based on:
  - make the actual query
  - fill table to predicted level of data if possible
  - check cost of query (use `Explain Analyze` for selects and just `Explain` for others)
  - add index, explain plans and compare them for improvements if any
  - if no improvements, not the time to add indexes yet
- Reindexing indexes are required if indexes get corrupted
  - requires the schema prefix when using `REINDEX INDEX`
  - we can use `REINDEX CONCURRENTLY` option to not block reads during creation of index
  - we can use `REINDEX INDEX` to rebuild a single index
  - we can use `REINDEX TABLE` to rebuild all indexes of a table
  - we can use `REINDEX SCHEMA` to rebuild all indexes of a schema (must be run by owner of schema)
  - we can use `REINDEX DATABASE` to rebuild all indexes of a database (must be run by owner of database)
  - reindexing can take a few options:
    - verbose gives more output about what indexes were reindexed etc
    - concurrent doesn't block reads but does block writes on the table
- Indexes are generally updated during insert/delete/update statements which can have performance implications
  - these are unlikely to cause the index to corrupt unless the updates are faster than autovacuum
  - autovacuum cleans up dead rows etc to free up data for the database
  - in that case, we can either batch the updates, speed up autovacuum or rebuild the index ever so often

---

## Cluster tables

- A table can be clustered based on an existing index defined on the table
  - `cluster <table> using <index>` (index here doesn't include the schema and only the name, table does include the schema)
- If clustered, it is physically reordered based on the index
- This is a one-time operation done on only the current table and new records don't follow order
- Table has to be reclustered for the new records to follow the order
- Once clustered, it is advisable to run `ANALYZE` so that the statistics are update for the planner to make good choices
- The table remembers the index used to cluster it by so after the first time, we can just say `cluster table` and it will recluster based on the last used index
  - so generally cluster once at start with specified index and then periodically run `cluster` and `analyze` across all clustered tables without any parameters
- `cluster` without a table name clusters all tables previously clustered in the database
  - this cannot be used in a transaction
- Clustering on a partitioned table alwas requires index to be specified and also cannot be done inside a transaction
- Clustering requires an access exclusive lock, implying that it blocks all read/write until clustering is finished
  - the progress of running clustering operations is logged in `pg_stat_progress_cluster`
- For a single row access, clustering is useless since the actual data order doesn't matter
  - if multiple rows match a continuous range of an indexed column
    - they are mostly on the same disk page if clustered and is faster to fetch
    - if we are trying to get specific values which aren't close by, a regular index will work just as well
  - getting all rows by sorting on the indexed column is faster when clustered since its already stored in that order
    - if we don't order by the index and do a regular select, they will still be ordered by the index if clustered
- We can stop the cluster's effects by dropping the corresponding index, but the ordering remains as is

---
