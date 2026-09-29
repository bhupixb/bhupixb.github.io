# Reproduce the SERIALIZABLE experiments

These scripts use:

```sh
psql -X -d exp -U ybcloud
```

The published test used PostgreSQL 17.11. The benchmark client was pgbench 18.4.

## Two-session failure

Prepare the 100-row table:

```sh
psql -X -d exp -U ybcloud -f setup.sql
```

Start Session 1:

```sh
psql -X -d exp -U ybcloud -f session-1.sql
```

Start Session 2 about one second later:

```sh
psql -X -d exp -U ybcloud -f session-2.sql
```

Run `inspect.sql` from a third session while the transactions sleep. Session 1
commits. Session 2 fails at COMMIT with SQLSTATE `40001`.

## Benchmark

The benchmark uses 10,000 rows and eight clients. Each client updates a distinct
`external_id`.

```sh
./benchmark.sh
```

The script runs three no-index tests, three indexed tests, and one no-index test
with up to ten attempts. It writes the raw pgbench output and plans to
`benchmark-results/`.

## Terminal recording

The recording script needs tmux and asciinema:

```sh
asciinema rec \
  --overwrite \
  --cols 120 \
  --rows 24 \
  --idle-time-limit 2 \
  --command ./record-terminal.sh \
  postgres-serializable-failure.cast
```
