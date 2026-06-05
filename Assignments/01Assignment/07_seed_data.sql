INSERT INTO customers (first_name, last_name, email, birth_date, country_code) VALUES
('Alice',   'Johnson',  'alice.johnson@gmail.com',   '1990-03-15', 'US'),
('Bob',     'Smith',    'bob.smith@yahoo.com',        '1985-07-22', 'UA'),
('Emma',    'Brown',    'emma.brown@outlook.com',     '1992-11-08', 'DE'),
('Liam',    'Wilson',   'liam.wilson@company.org',    '1988-01-30', 'GB'),
('Sophia',  'Davis',    'sophia.davis@mail.com',      '1995-06-12', 'FR'),
('Noah',    'Martinez', 'noah.martinez@gmail.com',    '1980-09-25', 'KP'),
('Olivia',  'Garcia',   'olivia.garcia@example.com',  '1993-04-18', 'UA'),
('William', 'Lee',      'william.lee@business.net',   '1975-12-05', 'US');

INSERT INTO accounts (customer_id, account_number, currency, balance) VALUES
(1, 'UA001111111111111111111111111', 'USD', 15000.00),
(2, 'UA002222222222222222222222222', 'UAH', 50000.00),
(3, 'UA003333333333333333333333333', 'EUR', 8000.00),
(4, 'UA004444444444444444444444444', 'USD', 25000.00),
(5, 'UA005555555555555555555555555', 'EUR', 3000.00),
(6, 'UA006666666666666666666666666', 'USD', 100000.00),
(7, 'UA007777777777777777777777777', 'UAH', 12000.00),
(8, 'UA008888888888888888888888888', 'USD', 45000.00);

INSERT INTO cards (account_id, card_number_hash, card_type, expiration_date) VALUES
(1, encode(sha256('4111111111111111'), 'hex'), 'DEBIT',  '2027-12-31'),
(2, encode(sha256('4222222222222222'), 'hex'), 'CREDIT', '2026-06-30'),
(3, encode(sha256('4333333333333333'), 'hex'), 'DEBIT',  '2028-03-31'),
(4, encode(sha256('4444444444444444'), 'hex'), 'CREDIT', '2027-09-30'),
(5, encode(sha256('4555555555555555'), 'hex'), 'PREPAID','2028-12-31'),
(6, encode(sha256('4666666666666666'), 'hex'), 'CREDIT', '2028-06-30');

INSERT INTO fraud_rules (rule_name, rule_type, threshold_value) VALUES
('HIGH_AMOUNT',       'amount_check',   10000),
('HIGH_RISK_COUNTRY', 'country_check',  1),
('HIGH_DAILY_VOLUME', 'volume_check',   50000),
('MULTIPLE_DECLINES', 'pattern_check',  3);

INSERT INTO transactions (account_id, card_id, amount, currency, merchant_category, merchant_country) VALUES
(1, 1,   250.00, 'USD', 'GROCERY',     'US'),
(2, 2,  1500.00, 'UAH', 'ELECTRONICS', 'UA'),
(3, 3,   800.00, 'EUR', 'TRAVEL',      'DE'),
(4, 4, 15000.00, 'USD', 'JEWELRY',     'KP'),
(5, 5,    45.00, 'EUR', 'FOOD',        'FR'),
(6, 6, 75000.00, 'USD', 'REAL_ESTATE', 'IR'),
(7, NULL, 200.00,'UAH', 'TRANSPORT',   'UA'),
(8, NULL,3000.00,'USD', 'ELECTRONICS', 'US');
