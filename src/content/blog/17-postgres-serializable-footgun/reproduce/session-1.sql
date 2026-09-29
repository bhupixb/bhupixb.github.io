\pset pager off
\timing on
SET application_name = 'serializable_demo_1';
BEGIN ISOLATION LEVEL SERIALIZABLE;
SET LOCAL enable_indexscan = off;
SET LOCAL enable_bitmapscan = off;
EXPLAIN (COSTS OFF) SELECT * FROM serializable_accounts;
SELECT count(*), sum(balance) FROM serializable_accounts;
SELECT pg_sleep(2);
UPDATE serializable_accounts SET balance = balance + 10 WHERE id = 1;
SELECT pg_sleep(3);
COMMIT;
