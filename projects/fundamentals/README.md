# SQL + PySpark practice project: Olist e-commerce

Learn joins, filters, window functions (`ROW_NUMBER`, `LAG`, partitions), subqueries/CTEs and indexes on a real dataset (Olist, about 100k orders from 2016 to 2018), then redo the same analysis in PySpark.

## Layout

```
datasets/EXTRACTED/brazilian-ecommerce/   the 9 CSVs
src/olist/
  config.py    paths and table definitions (override with OLIST_DATA_DIR / OLIST_DB_PATH)
  db.py        DuckDB connection
  load.py      CSV -> DuckDB tables
  checks.py    duplicate-key and orphan-foreign-key report
  runner.py    runs a .sql file statement by statement with timing
sql/
  01_joins.sql  02_filters_aggregations.sql  03_windows.sql
  04_subqueries_ctes.sql  05_indexes.sql
warehouse/     the generated olist.duckdb file
```

## Setup

```bash
pip install -r requirements.txt        # inside a venv or conda env on the cluster
export PYTHONPATH="$PWD/src"
export OLIST_DATA_DIR="/path/to/brazilian-ecommerce"
python -m olist load                   # builds warehouse/olist.duckdb
python -m olist check                  # understand keys before writing joins
python -m olist sql sql/01_joins.sql   # run a lesson (add -q 3 to run only statement 3)
```

If the home filesystem is slow or small, point the database elsewhere: `export OLIST_DB_PATH=/scratch/<your-path>/olist.duckdb`.

## How to use the lessons

Each file has numbered, commented queries and an EXERCISES block at the end. Read a query, predict the output, run it, then change it. Write your own solutions in new files (for example `sql/my_03.sql`), which the runner also accepts.

| Concept | File |
|---|---|
| Joins, fan-out, anti-joins | 01 |
| WHERE vs HAVING, NULLs, dates | 02 |
| ROW_NUMBER, PARTITION BY, LAG, running totals | 03 |
| Subqueries, EXISTS, correlated queries, CTEs | 04 |
| Indexes and query plans | 05 |

## Dataset gotchas worth knowing

* `customer_id` is generated per order. The real person is `customer_unique_id`.
* Orders can have several items, several payment rows and occasionally several reviews, so joining them carelessly inflates sums (see 01 Q5).
* Category names are Portuguese, `category_translation` has the English ones.
* Some columns are misspelled in the source (`product_name_lenght`). They are kept as is.
* Zip-code prefixes are loaded as text to keep leading zeros.

## Data Quality Findings

Initial checks using `python -m olist check` and `sql/06_data_quality_investigation.sql` identified the following issues.

### Duplicate review IDs

* `order_reviews` contains **99,224 rows** and **98,410 distinct `review_id` values**, or **814 rows beyond one row per distinct ID**.
* There are **789 `review_id` groups with duplicates**. Some IDs occur three or more times.
* The investigation found no duplicate-ID groups with conflicting non-null review scores, titles, or messages in the tested query. However, duplicate IDs can be associated with multiple orders, so they should not automatically be treated as redundant records.
* **Decision:** Keep the source records unchanged for now. Investigate the relationship between review IDs and orders further before choosing a deduplication rule.

### Missing product-category translations

* **13 products** have non-null Portuguese category names that are absent from `category_translation`:
  * `portateis_cozinha_e_preparadores_de_alimentos`: 10 products
  * `pc_gamer`: 3 products
* These are missing translation mappings, not necessarily missing product categories.
* **Decision:** Use a `LEFT JOIN` when adding English category names so these products are not dropped. Where needed, use `COALESCE` to fall back to the original Portuguese category name.

### Key and relationship checks

* No duplicate keys were found for the checked primary-key candidates in `orders`, `customers`, `products`, or `sellers`, or for the checked composite keys in `order_items` and `order_payments`.
* No orphan records were found in the checked relationships from orders, items, payments, and reviews to their referenced tables.
* The review-ID duplicates and missing category translations are exceptions that require further investigation rather than automatic data cleaning.

These findings are specific to the current source dataset and initial checks. The project retains the original data and documents anomalies rather than silently deleting or modifying records.

## About indexes in DuckDB

DuckDB is great for analytics but its indexing differs from PostgreSQL: indexes mostly speed up selective point lookups, and joins use hash joins regardless. Lesson 05 shows this on purpose.
For the classic B-tree experience, repeat that lesson in PostgreSQL or SQLite (exercise E3).

## Next phase: PySpark

Planned as `src/olist/spark/`: read the same CSVs into DataFrames, reproduce lessons 01 to 04 with `join`, `filter`, `groupBy` and `Window.partitionBy().orderBy()`, write Parquet, and compare against SQL on a larger generated dataset.
