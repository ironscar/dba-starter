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
- Docker image: https://hub.docker.com/r/yugabytedb/yugabyte (2024.2 is LTS version)
- Provides ACID compliance cluster-wide
- YugabyteDB storage engine is LSM (Log Structured Merge) based
  - LSM is optimized for high write throughput which batches writes and merges them into sorted files on disk

## Running a 1-node cluster

- `docker run -d --name yugabyte1 -p 7000:7000 -p 9000:9000 -p 15433:15433 -p 5435:5433 -p 9042:9042 yugabytedb/yugabyte:2024.2.6.1-b2 bin/yugabyted start --background=false`
  - `yugabyted` is an executable packaged in the image in the `bin` directory and `start` on that runs it
  - starting this on port `5435` as the postgres containers already use `5432` to `5434`
- `docker exec -it yugabyte1 yugabyted status` to check status of the database
  - this particular docker image is based on `AlmaLinux` (based on CentOS) and has `bash` installed
    - we can check this by `cat /etc/os-release`
  - does not have `clear` installed so use `Ctrl+L` to just scroll the terminal down while preserving the previous content
  - current volumes are created in `/tmp/docker-desktop-root/run/desktop/mnt/docker-desktop-disk/data/docker/volumes`
- `http://localhost:15433/` has the Yugabyte UI

Continue from https://docs.yugabyte.com/stable/quick-start/docker/#run-docker-in-a-persistent-volume
