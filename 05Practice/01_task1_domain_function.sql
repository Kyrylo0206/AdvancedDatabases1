DROP DOMAIN IF EXISTS secure_email_address CASCADE;
CREATE DOMAIN secure_email_address AS VARCHAR(255)
CHECK (VALUE ~* '^[A-Za-z0-9._%-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,4}$');

CREATE OR REPLACE FUNCTION extract_email_provider(p_email secure_email_address)
RETURNS VARCHAR LANGUAGE plpgsql AS $$
BEGIN
    RETURN split_part(p_email, '@', 2);
END;
$$;

SELECT name, email, extract_email_provider(email::secure_email_address) AS provider
FROM users
LIMIT 10;
