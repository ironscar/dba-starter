# Postgres Backup / Restore

## Backup

- Postgres comes with `pg_dump` and `pg_dumpall` tools to perform logical backups

### PG_DUMP

- Command line utility that takes a logical backup of a Postgres DB
- It creates a script/archive file representing the snapshot of the DB when command is run
- `pg_dump [connection_option] [option]` takes following flags:
  - `-U` username
  - `-h` hostname
  - `-p` port
  - `-d` dbname
  - `-n` schema
  - `-t` table
  - `-F` format
  - `-f` output file name
  - `-h` help
  - `-w` suppress password prompt (using a .pgpass file)
- There are other flags that can be found at https://neon.tech/postgresql/postgresql-administration/postgresql-backup-database#pgdump
- A `.pgpass` file stores password in this format `hostname:port:database:username:password`
  - Example: `localhost:5432:*:postgres:[pass]` implies all databases in the local DB running on port 5432
  - Default format is `plain` which creates an sql file
  - it also needs to be set to permissions 0600 by `chmod 600 ~/.pgpass` so that its no ignored
  - We put this file in the home directory of the user that is going to execute `pg_dump`
  - When we ran `pg_dump` as `root` from within container, it didn't prompt for a password

- Run `pg_dump -U postgres -d student_tracker -f ~/student_tracker_backup.sql`
  - we run this inside the docker container using `docker exec -it postgresdb1 /bin/bash`
  - when we run this, it generates an SQL file in root user's home directory
  - we can then copy it into WSL or Windows using `docker cp postgresdb1:/root/student_tracker_backup.sql <host_path>`
  - The `/root` is the home directory of root user in this Postgres image
  - The `host_path` can be `.` if you are already in the directory where you want to copy it
    - For `WSL`, your actual files are at `/mnt/c/Users/a0230288/`
  - We copied the backed up file into repo as `student_tracker_backup.sql`

### PG_DUMPALL

- `pg_dumpall` creates backup of all databases in the Postgres DB instance
- `pg_dumpall [connection_option] [option]` takes following flags:
  - `-U` username
  - `-h` host
  - `-p` port
  - `-g` or globals-only dumps all roles and tablespaces but not data
  - `-r` or roles-only
  - `-t` or tablespaces-only (no data from the tablespaces)
  - `-s` or schema-only (no data but all objects including roles, tablespaces, schemas, tables, index, triggers, functions etc)
- Other flags can be found at https://neon.tech/postgresql/postgresql-administration/postgresql-backup-database#pgdumpall

- We did the same with `pg_dumpall`
- We run `pg_dumpall -U postgres > ~/all_databases_backup.sql` in the container and then copy it out into the repo the same way

---

## PG_RESTORE

- Postgres comes with the `pg_restore` tool to restore from a backup file created by `pg_dump` or `pg_dumpall`
- It runs like `pg_restore [connection-option] [option] [filename]` and takes following flags:
  - `-U` username
  - `-h` hostname
  - `-p` port
  - `-d` dbname
  - `-t` table
  - `-j` number of parallel jobs to use when restoring
  - `-L` specifies a file with list of files that you want to restore from (if you have multiple files)
  - `-c` clean drops all objects before recreating them
  - `--if-exists` makes sure to check if exists for all drops in clean mode
- There are other flags mentioned at https://neon.tech/postgresql/postgresql-administration/postgresql-restore-database
- Restoring backups can even override passwords to match those of the backed up database if they were previously different
- We can use `-c` and `--if-exists` to reduce errors in backing up to a completely new database instance

### Restore single database from SQL file

- We will test this by creating a new DB container and then using pg_restore on top of that
- Run `psql -U postgres -d postgres /root/student_tracker_backup.sql` from terminal
  - We do this as `pg_restore` doesn't allow restoring from SQL files (text format dump)
  - We also need the database to exist in new DB so we use `postgres` as `student_tracker` doesn't exist there
- This basically copies data and DB objects that were in the student_tracker DB from container 1 into the postgres DB container 2
- But some things fail because they somehow didn't get captured in the backup and weren't in the new DB either
- When deleting container, remember to clear the volume backup at `/datadir/{whatever-folder}` so that the new container doesn't automatically pick up on that data
- Size of SQL file is 28KB

### Restore all databases from SQL file

- We will test this by creating a new DB container and then using pg_restore on top of that
- Run `psql -U postgres -d postgres /root/all_databases_backup.sql` from terminal
  - We do this as `pg_restore` doesn't allow restoring from SQL files (text format dump)
- This basically copies all data and DB objects from container 1 into container 2
- Some things may still fail if certain objects like the role already exist
- When deleting container, remember to clear the volume backup at `/datadir/{whatever-folder}` so that the new container doesn't automatically pick up on that data
- Size of SQL file is 33KB

### Restore all databases using TAR file

- You can create TAR files from `pg_dump` but not from `pg_dumpall` even if we name file as `.tar`
  - This is controlled by adding `-F tar` to the comand
- Once the file is on new container, we can use `pg_restore` from TAR file
- Run `pg_restore -U postgres -d postgres student_tracker_backup.tar` from CMD
- Size of TAR file is 62KB (bigger due to containing extra header information)
- For very large DB objects, we must use TAR as pg_dump rejects using plain-text SQL for such objects

### Final points

- Postgres allows tables larger than the entire file system
- Dumping such a DB to file wouldn't be possible normally
- But we can use https://www.postgresql.org/docs/8.0/backup.html#BACKUP-DUMP-LARGE to compress the dump

---

## Base Backup & Point-in-time recovery

- `pg_dump` is easy to use, creates consistent backups at time of running and allows flexible restoration
  - For very active DBs, backups might miss some data
  - For extremely large DBs, `pg_dump` might take a lot of time and impact performace
- When we are dealing with high-traffic or large databases or want a standy DB with quick failover
  - it would be better to use `pg_basebackup`
- `Point-in-time recovery` (PITR) is a feature that allows restore the database to a previous state from a particular point in time to recover from unwanted changes

### PG_BASEBACKUP

- Takes a base backup of a running Postgres cluster
  - basically the actual files that represent the DB instead of a set of SQL statements that can recreate the DB like in `pg_dump`
- It can take full or incrememntal backups
- It can be used for PITR and streaming-replication-standby server
- It takes backups of entire DB cluster always and cannot selectively do objects like `pg_dump`
- It can only restore for the same DB version on same platform so new versions of DB on different OS cannot be restored unlike `pg_dump`
- It is possible to run multiple base-backups at the same time but its better from a performance standpoint to take one backup and then copy it
- All flags for command can be found at https://www.postgresql.org/docs/current/app-pgbasebackup.html
- It first does a checkpoint on connecting to the Postgres server to copy
  - Refer to https://www.cybertec-postgresql.com/en/postgresql-what-is-a-checkpoint/ for what is checkpoint
  - this is usually slow as it waits for the next DB checkpoint (default using the value `-c spread`)
  - we can make it immediate by specifying value as `-c fast`
- The wal-method by default is `-X f` (fetch) which copies WAL (write-ahead-log) files at end of backup
  - but its possible to send the WAL files in parallel by opening a second parallel connection using `-X s` (stream)
- Backup data is inconsistent without the WAL files if DB is being modified during backup

#### Full backup

- Command looks like `pg_basebackup -h <host> -U <dbuser> -D <directory to copy to>`
  - We create a new postgres container
  - the previous container is at `192.168.196.2` and new one is at `192.168.196.3` (different for everyone)
  - we log into new container to run the base-backup command pointing to the ip of old container & store files in `/root/basebackup`
  - this fails with no replication connection for new container to old container in `pg_hba.conf`
  - so we add the entry as `host all all 192.168.196.3/32 trust` to `pg_hba.conf` of old container
  - then we have to restart the old container for changes to effect
  - next error is `role root doesn't exist`
  - so we add `-U postgres` and then it gets to work and copies all the data to second container
- In addition to all contents in `/var/lib/postgresql/data/pgdata`, it has a backup_label and backup_manifest
  - this manifest file can be used to verify the backup using `pg_verifybackup` and for incremental backups
- To restore the backup, we essentially have to replace the contents of current `pgdata` with this backup
  - So `cp -r /root/basebackup /var/lib/postgresql/data` to copy all contents of `basebackup` dir into `data` dir
  - Then in `data` dir, rename the `pgdata` dir to `pgdata_ini` by `mv pgdata pgdata_ini`
  - Also rename `basebackup` dir to `pgdata` using `mv basebackup pgdata`
  - Finally, we have to restart the container for changes to take effect
- This, like `pg_dumpall` copies even the password to be same even if it were different before
- For some cleanup
  - We will rename `basebackup` to `basebackup_full` to segregate it from incremental backups

#### Incremental backup

- This is only available from Postgres 17 and not in Postgres 16 [UNTESTED]
- The only addition here is the `-i <manifest_file>` flag that needs the manifest file from the last backup
- Let's also enable `-P` for reporting so that it adds stats to `pg_stat_progress_basebackup`
- We also update a table with update statement before taking the backup so that new container and old container differ
- Then we use the `pg_combinebackup <backup_full> <backup_incr1> <backup_incr2> -o <output_backup_dir>` command
  - the backups specified have to start with full and can specify as many incremental backups in order
  - the `output_backup_dir` will then house the final backup to be used as data directory

### Point-in-time Recovery (PITR)

- Continue from https://www.postgresql.org/docs/16/continuous-archiving.html
- This doesn't save details from the config files like `pg_hba.conf` or `postgresql.conf`
- We take a backup of the database and then continue archiving WALs
- WAL files are stored in `/var/lib/postgresql/data/pgdata/pg_wal`
- Then based on time, we can just replay archived WALs till that time to get the version of the DB at that time
  - `pg_dump` and `pg_dumpall` are logical backup tools and cannot be used for this
  - needs WALs starting from the base full backup
  - only works for full database server and not specific entities in it
- A Postgres system generates WAL files in segments of 16MB, each having a numeric name specifying its sequence position
  - when not using WAL archiving, the system renames these sequences and recycles them once the WALs have been written to disk
  - to do archiving of WALs, the `wal_level` should be `replica` or higher and `archive_mode` to `on` where default is `off` (check in `pg_settings` table)
  - we also need to specify the command to use for archiving in `archive_command` (only used if `archive_library` unset)
- We can set the `archive_command` to `'test ! -f /root/archived_wals/%f && cp %p /root/archived_wals/%f'`
  - we will create `archived_wals` directory and use `chown postgres archived_wals` to make `postgres` user as owner (otherwise archiving fails due to no access)
  - this tests if a certain WAL file (file specified by `%f`) exists in the archived directory and if not, copies it from its actual path (`%p`)
  - this command must return a 0 exit status so that Postgres knows to recycle the actual WAL file
  - we would essentially start archiving these in the primary server and then copy it over to secondary server to restore along with a base backup 
  - we must take a new base backup after setting up WAL archiving to make sure no WALs were deleted in the middle
- We go into `postgresql.conf` in data directory, modify the settings as specified above, and restart the container
- Now, archiving only happens once the WAL segment is completed, which may not happen often in a local container DB
  - to force archive, we can set `archive_timeout` to 300 (seconds is the unit => 5 minutes)
  - this will bloat the archive storage since even these WAL files are as big as the usual WAL files
  - maybe undo the timeout after test (set it back to 0 to disable it) or set `archive_mode = off`
  - alternatively, we can also use `select pg_switch_wal();` to force-switch WAL files regardless of timeout
- Postgres seems to create multiple WAL files ahead of time
  - at the end of the `archive_timeout`, it checks if there have been any updates to the DB
  - if not, no WAL files are archived
  - if yes, then that particular WAL file is archived and Postgres switches to one of the newly created ones
  - once archived, eventually Postgres cleans up the WAL files already archived
  - it also tends to archive the current WAL file when the container is shut down (though we shouldn't depend on this)
  - it also goes ahead and creates even newer ones, to use once these get switched out too
- We can check when something went wrong with archiving in the `pg_stat_archiver` (though it doesn't specify why it failed)

#### PITR in same server

- Take full backup of postgresdb1 in postgresdb2 and then dont touch postgresdb2
  - in fact shut down postgresdb2 to avoid confusion
- Then we take full backup of postgresdb1 in postgresdb1 at `11:57:03`
  - latest archived WAL is `000000010000000000000034`
- Now we make the changes in the base backup as required
  - including setting the `restore_command = 'cp /var/lib/postgresql/data/archived_wals/%f %p'`
- Then we make a few updates from Iron to Iron4 while switching WAL as we go
  - Iron -> Iron2 at `11:59:57` with WAL `000000010000000000000035`
  - Iron2 -> Iron3 at `12:00:58` with WAL `000000010000000000000036`
  - Iron3 -> Iron4 at `12:01:49` with WAL `000000010000000000000037`
- Then we rename the backup dir as pgdata and restart the container
  - final archived wal was `00000002000000000000003F`
  - we see that recovery was successful and all updates till Iron4 exist even though they weren't there at time of basebackup
- Implying, that archived WALs can only be used on the same database system and not on another server due to mismatch in database identifier
- Try removing the latest 2 WAL files and see if only updates till Iron3 are recovered
  - Won't be possible as the latest WAL file will get added in on restart
- We can set the `recovery_target_time = '2025-01-05 12:00:30+00'` in `postgresql.conf` to recover upto that time (set the actual time, here is a format example only)
  - this only shows updates till Iron2

#### PITR in different server

- Check how to change the database identifier so that you can backup/recover to different server
  - we can check the database cluster identifier by `select system_identifier from pg_control_system();`
  - seems after backup load, both clusters have same identifier so maybe:
    - we keep two copies of the backup (one with updates to conf and recovery.signal file and one without)
    - with one backup, we actually initialize the current container without setting restore_command etc
    - with second backup, we use the archived WAL files and at this point, we expect the DB identifiers to be same and hence work
- Let's write the trials here again
  - we want to backup `postgresdb` into `postgresdb2` (current value = Iron)
    - `postgresdb` id = `7405980916258975775`, `postgresdb2` id = `7456639771534237727`
  - first, we enable archiving mode on `postgresdb` and then take a base backup from inside `postgresdb2`
    - latest archived WAL after backup is `000000010000000000000036` at `03:31:10`
  - now we re-initialize `postgresdb2` with this base-backup but we also keep another copy of this to use with the archived_wals
    - we don't do anything else at this point (no permission changes, no change in configuration files in either backup etc)
      - we see that now database cluster ids match
    - we restart after setting postgresdb2 archive_mode off and verify that ids still match
  - now, we want to start updating and creating new archived WALs
    - Iron -> Iron2  in `000000010000000000000037` at `03:38:49`
    - Iron2 -> Iron3  in `000000010000000000000038` at `03:39:45`
    - Iron3 -> Iron4  in `000000010000000000000039` at `03:40:11`
  - now, let's copy over these archived WAL files over to postgresdb2 and set it up with the older backup copy
    - we do all changes in basebackup and also make sure to change permissions of `archived_wals` in addition to backup directory
  - then we restart `postgresdb2` and this time we can see all changes from archived WAL files have been restored correctly
  - we will remove the old directories, archived directory and comment the restore command, then restart again
    - we can see that it still works and this completes  PITR to backup server (just needed one extra initialization with the backup)

---

### Additional details

- We can find find all recovery target options (defining till what point to recover) in the `postgresql.conf`
  - date/time (done above)
  - named restore point
  - transaction id
  - WAL name
- Postgres also has the concept of timelines in terms of backup/recovery
  - When an archive recovery completes, a timeline is created to identify the WALs generated post-recovery
    - every recovery generates a `timelineId.history` file in the `pg_wal` directory
  - This timeline id (in hexadecimal) is the first part of the WAL file
  - It is possible to archive many different timelines and it is useful in the following use case
    - when we don't know exactly till what point we need to recover to
    - we can keep multiple `.history` files and by default, postgres picks the latest one
    - but we can specify the exact one to pick by setting the `recovery_target_timeline` in conf
  - We haven't tried this yet as it seems fairly involved so we will check this if it comes up
- We can configure `standalone hot standby` servers which can continually get the WAL files from primary
  - this allows read queries on the standby, even during recovery
  - we will check these out in `High availability, failover & replication` section
- We use scripts for archiving/recovery, we may want to track errors
  - for this we can check https://www.postgresql.org/docs/16/runtime-config-logging.html#GUC-LOGGING-COLLECTOR
  - we can set a way to store these logs in a specified location for debugging purposes (requires conf updates)
  - we are skipping this now and will come back to it if required
- Couple of caveats to be aware of
  - it is recommended not to modify template databases during base backups
  - it is recommended to take basebackups directly after creating/dropping tablespaces with specific paths
    - because when recovering to a new machine or directory, the recovery overwrites the data in the tablespace which maybe unintended

---
