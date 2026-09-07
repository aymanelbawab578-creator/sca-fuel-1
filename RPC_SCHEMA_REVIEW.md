# RPC Schema Review

## Scope

This review compares the supplied Supabase Production schema text with `FINAL_RPC_INVENTORY.md`.

No SQL was executed. No function, policy, table, constraint, index, grant, or data was changed.

The conclusions below are based only on the schema text supplied in the request. RLS policies, PostgreSQL functions, grants, Auth configuration, and role data were not included in that text.

## 1. Tables Confirmed in the Supplied Schema

The supplied schema contains these 19 tables:

- `invoice`
- `invoicepricechangelog`
- `invoicepricesetting`
- `modelconfig`
- `refuel`
- `user`
- `vehicle`
- `add_invoice`
- `inventory_discount`
- `store_adjustment`
- `fuel_price_change_log`
- `card_top_up`
- `card_consumption`
- `inventory_count`
- `mission`
- `gas_records`
- `card_delivery_record`
- `vehicle_plate_change`
- `missionexpense`
- `card_delivery_item`

## 2. Confirmed Keys and Foreign Keys

### Primary keys

Every supplied table declares a primary key on its `id` column.

### Foreign keys explicitly shown

- `refuel.vehicle_id -> vehicle.id`
- `inventory_discount.refuel_id -> refuel.id`
- `inventory_discount.vehicle_id -> vehicle.id`
- `mission.vehicle_id -> vehicle.id`
- `gas_records.vehicle_id -> vehicle.id`
- `missionexpense.mission_id -> mission.id`
- `card_delivery_item.record_id -> card_delivery_record.id`

### Relationships expected by the RPC inventory but not declared in the supplied schema

These relationships are used by the old Backend logic but are not shown as foreign keys in the supplied text:

- `card_consumption.mission_id -> mission.id`
- `card_consumption.expense_id -> missionexpense.id`
- `card_consumption.refuel_id -> refuel.id`
- `vehicle_plate_change.vehicle_id -> vehicle.id`
- `card_delivery_item.vehicle_id -> vehicle.id`
- `inventory_discount.vehicle_id` is present, but its delete behavior is not shown.
- `inventory_discount.refuel_id` is present, but its delete behavior is not shown.

The absence in the supplied text does not prove the constraints are absent in Production; it means they were not provided for verification.

## 3. Naming Differences

| Inventory/Backend name | Supplied Production schema name | Impact |
| --- | --- | --- |
| `mission_expense` | `missionexpense` | RPC SQL must use `missionexpense`, or an explicitly verified view must exist. |
| `invoice_price_setting` | `invoicepricesetting` | RPC SQL must use `invoicepricesetting`. |
| `invoice_price_change_log` | `invoicepricechangelog` | RPC SQL must use `invoicepricechangelog`. |
| `card_delivery_record` | `card_delivery_record` | Matches. |
| `card_delivery_item` | `card_delivery_item` | Matches. |
| `gas_records` | `gas_records` | Matches. |
| `add_invoice` | `add_invoice` | Matches. |
| `card_top_up` | `card_top_up` | Matches. |
| `card_consumption` | `card_consumption` | Matches. |
| `vehicle_plate_change` | `vehicle_plate_change` | Matches. |

The `FINAL_RPC_INVENTORY.md` must be corrected wherever it refers to `mission_expense`, `invoice_price_setting`, or `invoice_price_change_log` as physical table names.

## 4. Column and Type Differences Relevant to RPCs

### `mission`

Confirmed columns include:

- `created_at date`
- `vehicle_id integer nullable`
- `vehicle_number varchar nullable`
- `charged_liters double precision NOT NULL`
- `fuel_type varchar NOT NULL`
- driver/order/odometer/notes fields
- `status varchar NOT NULL`
- `card_notes text`
- `id integer`

The old Backend model includes these same business fields. `vehicle_id` is nullable in the supplied schema, so `create_mission` and `update_mission` must preserve the Backend's vehicle resolution behavior and must not blindly require a non-null vehicle.

### `missionexpense`

The physical table is `missionexpense`, not `mission_expense`.

Confirmed columns:

- `date date NOT NULL`
- `odometer double precision NOT NULL`
- `liters double precision NOT NULL`
- `receipt_data varchar nullable`
- `id integer`
- `mission_id integer nullable`

The old Backend model uses `mission_expense` as its model/table name, but the supplied Production schema uses `missionexpense`. All mission RPCs must account for this.

### `gas_records`

Confirmed:

- `gas_price numeric NOT NULL`
- `amount numeric NOT NULL`
- `quantity numeric NOT NULL`
- `vehicle_id integer NOT NULL`
- date and timestamp fields

The old Backend uses `Decimal` and calculates quantity rounded to two decimals. RPCs must use numeric arithmetic and preserve the same rounding behavior. No unique constraint for `(vehicle_id, start_date, end_date)` appears in the supplied schema text; this must be verified before relying on it for duplicate protection.

### `user`

Confirmed:

- `username varchar NOT NULL`
- `full_name varchar nullable`
- `role USER-DEFINED NOT NULL`
- `hashed_password varchar NOT NULL`
- `is_active boolean NOT NULL`
- timestamps and `is_synced`

The actual enum/type definition for `role` was not supplied. The actual role values cannot be verified from this schema text.

### `card_consumption`

The table contains nullable `mission_id`, `expense_id`, and `refuel_id`, but no foreign-key constraints are shown. This is significant for atomic reversal RPCs because the RPC must locate and delete linked rows explicitly.

### `card_delivery_item`

The table contains `vehicle_id`, but no foreign key to `vehicle` is shown. The uniqueness constraint `(record_id, vehicle_id, fuel_type)` is also not shown in the supplied text and must be verified before implementing duplicate protection in `create_card_delivery` and related RPCs.

## 5. RPCs That Are Structurally Possible with the Supplied Tables

These RPCs have all named physical tables present, subject to role/RLS/function verification:

- `create_refuel`
- `update_refuel`
- `delete_refuel`
- `create_mission`
- `update_mission`
- `delete_mission`
- `add_mission_expense`
- `update_mission_expense`
- `delete_mission_expense`
- `complete_mission`
- `card_topup`
- `card_deduct`
- `calculate_invoice`
- `get_dashboard_summary`
- `get_daily_report`
- `get_range_report`
- `get_station_fuel_quantities`
- `get_settlement_report`
- `get_vehicle_report`
- `create_card_delivery`
- `update_card_delivery`
- `add_card_delivery_vehicle`
- `import_card_delivery_gas_vehicles`
- `delete_card_delivery_vehicle`
- `delete_card_delivery`
- `create_gas_record`
- `update_gas_record`
- `delete_gas_record`
- `create_vehicle`
- `create_vehicles_batch`
- `update_vehicle`
- `create_inventory_count`
- `delete_inventory_count`
- `delete_add_invoice`
- `delete_invoice_price_change_log`
- `delete_plate_change`

“Structurally possible” does not mean safe or ready to execute. Each write RPC still requires verified role checks, exact constraints, transaction behavior, and return shape.

## 6. RPCs with Schema Gaps or Important Verification Requirements

### `delete_vehicle`

Tables are present, but the supplied schema does not show all dependent foreign keys or delete behavior. The RPC must explicitly reverse/delete refuel-dependent records according to the old Backend logic before deleting the vehicle.

### `change_vehicle_plate`

Required tables are present, but the supplied schema does not show foreign keys for `vehicle_plate_change.vehicle_id` or `card_delivery_item.vehicle_id`. It must update:

- `vehicle.number` and `vehicle.letters`
- a `vehicle_plate_change` row
- denormalized `mission.vehicle_number`
- denormalized `card_delivery_item.vehicle_number`

This must be atomic.

### `get_store_balances`

All required tables are present. The result depends on exact adjustment values and exclusions, including smart-card mission rows and price-change rows. No SQL function currently exists in the supplied schema text, so the result cannot be verified yet.

### `apply_price_change`

Required tables are present, but the inventory uses:

- `invoicepricesetting`
- `invoicepricechangelog`
- `fuel_price_change_log`
- `add_invoice`
- `inventory_discount`
- `store_adjustment`
- `vehicle`

The operation must preserve the old Backend's calculation of stock quantity difference, card balance settlement, logs, and adjustment rows in one transaction.

### `save_invoice_prices`

This must use `invoicepricesetting` and `invoicepricechangelog`, not underscored table names. It must call the same price-change settlement logic rather than independently updating prices.

### `cleanup_archived_data`

The supplied schema has no archive tables. The old Backend archive feature operates on production rows and external/local archive storage. A safe RPC cannot be finalized without the exact archive policy, target date rules, dependent-row order, and authorization requirements.

## 7. Unique Constraints and Indexes

The supplied schema text explicitly shows primary keys and column defaults. It does not show the complete `UNIQUE` constraints or `CREATE INDEX` definitions.

Therefore these requirements remain unverified:

- Unique gas record per vehicle/date period.
- Unique card-delivery period.
- Unique card-delivery item per record/vehicle/fuel.
- Unique vehicle number/letters combination.
- Supporting indexes used by reports and date filters.

RPCs must not assume these constraints exist until the actual Production constraint/index catalog is provided.

## 8. RLS, Policies, Functions, Grants, and Auth

The supplied schema contains no information about:

- RLS enabled state per table.
- Existing RLS policies.
- Existing PostgreSQL functions/RPCs.
- Function parameters or return types.
- Function ownership or `SECURITY DEFINER` status.
- Function execution grants.
- Table grants.
- Supabase Auth users.
- A link between `public.user` and `auth.users`.
- The actual values of the `public.user.role` user-defined type.

These must be extracted separately with read-only metadata queries before any SQL is designed or applied.

## 9. Final Status

- No SQL was executed.
- No Production object or data was changed.
- The supplied schema contains the physical tables needed by most RPC contracts.
- Several RPC contracts require corrected physical table names.
- Several expected foreign keys, unique constraints, and indexes are not shown and remain unverified.
- RLS, policies, Functions/RPCs, grants, Auth linkage, and actual role values remain unknown.
- No RPC can be marked Production-ready solely from the supplied schema text.
