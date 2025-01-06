select* from student;

update student set first_name = 'Iron4';

-- to switch to next WAL file
select pg_switch_wal();

-- to check system identifier
-- pg1 = 7405980916258975775
-- pg2 = 7456639771534237727
select system_identifier from pg_control_system();
