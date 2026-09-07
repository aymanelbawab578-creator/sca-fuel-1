# Final RPC Inventory

This inventory describes the RPC names referenced by Flutter. It is a plan
only. No function, policy, table, or database data has been changed.

## RPCs Called by Flutter

The Flutter write layer now routes all writes through RPCs. Direct table
`insert`, `update`, and `delete` calls are reserved for reads only; this is
required for the RLS policy that denies client-side writes.

| RPC | Parameters | Tables and logic | Return | Atomic |
| --- | --- | --- | --- | --- |
| `create_refuel` | `p_vehicle_id`, `p_current_odometer`, `p_liters`, `p_created_at`, `p_station` | Validate liters, dated odometer sequence, consumption flags; insert `refuel`; refresh `vehicle.last_odometer` and date | Created refuel row | Yes |
| `update_refuel` | `p_refuel_id`, `p_vehicle_id`, `p_current_odometer`, `p_liters`, `p_created_at`, `p_station` | Recalculate flags and dated sequence; update `refuel`; refresh `vehicle` | Updated refuel row | Yes |
| `delete_refuel` | `p_refuel_id` | Delete linked `card_consumption` and `inventory_discount`, delete `refuel`, refresh `vehicle` | Void | Yes |
| `create_mission` | `p_payload` JSONB | Normalize vehicle reference and fuel type; insert `mission` | Created mission row | Yes |
| `update_mission` | `p_mission_id`, `p_payload` JSONB | Normalize fields and vehicle reference; update `mission` | Updated mission row | Yes |
| `delete_mission` | `p_mission_id` | Reverse `mission_expense`, `card_consumption`, `refuel`, `inventory_discount`; refresh `vehicle`; delete `mission` | Void | Yes |
| `add_mission_expense` | `p_mission_id`, `p_payload` JSONB | Require open mission and positive liters; insert `mission_expense` | Created expense row | Yes |
| `update_mission_expense` | `p_mission_id`, `p_expense_id`, `p_payload` JSONB | Update expense and synchronize linked `refuel`, `inventory_discount`, `card_consumption`, `vehicle` | Updated expense row | Yes |
| `delete_mission_expense` | `p_mission_id`, `p_expense_id` | Remove draft, or reverse linked `card_consumption`, `refuel`, `inventory_discount`; refresh `vehicle` | Void | Yes |
| `complete_mission` | `p_mission_id`, `p_force` | Convert expenses into `refuel`, `inventory_discount`, `card_consumption`; update vehicle; close `mission` | Completed mission row | Yes |
| `card_topup` | `p_payload` JSONB | Insert `card_top_up`, `inventory_discount`, `store_adjustment`; use adjustment vehicle when required | Created top-up row | Yes |
| `card_deduct` | `p_payload` JSONB | Insert negative `card_top_up`, negative `inventory_discount`, and return `store_adjustment` | Created deduction row | Yes |
| `calculate_invoice` | `p_station`, `p_start_date`, `p_end_date`, `p_prices` JSONB | Read/filter `refuel` and `vehicle`; calculate fuel totals using supplied prices | Invoice calculation object | No write; one consistent read transaction recommended |
| `get_dashboard_summary` | None | Aggregate `vehicle`, `refuel`, `gas_records`, `mission`, and store data | Dashboard JSON | Read-only |
| `get_daily_report` | `p_date` | Aggregate daily `refuel`, `gas_records`, `mission`, and vehicle data | Daily report JSON | Read-only |
| `get_range_report` | `p_start_date`, `p_end_date` | Aggregate period data with date-based odometer rules | Range report JSON | Read-only |
| `get_station_fuel_quantities` | `p_start_date`, `p_end_date` | Group `refuel` by station and fuel | Station quantities JSON | Read-only |
| `get_settlement_report` | `p_start_date`, `p_end_date`, `p_fuel_type`, `p_vehicle_number` | Filter/group `inventory_discount` with `vehicle`, excluding card/price adjustment rows | Rows and fuel summary JSON | Read-only |
| `get_vehicle_report` | `p_vehicle_id` | Aggregate that vehicle's `refuel`, `gas_records`, and mission data | Vehicle report JSON | Read-only |
| `create_card_delivery` | `p_start_date`, `p_end_date` | Create `card_delivery_record` and period-derived `card_delivery_item` rows using `refuel`, `gas_records`, `vehicle` | Created delivery record | Yes |
| `update_card_delivery` | `p_record_id`, `p_items` JSONB | Validate and update delivery item states | Updated delivery record/items | Yes |
| `add_card_delivery_vehicle` | `p_record_id`, `p_vehicle_number` | Resolve `vehicle`; insert unique `card_delivery_item` | Updated delivery record/item | Yes |
| `import_card_delivery_gas_vehicles` | `p_record_id`, `p_start_date`, `p_end_date` | Find eligible `gas_records` and vehicles; insert unique delivery items | Updated delivery record/items | Yes |
| `delete_card_delivery_vehicle` | `p_record_id`, `p_item_id` | Delete one `card_delivery_item` after ownership check | Updated delivery record | Yes |
| `delete_card_delivery` | `p_record_id` | Delete items and delivery record | Void | Yes |
| `create_gas_record` | `p_payload` JSONB | Validate dates, calculate quantity with two-decimal half-up rounding, and insert `gas_records` | Created gas row | Yes |
| `update_gas_record` | `p_record_id`, `p_payload` JSONB | Revalidate period and quantity, then update `gas_records` | Updated gas row | Yes |
| `delete_gas_record` | `p_record_id` | Delete a gas record after existence/permission checks | Void | Yes |
| `create_vehicle` | `p_payload` JSONB | Validate defaults and insert `vehicle` | Created vehicle row | Yes |
| `create_vehicles_batch` | `p_payloads` JSONB array | Validate and insert all vehicles or none | Vehicle rows | Yes |
| `update_vehicle` | `p_vehicle_id`, `p_payload` JSONB | Update allowed vehicle fields | Updated vehicle row | Yes |
| `create_inventory_count` | `p_payload` JSONB | Normalize details and rounded total, insert `inventory_count` | Created count row | Yes |
| `delete_inventory_count` | `p_count_id` | Delete an inventory count | Void | Yes |
| `delete_add_invoice` | `p_invoice_id` | Soft-delete `add_invoice` and set deletion timestamp | Void | Yes |
| `delete_invoice_price_change_log` | `p_log_id` | Delete an invoice-price history row | Void | Yes |
| `delete_plate_change` | `p_change_id` | Delete a plate-history row after ownership/role check | Void | Yes |

## RPCs Required but Currently Guarded

Flutter intentionally refuses to perform these as separate table writes. The
service throws a clear error until the approved function exists:

| RPC | Why required | Tables | Return |
| --- | --- | --- | --- |
| `delete_vehicle` | Cascade refuels then delete vehicle safely | `refuel`, `vehicle` | Void |
| `change_vehicle_plate` | Update plate history plus denormalized mission/delivery numbers | `vehicle`, `vehicle_plate_change`, `mission`, `card_delivery_item` | Updated vehicle |
| `get_store_balances` | Preserve all stock/card exclusions and adjustments | `add_invoice`, `inventory_discount`, `card_top_up`, `card_consumption`, `store_adjustment` | Balance JSON |
| `apply_price_change` | Apply price settlement, logs, stock and card adjustments together | `invoicepricesetting`, `invoicepricechangelog`, `fuel_price_change_log`, `add_invoice`, `inventory_discount`, `store_adjustment`, `vehicle` | Change details JSON |
| `save_invoice_prices` | Route changed prices through the same settlement logic | Price-setting and adjustment tables above | Prices JSON |
| `cleanup_archived_data` | Delete archived production rows only as one confirmed operation | Archived `refuel`, `invoice`, and related rows | Cleanup report JSON |

## SQL/RLS Readiness Gate

No SQL migration is being executed. A deployable SQL migration cannot be
validated from this workspace alone because the active Supabase project
schema, existing RLS policies, Auth-to-role mapping, and exact PostgreSQL
column types/constraints have not been supplied. The old backend models are a
reference, not proof that the current production database has the same
constraints. The migration must therefore be reviewed against a fresh schema
inspection and run first against a non-production clone.

## Security Requirements

All write RPCs must be `SECURITY DEFINER`, validate the Supabase role claim,
and use a single transaction. Direct table writes from the client should be
revoked. Read RPCs require authenticated users and must preserve the existing
`Admin`, `Data Entry`, and `Viewer` behavior.

No RPC or RLS change has been executed.