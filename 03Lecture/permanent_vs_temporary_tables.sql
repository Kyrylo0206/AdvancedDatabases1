-- Run from postgres/default database
CREATE DATABASE L03;

-- Then connect to L01:
-- \c L01

-- 1. Create a permanent table
CREATE TABLE employees (
                           employee_id INT PRIMARY KEY,
                           name TEXT
);


INSERT INTO employees VALUES
    (1, 'Permanent table row');

-- 2. Check permanent table
SELECT * FROM employees;
-- Expected: Permanent table row

-- 3. Create a temporary table with the same name
CREATE TEMPORARY TABLE employees (
    employee_id INT PRIMARY KEY,
    name TEXT
);

INSERT INTO employees VALUES
    (1, 'Temporary table row');

-- 4. Query by name: temporary table takes priority
SELECT * FROM employees;
-- Expected: Temporary table row

-- 5. Prove permanent table still exists
SELECT * FROM public.employees;
-- Expected: Permanent table row

-- 6. Drop temporary table
DROP TABLE employees;

-- 7. Query by name again: permanent table is visible again
SELECT * FROM employees;
-- Expected: Permanent table row