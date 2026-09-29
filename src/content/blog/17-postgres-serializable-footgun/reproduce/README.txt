# Reproduce the SERIALIZABLE experiments

Connection: psql -X -d exp -U ybcloud
Tested server: PostgreSQL 17.11. Benchmark client: pgbench 18.4.

## Different names, different rows

In a fresh test database, run:

    psql -X -d exp -U ybcloud -f setup.sql

This creates accounts with 100 rows, a primary key on id, and no index on name.
The first two balances are 1100 and 321. Setup refuses to replace an existing
accounts table. If reusing the test table, check its schema and plans first.

Start Session 1, then Session 2 about one second later:

    psql -X -d exp -U ybcloud -f session-1.sql
    psql -X -d exp -U ybcloud -f session-2.sql

Both sessions SELECT by different names, then UPDATE their own rows by id.
Both SELECTs must finish before either UPDATE. Both UPDATEs run before the
first COMMIT. Session 1 commits first; Session 2 fails at COMMIT with 40001.
Run inspect.sql from a third session while the transactions sleep.
For manual timing, omit pg_sleep and follow the same statement order.

## Benchmark

The separate benchmark still uses serializable_accounts, 10,000 rows, and
external_id lookups. Run ./benchmark.sh for the original measured comparison.
The article's name-filtered demonstration does not change those saved results.

## Terminal recording

record-terminal.sh needs tmux and asciinema. It resets balances for accounts
IDs 1 and 2 to 1100 and 321, then runs the two transactions above. It leaves
row 1 at 111 and row 2 at 321 after Session 2 fails. Run it on a test database.

    asciinema rec --overwrite --command ./record-terminal.sh original-terminal.cast

original-terminal.cast preserves the real name-filtered database capture.
The article embeds an edited replay in a 110-column, 15-row layout. To
regenerate that presentation from the recorded SQL/results:

    python3 format-recording.py

The formatter does not execute SQL. It lays out the observed statements and
results explicitly; rerun and check the real capture when changing the example.
