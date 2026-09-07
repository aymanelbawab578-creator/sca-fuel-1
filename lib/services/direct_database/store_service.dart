import 'dart:convert';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../config/app_config.dart';

class DirectStoreService {
  static SupabaseClient get _client {
    if (!AppConfig.isSupabaseConfigured) {
      throw StateError('Supabase غير مهيأ.');
    }
    return Supabase.instance.client;
  }

  // ============================================================
  // Add Invoices
  // ============================================================

  static Future<List<Map<String, dynamic>>> listAddInvoices() async {
    final rows = await _client
        .from('add_invoice')
        .select()
        .eq('is_deleted', false)
        .order('created_at', ascending: false)
        .order('id', ascending: false);

    return _maps(rows);
  }

  static Future<Map<String, dynamic>> getAddInvoice(int id) async {
    final row =
        await _client.from('add_invoice').select().eq('id', id).single();

    return _map(row);
  }

  static Future<Map<String, dynamic>> createAddInvoice(
      Map<String, dynamic> payload) async {
    final row = await _client
        .from('add_invoice')
        .insert(_invoicePayload(payload))
        .select()
        .single();

    return _map(row);
  }

  static Future<Map<String, dynamic>> updateAddInvoice(
      int id, Map<String, dynamic> payload) async {
    final row = await _client
        .from('add_invoice')
        .update(_invoicePayload(payload))
        .eq('id', id)
        .select()
        .single();

    return _map(row);
  }

  static Future<void> deleteAddInvoice(int id) async {
    await _client.rpc(
      'delete_add_invoice',
      params: {'p_invoice_id': id},
    );
  }

  // ============================================================
  // Inventory Counts
  // ============================================================

  static Future<Map<String, dynamic>> createInventoryCount(
      Map<String, dynamic> payload) async {
    final details = payload['details'] is String
        ? payload['details']
        : jsonEncode(payload['details'] ?? []);

    final countPayload = {
      'counted_at': payload['counted_at'],
      'details': details,
      'total_value': _number(payload['total_value']).toStringAsFixed(2),
    };

    final result = await _client.rpc(
      'create_inventory_count',
      params: {
        'p_payload': countPayload,
      },
    );

    return _inventoryCount(
      _map(result is List ? result.first : result),
    );
  }

  static Future<List<Map<String, dynamic>>> listInventoryCounts() async {
    final rows = await _client
        .from('inventory_count')
        .select()
        .order('counted_at', ascending: false)
        .order('id', ascending: false);

    return _maps(rows).map(_inventoryCount).toList();
  }

  static Future<void> deleteInventoryCount(int id) async {
    await _client.rpc(
      'delete_inventory_count',
      params: {'p_count_id': id},
    );
  }

  // ============================================================
  // Invoice Prices
  // ============================================================

  static Future<Map<String, dynamic>> fetchInvoicePrices() async {
    final rows = await _client.from('invoicepricesetting').select();

    final prices = <String, double>{};

    for (final row in rows as List) {
      final value = Map<String, dynamic>.from(row as Map);

      prices['${value['fuel_type']}'] = _number(value['price']);
    }

    return {
      'prices': prices,
    };
  }

  static Future<List<Map<String, dynamic>>> fetchInvoicePriceHistory() async {
    final rows = await _client
        .from('invoicepricechangelog')
        .select()
        .order('changed_at', ascending: false);

    return _maps(rows);
  }

  static Future<void> deleteInvoicePriceHistory(int id) async {
    await _client.rpc(
      'delete_invoice_price_change_log',
      params: {'p_log_id': id},
    );
  }

  // ============================================================
  // Inventory Discount
  // ============================================================

  static Future<Map<String, dynamic>> createInventoryDiscount(
      Map<String, dynamic> payload) async {
    final normalized = {...payload};

    normalized['fuel_type'] =
        _normalizeFuelType('${payload['fuel_type'] ?? ''}');

    final row = await _client
        .from('inventory_discount')
        .insert(normalized)
        .select()
        .single();

    return _map(row);
  }

  // ============================================================
  // Store Balances
  //
  // الحساب يتم الآن عن طريق RPC:
  // get_store_balances
  // ============================================================

  static Future<Map<String, dynamic>> fetchStoreBalances() async {
    final result = await _client.rpc('get_store_balances');

    return Map<String, dynamic>.from(result as Map);
  }

  // ============================================================
  // Price Change
  // ============================================================

  static Future<Map<String, dynamic>> applyPriceChange(
    Map<String, dynamic> payload) async {
  final items = payload['items'];

  if (items is! List) {
    throw StateError('items must be a list');
  }

  final result = await _client.rpc(
    'apply_price_change',
    params: {
      'p_change_date': payload['change_date'],
      'p_items': items,
    },
  );

  if (result is Map) {
    return Map<String, dynamic>.from(result);
  }

  throw StateError('Invalid response from apply_price_change');
}

  static Future<Map<String, dynamic>> saveInvoicePrices(
      Map<String, double> prices) async {
    return _unsupportedAtomic('save_invoice_prices');
  }

  static Future<Map<String, dynamic>> _unsupportedAtomic(
      String operation) {
    throw StateError(
      '$operation يتطلب RPC ذرية قبل تنفيذه مباشرة.',
    );
  }

  // ============================================================
  // Helpers
  // ============================================================

  static double _number(Object? value) {
    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse('$value') ?? 0.0;
  }

  static String _normalizeFuelType(String value) {
    return const {
          'ديزل': 'سولار',
          'بنزين': 'بنزين 92',
          'بنزين92': 'بنزين 92',
          'بنزين95': 'بنزين 95',
        }[value] ??
        value;
  }

  static Map<String, dynamic> _invoicePayload(
      Map<String, dynamic> payload) {
    var solarQuantity = _number(payload['solar_quantity']);
    var gasoline92Quantity = _number(payload['gasoline_92_quantity']);
    var gasoline95Quantity = _number(payload['gasoline_95_quantity']);

    final items = payload['items'];

    if (items is List) {
      solarQuantity = 0;
      gasoline92Quantity = 0;
      gasoline95Quantity = 0;

      for (final item in items.whereType<Map>()) {
        final value = _number(item['item_value']);
        final price = _number(item['price_at_creation']);

        final quantity = price == 0 ? 0 : value / price;

        switch ('${item['fuel_type']}') {
          case 'سولار':
            solarQuantity += quantity;
            break;

          case 'بنزين 92':
            gasoline92Quantity += quantity;
            break;

          case 'بنزين 95':
            gasoline95Quantity += quantity;
            break;
        }
      }
    }

    final solarPrice = _number(payload['solar_price']);
    final gasoline92Price = _number(payload['gasoline_92_price']);
    final gasoline95Price = _number(payload['gasoline_95_price']);

    return {
      'invoice_number': payload['invoice_number'],
      'created_at': payload['created_at'],

      'solar_quantity': solarQuantity,
      'solar_price': solarPrice,
      'solar_total': _round(
        solarQuantity * solarPrice,
      ),

      'gasoline_92_quantity': gasoline92Quantity,
      'gasoline_92_price': gasoline92Price,
      'gasoline_92_total': _round(
        gasoline92Quantity * gasoline92Price,
      ),

      'gasoline_95_quantity': gasoline95Quantity,
      'gasoline_95_price': gasoline95Price,
      'gasoline_95_total': _round(
        gasoline95Quantity * gasoline95Price,
      ),

      'total_amount': _round(
        solarQuantity * solarPrice +
            gasoline92Quantity * gasoline92Price +
            gasoline95Quantity * gasoline95Price,
      ),

      'details': items is List
          ? jsonEncode(items)
          : payload['details'],

      'is_deleted': false,
      'deleted_at': null,
    };
  }

  static double _round(double value) {
    return (value * 100).roundToDouble() / 100;
  }

  static Map<String, dynamic> _inventoryCount(
      Map<String, dynamic> row) {
    final value = {...row};

    final details = value['details'];

    if (details is String) {
      value['details'] = jsonDecode(details);
    }

    return value;
  }

  static Map<String, dynamic> _map(Object row) {
    return Map<String, dynamic>.from(row as Map);
  }

  static List<Map<String, dynamic>> _maps(Object rows) {
    return (rows as List)
        .map((row) => _map(row))
        .toList();
  }
}
