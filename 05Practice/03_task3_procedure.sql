CREATE OR REPLACE PROCEDURE place_single_item_order(
    p_order_id      orders.order_id%TYPE,
    p_user_id       orders.user_id%TYPE,
    p_order_date    orders.order_date%TYPE,
    p_order_status  orders.order_status%TYPE,
    p_order_item_id order_items.order_item_id%TYPE,
    p_product_id    order_items.product_id%TYPE,
    p_quantity      order_items.quantity%TYPE,
    p_item_price    order_items.item_price%TYPE
)
LANGUAGE plpgsql AS $$
BEGIN
    INSERT INTO orders (order_id, user_id, order_date, order_status)
    VALUES (p_order_id, p_user_id, p_order_date, p_order_status);

    INSERT INTO order_items (order_item_id, order_id, order_date, product_id, quantity, item_price)
    VALUES (p_order_item_id, p_order_id, p_order_date, p_product_id, p_quantity, p_item_price);

    COMMIT;
END;
$$;

CALL place_single_item_order(
    'O-2025-8888', 'U000001', '2025-04-12 10:15:00', 'processing',
    'OI-2025-9999', 'P000001', 3, 45.50
);

SELECT * FROM orders     WHERE order_id = 'O-2025-8888';
SELECT * FROM order_items WHERE order_id = 'O-2025-8888';
