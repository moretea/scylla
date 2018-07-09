-- +micrate Up

CREATE TABLE projects (
  id    UUID NOT NULL PRIMARY KEY DEFAULT gen_random_uuid(),
  kind  TEXT NOT NULL,
  name  TEXT NOT NULL,
  owner TEXT NOT NULL,
  link  TEXT NOT NULL UNIQUE
);

-- +micrate Down
DROP TABLE projects;
