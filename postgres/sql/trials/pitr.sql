select* from student;

update student set first_name = 'Iron4';

-- to switch to next WAL file
select pg_switch_wal();
