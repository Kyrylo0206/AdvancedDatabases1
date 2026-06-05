-- Session A
BEGIN;
SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;

SELECT COUNT(*)
FROM reservations
WHERE event_id = 1;

-- Keep transaction open

-- COMMIT after the second SELECT
