CREATE EXTENSION IF NOT EXISTS pg_trgm;

CREATE INDEX IF NOT EXISTS idx_customers_email_trgm
ON customers USING gin (email gin_trgm_ops);

CREATE INDEX IF NOT EXISTS idx_customers_status_customer
ON customers (status, customer_id)
INCLUDE (full_name);

CREATE INDEX IF NOT EXISTS idx_orders_status_customer_amount
ON orders (status, customer_id)
INCLUDE (total_amount);

CREATE INDEX IF NOT EXISTS idx_orders_delivery_city_trgm
ON orders USING gin (delivery_city gin_trgm_ops);

CREATE INDEX IF NOT EXISTS idx_orders_status_delivery_city
ON orders (status, delivery_city);

CREATE INDEX IF NOT EXISTS idx_events_time_customer_type
ON customer_events_wide (event_time, customer_id, event_type);

CREATE INDEX IF NOT EXISTS idx_events_recent_type_customer
ON customer_events_wide (event_type, customer_id, event_time DESC)
WHERE event_time >= TIMESTAMP '2025-01-01 00:00:00';

CREATE INDEX IF NOT EXISTS idx_products_category_product
ON products (category, product_id);

CREATE INDEX IF NOT EXISTS idx_order_items_product_revenue
ON order_items (product_id)
INCLUDE (quantity, unit_price);

VACUUM ANALYZE customers;
VACUUM ANALYZE products;
VACUUM ANALYZE orders;
VACUUM ANALYZE order_items;
VACUUM ANALYZE customer_events_wide;


EXPLAIN (ANALYZE, BUFFERS)
SELECT customer_id, full_name, email, status
FROM customers
WHERE email LIKE '%gmail%';

EXPLAIN (ANALYZE, BUFFERS)
SELECT order_id, customer_id, order_date, status, total_amount, delivery_city
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
