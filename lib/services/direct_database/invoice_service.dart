import 'package:supabase_flutter/supabase_flutter.dart';

import '../../config/app_config.dart';

class DirectInvoiceService {
  static SupabaseClient get _client {
    if (!AppConfig.isSupabaseConfigured) {
      throw StateError('Supabase غير مهيأ.');
    }
    return Supabase.instance.client;
  }

  static Future<Map<String, dynamic>> create(
      Map<String, dynamic> payload) async {
    return _rpcMap('create_invoice', {'p_payload': _payload(payload)});
  }

  static Future<List<Map<String, dynamic>>> list({
    String? station,
    DateTime? date,
    int? month,
    int? year,
    String? invoiceNumber,
  }) async {
    var request = _client.from('invoice').select();
    if (station != null && station.isNotEmpty) {
      request = request.eq('station', station);
    }
    if (date != null) {
      request = request.eq('end_date', _date(date));
    } else {
      if (year != null) {
        request = request.gte('end_date', '$year-01-01');
        request = request.lte('end_date', '$year-12-31');
      }
      if (month != null && year != null) {
        final start = DateTime(year, month, 1);
        final end = DateTime(year, month + 1, 0);
        request = request.gte('end_date', _date(start));
        request = request.lte('end_date', _date(end));
      }
    }
    if (invoiceNumber != null && invoiceNumber.isNotEmpty) {
      request = request.eq('invoice_number', invoiceNumber);
    }
    final rows = await request
        .order('end_date', ascending: false)
        .order('id', ascending: false);
    return _maps(rows);
  }

  static Future<Map<String, dynamic>> get(int id) async {
    final row = await _client.from('invoice').select().eq('id', id).single();
    return _map(row);
  }

  static Future<Map<String, dynamic>> update(
      int id, Map<String, dynamic> payload) async {
    return _rpcMap('update_invoice', {
      'p_invoice_id': id,
      'p_payload': _payload(payload),
    });
  }

  static Future<void> delete(int id) async {
    await _client.rpc('delete_invoice', params: {'p_invoice_id': id});
  }

  static Future<Map<String, dynamic>> calculate({
    required String station,
    required String startDate,
    required String endDate,
    required Map<String, double> prices,
  }) async {
    final result = await _client.rpc('calculate_invoice', params: {
      'p_station': station,
      'p_start_date': startDate,
      'p_end_date': endDate,
      'p_prices': prices,
    });
    return _map(result is List ? result.first : result);
  }

  static Map<String, dynamic> _payload(Map<String, dynamic> payload) => {
        'station': payload['station'],
        'start_date': payload['start_date'],
        'end_date': payload['end_date'],
        'created_at': payload['created_at'] ?? payload['end_date'],
        'invoice_number': payload['invoice_number'],
        'total_amount': payload['total_amount'] ?? 0.0,
        'items': payload['items'] ?? [],
        'prices': payload['prices'] ?? {},
      };

  static String _date(DateTime value) =>
      '${value.year.toString().padLeft(4, '0')}-'
      '${value.month.toString().padLeft(2, '0')}-'
      '${value.day.toString().padLeft(2, '0')}';

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