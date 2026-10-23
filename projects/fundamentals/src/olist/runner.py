"""Run the statements of a .sql file one by one and print results.

File conventions:
  * statements are separated by a semicolon (so never put one inside a comment)
  * the comment block directly above a statement is its title
  * comment-only blocks (for example exercises) are skipped
"""
from pathlib import Path
from time import perf_counter

from .db import connect


def parse_sql_file(text):
    """Return a list of (title, sql) pairs."""
    parsed = []
    for chunk in text.split(";"):
        title_lines, sql_lines, in_sql = [], [], False
        for line in chunk.splitlines():
            stripped = line.strip()
            if not in_sql:
                if stripped.startswith("--"):
                    title_lines.append(stripped.lstrip("- ").strip())
                    continue
                if not stripped:
                    title_lines = []  # a blank line ends any earlier comment block
                    continue
                in_sql = True
            sql_lines.append(line)
        sql = "\n".join(sql_lines).strip()
        if sql:
            parsed.append((" ".join(title_lines), sql))
    return parsed


def run_file(path, only=None):
    statements = parse_sql_file(Path(path).read_text())
    con = connect()
    for n, (title, sql) in enumerate(statements, start=1):
        if only is not None and n != only:
            continue
        print(f"\n[{n}] {title}")
        start = perf_counter()
        if sql.upper().startswith("EXPLAIN"):
            for _key, plan in con.execute(sql).fetchall():
                print(plan)
        else:
            relation = con.sql(sql)  # None for statements like CREATE or DROP
            if relation is not None:
                relation.show()
        print(f"-- {perf_counter() - start:.3f}s")
    con.close()
