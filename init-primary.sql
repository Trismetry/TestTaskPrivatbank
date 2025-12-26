CREATE EXTENSION IF NOT EXISTS pgcrypto;
CREATE EXTENSION IF NOT EXISTS pg_cron;

-- Partitioned table T1 and partitions
-- (see project.sql for full schema)

CREATE PUBLICATION pub_T1 FOR TABLE T1;

CREATE ROLE replicator WITH LOGIN REPLICATION PASSWORD 'secret';
