# Database Performance at Scale

This markdown contains the notes from the book of the same name

## CHAPTER 1

- Always work on official drivers as unofficial ones may have bugs which you may not really be thinking about
- Client-side timeouts must be greater than server-side timeouts to avoid overpowering server with retries even though server may still be processing the older request but the client just considers them done
- Client shouldn't do retries unless the original request fails with a high guarantee, else server overload is again possible same as above
- Backups are super-important and must always be setup
- Backups must be scheduled during times when system is known to have less load so that it doesn't contend with actual requests
- Spikes must be planned for
- CAP theorum must be taken into account for your specific use case when selecting a database

## CHAPTER 2

- SQL uses B-trees for storing data which is slower at writing data than LSM based DBs like Cassandra and ScyllaDB
  - LSM based DBs are good for write-heavy workloads but take more space (until compaction runs) and may slow down reads too
  - Depending on your use case being either write-heavy or read-heavy, may want to choose a DB accordingly
  - Disk performance also matters as the disk may not be able to keep up even if the actual software is fast enough
  - Pricing models also matter as write-optimized DBs generally tend to cost more than read-optimized ones
  - Need to choose one which satisifies the present and stays relevant for the future too
- Some databases tend to keep recently queried data in memory which will benefit from higher RAM if recent data is queried often
  - other data has to be read from disk which benefit from systems with good disk I/O
- For delete-heavy workloads, LSM based DBs don't work well and can adversely affect read performance
- For large objects storage in GBs, prefer storing them in object storage solutions and use the actual DB as an address lookup
- Little's law specifies that `No: of DB requests (concurrency) = DB throughput * latency`
- It's important to have monitoring on internal data processes as well
- ACID transactions add to read/write overhead leading to infrastructure overhead

## CHAPTER 3

- This chapter discusses hadware considerations
- CPU
  - multicore with minimal resource sharing is better
- Memory/RAM
  - memory allocation & cache control
- I/O & Disk
  - types of read/write operations
  - read/write operations and throughput determine disk quality
- Network
  - DPDK & IRQ binding
- Most of this seems fairly low-level and not directly relevant yet but maybe relevant down the line

## CHAPTER 4

- This chapter discusses algorithmic optimizations used in DBs
- It mostly discusses B-trees and related details
- Knowing the tradeoffs of the underlying data structures of the DB can help in optimizing your workloads for it

## CHAPTER 5

- This chapter discusses database drivers

---

## CHAPTER 6

- This chapter discusses about how getting data closer can be beneficial to applications
- Databases can have (in growing order of flexibility): 
  - user-defined functions and aggregates
  - custom scripting language for the specific database
  - support one/more general-purpose language (WebAssembly included here as well)
    - Cassandra allows adding native functions in Java/Javascript
- Considerations for user-defined functions:
  - it needs to be a conscious decision to turn on JIT or not
  - evaluate if they are needed at all if all the computation can be done in services
  - test if CPU/memory utilization scales
- User-defnied aggregates can be useful if:
  - it is functionality not already built-in
  - amount of data required for the computations are huge to transfer from DB to services and much larger than the result
  - for user-defined aggregates, we need:
    - an initial set of values to start from
    - a necessary state-transition function to compute new state of values for each row
    - an optional final function to produce result from the final state of the initial set of values
    - a possible reduce function to combine results from multiple partial aggregate functions
      - this can be useful to distribute the corresponding partial computations in concurrent servers
  - ScyllaDB allows this distributed reduction functionality
  - some databases also allow configuring storing user aggregate function results in cache somewhere
- Web assembly (WASM) for user defined functions
  - WASM is a binary format for representing executable code designed to be embeddable into other projects
- Conflict-free replicated data types support the following characteristics:
  - users can update database replicas independently without coordinating with other database servers
  - an algorithm automatically resolve conflicts when data is written independently to replicas
  - replicas are allowed to be in different states but they are guaranteed to eventually converge to a common state
  - examples are G-counter, PN-counter, G-set/map, LWW-set/map

---

## Chapter 7

- This chapter discusses infrastructure and deployment models

---
