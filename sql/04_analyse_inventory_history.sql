

-- ==================================================
-- Daily detail: one row per date, SKU and warehouse
--    Previous observation, continuity, streak ID
--    and consecutive mismatch days up to each date
-- ==================================================


CREATE OR REPLACE VIEW inventory_history AS
WITH previous_observation AS (
    SELECT
        *,
        LAG(discrepancy_type) OVER (
            PARTITION BY sku, warehouse_id
            ORDER BY snapshot_date
        ) AS previous_discrepancy_type, 

        LAG(snapshot_date) OVER (
            PARTITION BY sku, warehouse_id
            ORDER BY snapshot_date
        ) AS previous_snapshot_date 
    FROM inventory_reconciliation
),

continuous_mismatch_days AS (
    SELECT
        *,
        CASE
            WHEN discrepancy_type <> 'MATCH'
            AND previous_discrepancy_type <> 'MATCH'
            AND snapshot_date - previous_snapshot_date = 1
                THEN 1
            ELSE 0
        END AS continuous_mismatch_flag
FROM previous_observation
),

start_flag_checked AS (
    SELECT
        *,
        CASE
            WHEN discrepancy_type <> 'MATCH'
            AND continuous_mismatch_flag = 0
                THEN 1
            ELSE 0
        END AS mismatch_start_flag
    FROM continuous_mismatch_days
),
mismatch_grouped AS (
    SELECT
        *,
        SUM(mismatch_start_flag) OVER (
            PARTITION BY sku, warehouse_id
            ORDER BY snapshot_date
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS mismatch_group_id
    FROM start_flag_checked
)
SELECT
    *,

    CASE
        WHEN discrepancy_type = 'MATCH' THEN 0
        ELSE COUNT(*) FILTER (
            WHERE discrepancy_type <> 'MATCH'
        ) OVER streak_window
    END AS streak_days,

    CASE
        WHEN discrepancy_type = 'MATCH' THEN NULL
        ELSE MIN(snapshot_date) FILTER (
            WHERE discrepancy_type <> 'MATCH'
        ) OVER streak_window
    END AS streak_start_date,

    CASE
        WHEN discrepancy_type = 'MATCH' THEN NULL
        ELSE MAX(snapshot_date) FILTER (
            WHERE discrepancy_type <> 'MATCH'
        ) OVER streak_window
    END AS streak_end_date
FROM mismatch_grouped

WINDOW streak_window AS (
    PARTITION BY sku, warehouse_id, mismatch_group_id
    ORDER BY snapshot_date
    ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
)

ORDER BY sku, warehouse_id, snapshot_date;

