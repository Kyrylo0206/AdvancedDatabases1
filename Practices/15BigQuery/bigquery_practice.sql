
SELECT 'Hello, BigQuery!' AS message;

SELECT
  name,
  SUM(number) AS total_births
FROM `bigquery-public-data.usa_names.usa_1910_current`
GROUP BY name
ORDER BY total_births DESC
LIMIT 10;

SELECT
  name,
  SUM(number) AS total_births
FROM `bigquery-public-data.usa_names.usa_1910_current`
WHERE name LIKE 'A%'
GROUP BY name
ORDER BY total_births DESC
LIMIT 10;
