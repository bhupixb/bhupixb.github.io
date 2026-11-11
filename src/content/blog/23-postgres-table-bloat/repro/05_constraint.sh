#!/usr/bin/env bash
# Time ADD CONSTRAINT ... CHECK (cold cache) and show which lock it takes.
# Then do the safe way: NOT VALID, then VALIDATE. Usage: ./05_constraint.sh <db>
set -euo pipefail; cd "$(dirname "$0")"; . ./lib.sh
DB=${1:-bloat}
CK="CHECK (account_id IS NOT NULL OR org_id IS NOT NULL)"
drop() { psqlc "$DB" -q -c "ALTER TABLE audit_event DROP CONSTRAINT IF EXISTS ck_audit_event_account_or_org_not_null"; }
drop

echo "### [$DB] 1. plain ADD CONSTRAINT (validates every row), cold cache"
cold
docker exec -e PGAPPNAME=ddl "$C" psql -U postgres -d "$DB" -X -c '\timing on' \
  -c "ALTER TABLE audit_event ADD CONSTRAINT ck_audit_event_account_or_org_not_null $CK" > "$T"/ddl.out 2>&1 &
show_lock "$DB" ddl
echo "  wait event of the ALTER while it runs:"
psqlc "$DB" -At -c "SELECT '  ' || state || ' / ' || coalesce(wait_event_type,'-') || ' / ' || coalesce(wait_event,'-')
                    FROM pg_stat_activity WHERE application_name = 'ddl'"
echo "  other sessions while it runs:"; probe "$DB"
wait; sed 's/^/  /' "$T"/ddl.out
drop

echo "### [$DB] 2. ADD CONSTRAINT ... NOT VALID, cold cache"
cold
psqlc "$DB" -c '\timing on' -c "BEGIN" \
  -c "ALTER TABLE audit_event ADD CONSTRAINT ck_audit_event_account_or_org_not_null $CK NOT VALID" \
  -c "SELECT mode FROM pg_locks WHERE pid = pg_backend_pid() AND relation = 'audit_event'::regclass" \
  -c "COMMIT" | sed 's/^/  /'

echo "### [$DB] 3. VALIDATE CONSTRAINT (still scans every row), cold cache"
cold
docker exec -e PGAPPNAME=validate "$C" psql -U postgres -d "$DB" -X -c '\timing on' \
  -c "ALTER TABLE audit_event VALIDATE CONSTRAINT ck_audit_event_account_or_org_not_null" > "$T"/val.out 2>&1 &
show_lock "$DB" validate
echo "  other sessions while it runs:"; probe "$DB"
wait; sed 's/^/  /' "$T"/val.out
drop
