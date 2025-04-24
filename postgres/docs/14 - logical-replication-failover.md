# Logical replication & Failover

## Introduction

- Logical replication allows replicating specific database objects at an entity-level instead of every object at a block level like streaming replication does
- It uses a publisher-subscriber model where one or more subscribers subscribe to one or more publications on a publisher node
- It allows cascading as well to get complex replication setups
- A single subscription will never cause conflicts but if other applications or subscribers write to same table, then conflicts can arise

## Publications

- Continue from https://www.postgresql.org/docs/16/logical-replication-publication.html

---
