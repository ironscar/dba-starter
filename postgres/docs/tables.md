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

## Select 

- Regular SQL queries work with the usual syntax except for the non-existence of `dual`
  - in this case we just skip the `from dual` part and it works as expected
- `WITH RECURSIVE` is a new thing which allows recursive queries like finding hierarchies
- `WITH` can also be used with `RETURNING` to move deleted rows of one table to another table

## Merge into

- Allows insert, update and delete all in one query
- Insert new records and update/delete existing record based on some condition

---

## Utility tables

- Utility tables store system information like what type of columns, what tables, what database objects etc
- Few of them are covered in the corresponding sql files

---
