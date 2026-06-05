CREATE OR REPLACE PROCEDURE process_transaction(p_transaction_id BIGINT)
LANGUAGE plpgsql AS $$
DECLARE
    v_score  INTEGER;
    v_status transaction_status_enum;
BEGIN
    v_score := calculate_transaction_risk_score(p_transaction_id);

    IF v_score >= 70 THEN
        v_status := 'FLAGGED';
    ELSE
        v_status := 'APPROVED';
    END IF;

    UPDATE transactions
    SET risk_score = v_score,
        status = v_status
    WHERE transaction_id = p_transaction_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Transaction % does not exist', p_transaction_id;
    END IF;
END;
$$;


CREATE OR REPLACE PROCEDURE create_fraud_alert(
    p_transaction_id BIGINT,
    p_reason         TEXT,
    p_risk_score     INTEGER
)
LANGUAGE plpgsql AS $$
BEGIN
    INSERT INTO fraud_alerts (transaction_id, reason, risk_score)
    VALUES (p_transaction_id, p_reason, p_risk_score);
END;
$$;


CREATE OR REPLACE PROCEDURE freeze_account(p_account_id BIGINT)
LANGUAGE plpgsql AS $$
BEGIN
    UPDATE accounts SET status = 'FROZEN' WHERE account_id = p_account_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Account % does not exist', p_account_id;
    END IF;
END;
$$;


CREATE OR REPLACE PROCEDURE approve_pending_transactions()
LANGUAGE plpgsql AS $$
BEGIN
    UPDATE transactions
    SET status = 'APPROVED'
    WHERE status = 'PENDING'
      AND risk_score < 70;
END;
$$;


CREATE OR REPLACE PROCEDURE refresh_fraud_dashboard()
LANGUAGE plpgsql AS $$
BEGIN
    REFRESH MATERIALIZED VIEW mv_daily_fraud_summary;
END;
$$;
