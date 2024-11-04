# Postgres SQL Triggers, Functions and Procedures

## Variables

- All PL/SQL stuff is enclosed within dollar-quotes like `$$` or `$<tag>$`
- We can declare variables in the declare section as `variable type = value` or `variable type := value`
  - we can also use the type of a specific column as `var1 table.column%type` or `var1 var2%type`
  - we can use `select <column> into <variable> from <table>...` to assign values to variables in body section
  - we can define type by rows like `variable table%rowtype` or `variable view%rowtype` and access fields as `variable.field`
  - we can use `record` type which can change type when reassigned values, so they be assigned any value whatsoever
  - we can create constants as `variable constant type := value`

---

## Logging

- We can use the `raise` command to issue a message in the following levels
  - `debug`, `log`, `notice`, `info`, `warning`, `exception`
  - it is specified as `raise level format,value1,value2,...`
  - `%` placeholders are placed in format to be replaced by the values in order (number of placeholders = number of values, else error)
  - if level unspecified, it uses `exception` by default and stops the execution there
  - Postgres only allows `info`, `warning`, `exception` and `notice` messages to be sent to client
  - You can add hints to errors as `raise format,value using hint = '<hint>'`

---

## Conditions

- We can have conditions based on `if.. elsif... else` or `case..when...then...else`
  - they end with `end if` and `end case` respectively

---

## Iterations

- We can do various kinds of iterations in PL/SQL
  - `LOOP` statement allows for looping continuously unless an `exit` condition is met
    - we end it with an `END LOOP` statement
    - labels for loops are specified as `<<loopname>> loop` and we exit them as `exit loopname;` but end is still `end loop`
    - for the exit condition, we can specify as `exit loopname when condition;`
    - If we want to use break/continue statements for outer loop in inside loop, we need labels, else we can do without labels
  - `WHILE` loops follow something like `<<label>> while condition loop... end loop`
    - these don't require an exit as they have the conditons on top
  - `FOR` loops follow something like `<<label>> for loop_index in [reverse] 1..10 [by step] loop ... end loop`
    - `step` is optional and specifies how much to decrement/increment by (defaulted to 1)
    - `reverse` is optional which allows decrementing the loop index by step
    - if using a select query, need to declare the for iteration variable, can use `record` or `table%rowtype` type

---

## Exception handling

- We can do exception handling in postgres with the `exception` block
  - we can check specific conditions with `when condition then` or generalized catch with `when others then`
  - these conditions can be actual conditons or stuff like `too_many_rows` or `no_data_found`
  - we can also use sql state codes like `when sqlstate = 'P0002'` which is the code for `no_data_found`
  - we may see usage of `into strict variable` here, basically if no rows or too many rows, `strict` throws an exception
  - by default, they don't throw exceptions and assign either null or the first value respectively without `strict`

---

## Parameters and return types

- For parameters and return types
  - parameters are specified in paranthesis of function/procedure include datatype and default value as `a int default 2`
  - return statements are like `return value;`;
  - calling with parameters for functions looks like: 
    - `select function_name(param_val1, param_val2)` with all params in order
    - `select function_name(name => val, name => val)` and params not required in order
    - we can skip params if they have been defaulted to some value
    - all parameters are `IN` mode by default and act like constants
    - we also have `OUT` and `INOUT` mode used for returns and updates respectively (prefer `IN` and `RETURN` instead)
- We can return multiple records from a function
  - using `returns table (col1 type1, col2 type2...)` and `return query select...`
  - you won't be able to do `select col1 from (select fn())` though
  - you need to select it as `select (fn()).col1` or `select (fn()).*`
  - we can also define return type as a set of specific table by `returns setof <table>`
- Sometimes `CREATE OR REPLACE` doesn't allow to replace due to change in return or parameter types
  - specifically if we are chaning from `IN` params to `OUT` params etc.
  - we have to drop it first and recreate it in that case

---

## Dropping

- While dropping functions/procedures, we also need to specify the params as they could be overloaded with same name
  - functions are overloaded if they have same name but different params list
  - there can be conflicts if one function has default arguments while another is overloaded
    - Postgres allows you to create it and thus throws runtime errors for when there are conflicts
  - we can drop multiple functions as a time by `drop function [if exists] f1, f2...fn [cascade/restrict]`
  - we can add `if exists` to prevent failures
  - we can use `cascade` to delete function and all its dependents
  - we can use `restrict` to reject delete if there are any dependents
- Procedures also support dropping with `drop procedure [if exists] proc1, proc2... procn [cascade/restrict]`
- For both, if no parameter conflicts and names are unique, we can drop just by name

---

## Functions vs Procedures

- Procedures do not return function value so don't have a `RETURNING` clause, which functions need
  - You can call just `return;` without an expression in procedures to immediately return from it though
- Procedures are executed using `CALL` whereas functions are executed using `SELECT`
  - In triggers we do `execute function f();`
- Procedures can commit and rollback transactions whereas functions cannot
- Procedures & functions can be dropped and altered with the `ALTER ROUTINE` & `DROP ROUTINE` commands

---

## Cursors

- A cursor allows you to traverse a result object row by row
- First we fetch a cursor and then open it, and keep going next until empty, and then close it
- In `declare` section, we define the cursor and its SQL statement
- In the body, we open the cursor and `FETCH NEXT` and store into a record variable
- When we define `returns table(col1 type1, col2 type2)`, col1 and col2 automatically become `OUT` params
- Then we can assign those output params values via the record variable
- If we do all this in a `LOOP` with the cursor, and then use `RETURN NEXT`, the results get put in table

---

## Triggers

- Triggers can be specified to order when:
  - before operation is attempted on row
  - after operation is completed on row
  - instead of the operation
    - example is if we are trying to do CRUD on view and instead trigger it to the actual table
- Operations include `insert/update/delete/truncate`
  - we can define `before/after/instead of` only once
  - we can define `insert/update/delete/truncate` multiple times with `OR` like `before insert OR update OR delete`
- `FOR EACH ROW` triggers execute once for every row which was/will be operated upon
- `FOR EACH STATEMENT` triggers execute once per operation regardless of the number of rows
- The `WHEN` clause specifies that the trigger should only be applied when the specified condition matches (always in paranthesis)
- Triggers are automatically dropped when the table connected to them is dropped
- The source and target of trigger must be in same database and table names must not include database name as prefix
- Triggers are specific to tables so there can be duplicate trigger names in a schema as long as the connected table is not same
  - don't keep duplicates as it may cause issues during deleting
  - thus, they also don't take schema prefix in name
- We always create functions for triggers and then execute it in the trigger
  - For insert, you have access to only `NEW` and you do `RETURN NEW` in its function
  - For update, you have access to both `NEW` and `OLD`, and you do `RETURN NEW` in its function
  - For delete, you have access to only `OLD` and you do `RETURN OLD` in its function
  - Trigger functions cannot take parameters like regular functions
  - For functions, we have to enclose the main body within `$$` and `$$ language plpgsql`
- To delete a trigger, use `drop trigger <trigger_name> on <table>;`
  - it takes option for `CASCADE` and `RESTRICT` which either deletes or throws error due to dependent objects
- We can change name of trigger by `ALTER trigger <trigger_name> on <table> rename to <new_trigger_name>`
- We can enable or disable triggers as
  - `ALTER table <table> <disable/enable> trigger <trigger_name>` or `ALTER table <table> <disable/enable> ALL`
  - the latter disables all existing triggers on the table, doesn't affect new triggers

### Cascading triggers

- Triggers can trigger themselves if they update the same table they are set on causing infinite recursion
  - This is called `CASCADING TRIGGERS` and the developer must attempt to avoid it
  - We can use `pg_trigger_depth()` to control if a trigger can trigger itself or other triggers
    - its an internal function that returns the depth of current trigger
      - 0 implies a user action triggered it, 1 implies just one trigger triggered it and so on
    - when we want other triggers to react to a trigger event as well, we can use this
    - we can specify the depth till which we want it to allow triggering (generally in WHEN clause of trigger)
  - When we want fine grained control, we can also use session variables to specify the recursion condition:
    - we can set it like `PERFORM set_config('session.session_var', <val>, false)`
      - `perform` is like `select` but is only used inside functions/procs when we are discarding the result of `select` 
      - the last parameter is if its local or not, implying if its set only for the current transaction
      - the `<val>` is always a text value so if you need numbers, you have to typecast it when you get its value
    - we can read it like `if current_setting('session.session_var', TRUE) = <val>`
      - the last param specifies whether it should throw error (false) or return null (true)
    - use these carefully as they cannot be unset in the same session

### Event triggers

- These get triggered when oen of the following events happen in the database
  - `ddl_command_start` is evoked before executing `CREATE/ALTER/DROP/GRANT/REVOKE/SECURITY/LABEL/COMMENT`
  - `ddl_command_end` is evoked after executing the above commands
  - `table_rewrite` is evoked when a table or type is altered with `ALTER`
  - `sql_drop` happens when any database object is dropped with `DROP`
- These can only be created by superuser
- These do not support `CREATE OR REPLACE` and so we have to `DROP` and `CREATE` them to modify them
- The function associated with it has `RETURNS EVENT_TRIGGER`
- We use `CREATE EVENT TRIGGER` to create an event trigger
  - we have access to certain contextual variables like `TG_EVENT` and `TG_TAG`
  - `TG_EVENT` specifies what event happened as specified above (example `sql_drop`)
  - `TG_TAG` has the specific event (example `DROP TRIGGER`)
  - they don't need a `RETURN NEW` in the function body
- To drop them, we use `DROP EVENT TRIGGER <trigger_name>;`

### Constraint triggers

- These are used to enforce conditions on a table that cannot be done by regular constraints
- Refer to https://www.cybertec-postgresql.com/en/triggers-to-enforce-constraints/ for an example
- Triggers can be subject to race conditions in `read committed` isolation for transactions happening concurrently
  - normal constraints are not subject to this as they look at all rows regardless of isolation level
  - we can raise the isolation level to `serializable` where transactions will happen without race conditions but some will fail due to concurrent transactions
- Constraint triggers are still liable to race conditons in `read committed` isolation but can be deferred till after transaction ends

---
