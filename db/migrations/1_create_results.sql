-- +micrate Up
CREATE EXTENSION IF NOT EXISTS pgcrypto;
CREATE EXTENSION IF NOT EXISTS timescaledb CASCADE;

CREATE TABLE results (
  id          UUID  NOT NULL PRIMARY KEY DEFAULT gen_random_uuid(),
  hook_data   JSONB NOT NULL,
  exit_status INT                      DEFAULT 0,
  created_at  TIMESTAMP WITH TIME ZONE NOT NULL,
  finished_at TIMESTAMP WITH TIME ZONE,
  project_id  UUID                     NOT NULL
);

CREATE INDEX ON results (project_id);

CREATE TABLE logs (
  time      TIMESTAMP WITH TIME ZONE NOT NULL,
  kind      TEXT                     NOT NULL,
  line      TEXT                     NOT NULL,
  result_id UUID                     NOT NULL
);

SELECT create_hypertable('logs', 'time', 'result_id');
CREATE INDEX ON logs (result_id);

-- +micrate Down
DROP TABLE results;
DROP TABLE logs;
