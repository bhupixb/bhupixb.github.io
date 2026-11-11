-- Where is the space? Live data vs dead tuples vs plain free space, for heap and TOAST.
SELECT 'heap' AS part, pg_size_pretty(table_len) AS size,
       tuple_count, round(tuple_percent::numeric, 1) AS live_pct,
       dead_tuple_count, round(dead_tuple_percent::numeric, 1) AS dead_pct,
       pg_size_pretty(free_space) AS free, round(free_percent::numeric, 1) AS free_pct
FROM pgstattuple('audit_event')
UNION ALL
SELECT 'toast', pg_size_pretty(table_len),
       tuple_count, round(tuple_percent::numeric, 1),
       dead_tuple_count, round(dead_tuple_percent::numeric, 1),
       pg_size_pretty(free_space), round(free_percent::numeric, 1)
FROM pgstattuple((SELECT reltoastrelid FROM pg_class WHERE relname = 'audit_event')::regclass);
