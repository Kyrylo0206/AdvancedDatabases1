# Assignment 3: Build a Production-Style Lakehouse Pipeline in Databricks

## Objective

Design and implement a simple Lakehouse architecture using Databricks Free Edition and Delta tables.

---

## Dataset

Use the [Superstore dataset](https://www.kaggle.com/datasets/vivek468/superstore-dataset-final).

---

## Architecture

```text
Raw Files
    ↓
Bronze
    ↓
Silver
    ↓
Gold
    ↓
Analytics
```

---

## Task 1 — Bronze Layer

Create a Delta table:

```text
bronze_orders
```

Requirements:

* Load CSV files
* Add `ingestion_timestamp`
* Add `source_file_name`
* Save as Delta

---

## Task 2 — Silver Layer

Create:

```text
silver_orders
```

Requirements:

* Remove duplicates using `ROW_NUMBER()`
* Standardize text fields
* Validate data:

    * sales >= 0
    * quantity > 0
    * ship_date >= order_date
* Store invalid records in:

```text
silver_rejected_orders
```

---

## Task 3 — Incremental Loading

Simulate daily loads:

```text
day_1.csv
day_2.csv
day_3.csv
```

Requirements:

* Load new data incrementally
* Prevent duplicates using:

```sql
MERGE INTO
```

---

## Task 4 — Gold Layer

Create the following tables:

### gold_sales_daily

| date | revenue |

### gold_sales_region

| region | revenue |

### gold_sales_category

| category | revenue |

### gold_customer_metrics

| customer | revenue | orders |

---

## Task 5 — Analytics

Using Spark SQL:

1. Top 5 products by revenue
2. Top region by revenue
3. Monthly revenue trend
4. Running revenue total
5. Top product per region

Use:

```sql
ROW_NUMBER()
LAG()
SUM() OVER()
```

---

## Task 6 — Performance Analysis

For at least one transformation:

* Review execution plan
* Explain:

    * Shuffle
    * Exchange
    * Broadcast Join
* Optimize one join using:

```python
broadcast()
```

### Tips for Performance Analysis

| Term              | Meaning                                                                 |
| ----------------- | ----------------------------------------------------------------------- |
| Shuffle           | Data movement between executors                                         |
| Exchange          | Physical plan operation that triggers a shuffle                         |
| Broadcast Join    | Replicates a small table to all executors for a faster join             |
| SortMergeJoin     | Standard join for large tables that requires a shuffle                  |
| BroadcastHashJoin | Optimized join that avoids large shuffles by broadcasting a small table |


---

## Task 7 — Documentation

Provide:

* Architecture diagram
* Data flow description
* Data quality rules
* Assumptions
* Limitations

---

## Bonus — Dashboard

Create a dashboard with at least:

* Revenue by Region
* Revenue by Category
* Monthly Revenue Trend

---

# Grading

| Task                 |   Points |
| -------------------- | -------: |
| Bronze Layer         |      2.0 |
| Silver Layer         |      3.0 |
| Incremental Loading  |      3.0 |
| Gold Layer           |      2.5 |
| Analytics            |      2.0 |
| Performance Analysis |      1.5 |
| Documentation        |      1.0 |
| **Subtotal**         | **15.0** |
| Dashboard (Bonus)    |      2.5 |
| **Total**            | **17.5** |

```

**Submission:** Databricks notebook(s), SQL queries, screenshots, and documentation.
```
