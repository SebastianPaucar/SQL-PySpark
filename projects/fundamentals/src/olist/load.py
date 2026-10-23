"""Load the nine Olist CSV files into DuckDB tables."""
from .config import DATA_DIR, TABLES
from .db import connect


def load_all(data_dir=DATA_DIR):
    con = connect()
    for table, (filename, type_overrides) in TABLES.items():
        csv_path = data_dir / filename
        if not csv_path.exists():
            raise FileNotFoundError(f"Missing {csv_path}. Set OLIST_DATA_DIR?")
        # sample_size=-1 makes DuckDB read every row when guessing column types
        con.execute(
            f"""
            CREATE OR REPLACE TABLE {table} AS
            SELECT * FROM read_csv('{csv_path}', header = true,
                                   sample_size = -1, types = {type_overrides})
            """
        )
        n = con.execute(f"SELECT COUNT(*) FROM {table}").fetchone()[0]
        print(f"loaded {table:<22} {n:>10,} rows")
    con.close()


if __name__ == "__main__":
    load_all()
