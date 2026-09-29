\pset pager off
SELECT pid, relation::regclass AS relation, locktype, page, tuple, mode, granted
FROM pg_locks
WHERE relation = 'accounts'::regclass OR mode = 'SIReadLock'
ORDER BY pid, locktype, page, tuple;

SELECT pid, application_name, state, wait_event_type, wait_event,
       pg_blocking_pids(pid) AS blocked_by
FROM pg_stat_activity
WHERE datname = current_database()
ORDER BY pid;
