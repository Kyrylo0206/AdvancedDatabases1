# Databricks notebook source
# Assignment 03: Production-Style Lakehouse Pipeline in Databricks
# Upload Superstore CSV files to /FileStore/superstore before running.

# COMMAND ----------

from pyspark.sql import functions as F
from pyspark.sql.window import Window
raw_path = "/FileStore/superstore"
bronze_path = "/tmp/advanced_databases/bronze_orders"
silver_path = "/tmp/advanced_databases/silver_orders"
rejected_path = "/tmp/advanced_databases/silver_rejected_orders"

# COMMAND ----------

# Task 1: Bronze Layer
bronze_df = (
    spark.read.option("header", True)
    .option("inferSchema", True)
    .csv(raw_path)
    .withColumn("ingestion_timestamp", F.current_timestamp())
    .withColumn("source_file_name", F.input_file_name())
)

bronze_df.write.format("delta").mode("overwrite").save(bronze_path)

spark.sql("DROP TABLE IF EXISTS bronze_orders")
spark.sql(f"CREATE TABLE bronze_orders USING DELTA LOCATION '{bronze_path}'")

# COMMAND ----------

# Task 2: Silver Layer
bronze_orders = spark.table("bronze_orders")

standardized = (
    bronze_orders
    .withColumnRenamed("Row ID", "row_id")
    .withColumnRenamed("Order ID", "order_id")
    .withColumnRenamed("Order Date", "order_date_raw")
    .withColumnRenamed("Ship Date", "ship_date_raw")
    .withColumnRenamed("Ship Mode", "ship_mode")
    .withColumnRenamed("Customer ID", "customer_id")
    .withColumnRenamed("Customer Name", "customer_name")
    .withColumnRenamed("Segment", "segment")
    .withColumnRenamed("Country", "country")
    .withColumnRenamed("City", "city")
    .withColumnRenamed("State", "state")
    .withColumnRenamed("Postal Code", "postal_code")
    .withColumnRenamed("Region", "region")
    .withColumnRenamed("Product ID", "product_id")
    .withColumnRenamed("Category", "category")
    .withColumnRenamed("Sub-Category", "sub_category")
    .withColumnRenamed("Product Name", "product_name")
    .withColumnRenamed("Sales", "sales")
    .withColumnRenamed("Quantity", "quantity")
    .withColumnRenamed("Discount", "discount")
    .withColumnRenamed("Profit", "profit")
    .withColumn("order_date", F.to_date("order_date_raw", "M/d/yyyy"))
    .withColumn("ship_date", F.to_date("ship_date_raw", "M/d/yyyy"))
    .withColumn("customer_name", F.initcap(F.trim("customer_name")))
    .withColumn("segment", F.initcap(F.trim("segment")))
    .withColumn("country", F.initcap(F.trim("country")))
    .withColumn("city", F.initcap(F.trim("city")))
    .withColumn("state", F.initcap(F.trim("state")))
    .withColumn("region", F.initcap(F.trim("region")))
    .withColumn("category", F.initcap(F.trim("category")))
    .withColumn("sub_category", F.initcap(F.trim("sub_category")))
    .withColumn("product_name", F.trim("product_name"))
)

dedupe_window = Window.partitionBy("order_id", "product_id", "row_id").orderBy(F.col("ingestion_timestamp").desc())
deduped = (
    standardized
    .withColumn("rn", F.row_number().over(dedupe_window))
    .filter(F.col("rn") == 1)
    .drop("rn")
)

valid_condition = (
    (F.col("sales") >= 0)
    & (F.col("quantity") > 0)
    & (F.col("ship_date") >= F.col("order_date"))
    & F.col("order_id").isNotNull()
    & F.col("product_id").isNotNull()
)

silver_orders = deduped.filter(valid_condition)
silver_rejected_orders = deduped.filter(~valid_condition)

silver_orders.write.format("delta").mode("overwrite").save(silver_path)
silver_rejected_orders.write.format("delta").mode("overwrite").save(rejected_path)

spark.sql("DROP TABLE IF EXISTS silver_orders")
spark.sql("DROP TABLE IF EXISTS silver_rejected_orders")
spark.sql(f"CREATE TABLE silver_orders USING DELTA LOCATION '{silver_path}'")
spark.sql(f"CREATE TABLE silver_rejected_orders USING DELTA LOCATION '{rejected_path}'")

# COMMAND ----------

# Task 3: Incremental Loading with MERGE
# Put daily CSV files under /FileStore/superstore_incremental/day_1.csv, day_2.csv, day_3.csv.
incremental_path = "/FileStore/superstore_incremental"

incremental_raw = (
    spark.read.option("header", True)
    .option("inferSchema", True)
    .csv(incremental_path)
    .withColumn("ingestion_timestamp", F.current_timestamp())
    .withColumn("source_file_name", F.input_file_name())
)

incremental_raw.createOrReplaceTempView("incoming_orders_raw")

spark.sql("""
CREATE OR REPLACE TEMP VIEW incoming_orders AS
SELECT
    `Row ID` AS row_id,
    `Order ID` AS order_id,
    `Order Date` AS order_date_raw,
    `Ship Date` AS ship_date_raw,
    to_date(`Order Date`, 'M/d/yyyy') AS order_date,
    to_date(`Ship Date`, 'M/d/yyyy') AS ship_date,
    initcap(trim(`Ship Mode`)) AS ship_mode,
    `Customer ID` AS customer_id,
    initcap(trim(`Customer Name`)) AS customer_name,
    initcap(trim(Segment)) AS segment,
    initcap(trim(Country)) AS country,
    initcap(trim(City)) AS city,
    initcap(trim(State)) AS state,
    `Postal Code` AS postal_code,
    initcap(trim(Region)) AS region,
    `Product ID` AS product_id,
    initcap(trim(Category)) AS category,
    initcap(trim(`Sub-Category`)) AS sub_category,
    trim(`Product Name`) AS product_name,
    Sales AS sales,
    Quantity AS quantity,
    Discount AS discount,
    Profit AS profit,
    ingestion_timestamp,
    source_file_name
FROM incoming_orders_raw
WHERE Sales >= 0
  AND Quantity > 0
  AND to_date(`Ship Date`, 'M/d/yyyy') >= to_date(`Order Date`, 'M/d/yyyy')
""")

spark.sql("""
MERGE INTO silver_orders AS target
USING incoming_orders AS source
ON target.order_id = source.order_id
   AND target.product_id = source.product_id
   AND target.row_id = source.row_id
WHEN MATCHED THEN UPDATE SET
    row_id = source.row_id,
    order_id = source.order_id,
    order_date_raw = source.order_date_raw,
    ship_date_raw = source.ship_date_raw,
    order_date = source.order_date,
    ship_date = source.ship_date,
    ship_mode = source.ship_mode,
    customer_id = source.customer_id,
    customer_name = source.customer_name,
    segment = source.segment,
    country = source.country,
    city = source.city,
    state = source.state,
    postal_code = source.postal_code,
    region = source.region,
    product_id = source.product_id,
    category = source.category,
    sub_category = source.sub_category,
    product_name = source.product_name,
    sales = source.sales,
    quantity = source.quantity,
    discount = source.discount,
    profit = source.profit,
    ingestion_timestamp = source.ingestion_timestamp,
    source_file_name = source.source_file_name
WHEN NOT MATCHED THEN INSERT (
    row_id,
    order_id,
    order_date_raw,
    ship_date_raw,
    order_date,
    ship_date,
    ship_mode,
    customer_id,
    customer_name,
    segment,
    country,
    city,
    state,
    postal_code,
    region,
    product_id,
    category,
    sub_category,
    product_name,
    sales,
    quantity,
    discount,
    profit,
    ingestion_timestamp,
    source_file_name
) VALUES (
    source.row_id,
    source.order_id,
    source.order_date_raw,
    source.ship_date_raw,
    source.order_date,
    source.ship_date,
    source.ship_mode,
    source.customer_id,
    source.customer_name,
    source.segment,
    source.country,
    source.city,
    source.state,
    source.postal_code,
    source.region,
    source.product_id,
    source.category,
    source.sub_category,
    source.product_name,
    source.sales,
    source.quantity,
    source.discount,
    source.profit,
    source.ingestion_timestamp,
    source.source_file_name
)
""")

# COMMAND ----------

# Task 4: Gold Layer
spark.sql("""
CREATE OR REPLACE TABLE gold_sales_daily AS
SELECT order_date AS date, ROUND(SUM(sales), 2) AS revenue
FROM silver_orders
GROUP BY order_date
""")

spark.sql("""
CREATE OR REPLACE TABLE gold_sales_region AS
SELECT region, ROUND(SUM(sales), 2) AS revenue
FROM silver_orders
GROUP BY region
""")

spark.sql("""
CREATE OR REPLACE TABLE gold_sales_category AS
SELECT category, ROUND(SUM(sales), 2) AS revenue
FROM silver_orders
GROUP BY category
""")

spark.sql("""
CREATE OR REPLACE TABLE gold_customer_metrics AS
SELECT
    customer_name AS customer,
    ROUND(SUM(sales), 2) AS revenue,
    COUNT(DISTINCT order_id) AS orders
FROM silver_orders
GROUP BY customer_name
""")

# COMMAND ----------

# Task 5: Analytics
spark.sql("""
SELECT product_name, ROUND(SUM(sales), 2) AS revenue
FROM silver_orders
GROUP BY product_name
ORDER BY revenue DESC
LIMIT 5
""").show(truncate=False)

spark.sql("""
SELECT region, ROUND(SUM(sales), 2) AS revenue
FROM silver_orders
GROUP BY region
ORDER BY revenue DESC
LIMIT 1
""").show(truncate=False)

spark.sql("""
SELECT date_trunc('month', order_date) AS month, ROUND(SUM(sales), 2) AS revenue
FROM silver_orders
GROUP BY date_trunc('month', order_date)
ORDER BY month
""").show(truncate=False)

spark.sql("""
SELECT
    order_date,
    ROUND(SUM(sales), 2) AS daily_revenue,
    ROUND(SUM(SUM(sales)) OVER (ORDER BY order_date), 2) AS running_revenue
FROM silver_orders
GROUP BY order_date
ORDER BY order_date
""").show(truncate=False)

spark.sql("""
WITH product_region_revenue AS (
    SELECT
        region,
        product_name,
        ROUND(SUM(sales), 2) AS revenue,
        ROW_NUMBER() OVER (PARTITION BY region ORDER BY SUM(sales) DESC) AS rn
    FROM silver_orders
    GROUP BY region, product_name
)
SELECT region, product_name, revenue
FROM product_region_revenue
WHERE rn = 1
ORDER BY region
""").show(truncate=False)

# COMMAND ----------

# Task 6: Performance Analysis
products_by_category = silver_orders.select("product_id", "product_name", "category").dropDuplicates(["product_id"])
orders_fact = silver_orders.select("order_id", "product_id", "sales", "quantity")

normal_join = orders_fact.join(products_by_category, "product_id")
normal_join.explain("formatted")

broadcast_join = orders_fact.join(F.broadcast(products_by_category), "product_id")
broadcast_join.explain("formatted")

# COMMAND ----------

# Optional dashboard source tables:
display(spark.table("gold_sales_region"))
display(spark.table("gold_sales_category"))
display(spark.sql("""
SELECT date_trunc('month', date) AS month, ROUND(SUM(revenue), 2) AS revenue
FROM gold_sales_daily
GROUP BY date_trunc('month', date)
ORDER BY month
"""))
