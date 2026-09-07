-- PRODUCTION_DIRECT_SUPABASE_MIGRATION.sql
-- REVIEW-ONLY DESIGN DOCUMENT - NOT EXECUTABLE
--
-- No SQL in this file has been executed.
-- Do not run this file on Production.
-- It intentionally contains no active CREATE, ALTER, DROP, INSERT, UPDATE,
-- DELETE, CREATE POLICY, or CREATE FUNCTION statements.
--
-- Source documents reviewed:
--   FINAL_RPC_INVENTORY.md
--   RPC_SCHEMA_REVIEW.md
--   Supplied Production schema text
--   sca-fleet-backend-main/app CRUD and endpoint logic

/*
===============================================================================
BLOCKERS / NEEDS VERIFICATION
===============================================================================

1. Auth-to-role mapping is unknown.
   The supplied schema has public."user".role USER-DEFINED and
   public."user".hashed_password, but it does not identify the enum type,
   its actual values, or a relationship to auth.users.id.
   No role claim or protected profile table was supplied.

2. Existing table Grants are unknown.
   Existing RLS is reported as enabled on all public tables, but the actual
   table policies and grants were not supplied. A policy design cannot safely
   grant reads or revoke writes without the current ACL baseline.

3. Existing Function/RPC Grants are unknown.
   No current functions were reported, but exact role grants and default
   privileges still need verification before applying function privileges.

4. Exact Production constraints are incomplete.
   The supplied schema does not include all UNIQUE constraints, indexes,
   foreign-key delete actions, sequences, enum definitions, or extensions.
   In particular verify:
     - gas_records(vehicle_id, start_date, end_date) uniqueness
     - card_delivery_record(start_date, end_date) uniqueness
     - card_delivery_item(record_id, vehicle_id, fuel_type) uniqueness
     - vehicle number/letters uniqueness
     - all card_consumption relationships
     - vehicle_plate_change.vehicle_id relationship

5. Physical names differ from the old Backend model names.
     - missionexpense (not mission_expense)
     - invoicepricesetting (not invoice_price_setting)
     - invoicepricechangelog (not invoice_price_change_log)
   All final function bodies must use the verified physical names.

6. Report result contracts are not SQL types.
   Flutter expects JSON objects with existing Backend response shapes. Each
   read RPC must be verified against the old reports.py calculations before
   assigning a final RETURNS type.

7. Archive cleanup is not fully specified.
   The local archive replacement is JSON/SharedPreferences. Production cleanup
   would delete live operational rows and requires a reviewed retention rule,
   dependency order, audit strategy, and Admin authorization.

8. Function bodies are intentionally absent.
   Reconstructing them without the live role mapping, exact constraints, and
   complete Production metadata would be speculative and unsafe.

Required read-only verification before converting this design into executable
SQL:
   - pg_enum / pg_type for the public.user role type and values
   - pg_policies and pg_class.relrowsecurity for every public table
   - pg_proc, pg_get_function_arguments, pg_get_function_result, prosecdef
   - information_schema.role_table_grants
   - function ACLs from pg_proc.proacl / aclexplode
   - pg_constraint, pg_indexes, pg_attribute, pg_attrdef
   - a safe Auth/profile mapping that does not expose passwords or row data
*/

/*
===============================================================================
VERIFIED PHYSICAL TABLE CONTRACT FROM SUPPLIED SCHEMA
===============================================================================

invoice
invoicepricechangelog
invoicepricesetting
modelconfig
refuel
user
vehicle
add_invoice
inventory_discount
store_adjustment
fuel_price_change_log
card_top_up
card_consumption
inventory_count
mission
gas_records
card_delivery_record
vehicle_plate_change
missionexpense
card_delivery_item

Explicitly supplied foreign keys:
   refuel.vehicle_id -> vehicle.id
   inventory_discount.refuel_id -> refuel.id
   inventory_discount.vehicle_id -> vehicle.id
   mission.vehicle_id -> vehicle.id
   gas_records.vehicle_id -> vehicle.id
   missionexpense.mission_id -> mission.id
   card_delivery_item.record_id -> card_delivery_record.id
*/

/*
===============================================================================
ROLE MODEL REQUIRED BY THE RPCS
===============================================================================

The intended role behavior is inherited from FastAPI:
   Admin      = all Admin and Data Entry operations
   Data Entry = operational writes
   Viewer     = authenticated reads only

The following helper is required conceptually by every SECURITY DEFINER write
function, but its SQL body is blocked until auth.users/profile mapping is
verified:

   app_role() -> text
   is_admin() -> boolean
   is_data_entry_or_admin() -> boolean

The helper must read a trusted server-controlled JWT claim or a verified
profile relation. It must never trust a client-supplied JSON role field.
*/

/*
===============================================================================
RLS DESIGN REQUIRED - COMMENT-ONLY UNTIL VERIFIED
===============================================================================

RLS is reported enabled on all public tables and policies are reported absent.
The intended final policy model is:

READ:
   Authenticated users may read approved operational/reporting data according
   to the existing application behavior.

WRITE:
   Direct INSERT/UPDATE/DELETE from client roles are denied on operational
   tables. All writes go through SECURITY DEFINER RPCs that validate role.

ADMIN:
   Model configuration, archive cleanup, and administrative user/profile
   operations require Admin.

DATA ENTRY / ADMIN:
   Vehicle, refuel, gas, mission, card, delivery, and operational store writes.

VIEWER:
   Read-only access.

Required policy families, pending verification of exact grants and profile
mapping:
   public.invoice
   public.invoicepricechangelog
   public.invoicepricesetting
   public.modelconfig
   public.refuel
   public."user"
   public.vehicle
   public.add_invoice
   public.inventory_discount
   public.store_adjustment
   public.fuel_price_change_log
   public.card_top_up
   public.card_consumption
   public.inventory_count
   public.mission
   public.gas_records
   public.card_delivery_record
   public.vehicle_plate_change
   public.missionexpense
   public.card_delivery_item

No CREATE POLICY statement is included until the above role and ACL facts are
verified.
*/

/*
===============================================================================
RPC CONTRACTS REQUIRED BY FLUTTER - COMMENT-ONLY SIGNATURE INVENTORY
===============================================================================

Atomic write RPCs:

  create_refuel(
    p_vehicle_id integer,
    p_current_odometer double precision,
    p_liters double precision,
    p_created_at date,
    p_station varchar
  ) RETURNS refuel

  update_refuel(
    p_refuel_id integer,
    p_vehicle_id integer,
    p_current_odometer double precision,
    p_liters double precision,
    p_created_at date,
    p_station varchar
  ) RETURNS refuel

  delete_refuel(p_refuel_id integer) RETURNS void

  create_mission(p_payload jsonb) RETURNS mission
  update_mission(p_mission_id integer, p_payload jsonb) RETURNS mission
  delete_mission(p_mission_id integer) RETURNS void

  add_mission_expense(p_mission_id integer, p_payload jsonb)
    RETURNS missionexpense
  update_mission_expense(
    p_mission_id integer,
    p_expense_id integer,
    p_payload jsonb
  ) RETURNS missionexpense
  delete_mission_expense(
    p_mission_id integer,
    p_expense_id integer
  ) RETURNS void
  complete_mission(p_mission_id integer, p_force boolean) RETURNS mission

  card_topup(p_payload jsonb) RETURNS card_top_up
  card_deduct(p_payload jsonb) RETURNS card_top_up

  create_card_delivery(p_start_date date, p_end_date date)
    RETURNS card_delivery_record
  update_card_delivery(p_record_id integer, p_items jsonb)
    RETURNS jsonb
  add_card_delivery_vehicle(p_record_id integer, p_vehicle_number varchar)
    RETURNS jsonb
  import_card_delivery_gas_vehicles(
    p_record_id integer,
    p_start_date date,
    p_end_date date
  ) RETURNS jsonb
  delete_card_delivery_vehicle(p_record_id integer, p_item_id integer)
    RETURNS jsonb
  delete_card_delivery(p_record_id integer) RETURNS void

  create_gas_record(p_payload jsonb) RETURNS gas_records
  update_gas_record(p_record_id integer, p_payload jsonb)
    RETURNS gas_records
  delete_gas_record(p_record_id integer) RETURNS void

  create_vehicle(p_payload jsonb) RETURNS vehicle
  create_vehicles_batch(p_payloads jsonb) RETURNS SETOF vehicle
  update_vehicle(p_vehicle_id integer, p_payload jsonb) RETURNS vehicle
  delete_vehicle(p_vehicle_id integer) RETURNS void
  change_vehicle_plate(
    p_vehicle_id integer,
    p_number varchar,
    p_letters varchar
  ) RETURNS vehicle
  delete_plate_change(p_change_id integer) RETURNS void

  create_inventory_count(p_payload jsonb) RETURNS inventory_count
  delete_inventory_count(p_count_id integer) RETURNS void
  delete_add_invoice(p_invoice_id integer) RETURNS void
  delete_invoice_price_change_log(p_log_id integer) RETURNS void

  create_invoice(p_payload jsonb) RETURNS invoice
  update_invoice(p_invoice_id integer, p_payload jsonb) RETURNS invoice
  delete_invoice(p_invoice_id integer) RETURNS void

  apply_price_change(p_payload jsonb) RETURNS jsonb
  save_invoice_prices(p_prices jsonb) RETURNS jsonb
  cleanup_archived_data(p_payload jsonb) RETURNS jsonb

Read/report RPCs:

  calculate_invoice(
    p_station varchar,
    p_start_date date,
    p_end_date date,
    p_prices jsonb
  ) RETURNS jsonb

  get_dashboard_summary() RETURNS jsonb
  get_daily_report(p_date date) RETURNS jsonb
  get_range_report(p_start_date date, p_end_date date) RETURNS jsonb
  get_station_fuel_quantities(p_start_date date, p_end_date date)
    RETURNS jsonb
  get_settlement_report(
    p_start_date date,
    p_end_date date,
    p_fuel_type varchar,
    p_vehicle_number varchar
  ) RETURNS jsonb
  get_vehicle_report(p_vehicle_id integer) RETURNS jsonb
  get_store_balances() RETURNS jsonb

Every write RPC above must be SECURITY DEFINER, set a safe search_path,
validate the authenticated role, validate inputs, and execute all related table
changes in one atomic database transaction. Read RPCs should be SECURITY
INVOKER unless a reviewed SECURITY DEFINER design is required for protected
aggregation.
*/

/*
===============================================================================
TABLES TOUCHED BY SENSITIVE RPC FAMILIES
===============================================================================

Refuel create/update/delete:
   refuel, vehicle, card_consumption, inventory_discount

Mission completion/reversal:
   mission, missionexpense, refuel, vehicle,
   card_consumption, inventory_discount

Card top-up/deduction:
   card_top_up, inventory_discount, store_adjustment, vehicle

Vehicle plate change:
   vehicle, vehicle_plate_change, mission, card_delivery_item

Price settlement:
   invoicepricesetting, invoicepricechangelog,
   fuel_price_change_log, add_invoice, inventory_discount,
   store_adjustment, vehicle

Card delivery:
   card_delivery_record, card_delivery_item, vehicle,
   refuel, gas_records

Store balances:
   add_invoice, inventory_discount, card_top_up,
   card_consumption, store_adjustment

Archive cleanup:
   Exact dependency set and retention semantics require verification.
*/

/*
===============================================================================
GRANTS DESIGN - COMMENT-ONLY UNTIL CURRENT ACLS ARE VERIFIED
===============================================================================

Expected end state:
   - authenticated: EXECUTE on approved read RPCs
   - data_entry role: EXECUTE on operational write RPCs
   - admin role: EXECUTE on all administrative/write RPCs
   - anon: no table write, no write RPC execution
   - direct table writes: revoked from client-facing roles

The exact Supabase role names and current ACLs are not present in the supplied
metadata. Do not add GRANT/REVOKE statements until they are captured and a
least-privilege diff is reviewed.
*/

/*
===============================================================================
FINAL STATUS
===============================================================================

This file is intentionally a review-only migration design. It does not create
RPCs or policies because the missing Auth/role mapping, ACLs, enum values,
complete constraint catalog, and exact report return contracts make executable
SQL unsafe to guess.

No SQL was executed and Production was not modified.
*/
