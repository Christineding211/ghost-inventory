
CREATE OR REPLACE VIEW inventory_reconciliation AS
WITH erp AS (
    SELECT
        snapshot_date,
        sku,
        warehouse_id,
        on_hand_qty,
        allocated_qty,
        on_hand_qty - allocated_qty AS erp_available_qty
    FROM raw_erp_inventory
),

wms AS (
    SELECT
        snapshot_date,
        sku,
        warehouse_id,
        physical_qty,
        reserved_qty,
        damaged_qty,
        quarantine_qty,
        physical_qty
            - reserved_qty
            - damaged_qty
            - quarantine_qty
            AS wms_available_qty
    FROM raw_wms_inventory
),

joined_inventory AS (
    SELECT
        COALESCE(
            erp.snapshot_date,
            wms.snapshot_date
        ) AS snapshot_date,

        COALESCE(
            erp.sku,
            wms.sku
        ) AS sku,

        COALESCE(
            erp.warehouse_id,
            wms.warehouse_id
        ) AS warehouse_id,

        erp.on_hand_qty
            AS erp_on_hand_qty,

        wms.physical_qty
            AS wms_physical_qty,

        erp.allocated_qty
            AS erp_allocated_qty,

        wms.reserved_qty
            AS wms_reserved_qty,

        wms.damaged_qty
            AS wms_damaged_qty,

        wms.quarantine_qty
            AS wms_quarantine_qty,

        erp.erp_available_qty,
        wms.wms_available_qty

    FROM erp
    FULL OUTER JOIN wms
        ON erp.snapshot_date = wms.snapshot_date
        AND erp.sku = wms.sku
        AND erp.warehouse_id = wms.warehouse_id
),

calculated_inventory AS (
    SELECT
        *,

        CASE
            WHEN erp_on_hand_qty IS NULL
                THEN 'WMS_ONLY'

            WHEN wms_physical_qty IS NULL
                THEN 'ERP_ONLY'

            ELSE 'BOTH'
        END AS source_status,

        CASE
            WHEN erp_on_hand_qty IS NOT NULL
             AND wms_physical_qty IS NOT NULL
                THEN erp_on_hand_qty - wms_physical_qty

            ELSE NULL
        END AS physical_diff,


        CASE
            WHEN erp_available_qty IS NOT NULL
             AND wms_available_qty IS NOT NULL
                THEN erp_available_qty - wms_available_qty

            ELSE NULL
        END AS available_diff

    FROM joined_inventory
),

classified_inventory AS (
    SELECT
        *,

        CASE
            WHEN source_status = 'ERP_ONLY'
                THEN 'ERP_ONLY'

            WHEN source_status = 'WMS_ONLY'
                THEN 'WMS_ONLY'

            WHEN physical_diff <> 0
                THEN 'PHYSICAL_MISMATCH'

            WHEN available_diff <> 0
                THEN 'AVAILABILITY_MISMATCH'

            ELSE 'MATCH'
        END AS discrepancy_type,

        CASE
            WHEN source_status = 'ERP_ONLY'
                THEN 'MISSING_RECORD_OR_INTEGRATION_ISSUE'

            WHEN source_status = 'WMS_ONLY'
                THEN 'MISSING_RECORD_OR_INTEGRATION_ISSUE'

            WHEN physical_diff = 0
             AND available_diff <> 0
             AND wms_damaged_qty > 0
                THEN 'POSSIBLE_DAMAGE_SYNC_ISSUE'

            WHEN physical_diff = 0
             AND available_diff <> 0
             AND erp_allocated_qty <> wms_reserved_qty
                THEN 'POSSIBLE_RESERVATION_SYNC_ISSUE'

            WHEN physical_diff <> 0
                THEN 'POSSIBLE_TIMING_OR_PHYSICAL_SYNC_ISSUE'

            ELSE 'NO_ISSUE'
        END AS possible_reason,

		CASE
            WHEN source_status = 'BOTH' 
                THEN GREATEST(available_diff, 0)

            ELSE NULL
        END AS oversell_risk_qty

    FROM calculated_inventory
),
classified_flag AS (
	SELECT
		*,
		CASE 
			WHEN source_status = 'BOTH'
				THEN physical_diff <> 0
			ELSE NULL
		END AS physical_mismatch_flag,

		CASE 
			WHEN source_status = 'BOTH'
				THEN available_diff <> 0
			ELSE NULL
		END AS available_mismatch_flag
		
	FROM classified_inventory
)
SELECT *
FROM classified_flag;
