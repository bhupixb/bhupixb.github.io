# Helpers shared by the experiment scripts. Run from the host.
C=${C:-bloat-pg13}
T=$(mktemp -d)
psqlc() { local db=$1; shift; docker exec -i "$C" psql -U postgres -d "$db" -X "$@"; }

# Empty both caches: Postgres shared_buffers (restart) and the Linux page cache
# of the Colima/Docker VM. This makes the next scan read from disk, like prod.
cold() {
  docker restart "$C" >/dev/null
  docker run --rm --privileged alpine sh -c 'sync; echo 3 > /proc/sys/vm/drop_caches'
  until docker exec "$C" pg_isready -U postgres -q; do sleep 0.5; done
}

# Print the lock a backend holds on audit_event. Waits until it shows up.
show_lock() {
  local db=$1 app=$2
  for _ in $(seq 1 200); do
    out=$(psqlc "$db" -At -c "
      SELECT l.mode || ' (granted=' || l.granted || ')'
      FROM pg_locks l JOIN pg_stat_activity a ON a.pid = l.pid
      WHERE a.application_name = '$app' AND l.relation = 'audit_event'::regclass")
    [ -n "$out" ] && { echo "  lock held by $app: $out"; return; }
    sleep 0.05
  done
  echo "  (no lock seen for $app; the statement may have finished first)"
}

# Try a read and a write with a 1s lock_timeout while DDL runs.
probe() {
  local db=$1
  psqlc "$db" -At -c "SET lock_timeout = '1s'; SELECT 'SELECT ok: ' || count(*) FROM (SELECT 1 FROM audit_event LIMIT 10) s" 2>&1 | grep -v '^LINE\|^ *\^' | sed 's/^/  /' || true
  psqlc "$db" -At -c "SET lock_timeout = '1s';
    INSERT INTO audit_event (id, account_id, entity_name, message, is_successful, resource_type, event_type, created_on)
    VALUES (gen_random_uuid(), gen_random_uuid(), 'Cluster', 'probe', true, 'CLUSTER', 'UPDATE', now())
    RETURNING 'INSERT ok'" 2>&1 | grep -v '^INSERT 0\|^LINE\|^ *\^' | sed 's/^/  /' || true
}
