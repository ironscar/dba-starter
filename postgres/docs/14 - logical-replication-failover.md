# Logical replication & Failover

## Introduction

- Logical replication allows replicating specific database objects at an entity-level instead of every object at a block level like streaming replication does
- It uses a publisher-subscriber model where one or more subscribers subscribe to one or more publications on a publisher node
- It allows cascading as well to get complex replication setups
- A single subscription will never cause conflicts but if other applications or subscribers write to same table, then conflicts can arise

### Publications

- A publication can be defined on any primary node (publisher)
- Its a set of changes generated from one/more tables
  - new tables can be added/removed using `ALTER PUBLICATION ADD TABLE` or `ALTER PUBLICATION REMOVE TABLE`
- Objects must be added explicitly except when publication is created for ALL TABLES
- It exists in only one database
- They can be configured to publish any of INSERT/UPDATE/DELETE/TRUNCATE (default all)
  - does not replicate DDL such as indexes so indexes would have to be recreated in the subscriber
- Publisher can have multiple subscribers
- Publishers can also be defined on a subset of a table by 
  - adding conditional statements based on columns
  - specifying only specific columns to be replicated
- We can see all publications from `pg_publication`

### Subscriptions

- A subscription is the downstream of the logical replication and defined on the standby nodes (subscriber)
- A subscription defines the connection to another database and a set of one or more publications
- It is possible to define multiple subscriptions between the same publisher and subscriber but they must not overlap
- Only superusers can see all subscriptions from `pg_subscription`
- If a subscription is dropped and recreated, data has to be resynchronized, else updates do not flow
- The target schema and table must already exist on subscriber node with the same name as part of initial synchronization
- Columns are also matched by name but order of columns in target table can be different, target can even have extra columns which will get filled in with default values

### Replication slot management

- Subscribers receive changes from a replication slot on the publisher node
- We can see replication slots in `pg_replication_slots`
- Normally an internal replication slot is created when a subscription is created but in some cases it might be useful to manage slot and subscription separately
  - if slot already exists
  - if publisher node is not reachable
  - slot needs to be retained even if subscription is being dropped
- A subscription cannot be dropped if the corresponding replication slot till exists and can be done in two ways
  - Method 1 (can be done entirely on the subscribing DB instance)
    - `alter subscription <subname> disable`
    - `alter subscription <subname> set (slot_name = NONE)` (needs the subscription to be disabled first)
    - `drop subscription <subname>`
  - Method 2 (needs commands to be run on both publisher instance and subscriber instance)
    - `select pg_drop_replication_slot('<rep_slot_name>');` (the replication slot will by default be created with same name as the subscription)
    - `drop subscription <subname>`

### Deferred slot creation

- Sometimes it maybe useful to create the replication slot separately
- We have two methods for this as well
  - Method 1
    - create subscription adding `WITH (connect=false)`
  - Method 2
    - create subscription adding `WITH (connect=false, slot_name=NONE, enabled=false, create_slot=false)` (last 2 are required if slot_name is `NONE`)
  - after this
    - create manual logical replication slot in publisher by `select pg_create_logical_replication_slot('<subname>', 'pgoutput')`
    - alter and refresh the subscription by `alter subscription <subname> enable` and `alter subscription <subname> refresh publication`

---

## Setup logical replication

### Work laptop v16 setup

- Current IP assignments
  - pgdb1: 192.168.196.2 
  - pgdb2: 192.168.196.3 (streaming primary)
  - pgdb3: 192.168.196.4
  - pgdb4: 192.168.196.5 (logical primary)
- We will begin with creating a new schema `logrec` with two tables `tlr1` and `tlr2` in it on `pgdb4`
  - insert data in there as well
- We will attempt to setup logical replication to the primary (currently `pgdb2`) for these tables
  - then verify these changes are streamed down to `pgdb1` and `pgdb3` by streaming replication
- We also have to create the same tables on `pgdb2` as part of the initial synchronization
  - don't insert data here yet
- Then we need to create publications on the publisher node
  - refer https://www.postgresql.org/docs/current/sql-createpublication.html for all the ways possible
  - the default `wal_level` is `replica` and this is insufficient for creating publications
    - only allows streaming replication
  - we need to set it to `logical` to record additional information in the WALs for logical decoding
    - allows both streaming and logical replication
- Then we need to create subscriptions on the subscriber nodes
  - refer https://www.postgresql.org/docs/current/sql-createsubscription.html for all the ways possible
  - need to set `wal_level` to `logical` for all subscriber nodes as well
  - once the subscription is created
    - logical replication copies all data in tables from `pgdb4` to empty tables of `pgdb2`
    - streaming replication replicates all data from `pgdb2` to `pgdb1` and `pgdb3`
- Next we will try inserting data into `pgdb4` and see if it gets replicated everywhere
  - after insert, logical replication publishes it to `pgdb2` and then streams it to `pgdb1` and `pgdb3`

### Personal laptop v18 setup

- pgdb1 (172.18.0.2) on port 5432 and pgdb2 (172.18.0.3) on port 5433 on WSL (172.26.144.1)
- pgdb1 will be primary and pgdb2 will be secondary
- creating subscription after creating empty tables helps the updates to flow, otherwise might need to resynchronize via `pg_dump / pg_restore`

---

## Issues

- When subscriber is shut down, then queries take extremely long on publisher, but resolves the moment the subscriber comes back online [CHECK]
  - Check if setting `synchronous_commit = off` helps [DID-NOT-WORK]
  - It randomly got resolved on its own so not really sure what happened

---

Continue from https://www.postgresql.org/docs/18/logical-replication-failover.html

Also refer to `origin` and `copy-data` parameters of subscriptions at https://www.postgresql.org/docs/17/sql-createsubscription.html for avoiding cyclic-recursion of updates in muti-master logical replications as mentioned in https://www.postgresql.org/message-id/CAHut%2BPuwRAoWY9pz%3DEubps3ooQCOBFiYPU9Yi%3DVB-U%2ByORU7OA%40mail.gmail.com
