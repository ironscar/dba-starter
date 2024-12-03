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

## Restore

- Postgres comes with the `pg_restore` tool to restore from a backup file created by `pg_dump` or `pg_dumpall`
- It runs like `pg_restore [connection-option] [option] [filename]` and takes following flags:
  - `-U` username
  - `-h` hostname
  - `-p` port
  - `-d` dbname
  - `-t` table
  - `-j` number of parallel jobs to use when restoring
  - `-L` specifies a file with list of files that you want to restore from (if you have multiple files)
- There are other flags mentioned at https://neon.tech/postgresql/postgresql-administration/postgresql-restore-database

- We will test this by creating a new DB container and then using pg_restore on top of that
  - we will do this once with just `student_tracker_backup.sql`
  - then we will delete this container
  - and we repeat with `all_databases_backup.sql`

---
