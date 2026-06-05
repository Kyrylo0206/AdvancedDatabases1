CREATE OR REPLACE FUNCTION calculate_customer_daily_volume(
    p_customer_id BIGINT,
    p_target_date DATE
) RETURNS NUMERIC AS $$
DECLARE
    v_total NUMERIC;
BEGIN
    SELECT COALESCE(SUM(t.amount), 0)
    INTO v_total
    FROM transactions t
    JOIN accounts a ON t.account_id = a.account_id
    WHERE a.customer_id = p_customer_id
      AND t.transaction_at::DATE = p_target_date
      AND t.status != 'DECLINED';
    RETURN v_total;
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION is_high_risk_country(p_country_code CHAR(2))
RETURNS BOOLEAN AS $$
BEGIN
    RETURN p_country_code = ANY(ARRAY['KP','IR','SY','CU','SD','MM','LY','SO','YE','AF']);
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION calculate_transaction_risk_score(p_transaction_id BIGINT)
RETURNS INTEGER AS $$
DECLARE
    v_score       INTEGER := 0;
    v_amount      NUMERIC;
    v_country     CHAR(2);
    v_daily_vol   NUMERIC;
    v_customer_id BIGINT;
    v_date        DATE;
BEGIN
    SELECT t.amount, t.merchant_country, a.customer_id, t.transaction_at::DATE
    INTO v_amount, v_country, v_customer_id, v_date
    FROM transactions t
    JOIN accounts a ON t.account_id = a.account_id
    WHERE t.transaction_id = p_transaction_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Transaction % not found', p_transaction_id;
    END IF;

    IF v_amount > 10000 THEN v_score := v_score + 40; END IF;
    IF v_amount BETWEEN 5000 AND 10000 THEN v_score := v_score + 20; END IF;
    IF is_high_risk_country(v_country) THEN v_score := v_score + 30; END IF;

    v_daily_vol := calculate_customer_daily_volume(v_customer_id, v_date);
    IF v_daily_vol > 50000 THEN v_score := v_score + 30; END IF;

    RETURN LEAST(v_score, 100);
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION mask_card_number(p_card_number VARCHAR)
RETURNS VARCHAR AS $$
BEGIN
    IF p_card_number IS NULL THEN
        RETURN NULL;
    END IF;

    IF LENGTH(p_card_number) <= 4 THEN
        RETURN REPEAT('*', LENGTH(p_card_number));
    END IF;

    RETURN REPEAT('*', LENGTH(p_card_number) - 4) || RIGHT(p_card_number, 4);
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION get_customer_age(p_customer_id BIGINT)
RETURNS INTEGER AS $$
DECLARE
    v_birth_date DATE;
BEGIN
    SELECT birth_date INTO v_birth_date FROM customers WHERE customer_id = p_customer_id;
    RETURN EXTRACT(YEAR FROM AGE(CURRENT_DATE, v_birth_date))::INTEGER;
END;
$$ LANGUAGE plpgsql;
