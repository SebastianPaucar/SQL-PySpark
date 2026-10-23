"""Data-quality checks: duplicate keys and orphan foreign keys.

These report findings rather than fail, because real data is rarely perfect and
understanding WHY a key is duplicated or missing is part of learning joins.
"""
from .db import connect

KEYS = [
    ("orders", ["order_id"]),
    ("customers", ["customer_id"]),
    ("products", ["product_id"]),
    ("sellers", ["seller_id"]),
    ("order_items", ["order_id", "order_item_id"]),
    ("order_payments", ["order_id", "payment_sequential"]),
    ("order_reviews", ["review_id"]),
]

# (child table, child column, parent table, parent column)
FOREIGN_KEYS = [
    ("orders", "customer_id", "customers", "customer_id"),
    ("order_items", "order_id", "orders", "order_id"),
    ("order_items", "product_id", "products", "product_id"),
    ("order_items", "seller_id", "sellers", "seller_id"),
    ("order_payments", "order_id", "orders", "order_id"),
    ("order_reviews", "order_id", "orders", "order_id"),
    ("products", "product_category_name", "category_translation", "product_category_name"),
]


def duplicate_keys(con, table, cols):
    """Number of key values that appear more than once."""
    key = ", ".join(cols)
    sql = f"SELECT COUNT(*) FROM (SELECT 1 FROM {table} GROUP BY {key} HAVING COUNT(*) > 1)"
    return con.execute(sql).fetchone()[0]


def orphans(con, child, ccol, parent, pcol):
    """Child rows whose foreign key has no matching parent row."""
    sql = f"""
        SELECT COUNT(*) FROM {child} AS c
        LEFT JOIN {parent} AS p ON p.{pcol} = c.{ccol}
        WHERE c.{ccol} IS NOT NULL AND p.{pcol} IS NULL
    """
    return con.execute(sql).fetchone()[0]


def run_checks():
    con = connect()
    print("== Duplicate keys (0 means the key is unique) ==")
    for table, cols in KEYS:
        print(f"{table:<16} {'+'.join(cols):<32} duplicated: {duplicate_keys(con, table, cols):,}")
    print("\n== Orphan foreign keys (0 means every child row finds its parent) ==")
    for child, ccol, parent, pcol in FOREIGN_KEYS:
        left = f"{child}.{ccol}"
        right = f"{parent}.{pcol}"
        print(f"{left:<34} -> {right:<40} orphans: {orphans(con, child, ccol, parent, pcol):,}")
    con.close()


if __name__ == "__main__":
    run_checks()
