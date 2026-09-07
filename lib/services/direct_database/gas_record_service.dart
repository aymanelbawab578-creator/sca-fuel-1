import 'package:supabase_flutter/supabase_flutter.dart';

import '../../config/app_config.dart';
import 'gas_record_logic.dart';

class DirectGasRecordService {
  static SupabaseClient get _client {
    if (!AppConfig.isSupabaseConfigured) {
      throw StateError('Supabase غير مهيأ.');
    }
    return Supabase.instance.client;
  }

  static Future<List<Map<String, dynamic>>> list({
    String? startDate,
    String? endDate,
  }) async {
    var request = _client.from('gas_records').select();
    if (startDate != null) request = request.eq('start_date', startDate);
    if (endDate != null) request = request.eq('end_date', endDate);
    final rows = await request
        .order('end_date', ascending: false)
        .order('id', ascending: false);
    return _maps(rows);
  }

  static Future<Map<String, dynamic>> create(
      Map<String, dynamic> payload) async {
    final amount = _number(payload['amount']);
    final gasPrice = _number(payload['gas_price']);
    _validateDates(payload['start_date'], payload['end_date']);
    final data = {...payload, 'quantity': GasRecordLogic.calculateQuantity(
      amount: amount,
      gasPrice: gasPrice,
    )};
    return _rpcMap('create_gas_record', {'p_payload': data});
  }

  static Future<Map<String, dynamic>> update(
      int id, Map<String, dynamic> payload) async {
    final current = _map(
        await _client.from('gas_records').select().eq('id', id).single());
    final data = {...current, ...payload}
      ..remove('id')
      ..remove('created_at')
      ..remove('updated_at');
    _validateDates(data['start_date'], data['end_date']);
    data['quantity'] = GasRecordLogic.calculateQuantity(
      amount: _number(data['amount']),
      gasPrice: _number(data['gas_price']),
    );
    return _rpcMap('update_gas_record', {
      'p_record_id': id,
      'p_payload': data,
    });
  }

  static Future<void> delete(int id) async {
    await _client.rpc('delete_gas_record', params: {'p_record_id': id});
  }

  static Future<List<Map<String, dynamic>>> report({
    required String fromDate,
    required String toDate,
    String? vehicleNumber,
  }) async {
    _validateDates(fromDate, toDate);
    final rows = await _client
        .from('gas_records')
        .select('vehicle_id,start_date,end_date,amount,quantity,vehicle(*)')
        .gte('end_date', fromDate)
        .lte('end_date', toDate);
    final grouped = <int, Map<String, dynamic>>{};
    for (final rawRow in rows as List) {
      final row = Map<String, dynamic>.from(rawRow as Map);
      final vehicle = Map<String, dynamic>.from(row['vehicle'] as Map);
      final number = '${vehicle['number'] ?? ''}';
      if (vehicleNumber != null &&
          vehicleNumber.trim().isNotEmpty &&
          !number.toLowerCase().contains(vehicleNumber.trim().toLowerCase())) {
        continue;
      }
      final vehicleId = row['vehicle_id'] as int;
      final result = grouped.putIfAbsent(vehicleId, () => {
            'vehicle_id': vehicleId,
            'vehicle_number': number,
            'letters': vehicle['letters'],
            'brand': vehicle['brand'],
            'model': vehicle['model'],
            'vehicle_type': vehicle['vehicle_type'],
            'total_amount': 0.0,
            'total_quantity': 0.0,
          });
      result['total_amount'] += _number(row['amount']);
      result['total_quantity'] += _number(row['quantity']);
    }
    final result = grouped.values.toList()
      ..sort((left, right) =>
          '${left['vehicle_number']}'.compareTo('${right['vehicle_number']}'));
    return result;
  }

  static void _validateDates(Object? start, Object? end) {
    final startDate = DateTime.parse('$start');
    final endDate = DateTime.parse('$end');
    GasRecordLogic.validatePeriod(startDate: startDate, endDate: endDate);
  }

  static double _number(Object? value) => (value as num).toDouble();

  static Map<String, dynamic> _map(Object row) =>
      Map<String, dynamic>.from(row as Map);

  static List<Map<String, dynamic>> _maps(Object rows) =>
      (rows as List).map((row) => _map(row)).toList();

  static Future<Map<String, dynamic>> _rpcMap(
      String function, Map<String, dynamic> params) async {
    final result = await _client.rpc(function, params: params);
    final row = result is List ? result.first : result;
    if (row is! Map) throw StateError('RPC $function أعاد نتيجة غير صالحة.');
    return _map(row);
  }
}