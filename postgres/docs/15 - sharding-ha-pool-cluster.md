# Shading / Automatic HA / Connection pooling - Cluster

We have few choices here:

- `PgPool2` can handle connection pooling and automatic HA failover
  - not reconmmended to work with Citus so maybe harder to do
  - could consider implement manual sharding with foreign data wrappers but maybe harder than using Citus
- `HAProxy` for load balancing + `PgBouncer` for connection pooling + `Patroni` for automatic HA failover
  - https://medium.com/@nicola.vitaly/setting-up-high-availability-postgresql-cluster-using-patroni-pgbouncer-docker-consul-and-95c70445b1b1
  - requires 3 new technologies instead of 1 just because Citus recommends it
- `YugabyteDB` directly for an all-in-one distributed DB solution
  - Citus is not required here

So we will go ahead with YugabyteDB for following reasons:
- It is one solution for load balancing, connection pooling, sharding and automatic failover and recovery
  - more systems => more failure points

## Getting started with YugabyteDB

- Its a high-performance, cloud-native distributed PostgreSQL-compliant database mainly meant for OLTP
- Docker image: https://hub.docker.com/r/yugabytedb/yugabyte (2025.1.2.0-b110 is latest version)
  - this version introduces compatibility with PostgreSQL v15
- Provides ACID compliance cluster-wide
- YugabyteDB storage engine is LSM (Log Structured Merge) based
  - LSM is optimized for high write throughput which batches writes and merges them into sorted files on disk

## Running a 1-node cluster

`docker run -d --name ygbt1 --hostname ygbt1 -p 7000:7000 -p 9000:9000 -p 15433:15433 -p 5435:5433 -p 9042:9042 --mount source=ygbt1,target=/datadir/ygbt yugabytedb/yugabyte:2025.1.2.0-b110 bin/yugabyted start --base_dir=/datadir/ygbt --background=false`

- Run above command to create first container:
  - `yugabyted` is an executable packaged in the image in the `bin` directory and `start` on that runs it
  - starting this on port `5435` as the postgres containers already use `5432` to `5434`
  - to enable persistence via volume, add the `--base_dir` option to update where in the container is actually stores data
    - then we can add a volume `ygbt1` to this so that its actually persisted
    - current volumes are created in `/tmp/docker-desktop-root/run/desktop/mnt/docker-desktop-disk/data/docker/volumes` when done using `--mount`
    - but it still creates two additional volumes nonetheless whose details we can see from `docker inspect ygbt1` and scrolling to the volumes section
  - creating with hostname to avoid startup errors is recreating new container with same volume
  - `http://localhost:15433/` has the Yugabyte UI
- `docker exec -it ygbt1 yugabyted status --base_dir=/datadir/ygbt` to check status of the database
  - this particular docker image is based on `AlmaLinux` (based on CentOS) and has `bash` installed
    - we can check this by `cat /etc/os-release`
  - does not have `clear` installed so use `Ctrl+L` to just scroll the terminal down while preserving the previous content
- The cluster contains two processes:
  - `YB-Master` keeps track of metadata for tables, users, permissions etc
  - `TB-TServer` is responsible for the actual data updates and queries
- A `Yugabyte universe` is the highest logical grouping of a distributed database comprising of one or more clusters and their nodes
  - cluster includes a primary cluster for read/write and optional replica clusters

### SQL Features on Yugabyte

- Yugabyte YSQL reuses PostgreSQL query layer and supports most PostgreSQL features
- To run commands, we need to load up `YSQLSH` on the container and we can do this by `docker exec` into container and then running `ysqlsh -h ygbt1 -p 5433`
  - the `-h` is essentially the `$(hostname)` env variable

#### Create databases and tables

- To create a database, we use `create database mydb1;`
  - `\c mydb1`: logs in to the database `mydb1` as user `yugabyte`
  - `\l` shows the list of current databases  
  - a regular `create table` command creates table in `public` schema by default
    - the DB doesn't seem to show up on the UI for some reason though in Database view until the table is created
  - `\dt` shows the list of relations in the current database
  - `\d+` displays more details about the tables like persistence, access method and size
  - we can also run other SQL commands here (like inserts) and see the data etc
  - `\q` to quit from `ysqlsh`
- Doing all this in terminal is a little hard so let's connect `PgAdmin` to this
  - we register a new server called `yugabyte@ygbt1` as `user@server` notation like we have been using
    - hostname = localhost, port = 5435, db = mydb1, user = yugabyte, no password yet
  - then we can see it has the db and the table we created and running a select query returns results we inserted from terminal

#### Users basics

- YugabyteDB has a recommended superuser called `yugabyte` but for now this has now password
- We can use commands as per `7 - admin-roles` for creating users and managing privileges

#### Persistence

- Let us try persistence now after removing old container and pruning extra volumes created other than the one we mounted
  - thankfully pruning doesn't remove the mounted volume, only the extra ones created by the last container
  - it created two new volumes but does indeed have the data we created previously

#### Data types

Continue from https://docs.yugabyte.com/stable/explore/ysql-language-features/data-types/
