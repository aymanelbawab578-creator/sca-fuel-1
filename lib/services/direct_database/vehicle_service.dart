import 'package:supabase_flutter/supabase_flutter.dart';

import '../../config/app_config.dart';
import '../../models/vehicle.dart';

class DirectVehicleService {
  static SupabaseClient get _client {
    if (!AppConfig.isSupabaseConfigured) {
      throw StateError(
        'Supabase غير مهيأ. شغّل التطبيق مع SCA_SUPABASE_URL و'
        'SCA_SUPABASE_ANON_KEY.',
      );
    }
    return Supabase.instance.client;
  }

  static List<Vehicle> _vehiclesFromRows(dynamic rows) {
    return (rows as List)
        .map((row) => Vehicle.fromJson(Map<String, dynamic>.from(row as Map)))
        .toList();
  }

  static Future<List<Vehicle>> search(String query) async {
    final rows = await _client
        .from('vehicle')
        .select()
        .eq('number', query)
        .order('id');
    return _vehiclesFromRows(rows);
  }

  static Future<Vehicle> getById(int id) async {
    final row = await _client.from('vehicle').select().eq('id', id).single();
    return Vehicle.fromJson(Map<String, dynamic>.from(row));
  }

  static Future<List<Vehicle>> list({
    String? query,
    int? limit,
    int? offset,
  }) async {
    final safeLimit = (limit ?? 20).clamp(1, 20);
    final safeOffset = (offset ?? 0).clamp(0, 1 << 31);
    var request = _client.from('vehicle').select();
    final normalizedQuery = query?.trim();
    if (normalizedQuery != null && normalizedQuery.isNotEmpty) {
      final pattern = '%${normalizedQuery.replaceAll(',', '')}%';
      request = request.or(
        'number.ilike.$pattern,letters.ilike.$pattern,registry.ilike.$pattern,'
        'code.ilike.$pattern,brand.ilike.$pattern,model.ilike.$pattern,'
        'vehicle_type.ilike.$pattern,fuel_type.ilike.$pattern',
      );
    }
    final rows = await request.range(safeOffset, safeOffset + safeLimit - 1);
    return _vehiclesFromRows(rows);
  }

static Future<Map<String, dynamic>> listPaged({
  String? query,
  int? limit,
  int? offset,
}) async {
  final items = await list(
    query: query,
    limit: limit,
    offset: offset,
  );
  return {
    'items': items,
    'total': items.length,
  };
}

static Future<Vehicle> create(Map<String, dynamic> payload) async {
  final result = await _client.rpc(
    'create_vehicle',
    params: {'p_payload': payload},
  );
  return _vehicleFromRpc(result);
}
  static Future<List<Vehicle>> createBatch(
      List<Map<String, dynamic>> payloads) async {
    final result = await _client.rpc('create_vehicles_batch', params: {'p_payloads': payloads});
    return _vehiclesFromRows(result);
  }

  static Future<Vehicle> update(int id, Map<String, dynamic> payload) async {
    final result = await _client.rpc('update_vehicle', params: {
      'p_vehicle_id': id,
      'p_payload': payload,
    });
    return _vehicleFromRpc(result);
  }

static Future<void> delete(int id) async {
  await _client.rpc(
    'delete_vehicle',
    params: {
      'p_vehicle_id': id,
    },
  );
}

 static Future<List<Map<String, dynamic>>> listPlateChanges() async {
  final result = await _client.rpc('get_vehicle_plate_changes');

  if (result is! List) {
    throw StateError('RPC get_vehicle_plate_changes أعاد نتيجة غير صالحة.');
  }

  return result
      .map((row) => Map<String, dynamic>.from(row as Map))
      .toList();
}
  static Future<Map<String, dynamic>> updatePlateChange(
    int id, String number, String? letters) async {
  final trimmedNumber = number.trim();

  if (trimmedNumber.isEmpty) {
    throw ArgumentError('رقم السيارة مطلوب');
  }

  final result = await _client.rpc(
    'update_plate_change',
    params: {
      'p_change_id': id,
      'p_number': trimmedNumber,
      'p_letters': letters?.trim(),
    },
  );

  if (result is! Map) {
    throw StateError(
      'RPC update_plate_change أعاد نتيجة غير صالحة.',
    );
  }

  return Map<String, dynamic>.from(result);
}

  static Future<void> deletePlateChange(int id) async {
    await _client.rpc('delete_plate_change', params: {'p_change_id': id});
  }

 static Future<Vehicle> updatePlate(
    int id, String number, String? letters) async {
  final trimmedNumber = number.trim();

  if (trimmedNumber.isEmpty) {
    throw ArgumentError('رقم السيارة مطلوب');
  }

  final result = await _client.rpc(
    'change_vehicle_plate',
    params: {
      'p_vehicle_id': id,
      'p_number': trimmedNumber,
      'p_letters': letters?.trim(),
    },
  );

  if (result is! Map) {
    throw StateError(
      'RPC change_vehicle_plate أعاد نتيجة غير صالحة.',
    );
  }

  return Vehicle.fromJson(
    Map<String, dynamic>.from(result),
  );
}

  static Vehicle _vehicleFromRpc(Object? result) {
    final row = result is List ? result.first : result;
    if (row is! Map) throw StateError('RPC المركبة أعاد نتيجة غير صالحة.');
    return Vehicle.fromJson(Map<String, dynamic>.from(row));
  }
}
