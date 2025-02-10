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
    - Warm standbys can be done by `File-based log shipping` or `Streaming replication` or both
    - Hot standbys have their own setup
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

### Standby server operation

- standby server enters standby mode if its data directory has a `standby.signal` file
- In standby mode, server can read WALs from an archive in file shipping or direclty over TCP connection to primary in streaming
- standby uses the `restore_command` to replay all WAL files from the archive location
- the failure response is discussed in more detail at https://www.postgresql.org/docs/16/warm-standby.html#STANDBY-SERVER-OPERATION
  - but the server will be stuck in a loop of trying to restore from archive and restore from primary until its stopped or promoted
- standby mode is exited when `pg_ctl promote` is run or `pg_promote()` is called

### Preparing standby server

- Take a base backup of primary and set it up on standby
- Create `standby.signal` file in data directory
- Set `restore_command` as before to copy files from WAL archive
- Setup all connections on standby as they are on primary as it will become primary after primary fails
- We can have any number of standby servers but if using streaming, `max_wal_senders` on primary must be set high enough
- Postgres recommends to use streaming replication in most scenarios unless the writes to DB are too infrequent
  - if infrequent, we can use logical replication or do continuous archiving with `scp` or `rsync` in the archive command
- For streaming replication, we also need to set `primary_conninfo` including the host, port, user and password if required
- If using WAL archive, size can be minimized using the `archive_cleanup` command to remove files no longer required by the server
  - we can use the `pg_archivecleanup <pathToArchive> %r` that does this automatically

### File-based WAL shipping

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

[TRIAL]
- Research on what tool to use for failover (ideally something that can work with different kinds of DBs)
- Try out streaming replication first and see if file-based log shipping is even required

[CONSIDERATIONS]
- Check what kind of manual setup would be required in the following cases:
  - postgres containers talk to themselves
    - need to create custom postgres image from current image with rsync and ssh installed
    - need to manually generate ssh keys for all standbys and primary and distribute the keys among them
      - does key need to be only on container or also on host?
    - if containers are destroyed etc, then reuse the keys generated previously (need to be stored)
  - some external job routinely copies WAL files from primary to standbys
    - need to create some sort of scheduled job that will copy the contents from primary archived directory to all standbys
    - still need ssh keys to be manually generated between these hosts
  - use streaming replication
    - if its always easier to setup and avoids all these problems, maybe do that first and skip this entirely
    - check if streaming is less frequent when writes are less frequent (so regular log shipping is not required at all)
  - need some way to always tell which server is primary from every other server - even after changes (failover)
    - apparently `select* from pg_stat_replication;` provides this information once the replication setup is done
- Also seems like failover is not automatically handled by postgres, and needs external intervention
  - Patroni, Pgpool-2, Repmgr, pg_auto_failover are some software that help with this (need to compare)
  - Check whether they can maintain a single connection point for consuming applications in some way and how

- Continue from https://www.postgresql.org/docs/16/warm-standby.html#STANDBY-SERVER-OPERATION

---
