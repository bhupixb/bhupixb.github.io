-- Size breakdown for audit_event: heap, TOAST, indexes, rows, bytes per row.
SELECT pg_size_pretty(pg_total_relation_size(c.oid))           AS total,
       pg_size_pretty(pg_relation_size(c.oid))                 AS heap,
       pg_size_pretty(pg_relation_size(c.reltoastrelid))       AS toast,
       pg_size_pretty(pg_table_size(c.oid))                    AS "table (heap+toast)",
       pg_size_pretty(pg_indexes_size(c.oid))                  AS indexes,
       c.reltuples::bigint                                     AS est_rows,
       s.n_live_tup, s.n_dead_tup,
       (pg_total_relation_size(c.oid) / greatest(c.reltuples, 1))::bigint AS bytes_per_row
FROM pg_class c JOIN pg_stat_user_tables s ON s.relid = c.oid
WHERE c.relname = 'audit_event';
