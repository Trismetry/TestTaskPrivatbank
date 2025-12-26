-- ============================================
-- 1. Partitioned table T1
-- ============================================
CREATE TABLE T1 (
    date DATE NOT NULL,
    id BIGINT NOT NULL,
    amount NUMERIC(12,2) NOT NULL,
    status INT NOT NULL DEFAULT 0,
    operation_guid UUID NOT NULL,
    message JSONB NOT NULL,
    PRIMARY KEY (operation_guid)
) PARTITION BY RANGE (date);

-- Example partitions (January–March 2025)
CREATE TABLE T1_2025_01 PARTITION OF T1
FOR VALUES FROM ('2025-01-01') TO ('2025-02-01');

CREATE TABLE T1_2025_02 PARTITION OF T1
FOR VALUES FROM ('2025-02-01') TO ('2025-03-01');

CREATE TABLE T1_2025_03 PARTITION OF T1
FOR VALUES FROM ('2025-03-01') TO ('2025-04-01');

-- ============================================
-- 2. Function to populate with sample data
-- ============================================
CREATE OR REPLACE FUNCTION fill_T1_data()
RETURNS void AS $$
DECLARE
    i INT;
BEGIN
    FOR i IN 1..100000 LOOP
        INSERT INTO T1 (date, id, amount, status, operation_guid, message)
        VALUES (
            '2025-01-01'::date + (i % 90),
            i,
            (random() * 1000)::NUMERIC(12,2),
            0,
            gen_random_uuid(),
            jsonb_build_object(
                'account_number', 'ACC' || i,
                'client_id', i % 5000,
                'operation_type', CASE WHEN i % 2 = 0 THEN 'online' ELSE 'offline' END
            )
        );
    END LOOP;
END;
$$ LANGUAGE plpgsql;

-- Call to generate data
SELECT fill_T1_data();

-- ============================================
-- 3. Uniqueness of operation_guid ensured by PK
-- ============================================

-- ============================================
-- 4. Scheduled job: insert every 5 seconds
-- ============================================
-- Requires pg_cron extension: CREATE EXTENSION pg_cron;
SELECT cron.schedule('insert_job', '*/5 * * * * *',
$$
    INSERT INTO T1 (date, id, amount, status, operation_guid, message)
    VALUES (
        now()::date,
        floor(random()*10000),
        (random()*500)::NUMERIC(12,2),
        0,
        gen_random_uuid(),
        jsonb_build_object('account_number','ACC'||floor(random()*10000),
                           'client_id',floor(random()*5000),
                           'operation_type','online')
    );
$$);

-- ============================================
-- 5. Scheduled job: update status every 3 seconds
-- ============================================
SELECT cron.schedule('update_job', '*/3 * * * * *',
$$
    UPDATE T1
    SET status = 1
    WHERE status = 0
      AND (
        (EXTRACT(SECOND FROM now())::int % 2 = 0 AND id % 2 = 0)
        OR
        (EXTRACT(SECOND FROM now())::int % 2 = 1 AND id % 2 = 1)
      );
$$);

-- ============================================
-- 6. Materialized view with trigger
-- ============================================
CREATE MATERIALIZED VIEW mv_sum AS
SELECT
    (message->>'client_id')::int AS client_id,
    (message->>'operation_type') AS operation_type,
    SUM(amount) AS total_sum
FROM T1
WHERE status = 1
GROUP BY client_id, operation_type;

-- Function to refresh MV
CREATE OR REPLACE FUNCTION refresh_mv_sum()
RETURNS trigger AS $$
BEGIN
    REFRESH MATERIALIZED VIEW CONCURRENTLY mv_sum;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger on status update
CREATE TRIGGER trg_refresh_mv
AFTER UPDATE OF status ON T1
FOR EACH STATEMENT
EXECUTE FUNCTION refresh_mv_sum();

-- ============================================
-- 7. Replication (logical)
-- ============================================
-- On primary instance:
-- CREATE PUBLICATION pub_T1 FOR TABLE T1;

-- On replica:
-- CREATE SUBSCRIPTION sub_T1
-- CONNECTION 'host=master_host dbname=mydb user=replicator password=secret'
-- PUBLICATION pub_T1;
