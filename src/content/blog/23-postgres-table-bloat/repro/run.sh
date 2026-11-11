#!/usr/bin/env bash
# Full repro on Postgres 13. Needs Docker (Colima works) and ~40 GB free disk.
# Scale with N_OLD / N_PRE / N_POST. Defaults leave ~900k live rows in a ~7x bloated table.
set -euo pipefail; cd "$(dirname "$0")"; . ./lib.sh
N_OLD=${N_OLD:-5880000} N_PRE=${N_PRE:-600000} N_POST=${N_POST:-300000}

docker build -q -t pg13-repack .
docker rm -f "$C" >/dev/null 2>&1 || true
docker run -d --name "$C" --shm-size=1g -e POSTGRES_PASSWORD=postgres -v "$PWD":/repro -w /repro pg13-repack >/dev/null
until docker exec "$C" pg_isready -U postgres -q; do sleep 0.5; done; sleep 2

echo "### load"
psqlc postgres -c 'CREATE DATABASE bloat'
psqlc bloat -q -v ON_ERROR_STOP=1 -f 01_schema.sql
psqlc bloat -v ON_ERROR_STOP=1 -v n_old="$N_OLD" -v n_pre="$N_PRE" -v n_post="$N_POST" -f 02_load.sql 2>&1 | grep -v NOTICE

echo "### bloated table"
psqlc bloat -c 'DROP TABLE audit_event_archive'   # not needed any more; saves disk
psqlc bloat -f 03_sizes.sql -f 04_pgstattuple.sql

# Byte-for-byte copies of the bloated table, so each fix starts from the same state.
psqlc postgres -c 'CREATE DATABASE bloat_vf TEMPLATE bloat' -c 'CREATE DATABASE bloat_repack TEMPLATE bloat'

./05_constraint.sh bloat
./06_vacuum_full_vs_repack.sh
psqlc bloat_vf -f 04_pgstattuple.sql
./05_constraint.sh bloat_vf

echo "### json vs jsonb"
psqlc bloat_vf -f 07_json_vs_jsonb.sql
