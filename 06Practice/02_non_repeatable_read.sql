-- Session A
BEGIN;
SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;

SELECT available_count
FROM tickets
WHERE event_id = 1;

-- Keep transaction open

-- COMMIT after the second SELECT
