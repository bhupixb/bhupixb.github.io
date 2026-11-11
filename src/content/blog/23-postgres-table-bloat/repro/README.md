# Repro: a 900k-row table that takes 7.8 GB

Reproduces table bloat after a large one-time DELETE on Postgres 13, then measures
what `ADD CONSTRAINT ... CHECK`, `NOT VALID` + `VALIDATE`, `VACUUM FULL` and `pg_repack` do to it.

Needs Docker (Colima works), about 40 GB of free disk, and about 10 minutes.

```bash
./run.sh
```

Smaller run: `N_OLD=600000 N_PRE=60000 N_POST=30000 ./run.sh`

| file | what it does |
|---|---|
| `Dockerfile` | `postgres:13` plus `pg_repack` |
| `01_schema.sql` | the table, `pgstattuple` and `pg_repack` extensions |
| `02_load.sql` | 5.88M old rows + 600k recent, archive + DELETE the old ones, VACUUM, then 300k more |
| `03_sizes.sql` | heap / TOAST / index size, rows, bytes per row |
| `04_pgstattuple.sql` | live vs dead vs free space, for heap and TOAST |
| `05_constraint.sh` | cold-cache timing and locks: plain CHECK, `NOT VALID`, `VALIDATE` |
| `06_vacuum_full_vs_repack.sh` | both fixes on byte-identical copies, with read/write probes |
| `07_json_vs_jsonb.sql` | same documents stored as `json` and `jsonb` |
| `results-pg13.txt` | output of one full run |

"Cold cache" means Postgres is restarted and the VM page cache is dropped before the statement,
so the scan reads from disk. The local NVMe disk is far faster than a cloud volume,
so compare the ratios, not the absolute times.

Clean up: `docker rm -f bloat-pg13 && docker volume prune`
