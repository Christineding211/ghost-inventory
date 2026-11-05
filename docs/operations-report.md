
# Ghost Inventory Operations Report

**Reporting period:** 1–7 September 2026  
**Data:** Simulated ERP and WMS inventory snapshots across two warehouses

## Seven-day summary

Of 420 reconciled snapshot records, 416 matched.
Four exceptions were flagged for investigation: **one P1 and three P2**.
The first item to investigate is BAT009 at WH01, where the ERP record had
no corresponding WMS snapshot record.

| Snapshot date | Records observed | Matched | Exceptions | Match rate |
| --- | ---: | ---: | ---: | ---: |
| 1 Sep | 60 | 60 | 0 | 100.00% |
| 2 Sep | 60 | 59 | 1 | 98.33% |
| 3 Sep | 60 | 59 | 1 | 98.33% |
| 4 Sep | 60 | 59 | 1 | 98.33% |
| 5 Sep | 60 | 59 | 1 | 98.33% |
| 6 Sep | 60 | 60 | 0 | 100.00% |
| 7 Sep | 60 | 60 | 0 | 100.00% |
| **Total** | **420** | **416** | **4** | **99.05%** |

## Investigation queue

| Priority | Date | SKU | Warehouse | Finding | Next check |
| --- | --- | --- | --- | --- | --- |
| **P1** | 5 Sep | BAT009 | WH01 | WMS snapshot record missing. Quantity difference unavailable. | Check the WMS export and data loading logs. |
| P2 | 4 Sep | BAT003 | WH02 | Recorded physical quantities differ. ERP shows 20 more available units than WMS. | Compare receipt, dispatch and inventory adjustment records. |
| P2 | 2 Sep | [BAT001](#case-study-bat001) | WH01 | ERP shows 10 more available units than WMS. WMS records 10 damaged units. | Check the damage records and verify how each system calculates availability. |
| P2 | 3 Sep | BAT002 | WH01 | ERP shows 10 more available units than WMS. WMS reserved 10 more units than ERP allocated. | Compare ERP allocations and WMS reservations at the same cut-off time. |

Each exception had a streak of one day at the time of observation.

## Case study BAT001

On 2 September at WH01, both systems recorded 88 physical units for BAT001.
ERP showed 74 available units and WMS showed 64, a difference of 10 units.

| System | Availability calculation | Available units |
| --- | --- | ---: |
| ERP | 88 on hand − 14 allocated | 74 |
| WMS | 88 physical − 14 reserved − 10 damaged − 0 quarantined | 64 |

Under the project’s availability rules, the 10 damaged units recorded in
WMS account for the full difference. The snapshots show the numerical
difference. Confirming whether a synchronisation issue occurred would
require the damage event, the applicable availability rules and the
related integration logs.

If order acceptance uses ERP availability, the difference could affect
how many units the business promises to customers. Confirm the damage
event and whether ERP should reflect it. If an issue is found and
corrected, rerun the reconciliation for aligned snapshots and check
whether the difference recurs.

## Metric definitions

| Metric | Definition |
| --- | --- |
| Records observed | Number of date, SKU and warehouse combinations present in at least one source. |
| Exceptions | Observed records classified as anything other than `MATCH`, including records missing from one source. |
| Reconciliation match rate | `MATCH` records divided by observed records. The weekly rate uses the weekly totals. This measures agreement between ERP and WMS. Physical inventory accuracy requires a separate stock count. |
| Mismatch streak | Number of consecutive calendar days with an observed exception for the same SKU and warehouse, ending on the reported date. A match or a gap breaks the streak. |
| Available quantity difference | ERP available quantity minus WMS available quantity when both values are available. A positive difference indicates potential exposure. Confirming an oversale requires order and fulfilment records. |
| Investigation priority | P1 for a missing record in one source or a streak of at least two days. P2 for a positive availability difference. P3 for other exceptions. Rules apply in that order. |

The match rate is based on observed records. A combination absent from
both systems requires a separate check against the expected snapshot list.

## Reproducing the results

- [Seven-day summary query](../sql/daily_summary.sql)
- [Investigation priority query](../sql/05_inventory_operations_report.sql)