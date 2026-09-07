import 'package:supabase_flutter/supabase_flutter.dart';

import '../../config/app_config.dart';
import 'archive_report_service.dart';

class DirectReportService {
  static SupabaseClient get _client {
    if (!AppConfig.isSupabaseConfigured) {
      throw StateError('Supabase غير مهيأ.');
    }

    return Supabase.instance.client;
  }

  static Future<Map<String, dynamic>> dashboard() =>
      _rpcMap('get_dashboard_summary', {});

  static Future<Map<String, dynamic>> daily(String date) =>
      ArchiveReportService.daily(date);

  static Future<Map<String, dynamic>> range(
    String startDate,
    String endDate,
  ) =>
      ArchiveReportService.range(
        startDate,
        endDate,
      );

  static Future<Map<String, dynamic>> stationFuelQuantities(
    String startDate,
    String endDate,
  ) =>
      ArchiveReportService.stationFuelQuantities(
        startDate,
        endDate,
      );

  static Future<Map<String, dynamic>> settlement({
    required String startDate,
    required String endDate,
    String? fuelType,
    String? vehicleNumber,
  }) =>
      _rpcMap('get_settlement_report', {
        'p_start_date': startDate,
        'p_end_date': endDate,
        'p_fuel_type': fuelType,
        'p_vehicle_number': vehicleNumber,
      });

  static Future<Map<String, dynamic>> _rpcMap(
    String function,
    Map<String, dynamic> params,
  ) async {
    final result = await _client.rpc(
      function,
      params: params,
    );

    final row = result is List
        ? (result.isEmpty ? null : result.first)
        : result;

    if (row is! Map) {
      throw StateError(
        'RPC $function أعاد نتيجة غير صالحة.',
      );
    }

    return Map<String, dynamic>.from(row);
  }
}
