# PostgreSQL Partitioned Table Project Test Task Illya Tihonyuk
Primary DB (postgres-primary)

   ├── Partitioned table T1   
   ├── pg_cron jobs (insert + update)   
   ├── Materialized view mv_sum   
   └── Publication pub_T1   
        ↓
Replica DB (postgres-replica)

   └── Subscription sub_T1 (receives changes)
   

---

This project is a test task that demonstrates how to build a partitioned table in PostgreSQL, 
populate it with large amounts of data, schedule recurring jobs with `pg_cron`,
maintain a materialized view, and configure logical replication between two instances.

Task Coverage:

1.Partitioned table T1 — defined in project.sql.

2.Data generation function (≥100k rows) — implemented in project.sql.

3.Uniqueness on operation_guid — enforced via PK/unique constraint in project.sql.

4.Scheduled job: insert every 5s — handled with pg_cron in project.sql.

5.Scheduled job: update every 3s (even/odd IDs) — handled with pg_cron in project.sql.

6.Materialized view with refresh trigger — defined in project.sql.

7.Replication to another instance — configured via init-primary.sql + init-replica.sql and orchestrated in docker-compose.yaml.

---


## 1. Project Structure

- **README.md** — documentation and instructions  
- **Makefile** — shortcuts for managing the cluster  
- **docker-compose.yaml** — defines primary and replica containers  
- **init-primary.sql** — initialization script for primary (extensions, publication, replication role)  
- **init-replica.sql** — initialization script for replica (extensions, subscription)  
- **project.sql** — schema, functions, cron jobs, materialized view, triggers  
- **data/** — local directories mounted for persistent storage  

## 2. Requirements

- Docker & Docker Compose
- PostgreSQL 15+ (with `pg_cron` and `pgcrypto` extensions)
- Two containers: **primary** and **replica**


## 3. Setup

This project includes a `Makefile` to simplify common tasks.

1. Start containers:
   ```bash
   make up
   
2.Connect to primary:

make psql-primary

3.Load schema and logic:

\i project.sql


Data generation: Run the function in project.sql to insert 100k+ rows.

Scheduled jobs: pg_cron inserts new rows every 5 seconds and updates statuses every 3 seconds.

Materialized view: Aggregates totals by client and operation type, refreshed automatically via trigger.

Replication: Changes on primary are replicated to the replica via logical replication.

Quickstart with Makefile


### Commands

- **Start cluster**  
  ```bash
  make up
   
- **Stop cluster**  
make down

- **Restart cluster**  
make restart

- **Connect to primary DB**  
make psql-primary

- **Connect to replica DB**  
make psql-replica

- **Wipe all data volumes (CAUTION: deletes DB data)**
make clean

- **View logs**  
make logs


Configure pg_cron
pg_cron jobs run only on the primary.

Materialized view refresh is triggered after status updates.

Replication requires wal_level=logical and proper pg_hba.conf configuration.


pg_cron runs inside PostgreSQL but requires a background worker.

1.Edit postgresql.conf on the primary instance:
shared_preload_libraries = 'pg_cron'
cron.database_name = 'your_database'

2.Restart PostgreSQL.
3.Verify:
SELECT * FROM cron.job;

You should see scheduled jobs once you add them (insert/update jobs in the project.sql script).


Step 3: Logical replication setup
1.Ensure wal_level is set to logical in postgresql.conf

wal_level = logical

max_replication_slots = 10

max_wal_senders = 10


Restart PostgreSQL if changed.


## 5. Monitoring
Check cron jobs:
SELECT * FROM cron.job_run_details ORDER BY runid DESC LIMIT 10;
Monitor replication lag:
SELECT * FROM pg_stat_subscription;


