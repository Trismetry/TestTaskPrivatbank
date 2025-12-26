CREATE EXTENSION IF NOT EXISTS pgcrypto;
CREATE EXTENSION IF NOT EXISTS pg_cron;

-- Same schema for T1 (see project.sql)

CREATE SUBSCRIPTION sub_T1
CONNECTION 'host=postgres-primary port=5432 dbname=mydb user=replicator password=secret'
PUBLICATION pub_T1;
