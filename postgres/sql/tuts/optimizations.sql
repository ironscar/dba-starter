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

analyze verbose;
vacuum;
