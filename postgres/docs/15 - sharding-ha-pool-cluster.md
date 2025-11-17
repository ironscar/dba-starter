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
