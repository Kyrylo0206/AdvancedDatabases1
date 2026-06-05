CREATE OR REPLACE VIEW vw_customer_accounts AS
SELECT
    c.customer_id,
    c.first_name,
    c.last_name,
    c.email,
    c.country_code,
    a.account_id,
    a.account_number,
    a.currency,
    a.balance,
    a.status AS account_status
FROM customers c
JOIN accounts a ON c.customer_id = a.customer_id;


CREATE OR REPLACE VIEW vw_recent_transactions AS
SELECT
    t.transaction_id,
    c.first_name || ' ' || c.last_name AS customer_name,
    a.account_number,
    t.amount,
    t.currency,
    t.merchant_category,
    t.merchant_country,
    t.status,
    t.risk_score,
    t.transaction_at
FROM transactions t
JOIN accounts a  ON t.account_id  = a.account_id
JOIN customers c ON a.customer_id = c.customer_id
WHERE t.transaction_at >= NOW() - INTERVAL '30 days'
ORDER BY t.transaction_at DESC;


CREATE OR REPLACE VIEW vw_flagged_transactions AS
WITH latest_alert AS (
    SELECT DISTINCT ON (transaction_id)
        transaction_id,
        reason,
        alert_status
    FROM fraud_alerts
    ORDER BY transaction_id, created_at DESC, alert_id DESC
)
SELECT
    t.transaction_id,
    c.customer_id,
    c.first_name || ' ' || c.last_name AS customer_name,
    t.amount,
    t.currency,
    t.merchant_country,
    t.risk_score,
    t.transaction_at,
    la.reason,
    la.alert_status
FROM transactions t
JOIN accounts a   ON t.account_id  = a.account_id
JOIN customers c  ON a.customer_id = c.customer_id
LEFT JOIN latest_alert la ON t.transaction_id = la.transaction_id
WHERE t.status = 'FLAGGED';


CREATE OR REPLACE VIEW vw_customer_risk_profile AS
WITH alert_counts AS (
    SELECT
        a.customer_id,
        COUNT(fa.alert_id) AS total_alerts
    FROM fraud_alerts fa
    JOIN transactions t ON fa.transaction_id = t.transaction_id
    JOIN accounts a ON t.account_id = a.account_id
    GROUP BY a.customer_id
)
SELECT
    c.customer_id,
    c.first_name || ' ' || c.last_name AS customer_name,
    c.country_code,
    COUNT(t.transaction_id)            AS total_transactions,
    COALESCE(SUM(t.amount), 0)         AS total_volume,
    COALESCE(AVG(t.risk_score), 0)     AS avg_risk_score,
    COALESCE(ac.total_alerts, 0)       AS total_alerts,
    is_high_risk_country(c.country_code) AS high_risk_country
FROM customers c
LEFT JOIN accounts a    ON c.customer_id   = a.customer_id
LEFT JOIN transactions t ON a.account_id  = t.account_id
LEFT JOIN alert_counts ac ON c.customer_id = ac.customer_id
GROUP BY c.customer_id, c.first_name, c.last_name, c.country_code, ac.total_alerts;
