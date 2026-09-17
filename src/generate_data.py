
from pathlib import Path

import numpy as np
import pandas as pd

# Basic settings

RANDOM_SEED = 42

START_DATE = "2026-09-01"
NUM_DAYS = 7

NUM_SKUS = 30

WAREHOUSES = ["WH01", "WH02"]

OUTPUT_DIR = Path("data/raw")



def inject_scenarios(
    erp_df: pd.DataFrame,
    wms_df: pd.DataFrame,
):
    """
    Inject predefined supply-chain discrepancy scenarios into ERP and WMS
    inventory data.

    The function starts from aligned baseline inventory data and deliberately
    introduces issues such as damaged stock not being synchronised,
    reservation delays, timing differences, and missing WMS records.

    Args:
        erp_df: ERP inventory snapshot data.
        wms_df: WMS inventory snapshot data.

    Returns:
        A tuple containing the modified ERP and WMS DataFrames.
    """

    erp_df = erp_df.copy()
    wms_df = wms_df.copy()

    # Scenario 1: DAMAGE_NOT_SYNCED
    damage_mask = (
        (wms_df["snapshot_date"] == pd.Timestamp("2026-09-02"))
        & (wms_df["sku"] == "BAT001")
        & (wms_df["warehouse_id"] == "WH01")
    )

    wms_df.loc[
        damage_mask,
        "damaged_qty"
    ] = 10

    # Scenario 2: RESERVATION_LAG
    reservation_mask = (
        (wms_df["snapshot_date"] == pd.Timestamp("2026-09-03"))
        & (wms_df["sku"] == "BAT002")
        & (wms_df["warehouse_id"] == "WH01")
    )

    wms_df.loc[
        reservation_mask,
        "reserved_qty"
    ] += 10

    # Scenario 3: TIMING_LAG
    timing_mask = (
        (erp_df["snapshot_date"] == pd.Timestamp("2026-09-04"))
        & (erp_df["sku"] == "BAT003")
        & (erp_df["warehouse_id"] == "WH02")
    )

    erp_df.loc[
        timing_mask,
        "on_hand_qty"
    ] += 20

    # Scenario 4: MISSING_WMS_RECORD
    missing_mask = (
        (wms_df["snapshot_date"] == pd.Timestamp("2026-09-05"))
        & (wms_df["sku"] == "BAT009")
        & (wms_df["warehouse_id"] == "WH01")
    )

    wms_df = wms_df.loc[
        ~missing_mask
    ].copy()

    return erp_df, wms_df






def generate_inventory_data():
    """
    Generate synthetic ERP and WMS inventory snapshots for reconciliation.

    Creates seven days of inventory data across multiple SKUs and warehouses.
    ERP and WMS records are initially generated from the same baseline inventory
    state, after which predefined discrepancy scenarios are injected to simulate
    realistic supply-chain data issues.

    The generated files are written to the raw data directory.

    Grain:
        One row represents one SKU at one warehouse for one snapshot date.
    """


    rng = np.random.default_rng(RANDOM_SEED)

    dates = pd.date_range(
        start=START_DATE,
        periods=NUM_DAYS,
        freq="D",
    )

    skus = [
        f"BAT{i:03d}"
        for i in range(1, NUM_SKUS + 1)
    ]

    erp_rows = []
    wms_rows = []

    for snapshot_date in dates:
        for sku in skus:
            for warehouse_id in WAREHOUSES:

                # Base physical inventory
                physical_qty = int(
                    rng.integers(40, 151)
                )

                # Some inventory has already been
                # committed/reserved for orders
                reserved_qty = int(
                    rng.integers(
                        0,
                        min(21, physical_qty + 1)
                    )
                )

                # First version:
                # ERP and WMS normally agree.
                # We will deliberately inject
                # discrepancies afterwards.
                erp_rows.append(
                    {
                        "snapshot_date": snapshot_date.date(),
                        "sku": sku,
                        "warehouse_id": warehouse_id,
                        "on_hand_qty": physical_qty,
                        "allocated_qty": reserved_qty,
                    }
                )

                wms_rows.append(
                    {
                        "snapshot_date": snapshot_date.date(),
                        "sku": sku,
                        "warehouse_id": warehouse_id,
                        "physical_qty": physical_qty,
                        "reserved_qty": reserved_qty,
                        "damaged_qty": 0,
                        "quarantine_qty": 0,
                    }
                )

    erp_df = pd.DataFrame(erp_rows)
    wms_df = pd.DataFrame(wms_rows)

    # Convert the ERP snapshot_date column to pandas datetime type
    erp_df["snapshot_date"] = pd.to_datetime(
        erp_df["snapshot_date"]
    )

    wms_df["snapshot_date"] = pd.to_datetime(
        wms_df["snapshot_date"]
    )

    # Inject test scenarios into the ERP and WMS inventory data
    erp_df, wms_df = inject_scenarios(
        erp_df,
        wms_df,
    )

    OUTPUT_DIR.mkdir(
        parents=True,
        exist_ok=True,
    )

    erp_df.to_csv(
        OUTPUT_DIR / "erp_inventory.csv",
        index=False,
    )

    wms_df.to_csv(
        OUTPUT_DIR / "wms_inventory.csv",
        index=False,
    )

    print(
        f"ERP inventory rows: {len(erp_df)}"
    )
    print(
        f"WMS inventory rows: {len(wms_df)}"
    )


if __name__ == "__main__":
    generate_inventory_data()
