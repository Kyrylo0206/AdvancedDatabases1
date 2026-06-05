EXPLAIN ANALYZE
SELECT order_id, user_id, order_status
FROM orders
WHERE user_id = 'usr_0042';

CREATE INDEX IF NOT EXISTS idx_orders_user_id ON orders(user_id);

EXPLAIN ANALYZE
SELECT order_id, user_id, order_status
FROM orders
WHERE user_id = 'usr_0042';

EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM order_items WHERE product_id = 'prod_0100';

EXPLAIN (ANALYZE, BUFFERS)
SELECT order_item_id, quantity, item_price
FROM order_items
WHERE product_id = 'prod_0100';

CREATE INDEX IF NOT EXISTS idx_order_items_covering
ON order_items(product_id)
INCLUDE (order_item_id, quantity, item_price);

EXPLAIN (ANALYZE, BUFFERS)
SELECT order_item_id, quantity, item_price
FROM order_items
WHERE product_id = 'prod_0100';

EXPLAIN ANALYZE
SELECT order_id, order_date
FROM orders
WHERE EXTRACT(YEAR FROM order_date) = 2024;

EXPLAIN ANALYZE
SELECT order_id, order_date
FROM orders
WHERE order_date >= '2024-01-01 00:00:00'
  AND order_date <  '2025-01-01 00:00:00';

CREATE INDEX IF NOT EXISTS idx_orders_year ON orders(EXTRACT(YEAR FROM order_date));

EXPLAIN ANALYZE
SELECT order_id, order_date
FROM orders
WHERE EXTRACT(YEAR FROM order_date) = 2024;

EXPLAIN ANALYZE
SELECT user_id, name, email
FROM users
WHERE user_id IN (
    SELECT user_id FROM orders WHERE order_status = 'completed'
);

EXPLAIN ANALYZE
SELECT DISTINCT u.user_id, u.name, u.email
FROM users u
JOIN orders o ON u.user_id = o.user_id
WHERE o.order_status = 'completed';

CREATE INDEX IF NOT EXISTS idx_orders_status ON orders(order_status);

EXPLAIN ANALYZE
SELECT user_id, name, email
FROM users
WHERE user_id IN (
    SELECT user_id FROM orders WHERE order_status = 'completed'
);

EXPLAIN ANALYZE
SELECT DISTINCT u.user_id, u.name, u.email
FROM users u
JOIN orders o ON u.user_id = o.user_id
WHERE o.order_status = 'completed';

EXPLAIN ANALYZE
SELECT order_id, order_status, order_date
FROM orders
WHERE user_id = 'usr_0100'
  AND order_status = 'completed'
ORDER BY order_date DESC;

CREATE INDEX IF NOT EXISTS idx_orders_user_status ON orders(user_id, order_status);

EXPLAIN ANALYZE
SELECT order_id, order_status, order_date
FROM orders
WHERE user_id = 'usr_0100'
  AND order_status = 'completed'
ORDER BY order_date DESC;

CREATE INDEX IF NOT EXISTS idx_orders_user_status_date
ON orders(user_id, order_status, order_date DESC);

EXPLAIN ANALYZE
SELECT order_id, order_status, order_date
FROM orders
WHERE user_id = 'usr_0100'
  AND order_status = 'completed'
ORDER BY order_date DESC;

EXPLAIN
SELECT COUNT(*) FROM order_items WHERE quantity > 2;

SELECT COUNT(*) FROM order_items WHERE quantity > 2;

DELETE FROM order_items WHERE order_item_id LIKE '%-1';

EXPLAIN
SELECT COUNT(*) FROM order_items WHERE quantity > 2;

VACUUM ANALYZE order_items;

EXPLAIN
SELECT COUNT(*) FROM order_items WHERE quantity > 2;

SELECT relname, n_live_tup, n_dead_tup
FROM pg_stat_user_tables
WHERE relname = 'order_items';

SELECT indexname, tablename, indexdef
FROM pg_indexes
WHERE schemaname = 'public'
  AND indexname LIKE 'idx_%'
ORDER BY tablename, indexname;
