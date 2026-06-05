CREATE INDEX IF NOT EXISTS idx_customers_loyalty_tier
    ON customers(loyalty_tier);

CREATE INDEX IF NOT EXISTS idx_customers_registration_date
    ON customers(registration_date);

CREATE INDEX IF NOT EXISTS idx_customers_email_lower
    ON customers(LOWER(email));

CREATE INDEX IF NOT EXISTS idx_customers_date_of_birth
    ON customers(date_of_birth);

CREATE INDEX IF NOT EXISTS idx_customers_composite
    ON customers(loyalty_tier, registration_date, date_of_birth)
    INCLUDE (customer_id, first_name, last_name, email, phone, date_of_birth, gender, city, postcode, country);

CREATE INDEX IF NOT EXISTS idx_transactions_customer_id
    ON transactions(customer_id);

CREATE INDEX IF NOT EXISTS idx_transactions_event_time
    ON transactions(event_time);

CREATE INDEX IF NOT EXISTS idx_transactions_payment_method
    ON transactions(payment_method);

CREATE INDEX IF NOT EXISTS idx_transactions_product_id
    ON transactions(product_id)
    WHERE MOD(product_id, 2) = 0;

CREATE INDEX IF NOT EXISTS idx_transactions_store_id
    ON transactions(store_id)
    WHERE MOD(store_id, 3) <> 0;

EXPLAIN ANALYZE
SELECT
    c.customer_id, c.first_name, c.last_name, c.email, c.phone,
    c.date_of_birth, c.gender, c.city, c.postcode, c.country,
    c.loyalty_tier, c.registration_date,
    LOWER(c.email) AS email_normalized,
    INITCAP(c.first_name || ' ' || c.last_name) AS full_name,
    EXTRACT(YEAR FROM AGE(CURRENT_DATE, c.date_of_birth)) AS age,
    COUNT(t.txn_id) AS total_transactions,
    SUM(t.quantity) AS total_quantity,
    COUNT(DISTINCT t.product_id) AS unique_products,
    COUNT(DISTINCT t.store_id) AS unique_stores,
    COUNT(DISTINCT t.staff_id) AS unique_staff,
    MIN(t.event_time) AS first_transaction_time,
    MAX(t.event_time) AS last_transaction_time,
    SUM(CASE WHEN t.payment_method = 'Card' THEN 1 ELSE 0 END) AS card_transactions,
    SUM(CASE WHEN t.payment_method = 'Cash' THEN 1 ELSE 0 END) AS cash_transactions,
    SUM(CASE WHEN t.payment_method NOT IN ('Card','Cash') THEN 1 ELSE 0 END) AS other_payment_transactions
FROM customers c
JOIN transactions t ON t.customer_id = c.customer_id
WHERE c.loyalty_tier IN ('Silver','Gold','Platinum')
  AND c.registration_date >= CURRENT_DATE - INTERVAL '15 years'
  AND (
      (c.date_of_birth > (CURRENT_DATE - INTERVAL '26 years')::date AND c.date_of_birth <= (CURRENT_DATE - INTERVAL '25 years')::date)
      OR (c.date_of_birth > (CURRENT_DATE - INTERVAL '31 years')::date AND c.date_of_birth <= (CURRENT_DATE - INTERVAL '30 years')::date)
      OR (c.date_of_birth > (CURRENT_DATE - INTERVAL '36 years')::date AND c.date_of_birth <= (CURRENT_DATE - INTERVAL '35 years')::date)
  )
  AND (LOWER(c.email) LIKE '%.org' OR LOWER(c.email) LIKE '%.com')
  AND LENGTH(c.email) BETWEEN 12 AND 80
  AND POSITION('@' IN c.email) > 1
  AND c.email ~* '^[a-z0-9._%+-]+@[a-z0-9.-]+\.[a-z]{2,}$'
  AND COALESCE(c.phone,'') ~ '[0-9]{7,}'
  AND LENGTH(TRIM(c.first_name)) >= 2
  AND LENGTH(TRIM(c.last_name)) >= 2
  AND LOWER(c.first_name) NOT LIKE 'test%'
  AND LOWER(c.last_name) NOT LIKE 'demo%'
  AND COALESCE(c.city,'') <> ''
  AND COALESCE(c.country,'') <> ''
  AND LENGTH(COALESCE(c.postcode,'')) BETWEEN 3 AND 12
  AND t.event_time >= CURRENT_DATE - INTERVAL '12 years'
  AND t.quantity > 0
  AND t.payment_method IN ('Card','Cash','Apple Pay','Google Pay')
  AND EXTRACT(HOUR FROM t.event_time) BETWEEN 8 AND 22
  AND EXTRACT(DOW FROM t.event_time) IN (1,2,3,4,5,6)
  AND MOD(t.product_id, 2) = 0
  AND MOD(t.store_id, 3) <> 0
  AND MD5(LOWER(c.email || COALESCE(c.phone,'') || c.customer_id::TEXT)) IS NOT NULL
  AND MD5(t.txn_id::TEXT || t.customer_id::TEXT || t.product_id::TEXT) IS NOT NULL
GROUP BY
    c.customer_id, c.first_name, c.last_name, c.email, c.phone,
    c.date_of_birth, c.gender, c.city, c.postcode, c.country,
    c.loyalty_tier, c.registration_date
HAVING
    COUNT(t.txn_id) >= 3
    AND SUM(t.quantity) >= 10
    AND COUNT(DISTINCT t.product_id) >= 2
ORDER BY
    total_quantity DESC, total_transactions DESC,
    MAX(t.event_time) DESC, LOWER(c.last_name), LOWER(c.first_name);
