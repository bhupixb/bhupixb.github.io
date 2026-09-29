\set ON_ERROR_STOP on

DROP TABLE IF EXISTS serializable_accounts;

CREATE TABLE serializable_accounts (
    id INT PRIMARY KEY,
    external_id INT NOT NULL,
    name TEXT NOT NULL,
    balance INT NOT NULL
);

INSERT INTO serializable_accounts(id, external_id, name, balance)
SELECT i, 10000 + i, 'user-' || i, 1000
FROM generate_series(1, 100) AS g(i);

ANALYZE serializable_accounts;
