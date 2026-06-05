SELECT count(*) FROM ecom_sales;

SELECT
    category,
    SUM(quantity)                        AS total_items_sold,
    SUM(quantity * item_price)           AS total_revenue,
    AVG(item_price)                      AS avg_item_price
FROM ecom_sales
WHERE order_status = 'completed'
GROUP BY category
HAVING SUM(quantity) > 3
ORDER BY total_revenue DESC;


SELECT
    COALESCE(category, 'ALL CATEGORIES') AS category,
    COALESCE(brand,    'ALL BRANDS')     AS brand,
    SUM(quantity * item_price)           AS total_revenue
FROM ecom_sales
WHERE order_status = 'completed'
GROUP BY GROUPING SETS (
    (category, brand),   
    (category),          
    ()                   
)
ORDER BY category ASC, total_revenue DESC;

WITH ranked_products AS (
    SELECT
        category,
        product_name,
        item_price,
        DENSE_RANK() OVER (
            PARTITION BY category
            ORDER BY item_price DESC
        ) AS product_rank
    FROM ecom_sales
    WHERE order_status = 'completed'
    GROUP BY category, product_name, item_price
)
SELECT
    category,
    product_name,
    item_price,
    product_rank
FROM ranked_products
WHERE product_rank <= 3
ORDER BY category ASC, product_rank ASC;



SELECT
    order_date,
    customer_email,
    quantity * item_price                    AS order_revenue,
    SUM(quantity * item_price)  OVER w       AS cumulative_spend,
    COUNT(order_id)             OVER w       AS running_order_count
FROM ecom_sales
WHERE order_status = 'completed'
WINDOW w AS (
    PARTITION BY customer_email
    ORDER BY order_date
    ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
)
ORDER BY customer_email, order_date;
