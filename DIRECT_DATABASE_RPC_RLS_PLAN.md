# Direct Supabase RPC and RLS Plan

This is a review plan only. It has not been applied to Supabase and does not
change the production database.

## Authentication

The current backend uses a custom `user` table and PBKDF2 password hashes. The
Flutter client must not query PostgreSQL with a database password. Before any
write migration, users must be mapped to Supabase Auth identities and their
role must be stored in a trusted JWT claim or a protected profile table.

The roles to preserve are `Admin`, `Data Entry`, and `Viewer`. Admin includes
the permissions of Data Entry in the current backend.

## RPCs for Atomic Writes

Each function below should validate the caller role, validate its inputs, and
perform all listed writes in one database transaction.

| RPC | Purpose | Tables touched | Allowed role |
| --- | --- | --- | --- |
| `create_refuel` | Calculate consumption flags, validate the dated odometer sequence, insert a refuel, and refresh the vehicle's latest odometer | `refuel`, `vehicle` | Data Entry, Admin |
| `update_refuel` | Recalculate flags, update the refuel, and refresh the vehicle by latest date | `refuel`, `vehicle` | Data Entry, Admin |
| `delete_refuel` | Reverse linked card/store records, delete the refuel, and refresh the vehicle | `card_consumption`, `inventory_discount`, `refuel`, `vehicle` | Data Entry, Admin |
| `create_gas_record` | Validate dates, calculate rounded quantity, enforce the vehicle-period uniqueness rule, and insert | `gas_records` | Data Entry, Admin |
| `update_gas_record` | Revalidate dates and quantity, then update the record | `gas_records` | Data Entry, Admin |
| `delete_gas_record` | Delete a gas record | `gas_records` | Data Entry, Admin |
| `create_vehicle` | Insert one vehicle after validating defaults | `vehicle` | Data Entry, Admin |
| `create_vehicles_batch` | Insert a batch as one transaction | `vehicle` | Data Entry, Admin |
| `update_vehicle` | Update vehicle data | `vehicle` | Data Entry, Admin |
| `delete_vehicle` | Delete dependent refuels and then the vehicle | `refuel`, `vehicle` | Data Entry, Admin |
| `change_vehicle_plate` | Record plate history, update the vehicle, and update denormalized references | `vehicle`, `vehicle_plate_change`, `mission`, `card_delivery_item` | Data Entry, Admin |
| `update_plate_change` | Update a plate-history row and its linked vehicle data | `vehicle_plate_change`, `vehicle` | Data Entry, Admin |
| `delete_plate_change` | Delete a plate-history row | `vehicle_plate_change` | Data Entry, Admin |
| `create_mission` | Normalize vehicle reference and insert an open mission | `mission`, `vehicle` | Data Entry, Admin |
| `update_mission` | Normalize optional fields and vehicle reference, then update the mission | `mission`, `vehicle` | Data Entry, Admin |
| `delete_mission` | Remove all mission expenses and linked accounting/refuel records, then the mission | `mission_expense`, `card_consumption`, `refuel`, `inventory_discount`, `vehicle`, `mission` | Data Entry, Admin |
| `add_mission_expense` | Validate open mission and positive liters, then insert a draft expense | `mission_expense`, `mission` | Data Entry, Admin |
| `update_mission_expense` | Update a draft or completed expense and synchronize linked refuel/accounting rows | `mission_expense`, `refuel`, `inventory_discount`, `card_consumption`, `vehicle` | Data Entry, Admin |
| `delete_mission_expense` | Delete a draft, or reverse all linked completed records and refresh the vehicle | `mission_expense`, `card_consumption`, `refuel`, `inventory_discount`, `vehicle` | Data Entry, Admin |
| `complete_mission` | Convert every expense into refuel, inventory discount, and card consumption, then close the mission | `mission`, `mission_expense`, `refuel`, `inventory_discount`, `card_consumption`, `vehicle` | Data Entry, Admin |
| `card_topup` | Transfer liters from shared stock to cards | `card_top_up`, `inventory_discount`, `store_adjustment`, `vehicle` | Data Entry, Admin |
| `card_deduct` | Reverse a card top-up and return liters to shared stock | `card_top_up`, `inventory_discount`, `store_adjustment`, `vehicle` | Data Entry, Admin |
| `create_add_invoice` | Normalize invoice items, calculate totals, and insert a stock addition | `add_invoice` | Authenticated write role, Admin |
| `update_add_invoice` | Recalculate totals and update a stock addition | `add_invoice` | Authenticated write role, Admin |
| `delete_add_invoice` | Soft-delete a stock addition | `add_invoice` | Authenticated write role, Admin |
| `create_inventory_discount` | Normalize fuel type and insert a stock deduction | `inventory_discount` | Authenticated write role, Admin |
| `create_inventory_count` | Normalize details and total, then insert a count | `inventory_count` | Authenticated write role, Admin |
| `delete_inventory_count` | Delete an inventory count | `inventory_count` | Authenticated write role, Admin |
| `apply_price_change` | Calculate quantity settlement and write all price, log, and adjustment rows | `invoice_price_setting`, `invoice_price_change_log`, `fuel_price_change_log`, `store_adjustment`, `inventory_discount`, `vehicle` | Authenticated write role, Admin |
| `delete_price_change_log` | Delete a price-change log | `fuel_price_change_log` | Authenticated write role, Admin |
| `save_invoice_prices` | Update current invoice prices and create change history | `invoice_price_setting`, `invoice_price_change_log` | Authenticated write role, Admin |
| `create_invoice` | Insert a calculated invoice | `invoice` | Authenticated write role, Admin |
| `update_invoice` | Update an invoice | `invoice` | Authenticated write role, Admin |
| `delete_invoice` | Delete an invoice | `invoice` | Authenticated write role, Admin |
| `create_card_delivery` | Create a delivery record and its period-derived items | `card_delivery_record`, `card_delivery_item`, `refuel`, `gas_records`, `vehicle` | Data Entry, Admin |
| `update_card_delivery` | Update delivery item status in one transaction | `card_delivery_record`, `card_delivery_item` | Data Entry, Admin |
| `add_card_delivery_vehicle` | Add a vehicle/fuel item with uniqueness validation | `card_delivery_item`, `card_delivery_record`, `vehicle` | Data Entry, Admin |
| `import_card_delivery_gas_vehicles` | Import eligible gas vehicles for a period | `card_delivery_item`, `gas_records`, `vehicle`, `card_delivery_record` | Data Entry, Admin |
| `delete_card_delivery_vehicle` | Delete one delivery item | `card_delivery_item` | Data Entry, Admin |
| `delete_card_delivery` | Delete delivery and its items | `card_delivery_item`, `card_delivery_record` | Data Entry, Admin |
| `create_model_config` | Insert a vehicle model configuration | `model_config` | Admin |
| `update_model_config` | Update a vehicle model configuration | `model_config` | Admin |
| `delete_model_config` | Delete a vehicle model configuration | `model_config` | Admin |
| `update_username` | Change the authenticated user's login/profile identity | Supabase Auth, protected user profile | Authenticated user |
| `change_password` | Change the authenticated user's password | Supabase Auth | Authenticated user |

## Read RPCs or Protected Views

These are derived queries and should not be recreated as unrestricted client
side table scans:

- `get_store_balances`: sums `add_invoice`, `inventory_discount`,
  `card_top_up`, `card_consumption`, and `store_adjustment` with the existing
  smart-card exclusions and settlement rules.
- `get_settlement_report`: reads `inventory_discount`, `refuel`, `vehicle`,
  and related adjustments for a date/fuel/vehicle range.
- `get_dashboard_summary`: reads aggregated `vehicle`, `refuel`,
  `gas_records`, `mission`, and store data.
- `get_daily_report`: reads daily `refuel`, `gas_records`, `mission`, and
  vehicle data.
- `get_range_report`: reads range-based refuel, mission, vehicle, and store
  data, including date-based odometer behavior.
- `get_station_fuel_quantities`: aggregates `refuel` by station and fuel.
- `get_vehicle_report`: aggregates one vehicle's `refuel`, `gas_records`, and
  mission data.
- `calculate_invoice`: calculates invoice totals from `invoice_price_setting`,
  `refuel`, `gas_records`, and vehicle data without writing.
- `get_invoice_prices` and `get_invoice_price_history`: read
  `invoice_price_setting` and `invoice_price_change_log`.
- `export_missions`, `export_daily_excel`, and `export_daily_pdf`: remain
  client-side exports after protected read RPCs; archive/GitHub operations are
  excluded from direct database mode.

## RLS Policies Required

RLS must be enabled on every table exposed to the Supabase API. The preferred
model is: authenticated users may read only through approved views/RPCs;
direct table INSERT/UPDATE/DELETE is revoked, and the write RPCs are
`SECURITY DEFINER` functions that validate the role claim. If direct reads are
needed, apply these policies:

| Table group | SELECT | INSERT/UPDATE/DELETE |
| --- | --- | --- |
| `vehicle`, `refuel`, `gas_records`, `mission`, `mission_expense`, `model_config` | Authenticated users; Admin/Data Entry/Viewer | Deny direct writes; use RPCs, with model config restricted to Admin |
| `vehicle_plate_change` | Authenticated users | Deny direct writes; use plate RPCs, Data Entry/Admin |
| `add_invoice`, `inventory_discount`, `inventory_count`, `store_adjustment` | Authenticated users | Deny direct writes; use store RPCs |
| `card_top_up`, `card_consumption` | Authenticated users | Deny direct writes; use card/mission/refuel RPCs |
| `invoice`, `invoice_price_setting`, `invoice_price_change_log`, `fuel_price_change_log` | Authenticated users | Deny direct writes; use invoice/price RPCs; price administration restricted to Admin where applicable |
| `card_delivery_record`, `card_delivery_item` | Authenticated users | Deny direct writes; use card-delivery RPCs |
| `user` / profile mapping | Own profile only | No direct password or role writes; use Supabase Auth and protected profile RPCs |

## Explicitly Excluded from Direct Database Mode

Archive creation, GitHub upload/download, temporary SQLite archive loading,
cleanup audit, and the current `manualSync` call are not database CRUD. They
must remain a separate local/admin feature or be removed from the emergency
client until an approved replacement is designed.

No item in this document has been executed.