"""Central place for paths and table definitions.

Override locations with environment variables when needed (for example to put the
database on a scratch filesystem on the cluster):

    export OLIST_DATA_DIR=/path/to/brazilian-ecommerce
    export OLIST_DB_PATH=/scratch/.../olist.duckdb
"""
import os
from pathlib import Path

PROJECT_ROOT = Path(__file__).resolve().parents[2]

DATA_DIR = Path(
    os.environ.get(
        "OLIST_DATA_DIR",
        PROJECT_ROOT / "datasets" / "EXTRACTED" / "brazilian-ecommerce",
    )
)
DB_PATH = Path(os.environ.get("OLIST_DB_PATH", PROJECT_ROOT / "warehouse" / "olist.duckdb"))

# table name -> (csv file, {column: forced type})
# Zip-code prefixes must stay text, otherwise "01151" silently becomes 1151.
TABLES = {
    "customers": (
        "olist_customers_dataset.csv",
        {"customer_zip_code_prefix": "VARCHAR"},
    ),
    "geolocation": (
        "olist_geolocation_dataset.csv",
        {"geolocation_zip_code_prefix": "VARCHAR"},
    ),
    "order_items": ("olist_order_items_dataset.csv", {}),
    "order_payments": ("olist_order_payments_dataset.csv", {}),
    "order_reviews": (
        "olist_order_reviews_dataset.csv",
        {"review_comment_title": "VARCHAR", "review_comment_message": "VARCHAR"},
    ),
    "orders": ("olist_orders_dataset.csv", {}),
    "products": ("olist_products_dataset.csv", {}),
    "sellers": (
        "olist_sellers_dataset.csv",
        {"seller_zip_code_prefix": "VARCHAR"},
    ),
    "category_translation": ("product_category_name_translation.csv", {}),
}
