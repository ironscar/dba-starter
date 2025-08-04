# Optimizations

## Temporary tables

- A temporary table only exists during a single DB session
- It is created with the `CREATE TEMP/TEMPORARY TABLE` statement (rest of it is same as `CREATE TABLE`)
- We can drop a temporary table using `DROP TABLE` like regular tables if we want to remove it in session
- Useful when we want to isolate some data and store it intermediately instead of adding to query complexity
- If created within a transaction scope, a temporary table is only visible to that transaction
- It doesn't have any direct performance gains
- In most cases however, temporary tables aren't very recommended

---

## Parallel Query

- Postgres can use parallel queries feature which allows leveraging multiple CPUs for certain queries to provide better performance
- Not all queries benefit from this
- In the `Explain Plan`, the prescence of `Gather` or `Gather Merge` node specifies that all the operations below it are executed in parallel
- In a single query, max number of workers is specified by `max_parallel_workers_per_gather`
- Total number of parallel workers that can exist at a time is specified by `max_worker_pocesses` and `max_parallel_workers`
  - You can check these by `select current_setting(<param_name>)` or `show <param_name>`
- Parallel query plans are not generated if:
  - queries that write or lock any data
  - queries that use cursors or iterations with custom PL/SQL inside
  - queries that are marked with `PARALLEL UNSAFE`
    - system functions are usually `PARALLEL SAFE` but user-defined functions are usually marked `PARALLEL UNSAFE`
  - queries that are running inside another parallel query
- Even if a parallel query plan is generated, it may not actually be parallelized if:
  - No available workers limited due to `max_worker_processes` or `max_parallel_workers`
  - in this case we can update the setting
- If a query is expected to produce a parallel plan but doesn't
  - we can try reducing `parallel_setup_cost` or `parallel_tuple_code` (min is zero)
- Two other parameters which maybe important in this regard are
  - `min_parallel_table_scan_size` specifies the minimum size of table data required for a parallel scan to be considered
  - `min_parallel_index_scan_size` specifies the minimum size of the index that is relevant to the scan for a parallel scan to be considered

### Parallel labelling

- Parallel labelling has the following values:
  - `PARALLEL UNSAFE` is when query operation cannot be part of a parallel plan in leader or worker
  - `PARALLEL RESTRICTED` is when query operation can be executed in leader but not worker
  - `PARALLEL SAFE` is when query operation can be executed in either leader or worker
- Following operations are always `PARALLEL RESTRICTED`
  - scans of CTEs
  - scans of temporary tables
  - scans of foreign tables (unless fdw has `isForeignScanParallelSafe` API specifies otherwise)
- `CREATE FUNCTION` can label user-defined functions explictly 
  - just add `PARALLEL <label>` at the end after `LANGUAGE plpgsql`
- In the following cases, functions must be marked `UNSAFE`
  - write to DB
  - change transaction state
  - access sequence
- In the following cases, functions must be marked `RESTRICTED`
  - access temporary tables
  - cursors

### Defaults

- The current defaults on this system are set to:
  - max_parallel_workers_per_gather = 2
  - max_worker_pocesses = 8
  - max_parallel_workers = 8
  - parallel_setup_cost = 1000
  - parallel_tuple_code = 0.1
  - min_parallel_table_scan_size = 8MB
  - min_parallel_index_scan_size = 512KB

---

## Genetic Query Optimizer

- The Generic query optimizer does query planning using heuristic search insead of exhaustive searching
  - it usually generates a more inferior plan than the exhaustive search
  - when there are too many tables involved, sometimes heuristic searching is faster than exhaustive searching while making up for the inferiority
- Some important ones are mentioned here
  - `geqo` enables/disables this optimizer (default is enabled)
  - `geqo_threshold` (integer) specifies the number of FROM items after which it should switch to this optimizer (default is 12)
  - `geqo_effort` (integer) specifies how much time it spends looking for a plan (default is 5)
    - larger value => more time => possibly better plan
  - other params tend to control how the genetic algorithm gets configured
    - refer to https://www.postgresql.org/docs/current/runtime-config-query.html#RUNTIME-CONFIG-QUERY-GEQO for these

---

## Vacuum

- `Vacuum` is for garbage collecting and optionally analyzing the database
- It reclaims storage by reclaiming space from dead tuples
  - dead tuples are tuples which are deleted or obsoleted by an update
  - the extra space is not given back to OS and kept there for reuse by the table itself
  - no exclusive locks are obtained but as a result, lesser space is reclaimed
- By default, it will process every table and column the current user has permissions to vacuum
  - we can specify tables and columns list to restrict this
- the `Analyze` command is what helps with the analyzing and can collect database statistics
  - `analyze verbose` gives the output on pgAdmin for number of pages, live and dead rows for each table
  - running this on partitions or inherited tables, doesn't update statistics on parent table, so has to be explicitly run on it
- Following are some important parameters:
  - `Full`: Takes longer and exclusively locks the table to reclaim more space from the table
    - internally, it rewrites the content of the table to a new disk file with no extra space and return the reclaimed space to the OS
    - it also needs more space to keep old and new at the same time, so should be used sparingly
  - `Verbose`: Prints a vacuum activity report for each table
  - `Analyze`: Updates statistics used by planner to determine the most efficient way to execute a query
  - `Index_cleanup`: Specifies if dead tuples are removed from indices or not
    - by default, index cleanup is skipped when there are too few dead tuples
  - `Parallel`: (integer) cleanup of indexes happen using parallel background workers when appropriate
    - its controlled by config params like `max_parallel_maintenance_workers` and `min_parallel_index_scan_size`
  - `Skip_database_stats`: specifies that updating database stats must be skipped
    - updating DB stats takes a long time for DBs with lots of tables
    - useful when issuing multiple Vacuum commands where by default, all of them will try to do this, whereas only last one should
    - or after all the actual ones, we can use issue vacuum with `only_database_stats` to only do the update
  - `Buffer_usage_limit`: can specify how much of shared buffer to use
    - bigger values will allow vacuum to run faster but may also evict useful pages from buffer
    - if unspecified, it uses the config param `vacuum_buffer_usage_limit`
  - parameters ought to be specified in order as sometimes they don't work otherwise
  - rest are discussed in https://www.postgresql.org/docs/current/sql-vacuum.html
- Vacuum requires the `MAINTAIN` privilege
- Vacuum can increase I/O traffic thereby affecting other active sessions
- The progress of vacuum can be seen in `pg_stat_progress_vacuum` and `pg_stat_progress_cluster` views for normal and full respectively

### Autovacuum

- Vacuum should be run often so that space can be reclaimed and DB statistics updated
- Generally this should be done without the `FULL` option so that production usage of tables is supported
- Postgres has an `autovacuum deamon` that can help do this
  - also supports scheduling dynamically based on DB usage which gets over the problem of a fixed schedule vacuum coinciding with a spike in usage
  - its working can be configured to some degree using config params (discussed later)
- In Postgres, transactions rely on a 32bit XID which wraps around to 0 after 4 billion transactions
  - this can cause catastrophic data loss as past transactions seem to appear in the future
  - this is another reason to run vacuum often (every 2 billion transactions) to avoid this issue
  - this is referred to as `freezing` and is controlled by `autovacuum_freeze_max_age` param (default is 200 million)
  - too high a value for this param may lead to `pg_xact` and `pg_commit` sub-directories to grow in size (upto 20.5GB together for the max of 2 billion)
    - if that is small compared to overall DB then no problem, but otherwise reduce this value 
- Sometimes autovacuum may not be able to remove old XIDs
  - in this case, the DB will throw warnings about it and a manual non-FULL vacuum from a superuser will resolve the issue
- Following are some params that affect autovacuum operation
  - `autovacuum_naptime`: specifies how often the deamon launches an autovacuum worker
    - if there are N databases in an installation, a new worker is launched every (naptime/N)
  - `autovacuum_max_workers`: specifies the total number of workers allowed to run at the same time
- Autovacuum doesn't automatically analyze partitioned or inherited tables and that might lead to suboptimal query plans
  - attempt to run an `analyze` command on those whenever data is first inserted or when there is significant change in its distribution
- Autovacuum doesn't analyze temporary tables either
- By default it is ON, you can see it by `show autovacuum;`

---

## Resource consumption

- Memory related
  - `shared_buffers`: (integer - default 128MB) sets the amount of memory the DB server uses as shared memory buffer
    - a reasonable starting value is 25% of RAM (more than 40% of RAM is unlikely to work well)
  - `huge_pages`: (on/off/try) allows using huge pages if possible, directly improves performance
  - `work_mem`: (integer - default 4MB) sets the amount of RAM to be used by a query operation before writing to temporary disk files
    - there are multiple operations in a single query and there are multiple queries in a session and multiple sessions on a server
- Disk
  - `temp_file_limit`: (integer) specifies the max disk space that a process can use for temporary files (default is no limit)
- Other params at https://www.postgresql.org/docs/current/runtime-config-resource.html

---

## Performance tips

### Explain plan additional details

- `Explain Plan` helps in seeing the query plan generated for a query based on current statistics
  - the cost specified in these plans are in random units but they can be configured by
    - `seq_page_cost`: cost of sequential disk page fetch defaulted to a value of 2
    - `random_page_cost`: cost of non-sequential disk page fetch default to a value of 4
      - normally this is a lot more expensive than four times the sequential fetch but most of these are expected to be in cache
      - reducing this value leads to preferring index scans and vice versa
      - if more of your data is cached (like in a smaller DB on a server with more RAM), feel free to reduce this value more
    - `effective_cache_size`: effective disk size available to a query, defaulted to 4GB
      - higher value makes it more probable to use an index scan over a sequential scan and vice versa
  - other params on costs are discussed in https://www.postgresql.org/docs/current/runtime-config-query.html#RUNTIME-CONFIG-QUERY-CONSTANTS
  - these params are set based on aggregates of all queries in an installation so changing them based on a few experiments is not recommended
  - `pg_class` view has `relpages` that can specify the number of disk pages in the current table
    - sequential costs depend on disk page count
  - `Explain Analyze` will run the actual query and give the millisecond execution time
    - this cannot be compared to the cost from Explain Plan which is in random units
  - Statistics from Explain Analyze can be less accurate if gettimeofday() calls are slow for the corresponding OS
    - this can be tested with the `pg_test_timing` command on terminal
    - per loop time overhead below 100ns is good enough

### Planner statistics

- The query planner looks at various DB statistics to compare costs and choose the plan including:
  - number of rows in table and index (stored in `pg_class`)
  - `default_statistics_target`: specifies the number of values `ANALYZE` uses to populate `pg_statistics` (default 100)
    - increasing this may make for more accurate planner estimates for columns with irregular distributions
    - this can be set on a per-column basis so can be decreased for columns with less data and simple distributions
  - normally columns are considered non-correlated but maybe correlated
    - we can create statistics objects and run `ANALYZE <independent_col>` to get statistics on those for the planner to get better estimates for correlated columns
    - using the `CREATE STATISTIC <name> (dependencies) ON <dependent_col_list> FROM <independent_col>`
    - currently only applicable for `=` and `IN` conditions and not others in Postgres
  - normally statistics are not gathered for groups of columns together resulting in bad estimates for `group by a,b,c`
    - we can create statistics object like `CREATE STATISTICS <name> (ndistinct) ON <col_list>`
    - it will get statistics on groups of columns used together (impractical to do for all combination of columns)
  - normally, statistics of common value lists are not gathered on groups of columns either
    - we can create statistics object like `CREATE STATISTICS <name> (mcv) ON <col_list>`
    - advisable to only create for column combinations used in conditions together
  - we can use the `pg_statistic_ext` and `pg_statistic_ext_data` views to see the statistics for these objects using a superuser

### Explicit Join Clauses

- Using explicit join clauses can sometimes control the planner to take less time
- This becomes noticeable when joining more than 8 tables
- We can set the `join_collapse_limit` to do this (generally equal to the `from_collapse_limit`)
  - takes an integer specifying the number of tables used in join, above which it will convert the joins to from items to reduce planning time
  - might produce inferior plans
  - 1 => use the join order explicitly set by the query

### Non-durable settings

- Durability is a feature of recording committed transactions in the event of OS or hardware crash
- It adds a lot of overhead per transaction so can be eliminated to some degree to run Postgres much faster as follows:
  - Place database data directory in RAM to eliminate all disk I/O (only possible if all data can be contained in RAM)
  - Turn off `fsync` which may cause data corruption on server crash by choosing to not write changes to disk
  - Turn off `synchronous_commit` on less important transactions which makes WALs not write on every commit, but risks data loss on random server crash
    - there are other values to it that we can set for optimal behavior like `off`, `local`, `remote_write`, `on` & `remote_apply`
  - Turn off `full_page_writes` which may cause data corruption on server crash
  - Increase `max_wal_size` and `checkpoint_timeout` which reduces freqency of checkpoints and increases size of pg_wal directory
  - Create `unlogged` table which makes the table non-crash-safe

### Populating DBs

- When inserting a large amount of data to DB (perhaps when starting the first time), it could take a long time on normal operation
- For multiple inserts, we can turn off autocommit and do one commit at the end (doing a `begin <sql> commit end` like a proc will allow this)
- Use `COPY` instead of INSERT for large number of rows as it is optimized for that, though provides lesser flexibility
  - it moves data from SQL to files or vice versa like `copy table (columns) from file` or `copy query to file`
  - more details at https://www.postgresql.org/docs/current/sql-copy.html
  - `pg_dump` by default uses `COPY`
- Remove indexes and constraints as index-updates and constraint-checks take more time, they can be recreated later
- Temporarily increasing `maintenance_work_mem` may speed up load operations, but it doesn't affect `COPY`
- Increasing `max_wal_size` as before to reduce checkpointing
- Disable WAL archiving and streaming replication and then take a base-backup and re-enable it after load
- Run `ANALYZE` after load is complete to update statistcs

- For more in-depth details, refer to https://www.postgresql.org/docs/current/performance-tips.html

---

## JIT

- Params that affect cost planning with JIT:
  - `jit`: specifies whether jit is on, default is on
  - `jit_above_cost`: cost above which JIT is activated, defaulted to 100,000
  - `jit_inline_above_cost`: cost above which JIT tries to inline functions and operators to improve execution speed at the cost of planning time, defaulted to 500,000
  - `jit_optimize_above_cost`: cost above which JIT applies more optimizations, usually set between `jit_above_cost` and `jit_inline_above_cost` for best results
- JIT involves turning some general purpose code to native code to speed up execution
  - currently only expression evaluation and tuple deforming (convert a tuple on disk to tuple in RAM) is supported
  - JIT can also inline functions and operations which are used within evaluations
    - only internal functions are supported and extension functions are not
  - Postgres, when built with LLVM, allows certain optimizations
    - https://llvm.org/docs/Passes.html#transform-passes discusses them
    - some optimizations are cheap while others are more expensive
  - By default, it is ON
  - The plan using Explain, will specify if JIT is being used
- It is mainly advisable to use for long-running CPU-intensive queries like analytical queries

---
