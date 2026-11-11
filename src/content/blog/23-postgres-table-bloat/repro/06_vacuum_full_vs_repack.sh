#!/usr/bin/env bash
# Shrink two identical clones of the bloated table: VACUUM FULL vs pg_repack.
# Shows sizes, time, and whether other sessions can read/write meanwhile.
set -euo pipefail; cd "$(dirname "$0")"; . ./lib.sh

echo "### VACUUM FULL on bloat_vf (cold cache)"
cold
psqlc bloat_vf -f 03_sizes.sql
docker exec -e PGAPPNAME=vf "$C" psql -U postgres -d bloat_vf -X -c '\timing on' -c 'VACUUM FULL audit_event' > "$T"/vf.out 2>&1 &
show_lock bloat_vf vf
echo "  other sessions while it runs:"; probe bloat_vf
wait; sed 's/^/  /' "$T"/vf.out
psqlc bloat_vf -f 03_sizes.sql

echo "### pg_repack on bloat_repack (cold cache)"
cold
psqlc bloat_repack -f 03_sizes.sql
start=$(date +%s)
docker exec "$C" pg_repack -U postgres -d bloat_repack -t audit_event > "$T"/rp.out 2>&1 &
RP=$!
ok=0; fail=0
while kill -0 $RP 2>/dev/null; do
  if probe bloat_repack | grep -q 'ERROR'; then fail=$((fail+1)); else ok=$((ok+1)); fi
  sleep 0.5
done
wait $RP; echo "  pg_repack took $(( $(date +%s) - start ))s"; sed 's/^/  /' "$T"/rp.out
echo "  probes during repack (SELECT + INSERT, 1s lock_timeout): ok=$ok failed=$fail"
psqlc bloat_repack -f 03_sizes.sql
