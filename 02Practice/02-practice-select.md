**Task:**
Write one SQL query that returns top customers by revenue using joins, filters, sorting, subqueries, and CTEs.

**Points:**
1

```sql
CREATE TABLE customers (
    customer_id INT PRIMARY KEY,
    customer_name VARCHAR(100),
    country VARCHAR(50)
);

CREATE TABLE products (
    product_id INT PRIMARY KEY,
    product_name VARCHAR(100),
    category VARCHAR(50),
    price DECIMAL(10, 2)
);

CREATE TABLE orders (
    order_id INT PRIMARY KEY,
    customer_id INT,
    order_date DATE,
    status VARCHAR(20),
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
);

CREATE TABLE order_items (
    order_item_id INT PRIMARY KEY,
    order_id INT,
    product_id INT,
    quantity INT,
    FOREIGN KEY (order_id) REFERENCES orders(order_id),
    FOREIGN KEY (product_id) REFERENCES products(product_id)
);

INSERT INTO customers VALUES
(1, 'Alice Johnson', 'USA'),
(2, 'Bob Smith', 'Canada'),
(3, 'Emma Brown', 'USA'),
(4, 'Liam Wilson', 'UK');

INSERT INTO products VALUES
(1, 'Laptop', 'Electronics', 1200.00),
(2, 'Mouse', 'Electronics', 25.00),
(3, 'Desk', 'Furniture', 300.00),
(4, 'Chair', 'Furniture', 150.00);

INSERT INTO orders VALUES
(1, 1, '2024-01-10', 'completed'),
(2, 1, '2024-02-15', 'completed'),
(3, 2, '2024-03-05', 'cancelled'),
(4, 3, '2024-03-20', 'completed'),
(5, 4, '2024-04-01', 'completed');

INSERT INTO order_items VALUES
(1, 1, 1, 1),
(2, 1, 2, 2),
(3, 2, 3, 1),
(4, 3, 4, 4),
(5, 4, 1, 1),
(6, 5, 4, 2);
```

**Expected query should use:**
`JOIN`, `WHERE`, `ORDER BY`, subquery, and `WITH` CTE.
