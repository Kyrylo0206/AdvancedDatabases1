CREATE OR REPLACE FUNCTION classify_user_loyalty(
    p_user_id   users.user_id%TYPE,
    OUT p_name        users.name%TYPE,
    OUT p_order_count INTEGER,
    OUT p_loyalty_tier VARCHAR(50)
)
LANGUAGE plpgsql AS $$
DECLARE
    v_order_count INTEGER;
BEGIN
    SELECT
        u.name,
        COUNT(o.order_id) FILTER (WHERE o.order_status = 'completed')
    INTO p_name, v_order_count
    FROM users u
    LEFT JOIN orders o USING (user_id)
    WHERE u.user_id = p_user_id
    GROUP BY u.user_id, u.name;

    p_order_count := v_order_count;

    IF v_order_count > 5 THEN
        p_loyalty_tier := 'Loyal Customer';
    ELSE
        p_loyalty_tier := 'Standard Customer';
    END IF;

    RETURN;
END;
$$;

SELECT * FROM classify_user_loyalty('U000001');
SELECT * FROM classify_user_loyalty('U000006');
