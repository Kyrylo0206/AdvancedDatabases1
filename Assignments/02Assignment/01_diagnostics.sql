CREATE EXTENSION IF NOT EXISTS pg_stat_statements;

SELECT
    query,
    calls,
    ROUND(total_exec_time::numeric, 2) AS total_exec_time_ms,
    ROUND(mean_exec_time::numeric, 2) AS mean_exec_time_ms,
    rows
FROM pg_stat_statements
ORDER BY total_exec_time DESC
LIMIT 20;

SELECT
    pid,
    usename,
    state,
    wait_event_type,
    wait_event,
    NOW() - query_start AS running_for,
    query
FROM pg_stat_activity
WHERE state <> 'idle'
ORDER BY running_for DESC;

SELECT
    blocked.pid AS blocked_pid,
    blocked.usename AS blocked_user,
    blocked.query AS blocked_query,
    blocking.pid AS blocking_pid,
    blocking.usename AS blocking_user,
    blocking.query AS blocking_query,
    blocked.wait_event_type,
    blocked.wait_event
FROM pg_stat_activity blocked
JOIN pg_stat_activity blocking
  ON blocking.pid = ANY(pg_blocking_pids(blocked.pid))
ORDER BY blocked.pid;

SELECT
    pid,
    usename,
    state,
    wait_event_type,
    wait_event,
    NOW() - query_start AS running_for,
    query
FROM pg_stat_activity
WHERE wait_event_type = 'Lock'
ORDER BY running_for DESC;

SELECT
    pid,
    usename,
    state,
    xact_start,
    NOW() - xact_start AS transaction_duration,
    query
FROM pg_stat_activity
WHERE xact_start IS NOT NULL
ORDER BY xact_start;

EXPLAIN (ANALYZE, BUFFERS)
SELECT *
FROM customers
WHERE email LIKE '%gmail%';

EXPLAIN (ANALYZE, BUFFERS)
SELECT *
FROM orders
WHERE delivery_city LIKE '%a%'
  AND status = 'paid';

EXPLAIN (ANALYZE, BUFFERS)
SELECT
    c.customer_id,
    c.full_name,
    COUNT(o.order_id) AS orders_count,
    SUM(o.total_amount) AS revenue
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
WHERE c.status = 'active'
GROUP BY c.customer_id, c.full_name
ORDER BY revenue DESC
LIMIT 100;

EXPLAIN (ANALYZE, BUFFERS)
SELECT
    customer_id,
    event_type,
    COUNT(*) AS events_count,
    MAX(event_time) AS last_event_time
FROM customer_events_wide
WHERE event_time >= NOW() - INTERVAL '180 days'
GROUP BY customer_id, event_type
ORDER BY events_count DESC
LIMIT 200;

EXPLAIN (ANALYZE, BUFFERS)
SELECT
    p.category,
    COUNT(*) AS items_sold,
    SUM(oi.quantity * oi.unit_price) AS revenue
FROM order_items oi
JOIN products p ON oi.product_id = p.product_id
GROUP BY p.category
ORDER BY revenue DESC;

SELECT
    relname,
    n_live_tup,
    n_dead_tup,
    last_vacuum,
    last_autovacuum,
    last_analyze,
    last_autoanalyze
FROM pg_stat_user_tables
ORDER BY n_dead_tup DESC;
