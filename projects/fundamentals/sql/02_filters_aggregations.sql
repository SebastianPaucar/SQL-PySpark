-- 02_filters_aggregations.sql
-- Concept: WHERE vs HAVING, GROUP BY, NULL behaviour, dates.

-- Q1: WHERE filters rows BEFORE grouping. Delivered orders per month.
SELECT date_trunc('month', order_purchase_timestamp)::DATE AS month,
       COUNT(*) AS orders
FROM orders
WHERE order_status = 'delivered'
GROUP BY 1
ORDER BY 1;

-- Q2: HAVING filters groups AFTER aggregation. States with more than 1000 orders.
SELECT c.customer_state, COUNT(*) AS orders
FROM orders AS o
JOIN customers AS c ON c.customer_id = o.customer_id
GROUP BY c.customer_state
HAVING COUNT(*) > 1000
ORDER BY orders DESC;

-- Q3: COUNT(*) counts rows but COUNT(column) skips NULLs. Missing delivery dates by status.
SELECT order_status,
       COUNT(*) AS total_orders,
       COUNT(order_delivered_customer_date) AS with_delivery_date,
       COUNT(*) - COUNT(order_delivered_customer_date) AS missing_delivery_date
FROM orders
GROUP BY order_status
ORDER BY total_orders DESC;

-- Q4: Conditional aggregation. Share of delivered orders that arrived after the estimated date.
SELECT COUNT(*) AS delivered_orders,
       SUM(CASE WHEN order_delivered_customer_date > order_estimated_delivery_date THEN 1 ELSE 0 END) AS late_orders,
       ROUND(100.0 * SUM(CASE WHEN order_delivered_customer_date > order_estimated_delivery_date THEN 1 ELSE 0 END)
             / COUNT(*), 2) AS pct_late
FROM orders
WHERE order_status = 'delivered'
  AND order_delivered_customer_date IS NOT NULL;

-- Q5: WHERE + GROUP BY + HAVING together. Slowest states by average days from purchase to delivery.
SELECT c.customer_state,
       COUNT(*) AS delivered_orders,
       ROUND(AVG(date_diff('day', o.order_purchase_timestamp, o.order_delivered_customer_date)), 1) AS avg_days
FROM orders AS o
JOIN customers AS c ON c.customer_id = o.customer_id
WHERE o.order_status = 'delivered'
  AND o.order_delivered_customer_date IS NOT NULL
GROUP BY c.customer_state
HAVING COUNT(*) >= 100
ORDER BY avg_days DESC
LIMIT 10;

-- EXERCISES
-- E1: Percentage of orders per order_status.
-- E2: Average hours between purchase and approval, per month.
-- E3: Product categories (English names) whose average review score is below 4 with at least 200 reviews.
