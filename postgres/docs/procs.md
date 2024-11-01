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
- To delete a trigger, use `drop trigger <trigger_name> on <table>;`
- Triggers can trigger themselves if they update the same table they are set on causing infinite recursion
  - This is called `CASCADING TRIGGERS` and the developer must attempt to avoid it
  - We can use `pg_trigger_depth()` to control if a trigger can trigger itself or other triggers
    - when we want other triggers to react to a trigger event as well, we can use this
    - if depth = 0 => no other triggers fired, else they are fired
  - We can also use session variables:
    - we can set it like `PERFORM set_config('session.session_var', <val>, false)`
    - we can read it like `if current_setting('session.session_var', TRUE) = <val>`
- There is also something called `CONSTRAINT TRIGGERS` [CHECK-THEM-LATER]

---
