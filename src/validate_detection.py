from pathlib import Path

import pandas as pd

PROJECT_ROOT = Path(__file__).resolve().parents[1]

KEYS = ["snapshot_date", "sku", "warehouse_id"]

# Map injected scenarios to the expected SQL reason labels.
REASON_MAPPING = {
    "DAMAGE_NOT_SYNCED": "POSSIBLE_DAMAGE_SYNC_ISSUE",
    "RESERVATION_LAG": "POSSIBLE_RESERVATION_SYNC_ISSUE",
    "TIMING_LAG": "POSSIBLE_TIMING_OR_PHYSICAL_SYNC_ISSUE",
    "MISSING_WMS_RECORD": "MISSING_RECORD_OR_INTEGRATION_ISSUE",
}


truth_df = pd.read_csv(
    PROJECT_ROOT / "data/reference/ground_truth_reason.csv",
    parse_dates=["snapshot_date"],
    dtype={
        "sku": "string",
        "warehouse_id": "string"
    }
)

detected_df = pd.read_csv(
    PROJECT_ROOT / "data/output/detected_discrepancies.csv",
    parse_dates=["snapshot_date"],
    dtype={
        "sku": "string",
        "warehouse_id": "string"
    }
)

# Exclude NORMAL rows so the truth set contains only injected discrepancies.
truth_df = truth_df[truth_df["true_reason"] != "NORMAL"].copy()

# Keep records from either dataset, matching by snapshot date, SKU, and warehouse.

compared_df = truth_df.merge(
    detected_df,
    on=KEYS,
    how="outer",
    validate="one_to_one",
    indicator=True
)


# Interpret merge(confusion matrix): both sides means a true positive; 
# a missed discrepancy (false negative); detected only means a false positive.
detection_labels = {
    "both": "TP",
    "left_only": "FN",
    "right_only": "FP",
}

compared_df["detection_result"] = compared_df["_merge"].map(
    detection_labels
)

# Compare reason labels only for records present in both datasets.
# discrepancy can still have a missing or incorrect reason.
# 1. Matching records have both a ground-truth scenario and a detected result
# 2. Check for missing values before comparing the actual and expected labels.
# 3. Only an exact match with the mapped SQL label counts as a correct reason.
# 4. Truth-only rows lack a detected result, and detected-only rows lack a
# ground-truth discrepancy; neither has the paired data needed for comparison.




reason_results = []

for index, row in compared_df.iterrows():
    
    if row["_merge"] == "both":
        expected = REASON_MAPPING[row["true_reason"]]
        actual = row["possible_reason"]

        if pd.isna(actual):
            reason_results.append("mismatched")
        elif actual == expected:
            reason_results.append("matched")
        else: 
            reason_results.append("mismatched")
    else:
        reason_results.append("cannot_compare")

compared_df["reason_result"] = reason_results

print(
    compared_df[
        [
            "snapshot_date",
            "sku",
            "warehouse_id",
            "_merge",
            "detection_result",
            "true_reason",
            "possible_reason",
            "reason_result",
        ]
    ].to_string(index=False)
)

print("\nReason comparison summary:")
print(compared_df["reason_result"].value_counts())
