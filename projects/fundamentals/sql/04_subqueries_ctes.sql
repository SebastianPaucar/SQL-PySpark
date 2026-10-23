-- 04_subqueries_ctes.sql
-- Concept: queries inside queries (scalar, IN, EXISTS, correlated) and CTEs for readability.

-- Q1: Scalar subquery. Items priced above the overall average item price.
SELECT order_id, product_id, price
FROM order_items
WHERE price > (SELECT AVG(price) FROM order_items)
ORDER BY price DESC
LIMIT 5;

-- Q2: IN subquery. Orders that received at least one 1-star review.
SELECT COUNT(*) AS orders_with_one_star
FROM orders
WHERE order_id IN (SELECT order_id FROM order_reviews WHERE review_score = 1);

-- Q3: NOT EXISTS. Delivered orders that never received a review.
SELECT COUNT(*) AS delivered_without_review
FROM orders AS o
WHERE o.order_status = 'delivered'
  AND NOT EXISTS (SELECT 1 FROM order_reviews AS r WHERE r.order_id = o.order_id);

-- Q4: Correlated subquery. Items priced above the average of THEIR OWN category (the inner query depends on the outer row).
SELECT i.order_id, i.product_id, p.product_category_name, i.price
FROM order_items AS i
JOIN products AS p ON p.product_id = i.product_id
WHERE i.price > (
  SELECT AVG(i2.price)
  FROM order_items AS i2
  JOIN products AS p2 ON p2.product_id = i2.product_id
  WHERE p2.product_category_name = p.product_category_name
)
LIMIT 10;

-- Q5: Same idea as Q4 with a window function instead of a correlated subquery. Compare readability and timing.
WITH priced AS (
  SELECT i.order_id, i.product_id, p.product_category_name, i.price,
         AVG(i.price) OVER (PARTITION BY p.product_category_name) AS category_avg
  FROM order_items AS i
  JOIN products AS p ON p.product_id = i.product_id
)
SELECT order_id, product_id, product_category_name, price
FROM priced
WHERE price > category_avg
LIMIT 10;

-- Q6: Chained CTEs. Seller scorecard. Reviews are averaged per order FIRST (some orders have several reviews), which keeps the grain right.
WITH seller_revenue AS (
  SELECT seller_id, COUNT(DISTINCT order_id) AS orders, SUM(price) AS revenue
  FROM order_items
  GROUP BY seller_id
),
order_score AS (
  SELECT order_id, AVG(review_score) AS score
  FROM order_reviews
  GROUP BY order_id
),
seller_score AS (
  SELECT s.seller_id, AVG(os.score) AS avg_score
  FROM (SELECT DISTINCT seller_id, order_id FROM order_items) AS s
  JOIN order_score AS os ON os.order_id = s.order_id
  GROUP BY s.seller_id
)
SELECT r.seller_id,
       r.orders,
       ROUND(r.revenue, 2) AS revenue,
       ROUND(sc.avg_score, 2) AS avg_score
FROM seller_revenue AS r
LEFT JOIN seller_score AS sc ON sc.seller_id = r.seller_id
WHERE r.orders >= 50
ORDER BY r.revenue DESC
LIMIT 10;

-- EXERCISES
-- E1: Products that were never sold (try both NOT EXISTS and LEFT JOIN ... IS NULL, compare).
-- E2: Sellers whose average review score is below the global average review score (scalar subquery).
-- E3: Rewrite Q6 so seller late-delivery percentage is included as one more CTE.
