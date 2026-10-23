-- A. Investigate duplicate review IDs
-- Check whether duplicate IDs correspond to repeated rows or different records.

SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT review_id) AS distinct_review_ids,
    COUNT(*) - COUNT(DISTINCT review_id) AS extra_rows
FROM order_reviews;

-- Inspect review IDs that occur more than once.
SELECT
    review_id,
    COUNT(*) AS occurrences,
    COUNT(DISTINCT order_id) AS distinct_orders
FROM order_reviews
GROUP BY review_id
HAVING COUNT(*) > 1
ORDER BY occurrences DESC
LIMIT 20;

-- Checks whether records sharing an ID also share the same review content and timestamps
SELECT
    review_id,
    COUNT(*) AS row_count,
    COUNT(DISTINCT order_id) AS distinct_orders,
    COUNT(DISTINCT review_score) AS distinct_scores,
    COUNT(DISTINCT review_comment_title) AS distinct_titles,
    COUNT(DISTINCT review_comment_message) AS distinct_messages,
    COUNT(DISTINCT review_creation_date) AS distinct_creation_dates,
    COUNT(DISTINCT review_answer_timestamp) AS distinct_answer_times
FROM order_reviews
GROUP BY review_id
HAVING COUNT(*) > 1
ORDER BY row_count DESC, review_id
LIMIT 20;

-- Find duplicate review IDs with conflicting review attributes.
SELECT
    review_id,
    COUNT(*) AS row_count,
    COUNT(DISTINCT order_id) AS distinct_orders,
    COUNT(DISTINCT review_score) AS distinct_scores,
    COUNT(DISTINCT review_comment_title) AS distinct_titles,
    COUNT(DISTINCT review_comment_message) AS distinct_messages
FROM order_reviews
GROUP BY review_id
HAVING COUNT(*) > 1
   AND (
       COUNT(DISTINCT review_score) > 1
       OR COUNT(DISTINCT review_comment_title) > 1
       OR COUNT(DISTINCT review_comment_message) > 1
   )
ORDER BY row_count DESC
LIMIT 20;

-- Compare the records associated with duplicate review IDs.
SELECT *
FROM order_reviews
WHERE review_id IN (
    SELECT review_id
    FROM order_reviews
    GROUP BY review_id
    HAVING COUNT(*) > 1
)
ORDER BY review_id
LIMIT 50;


-- B. Investigate product categories missing from the translation table
SELECT
    p.product_category_name,
    COUNT(*) AS product_count
FROM products AS p
LEFT JOIN category_translation AS t
    ON p.product_category_name = t.product_category_name
WHERE p.product_category_name IS NOT NULL
  AND t.product_category_name IS NULL
GROUP BY p.product_category_name
ORDER BY product_count DESC;
