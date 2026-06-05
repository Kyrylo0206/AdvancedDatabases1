CREATE OR REPLACE FUNCTION trg_fn_evaluate_transaction_risk()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
DECLARE
    v_score INTEGER;
BEGIN
    v_score := calculate_transaction_risk_score(NEW.transaction_id);

    UPDATE transactions
    SET risk_score = v_score,
        status = CASE
            WHEN v_score >= 70 THEN 'FLAGGED'
            ELSE status
        END
    WHERE transaction_id = NEW.transaction_id;

    RETURN NEW;
END;
$$;

CREATE OR REPLACE TRIGGER trg_evaluate_risk
AFTER INSERT ON transactions
FOR EACH ROW EXECUTE FUNCTION trg_fn_evaluate_transaction_risk();


CREATE OR REPLACE FUNCTION trg_fn_create_fraud_alert()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
    IF NEW.risk_score >= 70
       AND NOT EXISTS (
           SELECT 1
           FROM fraud_alerts fa
           WHERE fa.transaction_id = NEW.transaction_id
       ) THEN
        INSERT INTO fraud_alerts (transaction_id, reason, risk_score)
        VALUES (NEW.transaction_id, 'Automated: risk score ' || NEW.risk_score, NEW.risk_score);
    END IF;
    RETURN NEW;
END;
$$;

CREATE OR REPLACE TRIGGER trg_fraud_alert
AFTER UPDATE OF risk_score, status ON transactions
FOR EACH ROW EXECUTE FUNCTION trg_fn_create_fraud_alert();


CREATE OR REPLACE FUNCTION trg_fn_update_balance()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
    IF NEW.status = 'APPROVED' AND (OLD.status IS DISTINCT FROM 'APPROVED') THEN
        UPDATE accounts
        SET balance = balance - NEW.amount
        WHERE account_id = NEW.account_id;
    END IF;
    RETURN NEW;
END;
$$;

CREATE OR REPLACE TRIGGER trg_update_balance
AFTER UPDATE OF status ON transactions
FOR EACH ROW EXECUTE FUNCTION trg_fn_update_balance();


CREATE OR REPLACE FUNCTION trg_fn_track_status_history()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
    IF OLD.status IS DISTINCT FROM NEW.status THEN
        INSERT INTO transaction_status_history (transaction_id, old_status, new_status)
        VALUES (NEW.transaction_id, OLD.status, NEW.status);
    END IF;
    RETURN NEW;
END;
$$;

CREATE OR REPLACE TRIGGER trg_status_history
AFTER UPDATE OF status ON transactions
FOR EACH ROW EXECUTE FUNCTION trg_fn_track_status_history();


CREATE OR REPLACE FUNCTION trg_fn_audit_customers()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        INSERT INTO audit_log (customer_id, table_name, operation, new_value)
        VALUES (NEW.customer_id, 'customers', 'INSERT', to_jsonb(NEW));
    ELSIF TG_OP = 'UPDATE' THEN
        INSERT INTO audit_log (customer_id, table_name, operation, old_value, new_value)
        VALUES (NEW.customer_id, 'customers', 'UPDATE', to_jsonb(OLD), to_jsonb(NEW));
    ELSIF TG_OP = 'DELETE' THEN
        INSERT INTO audit_log (customer_id, table_name, operation, old_value)
        VALUES (OLD.customer_id, 'customers', 'DELETE', to_jsonb(OLD));
    END IF;
    RETURN COALESCE(NEW, OLD);
END;
$$;

CREATE OR REPLACE TRIGGER trg_audit_customers
AFTER INSERT OR UPDATE OR DELETE ON customers
FOR EACH ROW EXECUTE FUNCTION trg_fn_audit_customers();


CREATE OR REPLACE FUNCTION trg_fn_protect_customer_delete()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM accounts
        WHERE customer_id = OLD.customer_id AND status = 'ACTIVE'
    ) THEN
        RAISE EXCEPTION 'Cannot delete customer % — active accounts exist.', OLD.customer_id;
    END IF;
    RETURN OLD;
END;
$$;

CREATE OR REPLACE TRIGGER trg_protect_customer_delete
BEFORE DELETE ON customers
FOR EACH ROW EXECUTE FUNCTION trg_fn_protect_customer_delete();
