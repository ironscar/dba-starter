# Indexes

## Explain plan

- Beside `Run` settings, there are the `Explain Plan` settings on the query tool
  - there is `Explain Plan (F7)` and `Explain Analyze` followed by a dropdown
  - `Explain Plan` is the basic one which gives prediction on number of rows
  - `Explain Analyze` gives more accurate information but also executes your query so use carefully for non-SELECT queries
  - The dropdown shows additional configurations like how verbose and whether to include costs etc
    - we have to repeat these configs every time we open a new file
- Select a query in pgAdmin and press `F7`, to see:
  - A graphical output for the query in `Explain > Graphical` tab
  - An analysis showing startup (a) and total cost (b) as `cost=a..b` under `Explain > Analysis`
    - this shows up only if cost is checked in the dropdown for Explain settings
  - Plan `rows` is the number of rows expected to be returned
  - Plan `width` is the width in bytes of the output rows
- Comparing plans in tables with very less data are not the same as very large data
  - so when doing plans, fill table with realistic amounts of data to check

---


## Indexes

- Indexes can be created to make select queries faster but slow down updates and inserts
- Indexes use different algorithms based on the type of index created:
  - B-tree (default)
  - Hash
  - GiST
  - SP-GiST
  - GIN
- Indexes should be avoided when
  - tables are too small
  - tables have frequent write operations
  - the indexed column has many null values
  - the indexed column is heavily manipulated
- Indexes are created without a schema name but are automatically assigned to the schema for the indexed table
  - while dropping, that schema needs to be specified before the name
- Indexes can be created as:
  - single column (usual)
  - multiple column (if a set of columns is directly and commonly used in where conditions)
  - functional (if a specific function is commonly used to format the columns in where conditions)
  - partial (if a specific subset of column values based on some condition is to be indexed due to most accesses)
- We can compare how well the indexes are doing based on:
  - make the actual query
  - fill table to predicted level of data if possible
  - check cost of query (use `Explain Analyze` for selects and just `Explain` for others)
  - add index, explain plans and compare them for improvements if any
  - if no improvements, no the time to add indexes yet
- Check when to know indexes need to be rebuilt [TODO]

---
