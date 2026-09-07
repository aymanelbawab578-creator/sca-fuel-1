-- Read-only report RPCs used by the emergency Flutter client.
-- SECURITY INVOKER preserves the existing RLS policies on vehicle and refuel.

CREATE OR REPLACE FUNCTION public.get_dashboard_summary()
RETURNS jsonb
LANGUAGE plpgsql
SECURITY INVOKER
SET search_path = public
AS $$
DECLARE
  today_date date := current_date;
  total_vehicle_count integer;
  today_refuel_count integer;
  today_total_liters double precision;
  today_excess_count integer;
  today_illogical_count integer;
  excess_vehicle_data jsonb;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'authenticated user required'
      USING ERRCODE = 'insufficient_privilege';
  END IF;

  SELECT count(*)::integer
    INTO total_vehicle_count
    FROM public.vehicle;

  SELECT
    count(*)::integer,
    coalesce(sum(r.liters), 0)::double precision,
    count(*) FILTER (WHERE r.is_excess)::integer,
    count(*) FILTER (WHERE r.is_illogical)::integer
    INTO today_refuel_count,
         today_total_liters,
         today_excess_count,
         today_illogical_count
    FROM public.refuel AS r
   WHERE r.created_at = today_date;

  SELECT coalesce(jsonb_agg(
           jsonb_build_object(
             'vehicle_id', v.id,
             'number', v.number,
             'letters', v.letters,
             'vehicle_type', v.vehicle_type,
             'liters', r.liters,
             'current_odometer', r.current_odometer,
             'actual_percentage', r.actual_percentage,
             'created_at', r.created_at
           )
           ORDER BY r.id
         ), '[]'::jsonb)
    INTO excess_vehicle_data
    FROM public.refuel AS r
    JOIN public.vehicle AS v ON v.id = r.vehicle_id
   WHERE r.created_at = today_date
     AND r.is_excess = true;

  RETURN jsonb_build_object(
    'date', today_date,
    'vehicle_count', total_vehicle_count,
    'refuel_count', today_refuel_count,
    'total_liters', today_total_liters,
    'excess_count', today_excess_count,
    'illogical_count', today_illogical_count,
    'excess_vehicles', excess_vehicle_data
  );
END;
$$;

CREATE OR REPLACE FUNCTION public.get_daily_report(p_date date)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY INVOKER
SET search_path = public
AS $$
DECLARE
  report_records jsonb;
  total_count integer;
  total_liters_value double precision;
  fuel_totals_data jsonb;
  status_summary_data jsonb;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'authenticated user required'
      USING ERRCODE = 'insufficient_privilege';
  END IF;

  IF p_date IS NULL THEN
    RAISE EXCEPTION 'p_date is required'
      USING ERRCODE = 'invalid_parameter_value';
  END IF;

  WITH daily_rows AS (
    SELECT
      r.id AS refuel_id,
      r.vehicle_id,
      v.number AS vehicle_number,
      v.letters AS vehicle_letters,
      v.registry,
      v.vehicle_type,
      v.fuel_type,
      r.current_odometer AS odometer,
      r.liters,
      r.created_at,
      round(r.actual_percentage::numeric, 1)::double precision AS consumption_ratio,
      CASE
        WHEN coalesce(v.standard_consumption, 0) <= 0
          OR r.actual_percentage < v.standard_consumption * 0.5
          THEN 'نسبة غير منطقية'
        WHEN r.actual_percentage > v.standard_consumption * 1.5
          THEN 'متجاوز'
        ELSE 'طبيعي'
      END AS status,
      CASE
        WHEN coalesce(v.standard_consumption, 0) <= 0
          OR r.actual_percentage < v.standard_consumption * 0.5
          THEN 'illogical'
        WHEN r.actual_percentage > v.standard_consumption * 1.5
          THEN 'excess'
        ELSE 'natural'
      END AS status_code,
      coalesce(r.station, 'غير محدد') AS station
    FROM public.refuel AS r
    LEFT JOIN public.vehicle AS v ON v.id = r.vehicle_id
    WHERE r.created_at = p_date
    ORDER BY r.created_at, r.id
  )
  SELECT
    coalesce(jsonb_agg(to_jsonb(daily_rows) ORDER BY refuel_id), '[]'::jsonb),
    count(*)::integer,
    coalesce(sum(liters), 0)::double precision
    INTO report_records, total_count, total_liters_value
    FROM daily_rows;

  SELECT coalesce(jsonb_object_agg(fuel_type, liters), '{}'::jsonb)
    INTO fuel_totals_data
    FROM (
      SELECT coalesce(v.fuel_type, 'غير معروف') AS fuel_type,
             sum(r.liters)::double precision AS liters
        FROM public.refuel AS r
        LEFT JOIN public.vehicle AS v ON v.id = r.vehicle_id
       WHERE r.created_at = p_date
       GROUP BY coalesce(v.fuel_type, 'غير معروف')
       ORDER BY coalesce(v.fuel_type, 'غير معروف')
    ) AS fuel_totals;

  SELECT jsonb_build_object(
           'طبيعي', count(*) FILTER (WHERE status_code = 'natural'),
           'متجاوز', count(*) FILTER (WHERE status_code = 'excess'),
           'نسبة غير منطقية', count(*) FILTER (WHERE status_code = 'illogical')
         )
    INTO status_summary_data
    FROM (
      SELECT CASE
        WHEN coalesce(v.standard_consumption, 0) <= 0
          OR r.actual_percentage < v.standard_consumption * 0.5
          THEN 'illogical'
        WHEN r.actual_percentage > v.standard_consumption * 1.5
          THEN 'excess'
        ELSE 'natural'
      END AS status_code
      FROM public.refuel AS r
      LEFT JOIN public.vehicle AS v ON v.id = r.vehicle_id
      WHERE r.created_at = p_date
    ) AS statuses;

  RETURN jsonb_build_object(
    'date', p_date,
    'count', total_count,
    'total_liters', total_liters_value,
    'fuel_totals', fuel_totals_data,
    'status_summary', status_summary_data,
    'records', report_records
  );
END;
$$;

REVOKE ALL ON FUNCTION public.get_dashboard_summary() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.get_dashboard_summary() TO authenticated;

REVOKE ALL ON FUNCTION public.get_daily_report(date) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.get_daily_report(date) TO authenticated;