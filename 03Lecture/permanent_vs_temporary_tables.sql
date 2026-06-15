CREATE DATABASE L03;
CREATE TABLE employees (
                           employee_id INT PRIMARY KEY,
                           name TEXT
);


INSERT INTO employees VALUES
    (1, 'Permanent table row');

SELECT * FROM employees;

CREATE TEMPORARY TABLE employees (
    employee_id INT PRIMARY KEY,
    name TEXT
);

INSERT INTO employees VALUES
    (1, 'Temporary table row');

SELECT * FROM employees;
SELECT * FROM public.employees;
DROP TABLE employees;

SELECT * FROM employees;

