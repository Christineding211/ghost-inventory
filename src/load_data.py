
import os
from pathlib import Path

import pandas as pd
from sqlalchemy import create_engine, text


# 1. Database connection
# --------------------------------------------------

DB_URL = os.environ["INVENTORY_DB_URL"]


# 2. File paths
# --------------------------------------------------

BASE_DIR = Path(__file__).resolve().parent.parent

SQL_FILE = BASE_DIR / "sql" / "01_create_tables.sql"
ERP_CSV = BASE_DIR / "data" / "raw" / "erp_inventory.csv"
WMS_CSV = BASE_DIR / "data" / "raw" / "wms_inventory.csv"


def main():
    """
    Create raw inventory tables and load ERP/WMS CSV data.
    """

    # Create a connection manager for PostgreSQL.
    engine = create_engine(DB_URL)

    # Read the SQL used to create the raw tables.
    create_tables_sql = SQL_FILE.read_text(
        encoding="utf-8"
    )

    # Read the two CSV files into pandas DataFrames.
    erp_df = pd.read_csv(
        ERP_CSV,
        parse_dates=["snapshot_date"],
    )

    wms_df = pd.read_csv(
        WMS_CSV,
        parse_dates=["snapshot_date"],
    )

    print("Creating tables and loading data...")

    # Everything inside this block belongs to one transaction.
    with engine.begin() as conn:

        # Create the tables if they do not already exist.
        conn.execute(
            text(create_tables_sql)
        )

        # Remove data from the previous run.
        conn.execute(
            text(
                """
                TRUNCATE TABLE
                    raw_erp_inventory,
                    raw_wms_inventory;
                """
            )
        )

        # Load ERP data.
        erp_df.to_sql(
            name="raw_erp_inventory",
            con=conn,
            if_exists="append",
            index=False,
        )

        # Load WMS data.
        wms_df.to_sql(
            name="raw_wms_inventory",
            con=conn,
            if_exists="append",
            index=False,
        )

        # Count the rows loaded into PostgreSQL.
        erp_count = conn.execute(
            text(
                "SELECT COUNT(*) FROM raw_erp_inventory"
            )
        ).scalar_one()

        wms_count = conn.execute(
            text(
                "SELECT COUNT(*) FROM raw_wms_inventory"
            )
        ).scalar_one()

    # Close the connections managed by the engine.
    engine.dispose()

    print("Data loading completed!")
    print(f"ERP CSV rows: {len(erp_df)}")
    print(f"ERP database rows: {erp_count}")
    print(f"WMS CSV rows: {len(wms_df)}")
    print(f"WMS database rows: {wms_count}")


if __name__ == "__main__":
    main()