"""Command line entry point:  python -m olist <command>"""
import argparse

from . import checks, load, runner


def main():
    parser = argparse.ArgumentParser(prog="olist")
    sub = parser.add_subparsers(dest="command", required=True)
    sub.add_parser("load", help="load the CSV files into DuckDB")
    sub.add_parser("check", help="run key and foreign-key checks")
    sql = sub.add_parser("sql", help="run a .sql file")
    sql.add_argument("file")
    sql.add_argument("-q", "--query", type=int, help="run only statement number N")
    args = parser.parse_args()

    if args.command == "load":
        load.load_all()
    elif args.command == "check":
        checks.run_checks()
    else:
        runner.run_file(args.file, args.query)


if __name__ == "__main__":
    main()
