import 'package:supabase_flutter/supabase_flutter.dart';

import '../../config/app_config.dart';
import '../../models/refuel.dart';

class DirectRefuelService {
  static SupabaseClient get _client {
    if (!AppConfig.isSupabaseConfigured) {
      throw StateError('Supabase غير مهيأ.');
    }
    return Supabase.instance.client;
  }

  static Future<List<Refuel>> listByVehicle(int vehicleId) async {
    final rows = await _client
        .from('refuel')
        .select()
        .eq('vehicle_id', vehicleId)
        .order('created_at', ascending: false)
        .order('id', ascending: false);
    return (rows as List)
        .map((row) => Refuel.fromJson(Map<String, dynamic>.from(row as Map)))
        .toList();
  }

  static Future<Refuel> create(RefuelCreate input) async {
    final result = await _client.rpc('create_refuel', params: {
      'p_vehicle_id': input.vehicleId,
      'p_current_odometer': input.currentOdometer,
      'p_liters': input.liters,
      'p_created_at': input.createdAt?.toIso8601String().split('T').first,
      'p_station': input.station,
    });
    return _refuelFromRpc(result);
  }

  static Future<Refuel> update(int id, RefuelCreate input) async {
    final result = await _client.rpc('update_refuel', params: {
      'p_refuel_id': id,
      'p_vehicle_id': input.vehicleId,
      'p_current_odometer': input.currentOdometer,
      'p_liters': input.liters,
      'p_created_at': input.createdAt?.toIso8601String().split('T').first,
      'p_station': input.station,
    });
    return _refuelFromRpc(result);
  }

  static Future<void> delete(int id) async {
    await _client.rpc('delete_refuel', params: {'p_refuel_id': id});
  }

  static Refuel _refuelFromRpc(Object? result) {
    final row = result is List ? result.first : result;
    if (row is! Map) {
      throw StateError('RPC التفويلة أعاد نتيجة غير صالحة.');
    }
    return Refuel.fromJson(Map<String, dynamic>.from(row));
  }
}