# Optimizations

## Temporary tables

- A temporary table only exists during a single DB session
- It is created with the `CREATE TEMP/TEMPORARY TABLE` statement (rest of it is same as `CREATE TABLE`)
- We can drop a temporary table using `DROP TABLE` like regular tables if we want to remove it in session
- Useful when we want to isolate some data and store it intermediately instead of adding to query complexity
- If created within a transaction scope, a temporary table is only visible to that transaction
- It doesn't have any direct performance gains

---

## Parallel Query

- Postgres can use parallel queries feature which allows leveraging multiple CPUs for certain queries to provide better performance
- Not all queries benefit from this
- In the `Explain Plan`, the prescence of `Gather` or `Gather Merge` node specifies that all the operations below it are executed in parallel
- In a single query, max number of workers is specified by `max_parallel_workers_per_gather`
- Total number of parallel workers that can exist at a time is specified by `max_worker_pocesses` and `max_parallel_workers`
  - You can check these by `select current_setting(<paramName>)`
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

- Continue from https://www.postgresql.org/docs/current/sql-vacuum.html
- `Vacuum` is for garbage collecting and optionally analyzing the database
- It reclaims storage by reclaiming space from dead tuples
  - dead tuples are tuples which are deleted or obsoleted by an update
- By deafult, it will process every table and column the current user has permissions to vacuum
  - we can specify tables and columns list to restrict this
- the `Analyze` command is what helps with the analyzing and can collect database statistics
  - `analyze verbose` gives the output on pgAdmin for number of pages, live and dead rows for each table

---

## Performance tips

- Continue from https://www.postgresql.org/docs/current/performance-tips.html

---
