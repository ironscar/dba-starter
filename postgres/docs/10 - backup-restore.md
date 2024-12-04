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

- [TODOS]
  - Continue from https://www.postgresql.org/docs/current/app-pgbasebackup.html and https://www.cybertec-postgresql.com/en/pg_basebackup-creating-self-sufficient-backups/
  - Full backup with base backup
  - Incremental backup with base backup & combine backup
  - PITR
  - Streaming replication standby

---
