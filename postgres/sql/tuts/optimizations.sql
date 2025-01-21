---------------------------- TEMP TABLES ----------------------------

-- create temp table
create temp table my_temp_table as (
	select 1 id, 'Iron' name
	union
	select 2 id, 'Scar' name
);

-- doesn't exist if we switch over to a different connection and come back
select* from my_temp_table;

------------------------------ VACUUM --------------------------------

vacuum verbose analyze;

show autovacuum;

------------------------ PERFORMANCE TIPS -----------------------------

-- return number of disk pages in the specific table and its record count (only select)
-- explain gives the query plan
-- analyze gives the actual planning and execution time as well
-- buffers specifies how I/O intensive is the operation
explain (analyze, buffers) select relpages, reltuples from pg_class where relname = 'index_trial_tasks';
