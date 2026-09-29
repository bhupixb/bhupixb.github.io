\set target_external_id 10001 + :client_id

BEGIN ISOLATION LEVEL SERIALIZABLE;

SELECT balance AS old_balance
FROM serializable_accounts
WHERE external_id = :target_external_id
\gset

UPDATE serializable_accounts
SET balance = :old_balance + 1
WHERE external_id = :target_external_id;

COMMIT;
