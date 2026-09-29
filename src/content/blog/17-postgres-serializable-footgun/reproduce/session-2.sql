\pset pager off
\timing on
SET application_name = 'serializable_demo_2';
BEGIN ISOLATION LEVEL SERIALIZABLE;
SET LOCAL enable_indexscan = off;
SET LOCAL enable_bitmapscan = off;
SELECT count(*), sum(balance) FROM serializable_accounts;
SELECT pg_sleep(2.5);
UPDATE serializable_accounts SET balance = balance + 20 WHERE id = 2;
SELECT pg_sleep(3);
COMMIT;
