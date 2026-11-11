-- Same rows, json vs jsonb. Stored size per value (after TOAST compression) and table size.
DROP TABLE IF EXISTS doc_json, doc_jsonb;
CREATE TABLE doc_json  AS SELECT id, type_specific_data        AS doc FROM audit_event;
CREATE TABLE doc_jsonb AS SELECT id, type_specific_data::jsonb AS doc FROM audit_event;
VACUUM ANALYZE doc_json, doc_jsonb;

SELECT t, pg_size_pretty(pg_relation_size(c.oid))     AS heap,
          pg_size_pretty(pg_relation_size(c.reltoastrelid)) AS toast,
          pg_size_pretty(pg_table_size(c.oid))        AS total
FROM (VALUES ('json', 'doc_json'::regclass), ('jsonb', 'doc_jsonb'::regclass)) v(t, c0)
JOIN pg_class c ON c.oid = v.c0;

-- By document size, stored bytes per value (pg_column_size = on-disk, maybe compressed)
SELECT bucket,
       count(*)                                    AS docs,
       round(avg(octet_length(j.doc::text)))       AS avg_json_text,
       round(avg(pg_column_size(j.doc)))           AS avg_json_stored,
       round(avg(pg_column_size(b.doc)))           AS avg_jsonb_stored,
       round(100.0 * sum(pg_column_size(b.doc)) / sum(pg_column_size(j.doc)) - 100, 1) AS jsonb_vs_json_pct
FROM doc_json j JOIN doc_jsonb b USING (id),
LATERAL (SELECT CASE WHEN octet_length(j.doc::text) < 200  THEN '1: < 200 B'
                     WHEN octet_length(j.doc::text) < 2000 THEN '2: 200 B - 2 KB'
                     WHEN octet_length(j.doc::text) < 5000 THEN '3: 2 - 5 KB'
                     ELSE '4: > 5 KB' END AS bucket) k
GROUP BY ROLLUP (bucket) ORDER BY bucket;

DROP TABLE doc_json, doc_jsonb;
