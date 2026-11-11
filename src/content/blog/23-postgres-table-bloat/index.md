---
title: "VACUUM FULL took our audit table from 7.7 GB to 1 GB"
summary: "A table with 900k rows was using 7.7 GB on disk. It had no dead tuples. VACUUM FULL shrank it 7x. The likely cause was a one-time DELETE from long ago."
date: "November 10 2026"
draft: true
tags:

- PostgreSQL

---

We have an `audit_event` table in Postgres. It records who did what: user, account, a message, and a small JSON blob with details. Rows are only inserted, never updated.

While looking at a slow migration on this table, I checked its size. It was much bigger than it should be.

### 900k rows, 7.7 GB

| | total | table | indexes | rows | bytes per row |
|---|---|---|---|---|---|
| dev environment | 7,687 MB | 7,283 MB | 397 MB | 904k | ~8,900 |

Close to 9 KB per row, for rows that hold a few IDs, a short message and some JSON. That did not look right.

To compare, I restored a dump of the same data into a fresh database:

| | total | table | indexes | rows | bytes per row |
|---|---|---|---|---|---|
| dev environment | 7,687 MB | 7,283 MB | 397 MB | 904k | ~8,900 |
| same data, restored from a dump | 1,026 MB | 955 MB | 67 MB | 904k | ~1,190 |

Same rows, 7x less space. So about 6.6 GB of the live table was not data.

### Dead tuples? No

The usual reason for a big table is dead tuples. When you update or delete a row, Postgres does not remove it right away. The old version stays on disk as a dead tuple until VACUUM cleans it up.

```sql
SELECT n_live_tup, n_dead_tup, last_autovacuum
FROM pg_stat_user_tables
WHERE relname = 'audit_event';
```

```text
 n_live_tup | n_dead_tup |        last_autovacuum
------------+------------+-------------------------------
    1250000 |          0 | ...
```

Zero dead tuples. The table is insert-only, so this made sense. But then what was using the space?

### VACUUM FULL

`VACUUM FULL` writes a new copy of the table with only the live rows, then drops the old files. I ran it in the dev environment:

```sql
VACUUM FULL audit_event;
-- took 2 min 37 s
```

| | total | table | indexes | bytes per row |
|---|---|---|---|---|
| before | 7,687 MB | 7,283 MB | 397 MB | ~8,900 |
| after VACUUM FULL | 1,061 MB | 989 MB | 67 MB | ~1,230 |

7.2x smaller. 6.6 GB back, about 86% of the table.

### Why: empty space is not dead tuples

Plain `VACUUM` (and autovacuum) does not give space back to the operating system. It marks the space inside each 8 KB page as free, so that future inserts can use it. The file stays the same size. (It can only cut off empty pages at the very end of the file.)

So a table can have zero dead tuples and still be mostly empty space. `n_dead_tup` counts dead rows that VACUUM has not cleaned yet. It says nothing about free space that VACUUM already cleaned.

Where did that much free space come from? Long ago, a one-time migration moved audit rows older than 18 months into an archive table, and then ran:

```sql
DELETE FROM audit_event WHERE created_on <= now() - interval '18 months';
```

That deleted most of the table. Autovacuum then marked all of it as free. New audit rows went into those holes, but we insert far fewer rows than that delete removed. So the file kept its old size, and was mostly empty.

I can't prove that this is exactly what happened in our environment. But it fits everything we saw, so I tested it.

### Reproducing it

On Postgres 13 (the version we were on) in Docker, I made the same table and:

1. inserted 6.48M rows with realistic sizes (about 1.2 KB per row, some JSON large enough to go to TOAST),
2. deleted the 5.88M "old" ones, then ran VACUUM,
3. inserted 300k more rows.

The size never moved: 7,819 MB before the delete, 7,819 MB after VACUUM, 7,821 MB after the new inserts. The new rows simply filled some of the holes.

`pgstattuple` shows where the space went:

```sql
CREATE EXTENSION pgstattuple;
SELECT * FROM pgstattuple('audit_event');
```

| part | size | live data | dead tuples | free space |
|---|---|---|---|---|
| heap | 4,944 MB | 13% | 0% | 86% |
| TOAST | 2,525 MB | 13% | 0% | 87% |

(TOAST is where Postgres keeps large values, like big JSON documents, outside the main table. It bloats the same way.)

| | total | bytes per row |
|---|---|---|
| repro, bloated | 7,821 MB | ~9,200 |
| repro, after VACUUM FULL | 1,096 MB | ~1,280 |
| dev environment, bloated | 7,687 MB | ~8,900 |
| dev environment, after VACUUM FULL | 1,061 MB | ~1,230 |

The repro lands within a few percent of the real numbers. The scripts are in the [repro folder](https://github.com/bhupixb/bhupixb.github.io/tree/main/src/content/blog/23-postgres-table-bloat/repro) if you want to try it.

### Before you run VACUUM FULL in production

`VACUUM FULL` takes an `ACCESS EXCLUSIVE` lock. Nothing can read or write the table until it finishes. In the repro it blocked every query for 55 seconds.

[pg_repack](https://github.com/reorg/pg_repack) does the same rewrite online. It needs a primary key, and enough free disk for a second copy of the table. It only locks the table briefly at the start and at the end. In the repro it finished in 20 seconds, and every read and insert I ran during it succeeded.

Also, bloat is not always a problem. If you will insert that much data again soon, Postgres will reuse the free space. It matters when the space will never be reused, or when something has to read the whole table. A full scan reads every page, empty or not.

### What I would do differently

- **Check bloat after a big DELETE.** A one-time cleanup that removes most of a table should be followed by `VACUUM FULL` or `pg_repack`.
- **For tables that only grow, plan the purge.** Partitioning by time lets you drop old data with `DROP TABLE` on a partition. That removes the files, so there is no bloat at all.
- **Watch the bytes per row.** If it is far bigger than what a row should hold, look closer.

### Queries to check your own tables

Size and bytes per row:

```sql
SELECT pg_size_pretty(pg_total_relation_size(c.oid))      AS total,
       pg_size_pretty(pg_relation_size(c.oid))            AS heap,
       pg_size_pretty(pg_relation_size(c.reltoastrelid))  AS toast,
       pg_size_pretty(pg_indexes_size(c.oid))             AS indexes,
       c.reltuples::bigint                                AS est_rows,
       (pg_total_relation_size(c.oid) / greatest(c.reltuples, 1))::bigint AS bytes_per_row
FROM pg_class c
WHERE c.relname = 'audit_event';
```

Free space, without reading every row (`pgstattuple_approx` skips pages that the visibility map says are all-visible):

```sql
SELECT pg_size_pretty(table_len)       AS size,
       round(approx_free_percent::numeric, 1) AS free_pct,
       round(dead_tuple_percent::numeric, 1)  AS dead_pct
FROM pgstattuple_approx('audit_event');
```

Exact free space for the heap and the TOAST table (reads the whole table, so run it off-peak):

```sql
SELECT 'heap' AS part, * FROM pgstattuple('audit_event')
UNION ALL
SELECT 'toast', * FROM pgstattuple(
  (SELECT reltoastrelid FROM pg_class WHERE relname = 'audit_event')::regclass);
```

Dead tuples and last vacuum:

```sql
SELECT relname, n_live_tup, n_dead_tup, last_vacuum, last_autovacuum
FROM pg_stat_user_tables
ORDER BY n_dead_tup DESC;
```
