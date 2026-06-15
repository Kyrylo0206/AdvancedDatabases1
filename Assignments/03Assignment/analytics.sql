-- Assignment 03: Spark SQL Analytics

-- 1. Top 5 products by revenue.
SELECT product_name, ROUND(SUM(sales), 2) AS revenue
FROM silver_orders
GROUP BY product_name
ORDER BY revenue DESC
LIMIT 5;

-- 2. Top region by revenue.
SELECT region, ROUND(SUM(sales), 2) AS revenue
FROM silver_orders
GROUP BY region
ORDER BY revenue DESC
LIMIT 1;

-- 3. Monthly revenue trend.
SELECT date_trunc('month', order_date) AS month, ROUND(SUM(sales), 2) AS revenue
FROM silver_orders
GROUP BY date_trunc('month', order_date)
ORDER BY month;

-- 4. Running revenue total.
SELECT
    order_date,
    ROUND(SUM(sales), 2) AS daily_revenue,
    ROUND(SUM(SUM(sales)) OVER (ORDER BY order_date), 2) AS running_revenue
FROM silver_orders
GROUP BY order_date
ORDER BY order_date;

-- 5. Top product per region.
WITH product_region_revenue AS (
    SELECT
        region,
        product_name,
        ROUND(SUM(sales), 2) AS revenue,
        ROW_NUMBER() OVER (PARTITION BY region ORDER BY SUM(sales) DESC) AS rn
    FROM silver_orders
    GROUP BY region, product_name
)
SELECT region, product_name, revenue
FROM product_region_revenue
WHERE rn = 1
ORDER BY region;

-- 6. Previous month comparison using LAG().
WITH monthly AS (
    SELECT date_trunc('month', order_date) AS month, ROUND(SUM(sales), 2) AS revenue
    FROM silver_orders
    GROUP BY date_trunc('month', order_date)
)
SELECT
    month,
    revenue,
    LAG(revenue) OVER (ORDER BY month) AS previous_month_revenue,
    revenue - LAG(revenue) OVER (ORDER BY month) AS month_over_month_change
FROM monthly
ORDER BY month;
