# DB Administration: Managing tablespaces

## Introduction & Creation

- Use `pg_tablespace` to see current tablepaces
  - by default there is `pg_default` (stores user data) and `pg_global` (stores global data)
- Tablespaces control the disk layout for the database
- To create, we use `CREATE TABLESPACE <tablespace1> OWNER <user> LOCATION <directory_path>`
  - name should not start with `pg_` as those are reserved for system tablespaces
  - the directory path must exist before we run this and should not be inside the data directory
    - data directory on Alpine docker image is `/var/lib/postgresql/data/pgdata`
  - we can provide the directory path to specify what tables use what disk
  - this allows optimizing heavier operations on SSDs and lighter operations on HDDs etc
- Now the Alpine docker image by default, didn't allow postgres to access directories outside data dir
  - Default user is `root` when we log into the container
  - So, we can manually go to `/var/lib/postgresql/data` and create a `custom_data_dir`
  - Then, make postgres its owner by `chown postgres custom_data_dir`
- After that, we can run the create tablespace command to successfully create it
- Then we can create databases or tables or partitions in that new tablespace

## Alter commands

- `ALTER TABLESPACE <tablespace_name> RENAME TO <new_name>` to rename
- `ALTER TABLESPACE <tablespace_name> OWNER TO <new_owner>` to change owner
- `ALTER TABLESPACE <tablespace_name> SET <parameter> = <value>` to set a param for that tablespace
- Alter commands can only be run by superuser or owner of tablespace

## Drop tablespace

- `DROP TABLESPACE <name>` to drop it
- If it has data in it, we need to use `ALTER ... SET TABLESPACE <tablespace_name>`

## Containerization Strategy

- We can mount different disks on the machine (SSD/HDD)
- Then we can bind specific directories on host machine to those disks
- When we create the container, we already map a volume for the actual data (which can be on HDD)
- In addition, we can also mount another volume at a predefined directory for the SSD
  - then give that directory access to `postgres` user inside container
- Creating the tablespace in this new directory would then start using the SSD
- Ideally, we want to create the tablespace in the `/var/lib/postgresql/data` directory parallel to `pgdata`

---
