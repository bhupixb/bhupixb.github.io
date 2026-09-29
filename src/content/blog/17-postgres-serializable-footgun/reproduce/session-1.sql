\pset pager off
\timing on
SET application_name = 'name_demo_1';
BEGIN ISOLATION LEVEL SERIALIZABLE;
EXPLAIN (COSTS OFF) SELECT * FROM accounts WHERE name = 'user-1';
SELECT * FROM accounts WHERE name = 'user-1';
SELECT pg_sleep(2);
UPDATE accounts SET balance = 111 WHERE id = 1;
SELECT pg_sleep(3);
COMMIT;
