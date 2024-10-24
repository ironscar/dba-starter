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

## PLSQL

- All PL/SQL stuff is enclosed within dollar-quotes like `$$` or `$<tag>$`
- We can declare variables in the declare section as `variable type = value` or `variable type := value`
  - we can also use the type of a specific column as `var1 table.column%type` or `var1 var2%type`
  - we can use `select <column> into <variable> from <table>...` to assign values to variables in body section
  - we can define type by rows like `variable table%rowtype` or `variable view%rowtype` and access fields as `variable.field`
  - we can use `record` type which can change type when reassigned values, so they be assigned any value whatsoever
  - we can create constants as `variable constant type := value`
- We can use the `raise` command to issue a message in the following levels
  - `debug`, `log`, `notice`, `info`, `warning`, `exception`
  - it is specified as `raise level format,value1,value2,...`
  - `%` placeholders are placed in format to be replaced by the values in order (number of placeholders = number of values, else error)
  - if level unspecified, it uses `exception` by default and stops the execution there
  - Postgres only allows `info`, `warning`, `exception` and `notice` messages to be sent to client
  - You can add hints to errors as `raise format,value using hint = '<hint>'`
- We can have conditions based on `if.. elsif... else` or `case..when...then...else`
  - they end with `end if` and `end case` respectively
- We can do various kinds of iterations in PL/SQL [CONTINUE-HERE]


- Try the bulk archiving setup in POSTGRES [CHECK]

---

## Functions vs Procedures

- Procedures do not return function value so don't need a `RETURNING` clause, which functions need
- Procedures are executed using `CALL` whereas functions are executed using `EXECUTE`
- Procedures can commit and rollback transactions whereas functions cannot
- Procedures & functions can be dropped and altered with the `ALTER ROUTINE` & `DROP ROUTINE` commands

---
