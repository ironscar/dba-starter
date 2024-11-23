# Partitions

## Declarative Partitioning

### Introduction

- Splitting one large logical table into multiple physical tables
- Query performance can be improved when heavily accessed rows of table are in single partition
- Bulk loads and deletes can be handled on a partition-level, which is faster than doing bulk query
- There are three types of partitioning
  - `Range`: Table is partitioned into ranges based on one or set of columns with no overlap
  - `List`: Table is partitioned based on explicit values specified for each as a list
  - `Hash`: Table is partitioned based on modulus and remainder for each partition where dividing the parttion key (column) with specified modulus will produce specified remainder
- If we want to use other forms of partitioning, we can use `Inheritance` which maybe more flexible but not have the same performance benefits
  - Performance benefits for declarative partitions are only there is config setting `enable_partition_pruning` is set to `on`
- Partitions may have their own partitions, indexes, default values distinct from other partitions
- To find all partitions of tables, we can use `select distinct inhparent::regclass, inhrelid::regclass from pg_inherits`
  - this will also include indexes on the partition columns
  - we can join with `pg_class` on the `oid` column to `inhrelid` and check `relkind` has value `r` (indexes are `i`)
- we can select data from a partition by `select* from <partition_name>`
- During inserts or updates to parent table, records automatically get added into the correct partition
- Creating too many partitions can eventually add performance overheads

### Create Partitions

- First is to specify how to partition the table by `CREATE TABLE table ... PARTITION BY RANGE|LIST|HASH (column1,column2...)`
- Second is to create new tables as partitions by: 
  - `CREATE TABLE table_p01 PARTITION OF table FOR VALUES FROM (v1) TO (v2)` for range partitions
    - v1 is inclusive and v2 is exclusive
  - `CREATE TABLE table_p01 PARTITION OF table FOR VALUES (v1,v2...)` for list partitions
  - `CREATE TABLE table_p01 PARTITION OF table FOR VALUES WITH (MODULUS m, REMAINDER r)` for hash partitions
    - recommendations are that the modulus should be a power of 2 and the remainder be all numbers from 0 to modulus - 1
- We cannot create all this in one query in Postgres
- We can define tablespace for each partition by adding ` TABLESPACE <tablespace_name>`
- If you want to create sub-partitions for a partition, add ` PARTITION BY [RANGE|LIST|HASH] (cols)`
  - need to make sure that sub-partition values are a subset of the partition's as system doesn't check that and can cause runtime errors
- if we try to insert rows into table which specifies it should be partitioned but without actual partition tables, it fails insert
  - if the row to be inserted doesn't fit into any of the partitions, then query fails
  - if we are doing a bulk insert, full query fails and it doesn't insert any rows even if some of them satisfied for some partitions
  - if all rows are within defined partitions, it automatically gets inserted into correct partitions
  - we can verify this by doing `drop table <partition_name>` and seeing all rows in that partition deleted
- If we create an index for the partition key column on parent table, all existing and future partitions automatically create corresponding indexes for itself
  - if we attach/detach partitions here, indexes for each partitions persist
  - if index exists on to-be-attached partition, we can attach the index to parent table's index using `ALTER INDEX`
    - there are a few caveats with locking tables though so refer last section of `https://www.postgresql.org/docs/current/ddl-partitioning.html#DDL-PARTITIONING-DECLARATIVE-MAINTENANCE`
- You can also define a `DEFAULT` partition in case rows don't match any explicit partitions as below
  - `CREATE TABLE table_p01 PARTITION OF table DEFAULT`

### Drop partitions

- We can just use `drop table <partition_name>`
  - this does an `ACCESS EXCLUSIVE` lock on parent table (disallows reads)
- We can also do `ALTER TABLE parent_table DETACH PARTITION partition [CONCURRENTLY]`
  - this detaches the partition from the parent table but still allows accessing it
  - without concurrently, it still has an `ACCESS EXCLUSIVE` lock on parent table (disallows reads)
  - with concurrently, it has `SHARE UPDATE EXCLUSIVE` lock on parent table (disallows schema changes)
  - if indexes were created in parent table and as a result here, it persists even if its detached
  - we use `ALTER TABLE parent_table ATTACH PARTITION partition_table FOR VALUES FROM (v1) TO (v2)` to attach a partition
    - this partition maybe a completely new table or an older detached partition
    - this also uses `SHARE UPDATE EXCLUSIVE` lock on parent table (disallows schema changes)
    - before attach, it doesn't check the partition condition but during attach, it will and fail if there are rows that don't match
    - columns must match exactly
- If we drop the parent table, all partitions get automatically dropped
  - this holds true for the index of the parent table as well, where all partition indexes that got created also get dropped

### Limitations

- Unique key or PK on partitioned tables cannot include expressions or function calls
  - they even need to contain all the partition key columns if multiple are used
- `BEFORE ROW INSERT` triggers cannot change which partition will be the final destination of the row
- All partitions of a temporary table are temporary and all partitions of physical tables are also physical
- They cannot share inheritance with any regular tables

---

## Partition exchange

- Partition swap refers to swapping the records of a partition with records of a non-partitioned table
- Postgres doesn't have a Partition swap or exchange mechanism or it has to be done manually
- We can detach the partition which is currently part of the partitioned table
- We can attach the non-partitioned table as a new partition of the partitioned table
- Effectively, the records of the non-partitioned table are now in the partitioned table and the previous partition is now a separate non-partitioned table
- Indexes persist attach/detach operations so they remain consistent through this
- Uses cases
  - `Archiving data`: We can have the original and archived table, both partitioned
    - the original can have just 2 partitions while the archived can have any number
    - both partitions must be same rules to avoid validation errors and overlaps
    - at certain point of time, we detach the older partition from original and attach it to archived
    - if these tables are in different tablespaces, we can alter tablespace of archived partition
    - then, we create a new partition for original and wait to repeat the process
    - the process repeat will need to happen on a cron job of some sort

---

## Partitioning existing table

- Figure how to partition existing table, refer `exist-partitioning.sql`
- Shows how to use `EXECUTE` and `format()` to dynamically create tables and partitions
  - Also discusses the differences between `format()` and `using`

---

## Inheritance Partitioning

### Introduction

- Internally declarative partitions are linked by `Inheritance` but we cannot use all inheritance features for such partitions

---

## References [TODO-LAST]

- https://medium.com/@marinakrasnovatr81/postgresql-hash-partitioning-for-uuid-columns-no-triggers-and-rules-evenly-distribution-db7c8e9a9088

---
