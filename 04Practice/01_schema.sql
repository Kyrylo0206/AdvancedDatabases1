DROP TABLE IF EXISTS order_items CASCADE;
DROP TABLE IF EXISTS orders CASCADE;
DROP TABLE IF EXISTS products CASCADE;
DROP TABLE IF EXISTS users CASCADE;
DROP TYPE IF EXISTS order_status_enum CASCADE;

CREATE TABLE users (
    user_id VARCHAR(50) PRIMARY KEY,
    name    VARCHAR(255) NOT NULL,
    email   VARCHAR(255) NOT NULL UNIQUE
);

CREATE TABLE products (
    product_id   VARCHAR(50) PRIMARY KEY,
    product_name VARCHAR(255) NOT NULL,
    category     VARCHAR(100),
    brand        VARCHAR(100),
    price        DECIMAL(12,2) NOT NULL CHECK (price > 0),
    rating       FLOAT CHECK (rating BETWEEN 0 AND 5)
);

CREATE TYPE order_status_enum AS ENUM ('shipped','processing','completed','cancelled','returned');

CREATE TABLE orders (
    order_id     VARCHAR(50) NOT NULL,
    user_id      VARCHAR(50) NOT NULL REFERENCES users(user_id) ON DELETE RESTRICT,
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
    order_date    TIMESTAMP NOT NULL,
    product_id    VARCHAR(50) NOT NULL REFERENCES products(product_id) ON DELETE RESTRICT,
    quantity      INTEGER NOT NULL CHECK (quantity > 0),
    item_price    DECIMAL(12,2) NOT NULL CHECK (item_price >= 0),
    FOREIGN KEY (order_id, order_date) REFERENCES orders(order_id, order_date) ON DELETE CASCADE
);
