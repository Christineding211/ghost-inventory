
CREATE OR REPLACE VIEW inventory_operations_report AS
WITH period_summary AS (
    SELECT
        sku,
        warehouse_id,
        SUM(
            CASE
                WHEN discrepancy_type <> 'MATCH' THEN 1
                ELSE 0
            END
        ) AS mismatch_days_count,

        MIN(snapshot_date) FILTER (
            WHERE discrepancy_type <> 'MATCH'
        ) AS first_mismatch_date,

        MAX(snapshot_date) FILTER (
            WHERE discrepancy_type <> 'MATCH'
        ) AS last_mismatch_date

    FROM inventory_reconciliation
    WHERE snapshot_date BETWEEN DATE '2026-09-01'
                            AND DATE '2026-09-07'
    GROUP BY sku, warehouse_id
)

SELECT
    h.*,
    DATE '2026-09-01' AS analysis_start_date,
    DATE '2026-09-07' AS analysis_end_date,
    p.mismatch_days_count,
    p.first_mismatch_date,
    p.last_mismatch_date

FROM inventory_history AS h
LEFT JOIN period_summary AS p
    ON h.sku = p.sku
   AND h.warehouse_id = p.warehouse_id

WHERE h.snapshot_date BETWEEN DATE '2026-09-01'
                          AND DATE '2026-09-07';

--  investigate report
SELECT
    snapshot_date,
    sku,
    warehouse_id,
    source_status,
    discrepancy_type,
    streak_days,
    oversell_risk_qty,

    CASE
        WHEN source_status IN ('ERP_ONLY', 'WMS_ONLY') THEN 'P1'
        WHEN streak_days >= 2 THEN 'P1'
        WHEN oversell_risk_qty > 0 THEN 'P2'
        WHEN discrepancy_type <> 'MATCH' THEN 'P3'
        ELSE 'NO_ACTION'
    END AS investigation_priority,

    CASE
        WHEN source_status IN ('ERP_ONLY', 'WMS_ONLY')
            THEN 'Missing record in one source'
        WHEN streak_days >= 2
            THEN 'Mismatch observed on consecutive days'
        WHEN oversell_risk_qty > 0
            THEN 'ERP available quantity exceeds WMS'
        WHEN discrepancy_type <> 'MATCH'
            THEN 'Other inventory discrepancy'
        ELSE 'No discrepancy detected'
    END AS priority_reason

FROM inventory_operations_report;


