-- ==================================================
-- 1. Period summary: one row per SKU and warehouse
--    Mismatch days and first/latest mismatch dates
-- ==================================================


SELECT 
    sku,
    warehouse_id,
    SUM(
        CASE
            WHEN discrepancy_type <> 'MATCH'THEN 1
            ELSE 0
        END
    ) AS mismatch_days_count,
    MIN(snapshot_date) FILTER (WHERE discrepancy_type <> 'MATCH') AS first_mismatch_date,
    MAX(snapshot_date) FILTER (WHERE discrepancy_type <> 'MATCH') AS last_mismatch_date
FROM inventory_reconciliation
WHERE snapshot_date BETWEEN '2026-09-01' AND '2026-09-07'
GROUP BY sku, warehouse_id;