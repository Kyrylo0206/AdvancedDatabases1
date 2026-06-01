-- ============================================================
-- Practice 08: SQL Query Optimization — Seed Script
-- ============================================================
-- PREREQUISITE: Complete Practice 04 before running Practice 08.
-- Practice 04 creates the required schema (users, products, orders,
-- order_items) and loads real data from the Kaggle dataset.
--
-- Only run THIS script if you skipped Practice 04 and need
-- a minimal working dataset to proceed. It generates synthetic
-- test data using generate_series (no CSV or Kaggle account needed).
--
-- Tested on: PostgreSQL 8
-- Estimated runtime: ~15–30 seconds
-- ============================================================

-- ------------------------------------------------------------
-- 1. CLEANUP (safe to re-run)
-- ------------------------------------------------------------
DROP TABLE IF EXISTS order_items CASCADE;
DROP TABLE IF EXISTS orders       CASCADE;
DROP TABLE IF EXISTS products     CASCADE;
DROP TABLE IF EXISTS users        CASCADE;
DROP TYPE  IF EXISTS order_status_enum;

-- ------------------------------------------------------------
-- 2. SCHEMA
-- ------------------------------------------------------------
CREATE TYPE order_status_enum AS ENUM (
    'shipped', 'processing', 'completed', 'cancelled', 'returned'
);

CREATE TABLE users (
    user_id    VARCHAR(50) PRIMARY KEY,
    name       VARCHAR(100) NOT NULL,
    email      VARCHAR(150) NOT NULL UNIQUE,
    country    VARCHAR(50)
);

CREATE TABLE products (
    product_id   VARCHAR(50) PRIMARY KEY,
    product_name VARCHAR(200) NOT NULL,
    category     VARCHAR(100),
    brand        VARCHAR(100),
    price        NUMERIC(10, 2) CHECK (price > 0),
    rating       FLOAT CHECK (rating >= 0 AND rating <= 5)
);

CREATE TABLE orders (
    order_id     VARCHAR(50) NOT NULL,
    user_id      VARCHAR(50) NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    order_date   TIMESTAMP NOT NULL,
    order_status order_status_enum NOT NULL,
    PRIMARY KEY (order_id, order_date)
) PARTITION BY RANGE (order_date);

CREATE TABLE orders_2024 PARTITION OF orders
    FOR VALUES FROM ('2024-01-01 00:00:00') TO ('2025-01-01 00:00:00');

CREATE TABLE orders_2025 PARTITION OF orders
    FOR VALUES FROM ('2025-01-01 00:00:00') TO ('2026-01-01 00:00:00');

CREATE TABLE order_items (
    order_item_id VARCHAR(50) PRIMARY KEY,
    order_id      VARCHAR(50) NOT NULL,
    order_date    TIMESTAMP   NOT NULL,
    product_id    VARCHAR(50) NOT NULL REFERENCES products(product_id) ON DELETE RESTRICT,
    quantity      INTEGER     NOT NULL CHECK (quantity > 0),
    item_price    NUMERIC(10, 2) NOT NULL CHECK (item_price >= 0),
    FOREIGN KEY (order_id, order_date) REFERENCES orders(order_id, order_date) ON DELETE CASCADE
);

-- ------------------------------------------------------------
-- 3. SEED DATA
-- ------------------------------------------------------------

-- Users: 50 000 rows
INSERT INTO users (user_id, name, email, country)
SELECT
    'usr_' || LPAD(i::TEXT, 4, '0'),
    'User ' || i,
    'user' || i || '@example.com',
    (ARRAY['Ukraine','Poland','Germany','France','USA','UK','Canada'])[1 + (i % 7)]
FROM generate_series(1, 50000) AS s(i);

-- Products: 1 000 rows
INSERT INTO products (product_id, product_name, category, brand, price, rating)
SELECT
    'prod_' || LPAD(i::TEXT, 4, '0'),
    'Product ' || i,
    (ARRAY['Electronics','Clothing','Books','Furniture','Sports','Beauty','Food'])[1 + (i % 7)],
    (ARRAY['Alpha','Beta','Gamma','Delta','Willow','Sigma','Omega'])[1 + (i % 7)],
    round((10 + random() * 990)::numeric, 2),
    round((random() * 5)::numeric, 1)
FROM generate_series(1, 1000) AS s(i);

-- Orders: 200 000 rows spread across 2024–2025
INSERT INTO orders (order_id, user_id, order_date, order_status)
SELECT
    'ord_' || LPAD(i::TEXT, 6, '0'),
    'usr_' || LPAD((1 + (i % 50000))::TEXT, 4, '0'),
    TIMESTAMP '2024-01-01' + (random() * INTERVAL '730 days'),
    (ARRAY['shipped','processing','completed','cancelled','returned']::order_status_enum[])[1 + (i % 5)]
FROM generate_series(1, 200000) AS s(i);

-- Order items: 400 000 rows
INSERT INTO order_items (order_item_id, order_id, order_date, product_id, quantity, item_price)
SELECT
    'item_' || LPAD(i::TEXT, 6, '0'),
    o.order_id,
    o.order_date,
    'prod_' || LPAD((1 + (i % 1000))::TEXT, 4, '0'),
    1 + (i % 5),
    round((5 + random() * 495)::numeric, 2)
FROM generate_series(1, 400000) AS s(i)
JOIN (
    SELECT order_id, order_date,
           ROW_NUMBER() OVER () AS rn
    FROM orders
) o ON o.rn = s.i;

-- ------------------------------------------------------------
-- 4. STATISTICS
-- ------------------------------------------------------------
ANALYZE users, products, orders, order_items;

-- ------------------------------------------------------------
-- 5. VERIFICATION
-- ------------------------------------------------------------
SELECT 'users'         AS "table", COUNT(*) AS rows FROM users
UNION ALL
SELECT 'products',       COUNT(*) FROM products
UNION ALL
SELECT 'orders',         COUNT(*) FROM orders
UNION ALL
SELECT 'orders_2024',    COUNT(*) FROM orders_2024
UNION ALL
SELECT 'orders_2025',    COUNT(*) FROM orders_2025
UNION ALL
SELECT 'order_items',    COUNT(*) FROM order_items;
