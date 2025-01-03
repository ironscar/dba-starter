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
10. Backup/Restore [NOW]
    - pg_dump & pg_dumpall [DONE]
    - pg_restore [DONE]
    - pg_basebackup [DONE]
    - PITR [NOW]
11. DB links & Postgres_fdw
    - Foreign tables
    - Postgres CDC (Change data capture)
12. Optimization configurations
    - temporary tables (https://neon.tech/postgresql/postgresql-tutorial/postgresql-temporary-table)
    - with parallel_workers
    - Vacuum/Analyze
13. Sharding & Citus
14. High availability, failover & replication
    - https://pgdash.io/blog/horizontally-scaling-postgresql.html
    - https://www.enterprisedb.com/postgres-tutorials/postgresql-replication-and-automatic-failover-tutorial
    - https://www.postgresql.org/docs/current/runtime-config-replication.html
    - https://www.postgresql.org/docs/current/warm-standby.html
    - Shareplex?
15. Upgrade to DB versions
    - Try incremental base backups at this point
    - Can we automate upgrades too? 
16. DB DevOps strategy
    - Secret management and auto-update integration

---
