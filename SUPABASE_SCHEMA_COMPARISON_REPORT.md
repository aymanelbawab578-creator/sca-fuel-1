# Supabase Schema Comparison Report

## Scope and Safety

This report is based only on workspace artifacts. No connection to Supabase was
made, no SQL was executed, and no database object or data was changed.

The workspace contains no Supabase project URL/key values and no Supabase
migration directory. `AppConfig` accepts runtime values through
`SCA_SUPABASE_URL` and `SCA_SUPABASE_ANON_KEY`, but both are empty by default.
Therefore the live Supabase schema, live RLS, and live Auth configuration are
not verified.

## Evidence Found

### Local SQL dump

The file `backup_neon_before_supabase_insert_ready.sql` contains these public
tables:

- `invoice`
- `invoicepricechangelog`
- `invoicepricesetting`
- `modelconfig`
- `refuel`
- `user`
- `vehicle`

The dump also shows:

- Primary keys on those seven tables.
- A unique index on `invoicepricesetting.fuel_type`.
- Indexes on `vehicle.number` and `refuel.created_at`.
- A foreign key from `refuel.vehicle_id` to `vehicle.id` with `ON DELETE CASCADE`.
- No `CREATE POLICY` statements.
- No `ENABLE ROW LEVEL SECURITY` statements.
- No `auth.users` references.
- No Supabase RPC/function definitions.

This dump is not proof of the current production schema; its filename and
contents identify it as a historical Neon/PostgreSQL backup.

### Backend model expectations

The old backend defines additional operational tables that are absent from the
local dump text:

- `gas_records`
- `mission`
- `mission_expense`
- `add_invoice`
- `inventory_discount`
- `store_adjustment`
- `fuel_price_change_log`
- `card_top_up`
- `card_consumption`
- `inventory_count`
- `vehicle_plate_change`
- `card_delivery_record`
- `card_delivery_item`

The old backend also performs runtime schema alterations in
`sca-fleet-backend-main/app/db/session.py`, including mission, refuel,
vehicle, invoice, and card-consumption columns. Those alterations are not
equivalent to a verified Supabase migration.

## Auth and Roles Comparison

| Area | Local evidence | Required for direct Supabase mode | Status |
| --- | --- | --- | --- |
| Existing login | Custom `public.user` table with `hashed_password` | Supabase Auth user/session | Not verified/migrated |
| Password algorithm | PBKDF2-SHA256 through Passlib in FastAPI | Supabase Auth password storage | Not equivalent |
| Existing role enum | Dump values are lowercase `admin`, `data_entry`, `viewer` | Trusted role claim/profile checked by RPCs | Mapping required |
| Backend role checks | `Admin` can perform Data Entry operations | JWT/profile role checks in every RPC | Not implemented in DB |
| Flutter role source | Current client reads `user_metadata.role` with `Viewer` fallback | Trusted server-controlled claim/profile | Unsafe until configured |
| User preservation | Existing `public.user` rows must remain | Auth identities linked without deleting old rows | Migration design required |

## RPC Inventory Comparison

### Confirmed by code, not by live database

Flutter references RPCs listed in [FINAL_RPC_INVENTORY.md](FINAL_RPC_INVENTORY.md),
including refuel, mission, card, report, invoice, gas, vehicle, inventory,
and card-delivery functions. These names are client contracts only. No matching
function definitions were found in the workspace SQL artifacts.

### Schema blockers

The following RPC families require tables not proven by the local dump:

- Missions and cards require `mission`, `mission_expense`, `card_top_up`,
  `card_consumption`, `inventory_discount`, and `store_adjustment`.
- Gas requires `gas_records` and its unique vehicle/date-period constraint.
- Card delivery requires `card_delivery_record` and `card_delivery_item`.
- Store balances and price changes require the complete adjustment model.
- Plate changes require `vehicle_plate_change` plus denormalized mission and
  card-delivery columns.
- Archive cleanup requires a verified archive policy and exact dependency graph.

### Direct-write correction

The Flutter write services have been changed to call RPCs for these operations
instead of writing directly to tables: gas CRUD, invoice CRUD, vehicle create/
batch/update, inventory count create/delete, add-invoice delete, invoice-price
log deletion, and plate-change deletion. This matches the intended RLS model,
but the corresponding functions still need to exist in Supabase.

## RLS Comparison

No live RLS state is available. The local SQL dump contains no policy or RLS
statements, so the following cannot be marked as existing:

- Authenticated read policies.
- Viewer/Data Entry/Admin role policies.
- Direct-write denial policies.
- Profile ownership policies.
- RPC execution grants.

The intended policy model remains documented in
[DIRECT_DATABASE_RPC_RLS_PLAN.md](DIRECT_DATABASE_RPC_RLS_PLAN.md): deny direct
writes, expose controlled reads, and validate roles inside `SECURITY DEFINER`
RPCs.

## Conclusion

The current workspace proves the historical PostgreSQL shape and the old
backend's expected model/logic, but it does not prove the active Supabase
schema, RLS, Auth users, role mapping, or RPCs. Creating or applying SQL now
would be speculative and could affect production. A safe next step is a
read-only schema export from the target Supabase project, including table
columns/constraints, `pg_policies`, function signatures, grants, and Auth/profile
role mapping. That export can then be compared line-by-line against the final
inventory before generating an executable migration.