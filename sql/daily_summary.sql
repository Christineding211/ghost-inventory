SELECT 
snapshot_date,
COUNT(*) AS observed_records,
COUNT(*) FILTER (WHERE discrepancy_type = 'MATCH') AS matched_records,
COUNT(*) FILTER (WHERE discrepancy_type <> 'MATCH') AS mismatched_records,
ROUND(
	100.0* COUNT(*) FILTER (WHERE discrepancy_type = 'MATCH')/ NULLIF ( COUNT(*),0) ,2) AS reconciliation_match_pct
FROM inventory_operations_report
GROUP BY snapshot_date
ORDER BY snapshot_date;

