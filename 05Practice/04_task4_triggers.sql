CREATE TABLE IF NOT EXISTS order_status_logs (
    log_id       BIGSERIAL PRIMARY KEY,
    order_id     VARCHAR(50) NOT NULL,
    old_status   order_status_enum,
    new_status   order_status_enum NOT NULL,
    changed_at   TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE OR REPLACE FUNCTION check_order_modification_eligibility()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
DECLARE
    v_current_status order_status_enum;
BEGIN
    SELECT order_status INTO v_current_status
    FROM orders
    WHERE order_id = NEW.order_id AND order_date = NEW.order_date;

    IF v_current_status IN ('completed', 'shipped', 'cancelled', 'returned') THEN
        RAISE EXCEPTION 'Cannot modify order_items for order % — status is %.', NEW.order_id, v_current_status;
    END IF;

    RETURN NEW;
END;
$$;

CREATE OR REPLACE TRIGGER trg_prevent_isolated_order_items
BEFORE INSERT OR UPDATE ON order_items
FOR EACH ROW EXECUTE FUNCTION check_order_modification_eligibility();

CREATE OR REPLACE FUNCTION trg_fn_log_order_status()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
    IF OLD.order_status IS DISTINCT FROM NEW.order_status THEN
        INSERT INTO order_status_logs (order_id, old_status, new_status)
        VALUES (NEW.order_id, OLD.order_status, NEW.order_status);
    END IF;
    RETURN NEW;
END;
$$;

CREATE OR REPLACE TRIGGER trg_log_order_status
AFTER UPDATE OF order_status ON orders
FOR EACH ROW EXECUTE FUNCTION trg_fn_log_order_status();

UPDATE orders SET order_status = 'shipped'
WHERE order_id = 'O-2025-8888' AND order_date = '2025-04-12 10:15:00';

SELECT * FROM order_status_logs WHERE order_id = 'O-2025-8888';
