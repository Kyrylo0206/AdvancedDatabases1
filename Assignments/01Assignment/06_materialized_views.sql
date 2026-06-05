CREATE MATERIALIZED VIEW mv_daily_fraud_summary AS
WITH daily_transactions AS (
    SELECT
        t.transaction_at::DATE AS transaction_date,
        COUNT(t.transaction_id) AS total_transactions,
        COALESCE(SUM(t.amount), 0) AS total_amount,
        COUNT(t.transaction_id) FILTER (WHERE t.status = 'FLAGGED') AS flagged_transactions,
        COALESCE(SUM(t.amount) FILTER (WHERE t.status = 'FLAGGED'), 0) AS suspicious_amount,
        ROUND(AVG(t.risk_score), 2) AS avg_risk_score
    FROM transactions t
    GROUP BY t.transaction_at::DATE
),
daily_alerts AS (
    SELECT
        t.transaction_at::DATE AS transaction_date,
        COUNT(DISTINCT fa.alert_id) AS total_fraud_alerts
    FROM transactions t
    JOIN fraud_alerts fa ON fa.transaction_id = t.transaction_id
    GROUP BY t.transaction_at::DATE
),
daily_customer_risk AS (
    SELECT
        t.transaction_at::DATE AS transaction_date,
        a.customer_id,
        SUM(t.risk_score) AS total_risk_score,
        ROW_NUMBER() OVER (
            PARTITION BY t.transaction_at::DATE
            ORDER BY SUM(t.risk_score) DESC, a.customer_id
        ) AS risk_rank
    FROM transactions t
    JOIN accounts a ON t.account_id = a.account_id
    WHERE t.risk_score > 0
    GROUP BY t.transaction_at::DATE, a.customer_id
)
SELECT
    dt.transaction_date,
    dt.total_transactions,
    dt.total_amount,
    dt.flagged_transactions,
    dt.suspicious_amount,
    dt.avg_risk_score,
    dcr.customer_id AS top_risky_customer_id,
    COALESCE(da.total_fraud_alerts, 0) AS total_fraud_alerts
FROM daily_transactions dt
LEFT JOIN daily_alerts da USING (transaction_date)
LEFT JOIN daily_customer_risk dcr
    ON dt.transaction_date = dcr.transaction_date
   AND dcr.risk_rank = 1
WITH DATA;

CREATE UNIQUE INDEX idx_mv_daily_fraud_date ON mv_daily_fraud_summary(transaction_date);
