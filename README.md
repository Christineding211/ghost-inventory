
## Running the Inventory SQL Scripts

Run the scripts in the `sql/` directory in the order shown below. After running `01_create_tables.sql`, load the ERP and WMS inventory data into PostgreSQL before running scripts `02` to `05`.

| Order | Script | Purpose |
| --- | --- | --- |
| 1 | `01_create_tables.sql` | Creates the raw ERP and WMS inventory tables. |
| 2 | `02_reconcile_inventory.sql` | Runs a basic reconciliation query to compare ERP and WMS inventory quantities. |
| 3 | `03_classified_possible_problem.sql` | Creates the `inventory_reconciliation` view with discrepancy classifications, possible causes, positive differences in ERP availability, and separate flags for physical and available quantity mismatches. |
| 4 | `04_analyse_inventory_history.sql` | Creates the `inventory_history` view, which calculates consecutive mismatch days for each SKU and warehouse up to each observation date. |
| 5 | `05_inventory_operations_report.sql` | Creates the `inventory_operations_report` view by joining daily inventory history with the `period_summary` results. The script ends with a query that assigns investigation priorities and explains each assignment. |

The demonstration report covers **1 to 7 September 2026**, inclusive. For each SKU and warehouse, `period_summary` calculates the number of mismatch days and the first and most recent mismatch dates within that period.

The period summary appears on every daily row for the same SKU and warehouse. When aggregating `mismatch_days_count` across the report, count each SKU and warehouse combination once to avoid double counting.

The final `SELECT` in `05_inventory_operations_report.sql` calculates `investigation_priority` and `priority_reason`. These columns are available in the results of that query.