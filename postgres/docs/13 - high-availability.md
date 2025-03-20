# High availability, Failover & Sharding

## Introduction

- Database servers can allow for a second server to take over quickly if the primary server fails, and this is called high availability
- It is fairly easy to have multiple read DBs but its harder for writes because writes have to be propagated to all DB servers to remain consistent
- This consistency challenge happens due to synchronization and there are different solutions with different tradeoffs
  - there could be `warm standby` servers which cannot do anything but synchronize with writer
  - there could be `hot standby` servers which synchronize with writer but also allow reads (select queries)

## Solution comparison

- External interventions:
  - `Shared Disk Failover`
    - Uses a single disk array shared by multiple servers, like NFS for example
    - If one server fails, the second server is able to mount the disk and start automatically
    - this allows rapid failover and no data loss
    - shared disk must have full POSIX behavior
    - only one server can access disk at one time
    - if disk fails, everything fails
  - `File System Replication`
    - similar to `Shared Disk Failover`
    - difference is that the entire file system is copied over to another server
    - the copies have to be done in the same order as they are done on primary server to remain consistent
    - `DRBD` is a system replication solution for Linux which can be used for this
    - this allows standby servers to access the copied filesystem and if one disk fails, another standby can be brought up
    - its not as fast in failover and the file system copying adds a time lag
  - `Trigger-based Replication`
    - Send data modifications from a primary server to a standby asynchronously
    - this happens at a per-table basis because its based on triggers
    - this is often done for offloading large analytical or data warehouse queries
    - `Slony-1` is a solution that provides this for Postgres
  - `Multi-server Parallel Execution`
    - allows multiple servers to work concurrently on a single query
    - usually works by splitting the data among multiple servers and let each server do its part with its data
    - central server can then combine the results and return it
    - this can be done with the `PL/Proxy toolset`
- Internal solutions:
  - `WAL Shipping`
    - Warm and Hot standby servers can be kept up to date with a stream of WAL records
    - if primary fails, these standby servers can be quickly made primary
    - this can be synchronous or asynchronous, and has to be done for the entire database
    - Warm standbys can be done by `File-based log shipping` (skip) or `Streaming replication` (preferred) or both
    - Hot standbys are just a setting that can either allow read connections or not
  - `Logical Replication`
    - DB server can send stream of data modifications constructed from WAL to another server and also subscribe to changes from another
    - conflict resolution might become necessary as a result
    - this can be done at a per-table level
  - Both of the above have
    - no overhead on primary
    - never lose data if synchronous and never wait for other servers if asynchronous
  - `Sharding`
    - partition the data into multiple sets where each set is only modified by one server
    - above replication maybe used to synchronize changes of one server's set to another to provide reads
- Some other solutions are also discussed at https://www.postgresql.org/docs/16/different-replication-solutions.html

---

## WAL Shipping with Standby servers

- Continuous archiving can be used to create an active-passive HA cluster & warm standby servers are ready to take over if primary fails
- The primary server works in `continuous archive mode` while each standby server works in `continuous recovery mode`
- It doesn't require much administration by DBA and also has low performance impact on primary server
- WAL shipping is asynchronous which implies there can be data loss
- file-based shipping has to be done one file at a time (16MB) once each new WAL segment is written
- streaming replication allows more frequent transfers than file-based shipping, thereby enabling a smaller data loss window
- Doing a manual recovery from base backup takes a much longer duration and hence is not high-availability
- The primary and standby servers must be as similar as possible in terms of hardware and Postgres version
- The idea is all standbys should be upgraded first (because its more likely to be able to still replicate)
  - switch to one of these as primary if all good and then upgrade the old primary as a standby
- We have to create the `standby.signal` in data directory of standby to put it into standby mode
- The failure response is discussed in more detail at https://www.postgresql.org/docs/16/warm-standby.html#STANDBY-SERVER-OPERATION
  - but the server will be stuck in a loop of trying to restore from archive and restore from primary until its stopped or promoted

### File-based WAL shipping [SKIP]

- No streaming, use `scp` or `rsync` on primary and archive WAL files to every standby
  - neither is directly available on the Postgres docker container
  - apparently rsync is better than scp because scp can lead to copying partial WAL files if it fails in the middle
  - Alpine uses `apk` as package manager so we need to run `apk add rsync` and see if it works
  - This doesn't work directly so we need to add a DNS entry to the container in `/etc/resolv.conf` as `nameserver 8.8.8.8`
    - this file is automatically generated by WSL during every container restart so your changes won't survive restart
    - this is being overwritten by the host machine's DNS settings
    - we also need to comment out the current nameserver setting as it may lead to things not working out
    - with this, we were able to manually install `rsync` in both servers
  - For rsync to work, we need ssh, which is also not there on these servers, so we have to install that too
  - Looks like more and more customizations required, while streaming is a lot easier to setup, so use streaming instead
- Standby uses the `restore_command` to replay all WAL files from the archive location if using file-based log shipping
- If using WAL archive, size can be minimized using the `archive_cleanup` command to remove files no longer required by the server
  - we can use the `pg_archivecleanup <pathToArchive> %r` that does this automatically
- Postgres recommends to use streaming replication in most scenarios unless the writes to DB are too infrequent
  - if infrequent, we can use logical replication or do continuous archiving with `scp` or `rsync` in the archive command

### Streaming replication [PREFER]

- The following cannot be replicated: Views, Materialized Views, Partition Root Tables, or Foreign Tables, Large Objects and Sequences
- Postgres logical replication is restricted to DML operations only, with no support for DDL or truncate
- First, let's sync both DB containers with a base backup from one to another
- Let us have `postgresdb` as primary and `postgresdb2` as standby
- Setup all connections on standby as they are on primary as it will become primary after primary fails
- We can have any number of standby servers but if using streaming, `max_wal_senders` on primary must be set high enough (uncomment in `postgresql.conf`)
- Let's configure standby with `standby.signal` file (which puts the server in standby mode)
  - in standby mode, server can read WALs direclty over TCP connection to primary
- Set `primary_conninfo='host=192.168.196.2 port=5432 user=postgres options=''-c wal_sender_timeout=5000'''`
  - this is necessary for streaming to be setup
  - this sets the connection to primary and specifies that replication ought to be stopped if WALs not received in 5 seconds like if a server has crashed
    - there is a config with the same name which defaults to 1 minute
  - this can take a password as well or the password can be set in the `~/.pgpass` file
  - restore commands are not required
- We need to take the basebackup and make all these changes and then restart at once for streaming to work correctly
  - if `hot_standby=off`, we won't be able to connect to the standby server to check, but default is `on`
  - but we can query `pg_stat_replication` on primary to see there is a new record showing the streaming
  - we can also query `pg_stat_wal_receiver` on standby to see the new record
- Updating data in primary now also automatically gets replicated on the standby
- To guage types of delays in replication
  - we can use the `pg_current_wal_lsn()` on primary to check the current WAL
  - we can use the `pg_last_wal_receive_lsn()` on standby to check the last received WAL
  - we can check the difference between the two to guage how far behind the standby is
  - if difference between `pg_current_wal_lsn()` and `pg_stat_replication.sent_lsn` on primary is large => primary is under load
  - if difference between `pg_last_wal_receive_lsn()` on standby and `pg_stat_replication.sent_lsn` on primary is large => network is slow
  - if difference between `pg_last_wal_receive_lsn()` and `pg_stat_wal_receiver.flushed_lsn` on standby is large => WALs are coming in faster than can be replayed
- If we shut down standby for some time, make an update on primary and then restart the standby, it catches up on the updates
- If we try update statement on standby, it fails with error `cannot execute UPDATE in read-only transaction`
- Even if no writes are happening on primary, messages are regularly sent between primary and secondary over network
  - we can check this on the `pg_stat_wal_receiver.last_msg_send_time` column over multiple times

### Replication Slots

- Replication slots are a way to make sure that WAL segments aren't removed from primary until it has been received by all standbys
- It can only retain WALs upto a limit of `max_slot_wal_keep_size`
- `hot_standby_feedback` is a config param that decides if hot standby will send feedback to primary with respect to rows being removed on primary by vacuum, but only when its connected - whereas replication slots are always valid
- It is generally a better option to set replication slots than trying to do hot_standby_feedback or manual WAL segment persisting
  - all of the above options imply additional space being used to persist WALs
- Slots can be given a name and seen in the `pg_replication_slots` view
- We can create new replication slots with `select pg_create_physical_replication_slot('<name>')` on primary
  - currently we use `standby_1` as the slot for `postgresdb2`
  - each standby has to connect to a distinct slot at one time => number of standbys = number of replication slots
  - we can drop replication slots by `select pg_drop_replication_slot('<name>')` on primary
- We can set the `primary_slot_name` config param in `postgresql.conf` on standby to use that replication slot

### Cascading Replications

- We can also cascade replications from one standby to another thus reducing number of connections to primary
- Cascading replications are asynchronous currently and synchronous settings change nothing for it
- The steps are as follows:
  - we take a basebackup of primary (make sure to keep `root` as owner and not reassign ownership to `postgres`)
  - we create `standby.signal` inside basebackup
  - we need to set the `primary_conninfo` on the downstream standby to point to the upstream standby
  - we also need to make sure `pg_hba.conf` has the entries to connect accordingly
  - then restart the server
- We can also directly take basebackup of upstream standby, thereby skipping the creation of `standby.signal`
  - we still have to do the other steps
  - the benefit is that there is lesser load on the primary
  - the cons are as follows:
    - standby doesn't switch to new WAL during backup so backups may take long time for the last WAL (can manually run `pg_switch_wal()` on standby)
    - if standby is promoted to primary during backup, backup fails
- At this point, there will be a new entry in `pg_stat_replication` of upstream standby pointing to downstream standby
  - making an update on primary flows down to upstream standby and then to downstream even though primary `pg_hba.conf` doesn't have entries for downstream standby 

### Synchronous Replication

- Streaming is asynchronous by default, which can cause data loss if primary crashes before changes have been replicated to standby
- We can set streaming to synchronous to avoid this data loss, which is only supported by immediate standbys from main primary
- To enable this
  - set `synchronous_commit=on` on primary (default so no changes required)
    - we can also set this to `remote_write` which is less durable as it doesn't flush to disk on standby
    - but this returns faster than `on` which waits for flushing
    - good to consider as data loss here only happens if both primary and standby fail at same time which is very rare
  - set `synchronous_standby_names` on primary to specify a list of standbys to do synchronous commit on
    - the standby name can be specified as `application_name` in the `primary_conninfo` specified
    - if not specified, the `cluster_name` of standby is used (by default this is empty)
    - we go ahead and assign cluster names to each container and restart them
  - these application names will show up automatically in the `pg_stat_replication` view, and `sync_state` will show `sync`
- The standby names on primary also have some handy methods
  - `FIRST <num> (<name1>, ...)` can specify the first N in a list of standbys to replicate synchronously to
    - only the first N will be synchronous and the rest will be async
    - if one of the first N fail, then first N unfailed onces become sync and rest are async automatically
  - `ANY <num> (<name1>, ...)` can specify any N of standbys to be synchronous
    - so if `num = 2` and commit is received from 2 servers, the rest will be async
    - helps in faster commits as you only wait for the first two that acknowledge

### Planning for Performance & HA

- Synchronous replication affects performance especially with servers which are distant in the network
- Network bandwidth must also be higher than the rate of generation of WAL data across the entire HA setup
- If a synchronous standby crashes during a transaction commit, primary will keep waiting and never complete transactions
  - thus, we should have some synchronous and some async standbys using `ANY` (or `FIRST` if we know geographical details)

- Set `'ANY 1 (pgdb2, pgdb4)'` and see if stopping standby_1 automatically makes standby_2 as sync
  - when we do this, the `pg_stat_replication` table on primary specifies `sync_state` as `quorum`

### Failover strategy for Streaming replication

- Let us first try to do a manual failover
    - `postgresdb` = `pgdb1`
    - `postgresdb2` = `pgdb2` <=- `pgdb1`
    - `postgresdb3` = `pgdb3` <-- `pgdb2`
    - `postgresdb4` = `pgdb4` <=- `pgdb1`
    - Here `<--` implies async streaming and `<=-` implies quorum-based sync streaming
  - standby mode is exited when `pg_ctl promote` is run or `pg_promote()` is called [TRY]
    - update standby names on each server such that it doesn't need restart if it becomes primary
    - update cluster names as during failover, a standby will become primary and the naming will be confusing
    - shut down primary
    - run `select pg_promote();` on standby1
      - interim state of new system should be as follows:
        - `pgdb1` [DOWN]
        - `pgdb2` [PRIMARY]
        - `pgdb3` <=- `pgdb2`
        - `pgdb4` <=- `pgdb2`
    - run some update query on new primary and confirm replication to other standbys
    - restart primary as new standby
      - final state of system should be as follows:
        - `pgdb1` <-- `pgdb4` [CASCADED_STANDBY]
        - `pgdb2` [PRIMARY]
        - `pgdb3` <=- `pgdb2` [standby2]
        - `pgdb4` <=- `pgdb2` [standby1]
      - final state after `pgdb2` primary fails is:
        - `pgdb1` <=- `pgdb4` [standby2]
        - `pgdb2` <-- `pgdb3` [CASCADED_STANDBY]
        - `pgdb3` <=- `pgdb4` [standby1]
        - `pgdb4` [PRIMARY]
      - final state after `pgdb4` primary fails is:
        - `pgdb1` <=- `pgdb3` [standby1]
        - `pgdb2` <=- `pgdb3` [standby2]
        - `pgdb3` [PRIMARY]
        - `pgdb4` <-- `pgdb1` [CASCADED_STANDBY]
      - final state after `pgdb3` primary fails is (similar to inital config):
        - `pgdb1` [PRIMARY]
        - `pgdb2` <=- `pgdb1` [standby1]
        - `pgdb3` <-- `pgdb2` [CASCADED_STANDBY]
        - `pgdb4` <=- `pgdb1` [standby2]
    - the logic at each failover here is as follows:
      - when primary goes down, standby1 will become new primary
      - cascading_standby will become standby2 and standby2  will become standby1
      - when old primary comes back online, it will become cascading_standby
      - if a non-primary fails, we just try to restart it as is

- Here are the steps we are following:
  - we updated the names in file of all the DBs in the following order (but didn't restart yet)
    - `postgresdb3` -> `pgdb3`
    - `postgresdb4` -> `pgdb4`
    - `postgresdb2` -> `pgdb2`
    - `postgresdb` -> `pgdb1`
  - then we restarted all the servers in that order (ideally we set the names like this from the start)
    - interestingly we had to restart `pgAdmin` for the updates to show up in `pg_stat_replication`
  - then we need to update the connections such that they can remain relevant across failover and normal ops
    - first we go to `pgdb1`
      - then we updated the `primary_conninfo` on `pgdb1` to point to `pgdb4` which will be ignored while its primary but after failover it will point to that
      - once `pgdb1` fail happens and it comes back as standby, its `synchronous_standby_names` will be ignored as that config is only relevant on a primary
    - next we go to `pgdb2`
      - its `primary_conninfo` can remain unchanged as it will be ignored when it becomes primary after failover
      - we will update the `synchronous_standby_names` to be `ANY 1 (pgdb3,pgdb4)` which will only become viable once it becomes primary after failover
      - just need to run `pg_promote` function when primary fails - which is currently MANUAL but ideally needs to be automated
    - next we go to `pgdb4`
      - its `primary_conninfo` points to primary as `pgdb1` currently and we will need to update it to point to `pgdb2` after failover - this is MANUAL but since its still a standby (this is permissible)
      - its `synchronous_standby_names` needs to be `ANY 1 (pgdb1,pgdb3)` which will come into play once it becomes primary
    - finally we go to `pgdb3`
      - its `primary_conninfo` points to primary as `pgdb2` which is fine as post-failover it will continue to point to that itself
      - its `synchronous_standby_names` needs to be `ANY 1 (pgdb1,pgdb2)` which will come into play once it becomes primary
  - we will go ahead and restart again in same order as before and then restart pgadmin too for safe measure
  - we can refer to the `get cluster name and standby/primary connection details` query in the SQL file
  - next steps are to actually simulate a fail and then failover
    - stop pgdb1
      - currently row = `Iron3, Scar3`
    - run promote on pgdb2
      - at this point, `standby.signal` is removed from pgdb2 data directory
    - do some query updates on pgdb2 and check if they are replicated to pgdb3 synchronously now
      - currently row = `Iron3, Scar` on pgdb2,pgdb3
    - update `primary_conninfo` on pgdb4 and restart it
      - we also need to comment the `primary_slot_name` since it doesn't exist on pgdb2 though ideally we should create them on all the servers
      - after restart, pgdb4 catches up to currently row = `Iron3, Scar`
    - do some query updates on pgdb2 and check if they are replicated to both pgdb3 and pgdb4 in quorum
      - currently row = `Iron4, Scar` on pgdb2, pgdb3, pgdb4
    - restart pgdb1 and update it to standby by creating `standby.signal` and see if it works directly [TODO]
      - when we restart pgdb1, ideally it shouldn't be accessible from any apps as it will initially still think its master and we don't want any WAL conflicts due to writes on it at this point
      - when these containers are restarted, their IPs also change
        - thus pgdb1 became `192.168.196.105` and pgdb4 became `192.168.196.102`, so we need to keep that in mind when we set the primary conf atleast for local tests
      - pgdb1 is not getting any updates from anywhere [DEBUG]
        - the WALs could not be replayed directly due to timeline forking so we can try `pg_rewind` [TRY]
      - if it doesn't work directly, create new container by taking basebackup of pgdb4 and call it pgdb1
    - do some query updates on pgdb2 and check if pgdb1 is getting updates from pgdb4
    - if all works, manual failover process is complete
  - following steps were manual
    - running manual promote
    - update `primary_conninfo` of standby2 to new primary
    - restart primary as standby

- Check if we need to setup replication slots as part of database initialization [CHECK]
  - Yes this is required as replication won't work if a slot is specified on standby and doesn't exist on primary
- Patroni can apparently handle automatic failovers but needs extra nodes [Sharding-&-HA-Cluster-deployments]

### Hot Standby

- Continue from https://www.postgresql.org/docs/16/hot-standby.html

---
