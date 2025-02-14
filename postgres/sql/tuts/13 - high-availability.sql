--------------------------- STREAMING REPLICATION -------------------------

-- find the replication record on primary
select* from pg_stat_replication;

-- default is hot standby on
select* from current_setting('hot_standby');

-- update data
update student set first_name = 'Iron3' where id = 1;

-- changes are replicated successfully on standby
select* from student;

-- find the WAL reciever record on standby
select* from pg_stat_wal_receiver;

-- current WAL on primary (0/3F0003B8)
select* from pg_current_wal_lsn();

-- last WAL received on standby (0/3F0003B8)
select* from pg_last_wal_receive_lsn();

-- check if server is primary (false) or standby (true)
select pg_is_in_recovery();

-- max wal senders on primary
select current_setting('max_wal_senders');

-- create replication slots on primary
select pg_create_physical_replication_slot('standby_1');
select pg_create_physical_replication_slot('standby_2');

-- replication slots on primary
select* from pg_replication_slots;

-- get cluster name
select current_setting('cluster_name');

----------------------------- LOGICAL REPLICATION ---------------------------
