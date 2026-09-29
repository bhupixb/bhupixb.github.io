\pset pager off
\timing on
SET application_name = 'name_demo_2';
BEGIN ISOLATION LEVEL SERIALIZABLE;
SELECT * FROM accounts WHERE name = 'user-2';
SELECT pg_sleep(2.5);
UPDATE accounts SET balance = 123 WHERE id = 2;
SELECT pg_sleep(3);
COMMIT;
\echo SQLSTATE: :SQLSTATE
