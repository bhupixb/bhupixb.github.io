\set ON_ERROR_STOP on
-- Use a fresh test database. This intentionally does not drop an existing table.
CREATE TABLE accounts (
    id INT PRIMARY KEY,
    name TEXT NOT NULL,
    balance INT NOT NULL
);
INSERT INTO accounts(id, name, balance)
SELECT i, 'user-' || i,
       CASE i WHEN 1 THEN 1100 WHEN 2 THEN 321 ELSE 1000 END
FROM generate_series(1, 100) AS g(i);
ANALYZE accounts;
