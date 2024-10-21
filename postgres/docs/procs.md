# Postgres SQL Triggers, Functions and Procedures

## Triggers

- Triggers can be specified to order when:
  - before operation is attempted on row
  - after operation is completed on row
  - instead of the operation
    - example is if we are trying to do CRUD on view and instead trigger it to the actual table
- Operations include (insert/update/delete/truncate)
- `FOR EACH ROW` triggers execute once for every row which was/will be operated upon
- `FOR EACH STATEMENT` triggers execute once per operation regardless of the number of rows
- The `WHEN` clause specifies that the trigger should only be applied when the specified condition matches
- Triggers are automatically dropped when the table connected to them is dropped
- The source and target of trigger must be in same database and table names must not include database name as prefix
- Triggers are specific to tables so there can be duplicate trigger names in a schema as long as the connected table is not same
  - don't keep duplicates as it may cause issues during deleting
  - thus, they also don't take schema prefix in name
- We always create functions for triggers and then execute it in the trigger
  - For insert, you have access to only `NEW`
  - For update, you have access to both `NEW` and `OLD`
  - For delete, you have access to only `OLD`
  - Trigger functions cannot take parameters like regular functions
  - For functions, we have to enclose the main body within `$$` and `$$ language plpgsql`
- To delete a trigger, use `drop trigger <trigger_name>;`
- There is also something called `CONSTRAINT TRIGGERS` [CHECK-THEM-LATER]

---
