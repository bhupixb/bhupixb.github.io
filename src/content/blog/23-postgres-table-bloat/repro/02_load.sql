-- Fills audit_event like years of real use, then runs the old one-time cleanup.
-- psql vars: n_old (rows older than 18 months), n_pre (recent rows before cleanup),
--            n_post (rows inserted after cleanup).

SELECT setseed(0.42);

-- Pools of realistic values. Rows pick from them by a hash of the row number.
DROP TABLE IF EXISTS pool_doc, pool_msg, pool_ua;

-- type_specific_data: mixed sizes. Hex from md5 so pglz cannot shrink it much.
CREATE UNLOGGED TABLE pool_doc AS
SELECT i AS id,
       -- compact text, like an app's JSON serializer writes it
       replace(replace(jsonb_build_object(
         'requestId', md5(i::text),
         'changes', (SELECT coalesce(jsonb_agg(jsonb_build_object(
                         'field', 'spec.field_' || j,
                         'old', md5(i || 'o' || j),
                         'new', md5(i || 'n' || j))), '[]'::jsonb)
                     FROM generate_series(1,
                       CASE WHEN r < 0.50 THEN 0              -- tiny, ~60 B
                            WHEN r < 0.88 THEN 3 + (r*1000)::int % 6   -- 0.3-0.9 KB
                            WHEN r < 0.98 THEN 20 + (r*1000)::int % 20 -- 2-4 KB (TOAST)
                            ELSE 60 + (r*1000)::int % 60               -- 6-12 KB (TOAST)
                       END) j)
       )::text, '": ', '":'), ', "', ',"')::json AS doc
FROM (SELECT i, random() AS r FROM generate_series(0, 9999) i) s;

CREATE UNLOGGED TABLE pool_msg AS
SELECT i AS id,
       format('User %s %s %s %s in project %s. Request %s finished with status %s after %s ms.%s',
              'user' || (i % 500) || '@example.com',
              (ARRAY['created','updated','deleted','paused','resumed'])[1 + i % 5],
              (ARRAY['cluster','backup schedule','network allow list','api key','read replica'])[1 + i % 5],
              'prod-db-' || (i % 300),
              'project-' || (i % 800),
              md5(i::text),
              (ARRAY['OK','OK','OK','FAILED'])[1 + i % 4],
              (i * 37) % 9000,
              CASE WHEN i % 3 = 0 THEN ' Reason: ' || repeat('validation detail ', 1 + i % 6) ELSE '' END
       ) AS msg
FROM generate_series(0, 999) i;

CREATE UNLOGGED TABLE pool_ua AS
SELECT i AS id,
       (ARRAY[
         'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/126.0.0.0 Safari/537.36',
         'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/125.0.0.0 Safari/537.36 Edg/125.0.0.0',
         'Mozilla/5.0 (X11; Linux x86_64; rv:127.0) Gecko/20100101 Firefox/127.0',
         'terraform-provider/1.4.2 (+https://registry.terraform.io) go-resty/2.13.1',
         'python-requests/2.32.3',
         'cli/2.8.0 (darwin; arm64) go1.22.4'
       ])[1 + i % 6] AS ua
FROM generate_series(0, 5) i;

-- Insert n rows with created_on spread between t_from and t_to, in 250k batches.
CREATE OR REPLACE PROCEDURE load_rows(n bigint, t_from timestamptz, t_to timestamptz, start_at bigint)
LANGUAGE plpgsql AS $$
DECLARE b bigint := 250000; lo bigint := 0;
BEGIN
  WHILE lo < n LOOP
    INSERT INTO audit_event
    SELECT gen_random_uuid(),
           CASE WHEN g % 10 <> 0 THEN md5('acct' || abs(hashint8(g)) % 2000)::uuid END,
           CASE WHEN g % 10 IN (0, 1, 2) THEN md5('org' || abs(hashint8(g)) % 400)::uuid END,
           'account-' || abs(hashint8(g)) % 2000,
           md5('proj' || abs(hashint8(g)) % 8000)::uuid,
           'project-' || abs(hashint8(g)) % 8000,
           CASE WHEN g % 4 <> 0 THEN md5('cl' || abs(hashint8(g)) % 30000)::uuid END,
           CASE WHEN g % 4 <> 0 THEN 'prod-db-' || abs(hashint8(g)) % 30000 END,
           md5('u' || abs(hashint8(g)) % 50000)::uuid,
           'user' || abs(hashint8(g)) % 50000 || '@example.com',
           CASE WHEN g % 50 = 0 THEN 'support' || g % 20 || '@example.com' END,
           (ARRAY['Cluster','Project','User','ApiKey','Backup'])[1 + g % 5],
           CASE WHEN g % 2 = 0 THEN gen_random_uuid() END,
           CASE WHEN g % 7 = 0 THEN md5('k' || g % 3000)::uuid END,
           CASE WHEN g % 7 = 0 THEN 'ci-key-' || g % 3000 END,
           ua.ua,
           '10.' || g % 256 || '.' || (g / 256) % 256 || '.' || (g / 65536) % 256,
           m.msg,
           g % 23 <> 0,
           false,
           (ARRAY['CLUSTER','PROJECT','USER','API_KEY','BACKUP','NETWORK','BILLING'])[1 + g % 7],
           (ARRAY['CREATE','UPDATE','DELETE','PAUSE','RESUME','LOGIN','INVITE'])[1 + g % 7],
           d.doc,
           t_from + (t_to - t_from) * ((g - start_at)::float8 / n),
           NULL
    FROM generate_series(start_at + lo, start_at + least(lo + b, n) - 1) g
    JOIN pool_doc d ON d.id = abs(hashint8(g)) % 10000
    JOIN pool_msg m ON m.id = abs(hashint8(g + 7)) % 1000
    JOIN pool_ua ua ON ua.id = abs(hashint8(g + 13)) % 6
    ORDER BY g;   -- keep insert order = time order, like a real append-only table
    COMMIT;
    lo := lo + b;
    RAISE NOTICE 'inserted % / %', least(lo, n), n;
  END LOOP;
END $$;

\echo '== phase 1: years of history (older than 18 months)'
CALL load_rows(:n_old, now() - interval '5 years', now() - interval '19 months', 0);
\echo '== phase 2: recent rows, before the cleanup'
CALL load_rows(:n_pre, now() - interval '18 months', now() - interval '3 months', :n_old);
VACUUM ANALYZE audit_event;

\echo '== sizes before cleanup'
\i 03_sizes.sql

\echo '== phase 3: the one-time cleanup migration (archive + DELETE)'
\timing on
INSERT INTO audit_event_archive SELECT * FROM audit_event WHERE created_on <= now() - interval '18 months';
DELETE FROM audit_event WHERE created_on <= now() - interval '18 months';
\timing off
VACUUM ANALYZE audit_event;   -- what autovacuum would do soon after

\echo '== sizes after cleanup + vacuum'
\i 03_sizes.sql

\echo '== phase 4: normal inserts continue after the cleanup'
CALL load_rows(:n_post, now() - interval '3 months', now(), :n_old + :n_pre);
VACUUM ANALYZE audit_event;
DROP TABLE pool_doc, pool_msg, pool_ua;
CHECKPOINT;
