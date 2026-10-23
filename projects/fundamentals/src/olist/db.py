"""Database connection helper (DuckDB)."""
from .config import DB_PATH


def connect(path=None):
    """Open (and create if needed) the project database file."""
    import duckdb  # imported lazily so other modules can be tested without it

    target = path or DB_PATH
    target.parent.mkdir(parents=True, exist_ok=True)
    return duckdb.connect(str(target))
