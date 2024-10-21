# Postgres SQL Tables

## Create

- use `CREATE TABLE` command to do this
- we can set the type to `serial` to auto-generate ids
- we can delete tables using `drop table {tableName}`

## Alter

- you can alter a variety of things as show in the corresponding sql file

## Insert

- use `INSERT INTO` command to do this
- we can either do `VALUES (...)` to insert a single row
- or we can do `SELECT` and `UNION` as shown in `tables.sql` to insert multiple rows

## Update

- use `UPDATE` command to do this

## Delete

- use `DELETE FROM` commmand to do this

## Truncate

- use `TRUNCATE TABLE <tableName>` command to do this
- this doesn't delete the table but deletes all the data from the table

## Select 

- Regular SQL queries work with the usual syntax except for the non-existence of `dual`
  - in this case we just skip the `from dual` part and it works as expected
- `WITH RECURSIVE` is a new thing which allows recursive queries like finding hierarchies
  - type casting can be done as `column::text` to cast it to type `text`
  - the order of operations in `WITH RECURSIVE` is as follows
    - the anchor member (top query of union to the direct table) executes first (call it R0)
    - then taking R0 as input, the recursive member (the other query in union) executes next (call it R1)
      - basically R0 acts as cte
    - then taking R1 as input, the recursive member runs again to get R2 and keeps going
      - stops only if Rx is an empty result
    - then returns `R0 union R1 union R2 union R3 ..... Rx`
      - depends on if we use `union` or `union all` inside the with clause
- `WITH` can also be used with `RETURNING` to move deleted rows of one table to another table
- To get the current date, we use `select current_date;` unlike sysdate in Oracle

## Merge into

- Allows insert, update and delete all in one query
- Insert new records and update/delete existing record based on some condition

---

## Utility tables

- Utility tables store system information like what type of columns, what tables, what database objects etc
- Few of them are covered in the corresponding sql files
- The ones in `information_schema` require the schema to be specified while querying
- The ones in `pg_catalog` are directly accessible and don't require the schema to be specified while querying

---
