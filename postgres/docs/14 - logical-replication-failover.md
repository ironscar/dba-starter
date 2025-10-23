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

- Security aspects of logical replication specified at https://www.postgresql.org/docs/18/logical-replication-security.html
- Work laptop setup (current IP assignments):
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

### Resynchronization

- Start with personal laptop setup where pgdb1 already has a few records
  - `pgdb1 (172.18.0.2)` on port `5432` and `pgdb2 (172.18.0.3)` on port `5433` on `WSL (172.26.144.1)`
  - pgdb3 will be initial primary and pgdb2 will be secondary
- running `pg_dump -Ft --no-data -t 'logrec.*' postgres -h 172.18.0.2 -p 5432 -U postgres > logrec.tar` on pgdb2 creates a TAR dump of all tables in `logrec` schema from pgdb1
- running `pg_restore -d postgres -U postgres logrec.tar` restores the dump into pgdb2 with those tables but no data
- we do `--no-data` because if data is there, new data doesn't seem to flow at all even after the subscription is created
- if tables are empty, then after creating subscription, the existing data is copied automatically and additional data starts flowing

---

## Logical replication failover

- This is used to allow subscriber nodes to continue replicating data from publisher even after publisher goes down
- The logical slots can be specified with `failover = true` when creating subscription to enable this feature
  - this ensures a seamless transition once the standby is promoted for it to act as the new logical publisher
- This process has a few prerequisites:
  - the current publisher and standby must be setup with streaming replication
  - the standby must have `sync_replication_slots = on` so that the replication slots can be synced asynchronously using a slotsync worker
  - it is mandatory to have a physical replication slot between primary and standby by configuring a `primary_slot_name` on the standby
  - `hot_standby_feedback = on` must also be set on the standby and `primary_conninfo` must include a valid `dbname` and `password`
    - having the password here maybe a security concern so its possible to specify in a `pgpass` file
    - even if streaming replication works without password, the `slotsync_worker` still needs a password to connect
  - its also recommended to set `synchronized_standby_slots` for the physical slot on the primary to prevent the subscriber from consuming changes faster than the standby
    - basically the standby gets updates synchronously and is guaranteed to stay ahead of the subscriber which gets updates asynchronously
    - make sure not to add the logical slots to `synchronized_standby_slots` in that case
  - refer to https://www.postgresql.org/docs/18/logicaldecoding-explanation.html#LOGICALDECODING-REPLICATION-SLOTS-SYNCHRONIZATION for additional details and caveats
- Once the current publisher (primary) goes down
  - it is recommended to disable the subscription on subscribers
    - this doesn't lead to loss of data as the updates are stored based on the associated replication slot on the publisher
    - once the subscription is restarted, the slot sends over all this data
    - however, this can also lead to data bloat at the slot level if too much time is taken before the subscription is enabled
  - then we must promote the standby
  - after promote, we need to make sure that all relevant logical replication slots are copied to the standby and ready for sync since the copy is asynchronous
  - then, alter the connection string of the subscription to promoted standby and enable the subscription

### Trial

- Create new `pgdb3 (172.18.0.4)` container running on host port 5434 which will act as the primary
  - enable connections from pgdb1 to pgdb3 etc by updating `pg_hba.conf`
  - take basebackup and restart container
  - update `cluster_name` for all containers to differentiate
  - add `standby.signal` and update `primary_conninfo` with `dbname` and `password` so that it can start acting as standby
  - set `sync_replication_slots = on`, `hot_standby_feedback = on, primary_slot_name = 'standby_1'` on standby
  - setting `wal_level = logical` is required for `sync_replication_slots = on`
  - restart container again
  - now streaming replication should be working with all pre-requisites on standby
- Setup logical replication with `pgdb2`
  - create publication for tables in `pgdb3` and verify publication gets created on `pgdb1` automatically
  - create empty tables and then subscription with `failover = true` on `pgdb2`
  - now logical replication between `pgdb3` and `pgdb2` would also be working
  - now both `pgdb1` and `pgdb3` would have an entry for the failover subscription in `pg_replication_slots`
    - the standby only gets those slots synchronized which are used for logical replication and are marked with `failover=true`
    - it takes a little bit of time for this to happen because slotsync is asynchronous
- Current setup: `pgdb1 ---<--- PHYSICAL ---<--- pgdb3 --->--- LOGICAL --->--- pgdb2`
- Now we need to simulate a failover by stopping `pgdb3`
  - Need to stop pgdb3
  - Then do following following manual steps
    - disable subscription on pgdb2
    - promote of standby pgdb1
    - update of subscription host on pgdb2
    - enable subscription on pgdb2 
  - Verify logical failover replication
    - chances are that currently `standby_1` physical replication slot doesn't exist on new primary `pgdb1`
    - but `synchronized_standby_slots` refers to it and blocks logical replication
    - so let's comment `synchronized_standby_slots = 'standby_1'` and reload config using `select pg_reload_conf()`
    - now even after this there could be problems because once it finds this issue, it doesn't keep trying
      - logical replication gets paused here so that in case there is a standby on a sync replication slot, it should remain ahead of the logical standby to allow future failover successfully
    - so we restart `pgdb2` and then logical replication starts working
  - Now, lets recover `pgdb3` as standby of `pgdb1` ready for next failover [DID-NOT-WORK]
    - this didn't work though as timelines diverged
    - we aren't redoing this as this is ultimately same as recovery in physical streaming replication with some more config updates
    - instead, we started with a new container and once streaming and slotsync started working, we enabled the `synchronized_standby_slots`
      - in a dynamic production environment, this may mean disabling the subscription again so that the standby can remain ahead
- Current personal laptop setup: `pgdb3 ---<--- PHYSICAL ---<--- pgdb1 --->--- LOGICAL --->--- pgdb2`

---

## Additional logical replication concepts

### Row filters

- Row filters are set at the publication-level
- They allow filtering which rows are published to subscriptions based on specified conditions
  - this is done as `create publication <pub_name> for table <table_name> where (<conditions>)` and the paranthesis is necessary around conditions
  - conditions cannot contain user-defined functions, operators, types, collations, system column references or non-immutable built-in functions
- Row filters have no effect for `TRUNCATE`
- For `UPDATE`, row filters are evaluated on both the old and new rows
  - if both are true, its replicated as an update
  - if both are false, its not replicated at all
  - if old is true and new is false, then its replicated as a DELETE
  - if old is false and new is true, then its replicated as INSERT
- During initial logical synchronization, only rows that match the row filter are copied over
- If the same table is published on different publications with different row filters for the same operation, the effective condition is OR of all of the individual ones
- In partitioned tables, we can specify the `publish_via_partition_root` boolean flag to specify if parent (root) row filter gets used or child row filter gets used in create publication statement

### Column lists

- Allows defining a list of columns to be published instead of all columns of the table
  - they are specified as `create publication <pub_name> for table <table_name> (<column1, column2 ....>)` with paranthesis for column list
- Recommended to include the primary key or some index column (especially for UPDATE and DELETE)
- If no columns are specified, then any new columns added later are also automatically picked up

### Conflicts

- Since changes are allowed on subscriber as well, it can lead to data conflicts
- If incoming data violates any constraints, then replication will stop
- Conflict statistics show up in `pg_stat_subscription_stats` for the following:
  - `insert_exists`: Occurs when a row being inserted violates a `NOT DEFEREABLE` and `UNIQUE` constraint
    - needs `track_commit_timestamp = on` on subscriber to track the origin / timestamp of change origin
    - an error is raised until issue is resolved manually
  - `update_origin_differs`: Occurs when updating a row that was already updated by something else
    - needs `track_commit_timestamp = on` on subscriber to detect this
    - the update is currently always applied regardless of the origin
  - `update_exists`: Occurs when a row being updated violates a `NOT DEFEREABLE` and `UNIQUE` constraint
    - needs `track_commit_timestamp = on` on subscriber to track the origin / timestamp of change origin
    - an error is raised until issue is resolved manually
  - `update_missing`: Occurs when row to be updated doesn't exist
    - updates are skipped in this case
  - `delete_origin_differs`: Occurs when deleting a row that was already updated by something else
    - needs `track_commit_timestamp = on` on subscriber to detect this
    - the delete is currently always applied regardless of the origin
  - `delete_missing`: Occurs when row to be deleted doesn't exist
    - deletes are skipped in this case
  - `multiple_unique_conflicts`: Occurs when a row being inserted / updated violates multiple `NOT DEFEREABLE` and `UNIQUE` constraints
    - needs `track_commit_timestamp = on` on subscriber to track the origin / timestamp of change origin
    - an error is raised until issue is resolved manually
- There are other violations that aren't captured in the above view such as exclusion constraint violations
- Details about these conflicts can be found in the subscriber logs
- More info at https://www.postgresql.org/docs/18/logical-replication-conflicts.html

- Try introducing and resolving one missing and one manual conflict
  - Try an `update_origin_differs` in two ways: [DONE]
    - update a record such that id (primary key) is same but the name is different
    - update a record such that id (primary key) and name is same
    - verify in both cases update is just applied
  - Try an `insert_exists` in two ways: [DONE]
    - input a record where the id (primary key) is same but the name is different
    - input a record where the id (primary key) and name is same
    - check in which case we have to resolve it manually and how
      - in both cases, the `logical replication apply worker` just exits and logical replication stops (verified from logs)
      - for resolving the conflict, we delete the entry that we manually inserted on subscriber
      - the moment we do, it automatically brings the subscriber back up to date with publisher by starting the logical replication again
    - We also tried `delete_missing` by manually deleting on subscriber and then deleting same record on publisher [DONE]
      - nothing happens to subscriber and logical replication is still active

### Restrictions

- Logical replication (v18) has current restrictions which maybe addressed in the future
  - DDL is not replicated so if schema changes on publisher and not on subscriber, replication will error out until subscriber schema is fixed
    - usually better to apply schema changes to subscriber first
  - Sequences are not replicated
    - the data in tables which were generated by sequence will be correct
    - but the current value of sequence on subscriber (if it even exists) will have initial value
  - Truncate over logical replication may fail if there are multiple tables with foreign key relations and some of them aren't in the publication
  - Large objects (https://www.postgresql.org/docs/18/largeobjects.html) cannot be logically replicated
  - Logical replication is not supported over views, materialized views or foreign tables
    - partitioned tables are allowed as long as the same partitions exist on subscriber

### Relevant configuration settings

- For publishers:
  - `wal_level = logical`
  - `max_replication_slots` set to a number greater than total number of subscriptions and some extra initial table synchronization workers
  - `max_wal_senders` set to number of physical replicas + `max_replication_slots`
- For subscribers:
  - `max_active_replication_origins` set to a number greater than total number of subscriptions and some extra initial table synchronization workers
  - `max_logical_replication_workers` set to a number greater than total number of subscriptions and some extra initial table synchronization workers
  - `max_worker_processes` set to `max_logical_replication_workers + 1` (and additionally any more required for parallel queries)
  - `max_sync_workers_per_subscription` controls amount of parallelization in initial data copy
  - `max_parallel_apply_workers_per_subscription` controls amount of parallelization for in-progress transactions if subscription parameter `streaming = parallel`

---

## Learnings

- Logical replication is useful for doing one-time migrations / upgrades across different Postgres versions or hosts
  - especially when we need some dynamic updates to flow in while we migrate which cannot be done using `pg_dump`
  - if dynamic updates are not required, rely on `pg_dump` alone
- Logical replication doesn't include DDL and is not a good alternative to physical streaming replication and true HA setups
- Ideal setup would be:
  - `pg_basebackup` if need to migrate / copy data without dynamic updates into same Postgres version on same type of host 
  - `pg_dump` if just need to migrate / copy data without dynamic updates into new Postgres version or new type of host
  - streaming replication with failovers for true HA setups
  - logical replication with failovers for migrations / upgrades requiring dynamic updates to flow in
- Also refer to `origin` and `copy-data` parameters of subscriptions at https://www.postgresql.org/docs/17/sql-createsubscription.html for avoiding cyclic-recursion of updates in muti-master logical replications as mentioned in https://www.postgresql.org/message-id/CAHut%2BPuwRAoWY9pz%3DEubps3ooQCOBFiYPU9Yi%3DVB-U%2ByORU7OA%40mail.gmail.com

---
