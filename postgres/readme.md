# Postgres SQL

For our cloud native learnings, we will do stuff on PostgresSQL

## Todo

1. Setup [DONE]
2. Tables [DONE]
3. Indexes [DONE]
4. Materialized views [DONE]
5. Procedures, Functions & Triggers [DONE]
6. Administration [DONE]
7. Role & User management [DONE]
8. Space management [DONE]
9. Partitions [DONE]
10. Backup/Restore [DONE]
    - pg_dump & pg_dumpall [DONE]
    - pg_restore [DONE]
    - pg_basebackup [DONE]
    - PITR [DONE]
11. DB links & Postgres_fdw [DONE]
    - DB links [DONE]
    - Foreign data wrappers [DONE]
12. Optimization configurations [DONE]
    - temporary tables [DONE]
    - parallel query [DONE]
    - genetic query optimizer [DONE]
    - vacuum [DONE]
    - performance tips [DONE]
    - JIT [DONE]
13. High availability, replication & failover [NOW]
    - https://www.postgresql.org/docs/16/high-availability.html [NOW]
    - https://pgdash.io/blog/horizontally-scaling-postgresql.html
    - https://www.postgresql.org/docs/current/runtime-config-replication.html
    - https://www.postgresql.org/docs/16/logical-replication.html
14. Sharding & HA Cluster deployments
    - Patroni: https://patroni.readthedocs.io/en/latest/ (for auto-failover)
    - Citus: https://www.citusdata.com/ (for sharding)
    - YugabyteDB: https://www.yugabyte.com/yugabytedb/
    - Distributed Multi-master HA and failover: (https://www.yugabyte.com/postgresql/distributed-postgresql/)
15. App integrations
    - With sharding and HA setup with failover
    - For procs/functions
    - Use Debezium to use CDC from DB (https://debezium.io/releases/ and https://debezium.io/)
16. Upgrade to DB versions
    - Try incremental base backups at this point
    - Can we automate upgrades too? 
17. DB DevOps strategy
    - Secret management
    - Password rotation
    - Auto-update integration
    - Testing

---
