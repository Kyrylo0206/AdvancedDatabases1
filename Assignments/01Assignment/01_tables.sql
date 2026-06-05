DROP TABLE IF EXISTS audit_log CASCADE;
DROP TABLE IF EXISTS fraud_alerts CASCADE;
DROP TABLE IF EXISTS fraud_rules CASCADE;
DROP TABLE IF EXISTS transaction_status_history CASCADE;
DROP TABLE IF EXISTS transactions CASCADE;
DROP TABLE IF EXISTS cards CASCADE;
DROP TABLE IF EXISTS accounts CASCADE;
DROP TABLE IF EXISTS customers CASCADE;

DROP TYPE IF EXISTS transaction_status_enum CASCADE;
DROP TYPE IF EXISTS account_status_enum CASCADE;
DROP TYPE IF EXISTS card_status_enum CASCADE;
DROP TYPE IF EXISTS alert_status_enum CASCADE;

CREATE TYPE transaction_status_enum AS ENUM ('PENDING', 'APPROVED', 'DECLINED', 'FLAGGED');
CREATE TYPE account_status_enum     AS ENUM ('ACTIVE', 'FROZEN', 'CLOSED');
CREATE TYPE card_status_enum        AS ENUM ('ACTIVE', 'BLOCKED', 'EXPIRED');
CREATE TYPE alert_status_enum       AS ENUM ('OPEN', 'REVIEWED', 'RESOLVED', 'FALSE_POSITIVE');

CREATE TABLE customers (
    customer_id  BIGSERIAL PRIMARY KEY,
    first_name   VARCHAR(100) NOT NULL,
    last_name    VARCHAR(100) NOT NULL,
    email        VARCHAR(255) NOT NULL UNIQUE,
    birth_date   DATE NOT NULL,
    country_code CHAR(2) NOT NULL,
    created_at   TIMESTAMP NOT NULL DEFAULT NOW(),
    is_active    BOOLEAN NOT NULL DEFAULT TRUE
);

CREATE TABLE accounts (
    account_id     BIGSERIAL PRIMARY KEY,
    customer_id    BIGINT NOT NULL REFERENCES customers(customer_id) ON DELETE RESTRICT,
    account_number VARCHAR(34) NOT NULL UNIQUE,
    currency       CHAR(3) NOT NULL CHECK (currency IN ('UAH', 'USD', 'EUR')),
    balance        NUMERIC(18, 2) NOT NULL DEFAULT 0 CHECK (balance >= 0),
    status         account_status_enum NOT NULL DEFAULT 'ACTIVE',
    opened_at      TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE TABLE cards (
    card_id          BIGSERIAL PRIMARY KEY,
    account_id       BIGINT NOT NULL REFERENCES accounts(account_id) ON DELETE CASCADE,
    card_number_hash VARCHAR(64) NOT NULL UNIQUE,
    card_type        VARCHAR(20) NOT NULL CHECK (card_type IN ('DEBIT', 'CREDIT', 'PREPAID')),
    status           card_status_enum NOT NULL DEFAULT 'ACTIVE',
    expiration_date  DATE NOT NULL
);

CREATE TABLE transactions (
    transaction_id      BIGSERIAL PRIMARY KEY,
    account_id          BIGINT NOT NULL REFERENCES accounts(account_id) ON DELETE RESTRICT,
    card_id             BIGINT REFERENCES cards(card_id) ON DELETE SET NULL,
    amount              NUMERIC(18, 2) NOT NULL CHECK (amount > 0),
    currency            CHAR(3) NOT NULL CHECK (currency IN ('UAH', 'USD', 'EUR')),
    merchant_category   VARCHAR(100),
    merchant_country    CHAR(2),
    status              transaction_status_enum NOT NULL DEFAULT 'PENDING',
    risk_score          INTEGER NOT NULL DEFAULT 0 CHECK (risk_score BETWEEN 0 AND 100),
    transaction_at      TIMESTAMP NOT NULL DEFAULT NOW(),
    created_at          TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE TABLE transaction_status_history (
    history_id     BIGSERIAL PRIMARY KEY,
    transaction_id BIGINT NOT NULL REFERENCES transactions(transaction_id) ON DELETE CASCADE,
    old_status     transaction_status_enum,
    new_status     transaction_status_enum NOT NULL,
    changed_at     TIMESTAMP NOT NULL DEFAULT NOW(),
    changed_by     VARCHAR(100) NOT NULL DEFAULT current_user
);

CREATE TABLE fraud_rules (
    rule_id         BIGSERIAL PRIMARY KEY,
    rule_name       VARCHAR(100) NOT NULL UNIQUE,
    rule_type       VARCHAR(50) NOT NULL,
    threshold_value INTEGER NOT NULL CHECK (threshold_value > 0),
    is_active       BOOLEAN NOT NULL DEFAULT TRUE
);

CREATE TABLE fraud_alerts (
    alert_id       BIGSERIAL PRIMARY KEY,
    transaction_id BIGINT NOT NULL REFERENCES transactions(transaction_id) ON DELETE CASCADE,
    rule_id        BIGINT REFERENCES fraud_rules(rule_id) ON DELETE SET NULL,
    reason         TEXT NOT NULL,
    risk_score     INTEGER NOT NULL CHECK (risk_score BETWEEN 0 AND 100),
    alert_status   alert_status_enum NOT NULL DEFAULT 'OPEN',
    created_at     TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE TABLE audit_log (
    audit_id    BIGSERIAL PRIMARY KEY,
    customer_id BIGINT REFERENCES customers(customer_id) ON DELETE SET NULL,
    table_name  VARCHAR(100) NOT NULL,
    operation   VARCHAR(10) NOT NULL CHECK (operation IN ('INSERT', 'UPDATE', 'DELETE')),
    old_value   JSONB,
    new_value   JSONB,
    changed_at  TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_transactions_account_id    ON transactions(account_id);
CREATE INDEX idx_transactions_card_id       ON transactions(card_id);
CREATE INDEX idx_transactions_status        ON transactions(status);
CREATE INDEX idx_transactions_at            ON transactions(transaction_at);
CREATE INDEX idx_fraud_alerts_transaction   ON fraud_alerts(transaction_id);
CREATE INDEX idx_accounts_customer_id       ON accounts(customer_id);
CREATE INDEX idx_audit_log_customer_id      ON audit_log(customer_id);
