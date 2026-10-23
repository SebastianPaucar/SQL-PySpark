-- 03_windows.sql
-- Concept: window functions. They compute per-group values WITHOUT collapsing rows.
-- Remember: customer_id is per ORDER, customer_unique_id is the real person.

-- Q1: ROW_NUMBER + PARTITION BY. Latest order per person. The CTE is needed because WHERE cannot see window results.
WITH orders_by_person AS (
  SELECT c.customer_unique_id,
         o.order_id,
         o.order_purchase_timestamp,
         ROW_NUMBER() OVER (
           PARTITION BY c.customer_unique_id
           ORDER BY o.order_purchase_timestamp DESC
         ) AS rn
  FROM orders AS o
  JOIN customers AS c ON c.customer_id = o.customer_id
)
SELECT customer_unique_id, order_id, order_purchase_timestamp
FROM orders_by_person
WHERE rn = 1
LIMIT 10;

-- Q2: Same result with DuckDB's QUALIFY shortcut (filters on a window result without a CTE).
SELECT c.customer_unique_id, o.order_id, o.order_purchase_timestamp
FROM orders AS o
JOIN customers AS c ON c.customer_id = o.customer_id
QUALIFY ROW_NUMBER() OVER (
  PARTITION BY c.customer_unique_id
  ORDER BY o.order_purchase_timestamp DESC
) = 1
LIMIT 10;

-- Q3: Top 3 products by revenue within each category (two sample categories to keep output short).
WITH product_revenue AS (
  SELECT p.product_category_name AS category,
         i.product_id,
         SUM(i.price) AS revenue
  FROM order_items AS i
  JOIN products AS p ON p.product_id = i.product_id
  GROUP BY 1, 2
),
ranked AS (
  SELECT *, ROW_NUMBER() OVER (PARTITION BY category ORDER BY revenue DESC) AS rn
  FROM product_revenue
)
SELECT category, product_id, ROUND(revenue, 2) AS revenue, rn
FROM ranked
WHERE rn <= 3
  AND category IN ('beleza_saude', 'informatica_acessorios')
ORDER BY category, rn;

-- Q4: LAG compares a row with the previous row in its partition. Days since a person's previous order (repeat buyers only).
WITH person_orders AS (
  SELECT c.customer_unique_id, o.order_id, o.order_purchase_timestamp AS purchased_at
  FROM orders AS o
  JOIN customers AS c ON c.customer_id = o.customer_id
)
SELECT customer_unique_id,
       order_id,
       purchased_at,
       LAG(purchased_at) OVER w AS previous_purchase,
       date_diff('day', LAG(purchased_at) OVER w, purchased_at) AS days_since_previous
FROM person_orders
WHERE customer_unique_id IN (
  SELECT customer_unique_id FROM person_orders GROUP BY customer_unique_id HAVING COUNT(*) > 1
)
WINDOW w AS (PARTITION BY customer_unique_id ORDER BY purchased_at)
ORDER BY customer_unique_id, purchased_at
LIMIT 20;

-- Q5: Running total and month-over-month change of delivered revenue (aggregate first, then window).
WITH monthly AS (
  SELECT date_trunc('month', o.order_purchase_timestamp)::DATE AS month,
         SUM(i.price) AS revenue
  FROM orders AS o
  JOIN order_items AS i ON i.order_id = o.order_id
  WHERE o.order_status = 'delivered'
  GROUP BY 1
)
SELECT month,
       ROUND(revenue, 2) AS revenue,
       ROUND(SUM(revenue) OVER (ORDER BY month), 2) AS running_revenue,
       ROUND(100.0 * (revenue - LAG(revenue) OVER (ORDER BY month))
             / LAG(revenue) OVER (ORDER BY month), 1) AS mom_pct
FROM monthly
ORDER BY month;

-- Q6: A window over an aggregate. Share of orders per payment type, using SUM(COUNT(*)) OVER ().
SELECT payment_type,
       COUNT(*) AS payments,
       ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 2) AS pct_of_payments
FROM order_payments
GROUP BY payment_type
ORDER BY payments DESC;

-- EXERCISES
-- E1: Show RANK, DENSE_RANK and ROW_NUMBER side by side for states ordered by number of orders, then for review scores (ties!).
-- E2: NTILE(4) quartiles of order value (sum of item prices per order).
-- E3: 7-day moving average of daily orders using ROWS BETWEEN 6 PRECEDING AND CURRENT ROW.
