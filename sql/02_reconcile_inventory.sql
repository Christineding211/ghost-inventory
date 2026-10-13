-- =========================================================
-- Purpose:
-- Compare ERP and WMS inventory snapshots at the same grain:
-- snapshot_date + sku + warehouse_id
-- =========================================================

WITH erp AS (

    -- Step 1: Prepare ERP inventory
    
    SELECT
        snapshot_date,
        sku,
        warehouse_id,
        on_hand_qty,
        allocated_qty,

        on_hand_qty - allocated_qty
            AS erp_available_qty

    FROM raw_erp_inventory
),

wms AS (

    -- Step 2: Prepare WMS inventory
    
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
)

-- Step 3: Reconcile ERP and WMS inventory

SELECT

    -- Use the ERP value when available.
    -- Otherwise, use the WMS value.
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

    -- ERP physical inventory information
    erp.on_hand_qty AS erp_on_hand_qty,

    -- WMS physical inventory information
    wms.physical_qty AS wms_physical_qty,

    -- ERP committed inventory
    erp.allocated_qty AS erp_allocated_qty,

    -- WMS unavailable inventory
    wms.reserved_qty AS wms_reserved_qty,

    wms.damaged_qty AS wms_damaged_qty,

    wms.quarantine_qty AS wms_quarantine_qty,

    -- Calculated sellable inventory
    erp.erp_available_qty,
    wms.wms_available_qty

FROM erp

FULL OUTER JOIN wms
    ON erp.snapshot_date = wms.snapshot_date
    AND erp.sku = wms.sku
    AND erp.warehouse_id = wms.warehouse_id

ORDER BY
    snapshot_date,
    sku,
    warehouse_id;