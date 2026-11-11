-- Table shape matches the real audit table (names made generic).
CREATE EXTENSION IF NOT EXISTS pgstattuple;
CREATE EXTENSION IF NOT EXISTS pg_repack;

DROP TABLE IF EXISTS audit_event, audit_event_archive;

CREATE TABLE audit_event (
  id                        uuid PRIMARY KEY,
  account_id                uuid,
  org_id                    uuid,
  account_name              varchar(255),
  project_id                uuid,
  project_name              varchar(255),
  cluster_id                uuid,
  cluster_name              varchar(255),
  user_id                   uuid,
  user_email                varchar(255),
  impersonating_user_email  varchar(255),
  entity_name               varchar(255) NOT NULL,
  task_id                   uuid,
  api_key_id                uuid,
  api_key_name              varchar(255),
  user_agent                varchar(512),
  client_ip                 varchar(64),
  message                   text NOT NULL,
  is_successful             boolean NOT NULL,
  is_rollback               boolean NOT NULL DEFAULT false,
  resource_type             varchar(255) NOT NULL
    CHECK (resource_type IN ('CLUSTER','PROJECT','USER','API_KEY','BACKUP','NETWORK','BILLING')),
  event_type                varchar(255) NOT NULL
    CHECK (event_type IN ('CREATE','UPDATE','DELETE','PAUSE','RESUME','LOGIN','INVITE')),
  type_specific_data        json,
  created_on                timestamptz NOT NULL,
  updated_on                timestamptz
);
CREATE INDEX audit_event_account_id ON audit_event(account_id);

CREATE TABLE audit_event_archive (LIKE audit_event INCLUDING DEFAULTS);
