# Views

## Default Views

- Default views that compute a specific result and provide it as a virtual table
- This data is not actually stored anywhere and any query processing required to get that data is done at runtime
- Views don't support insert/update/delete on its own 
  - Views with only one table and no with clause (and some other conditions) do support it but more complex views do not
  - We can use `Rules` to support it
- Views don't need to be refreshed as they directly go to the base tables and get the data every time
- You can use `CREATE OR REPLACE` with views

---

# Materialized Views

- They work like views but actually store the result so that no processing is done at runtime
  - Don't support insert/update/delete in any case whatsoever
- You can refresh materialized views using the `REFRESH MATERIALIZED VIEW` command as they don't get auto-refreshed
- You can use `CREATE MATERIALIZED VIEW IF NOT EXISTS` here but not `CREATE OR REPLACE`

---
