import 'package:supabase_flutter/supabase_flutter.dart';

import '../../config/app_config.dart';

class DirectCardDeliveryService {
  static SupabaseClient get _client {
    if (!AppConfig.isSupabaseConfigured) {
      throw StateError('Supabase غير مهيأ.');
    }
    return Supabase.instance.client;
  }

  static Future<List<Map<String, dynamic>>> list() async {
  final rows = await _client
      .from('card_delivery_record')
      .select('*, card_delivery_item(*)')
      .order('end_date', ascending: false)
      .order('id', ascending: false);

  final records = _maps(rows);

  // جلب رقم العربية والسجل من جدول vehicle
  final vehicles = await _client
      .from('vehicle')
      .select('id, number, registry');

  final vehicleMap = <int, Map<String, dynamic>>{
    for (final vehicle in vehicles)
      vehicle['id'] as int: Map<String, dynamic>.from(vehicle as Map),
  };

  // إضافة registry لكل عربية داخل سجل تسليم الكروت
  for (final record in records) {
    final rawItems = record['card_delivery_item'];

    if (rawItems is! List) continue;

    for (var i = 0; i < rawItems.length; i++) {
      final rawItem = rawItems[i];

      if (rawItem is! Map) continue;

      final item = Map<String, dynamic>.from(rawItem);
      final vehicleId = item['vehicle_id'];

      if (vehicleId is int) {
        final vehicle = vehicleMap[vehicleId];

        if (vehicle != null) {
          item['registry'] = vehicle['registry'];
          item['vehicle_number'] ??= vehicle['number'];
        }
      }

      rawItems[i] = item;
    }

    record['card_delivery_item'] = rawItems;
  }

  return records;
}

  static Future<Map<String, dynamic>> create(
          DateTime startDate, DateTime endDate) =>
      _rpcMap('create_card_delivery', {
        'p_start_date': _date(startDate),
        'p_end_date': _date(endDate),
      });

  static Future<Map<String, dynamic>> update(
          int id, List<Map<String, dynamic>> items) =>
      _rpcMap('update_card_delivery', {
        'p_record_id': id,
        'p_items': items,
      });

  static Future<Map<String, dynamic>> addVehicle(
          int id, String vehicleNumber) =>
      _rpcMap('add_card_delivery_vehicle', {
        'p_record_id': id,
        'p_vehicle_number': vehicleNumber,
      });

  static Future<Map<String, dynamic>> importGasVehicles(
          int id, String startDate, String endDate) =>
      _rpcMap('import_card_delivery_gas_vehicles', {
        'p_record_id': id,
        'p_start_date': startDate,
        'p_end_date': endDate,
      });

  static Future<Map<String, dynamic>> deleteVehicle(
          int id, int itemId) =>
      _rpcMap('delete_card_delivery_vehicle', {
        'p_record_id': id,
        'p_item_id': itemId,
      });

  static Future<void> delete(int id) async {
    await _client.rpc(
      'delete_card_delivery',
      params: {'p_record_id': id},
    );
  }

  static Future<Map<String, dynamic>> _rpcMap(
      String function, Map<String, dynamic> params) async {
    final result = await _client.rpc(
      function,
      params: params,
    );

    final row = result is List ? result.first : result;

    if (row is! Map) {
      throw StateError('RPC $function أعاد نتيجة غير صالحة.');
    }

    return Map<String, dynamic>.from(row);
  }

  static String _date(DateTime value) =>
      '${value.year.toString().padLeft(4, '0')}-'
      '${value.month.toString().padLeft(2, '0')}-'
      '${value.day.toString().padLeft(2, '0')}';

  static List<Map<String, dynamic>> _maps(Object rows) =>
      (rows as List)
          .map((row) => Map<String, dynamic>.from(row as Map))
          .toList();
}
