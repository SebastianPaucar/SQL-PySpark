-- 05_indexes.sql
-- Concept: indexes and query plans. Read the timing printed after each statement.
-- DuckDB uses ART indexes. They help selective point lookups, but they are NOT used by hash joins
-- and DuckDB already skips data blocks automatically using min/max statistics. This differs from
-- PostgreSQL, where B-tree indexes also help joins and range scans. See the README.

-- Q1: Clean start so the file can be re-run.
DROP INDEX IF EXISTS idx_items_order_id;

-- Q2: Baseline. Point lookup WITHOUT an index. Look for a sequential scan in the plan.
EXPLAIN ANALYZE
SELECT * FROM order_items WHERE order_id = '00010242fe8c5a6d1ba2dd792cb16214';

-- Q3: Create the index.
CREATE INDEX idx_items_order_id ON order_items (order_id);

-- Q4: Same lookup WITH the index. Compare the plan and timing against Q2 (an index scan should appear).
EXPLAIN ANALYZE
SELECT * FROM order_items WHERE order_id = '00010242fe8c5a6d1ba2dd792cb16214';

-- Q5: A join over the whole table. Notice the plan still uses a hash join, so the index does not help here.
EXPLAIN ANALYZE
SELECT COUNT(*)
FROM orders AS o
JOIN order_items AS i ON i.order_id = o.order_id;

-- Q6: Clean up.
DROP INDEX idx_items_order_id;

-- EXERCISES
-- E1: Add a composite index on order_payments (order_id, payment_sequential) and test a lookup on both columns.
-- E2: Filter on a column that has no index (for example seller_id) and compare timing with an indexed filter.
-- E3: Repeat this experiment in SQLite or PostgreSQL and compare how B-tree indexes behave on joins.
