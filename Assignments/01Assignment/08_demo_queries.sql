SELECT calculate_customer_daily_volume(1, CURRENT_DATE);

SELECT is_high_risk_country('KP');
SELECT is_high_risk_country('US');

SELECT calculate_transaction_risk_score(transaction_id), transaction_id, amount
FROM transactions
ORDER BY transaction_id;

SELECT mask_card_number('4111111111111111');

SELECT get_customer_age(1);

CALL process_transaction(4);
CALL process_transaction(6);

SELECT transaction_id, status, risk_score FROM transactions WHERE transaction_id IN (4, 6);

CALL create_fraud_alert(4, 'Manual review: high-value jewelry purchase in high-risk country', 90);

SELECT * FROM fraud_alerts;

CALL freeze_account(6);
SELECT account_id, status FROM accounts WHERE account_id = 6;

CALL approve_pending_transactions();
SELECT transaction_id, status FROM transactions WHERE status = 'APPROVED';

SELECT * FROM vw_customer_accounts;

SELECT * FROM vw_recent_transactions LIMIT 10;

SELECT * FROM vw_flagged_transactions;

SELECT * FROM vw_customer_risk_profile ORDER BY avg_risk_score DESC;

SELECT * FROM transaction_status_history ORDER BY changed_at DESC;

SELECT * FROM audit_log ORDER BY changed_at DESC;

SELECT * FROM mv_daily_fraud_summary ORDER BY transaction_date DESC;

CALL refresh_fraud_dashboard();
SELECT * FROM mv_daily_fraud_summary ORDER BY transaction_date DESC;
