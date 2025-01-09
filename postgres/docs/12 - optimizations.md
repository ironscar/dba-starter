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

- Continue from https://www.postgresql.org/docs/current/how-parallel-query-works.html
- Postgres can use parallel queries feature which allows leveraging multiple CPUs for certain queries to provide better performance
- Not all queries benefit from this

---
