
CREATE TABLE IF NOT EXISTS raw_erp_inventory (
    snapshot_date DATE NOT NULL,
    sku VARCHAR(20) NOT NULL,
    warehouse_id VARCHAR(20) NOT NULL,
    on_hand_qty INTEGER NOT NULL,
    allocated_qty INTEGER NOT NULL,
    PRIMARY KEY (snapshot_date, sku, warehouse_id)
);

CREATE TABLE IF NOT EXISTS raw_wms_inventory (
    snapshot_date DATE NOT NULL,
    sku VARCHAR(20) NOT NULL,
    warehouse_id VARCHAR(20) NOT NULL,
    physical_qty INTEGER NOT NULL,
    reserved_qty INTEGER NOT NULL,
    damaged_qty INTEGER NOT NULL,
    quarantine_qty INTEGER NOT NULL,
    PRIMARY KEY (snapshot_date, sku, warehouse_id)
);