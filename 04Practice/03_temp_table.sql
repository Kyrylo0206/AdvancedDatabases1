CREATE TEMPORARY TABLE temp_revenue_risks AS
SELECT order_id
FROM orders
WHERE order_date >= '2025-01-01 00:00:00'
  AND order_date <  '2026-01-01 00:00:00'
  AND order_status IN ('cancelled', 'returned');

SELECT
    p.category,
    SUM(oi.quantity * oi.item_price)  AS lost_revenue,
    COUNT(DISTINCT trr.order_id)      AS impacted_orders
FROM temp_revenue_risks trr
JOIN order_items oi ON trr.order_id = oi.order_id
JOIN products p     ON oi.product_id = p.product_id
GROUP BY p.category
ORDER BY lost_revenue DESC;
