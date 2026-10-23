-- 01_joins.sql
-- Concept: combining tables through shared keys.
-- Run everything:   python -m olist sql sql/01_joins.sql
-- Run one query:    python -m olist sql sql/01_joins.sql -q 3

-- Q1: INNER JOIN. Orders with customer location. Rows without a match on both sides disappear.
SELECT o.order_id, o.order_status, c.customer_city, c.customer_state
FROM orders AS o
JOIN customers AS c ON c.customer_id = o.customer_id
LIMIT 5;

-- Q2: Row fan-out. One order has many items, so joining orders to items multiplies order rows.
SELECT
  (SELECT COUNT(*) FROM orders) AS order_rows,
  (SELECT COUNT(*) FROM orders AS o JOIN order_items AS i ON i.order_id = o.order_id) AS rows_after_join;

-- Q3: LEFT JOIN + IS NULL (anti-join). Orders that have no items at all, by status.
SELECT o.order_status, COUNT(*) AS orders_without_items
FROM orders AS o
LEFT JOIN order_items AS i ON i.order_id = o.order_id
WHERE i.order_id IS NULL
GROUP BY o.order_status
ORDER BY orders_without_items DESC;

-- Q4: Multi-table join. Revenue by English category name (translation table is LEFT joined so nothing is lost).
SELECT COALESCE(t.product_category_name_english, p.product_category_name, 'unknown') AS category,
       ROUND(SUM(i.price), 2) AS revenue,
       COUNT(DISTINCT i.order_id) AS orders
FROM order_items AS i
JOIN products AS p ON p.product_id = i.product_id
LEFT JOIN category_translation AS t ON t.product_category_name = p.product_category_name
GROUP BY 1
ORDER BY revenue DESC
LIMIT 10;

-- Q5: Fan-out trap. Joining items to payments repeats item prices once per payment row, inflating the sum.
SELECT
  (SELECT ROUND(SUM(price), 2) FROM order_items) AS correct_item_revenue,
  (SELECT ROUND(SUM(i.price), 2)
   FROM order_items AS i
   JOIN order_payments AS p ON p.order_id = i.order_id) AS inflated_by_join;

-- EXERCISES (write your own queries in a new file such as sql/my_01.sql)
-- E1: Average freight_value per customer_state (chain order_items, orders, customers).
-- E2: Orders that have payments but no items, or items but no payments (try FULL OUTER JOIN).
-- E3: Which sellers ship to the most distinct customer states?
