import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:excel/excel.dart';
import 'dart:typed_data';

import '../../config/app_config.dart';

class DirectMissionService {
  static SupabaseClient get _client {
    if (!AppConfig.isSupabaseConfigured) {
      throw StateError('Supabase غير مهيأ.');
    }
    return Supabase.instance.client;
  }

  static Future<List<Map<String, dynamic>>> list() async {
  final rows = await _client
      .from('mission')
      .select('*, missionexpense(*)')
      .order('status', ascending: false)
      .order('created_at', ascending: false);

  final missions = _maps(rows);

  for (final mission in missions) {
    mission['expenses'] = mission['missionexpense'] ?? [];
  }

  return missions;
}

  static Future<Map<String, dynamic>> get(int id) async {
  final row = await _client
      .from('mission')
      .select('*, missionexpense(*)')
      .eq('id', id)
      .single();

  final result = _map(row);

  result['expenses'] = result['missionexpense'] ?? [];

  return result;
}

  static Future<Map<String, dynamic>> create(
      Map<String, dynamic> payload) =>
      _rpcMap('create_mission', {'p_payload': payload});

  static Future<Map<String, dynamic>> update(
          int id, Map<String, dynamic> payload) =>
      _rpcMap('update_mission', {
        'p_mission_id': id,
        'p_payload': payload,
      });

  static Future<void> delete(int id) async {
    await _client.rpc('delete_mission', params: {
      'p_mission_id': id,
    });
  }

  static Future<Map<String, dynamic>> addExpense(
          int missionId, Map<String, dynamic> payload) =>
      _rpcMap('add_mission_expense', {
        'p_mission_id': missionId,
        'p_payload': payload,
      });

  static Future<Map<String, dynamic>> updateExpense(
          int missionId,
          int expenseId,
          Map<String, dynamic> payload) =>
      _rpcMap('update_mission_expense', {
        'p_mission_id': missionId,
        'p_expense_id': expenseId,
        'p_payload': payload,
      });

  static Future<void> deleteExpense(
      int missionId,
      int expenseId,
  ) async {
    await _client.rpc('delete_mission_expense', params: {
      'p_mission_id': missionId,
      'p_expense_id': expenseId,
    });
  }

  static Future<Map<String, dynamic>> complete(
      int id, {
        bool force = false,
      }) =>
      _rpcMap('complete_mission', {
        'p_mission_id': id,
        'p_force': force,
      });

  static Future<Map<String, dynamic>> cardTopup(
          Map<String, dynamic> payload) =>
      _rpcMap('card_top_up', {
        'p_payload': payload,
      });

  static Future<Map<String, dynamic>> cardDeduct(
          Map<String, dynamic> payload) =>
      _rpcMap('card_deduct', {
        'p_payload': payload,
      });

  static Future<Uint8List> export({
    DateTime? startDate,
    DateTime? endDate,
    String? vehicleNumber,
  }) async {
    final missions = await list();

    final filtered = missions.where((mission) {
      final createdAt =
          DateTime.tryParse('${mission['created_at'] ?? ''}');

      if (createdAt == null) return false;

      if (startDate != null && createdAt.isBefore(startDate)) {
        return false;
      }

      if (endDate != null && createdAt.isAfter(endDate)) {
        return false;
      }

      if (vehicleNumber != null &&
          vehicleNumber.trim().isNotEmpty) {
        final value = '${mission['vehicle_number'] ?? ''}';

        if (!value.contains(vehicleNumber.trim())) {
          return false;
        }
      }

      return true;
    }).toList();

    final workbook = Excel.createExcel();
    final sheet = workbook['المأموريات والتفويلات'];

    sheet.appendRow([
      'م',
      'تاريخ الإنشاء',
      'رقم السيارة',
      'اللترات المشحونة',
      'نوع الوقود',
      'اسم السائق',
      'الرقم الوظيفي للسائق',
      'الاتجاه',
      'رقم الأمر',
      'تاريخ الأمر',
      'عداد البداية',
      'عداد النهاية',
      'ملاحظات المأمورية',
      'الحالة',
      'تاريخ التفويل',
      'عداد التفويل',
      'لترات التفويل',
      'بيانات الإيصال',
      'ملاحظات التفويل',
    ]);

    for (var index = 0;
        index < filtered.length;
        index++) {
      final mission = filtered[index];

      final expenses =
          (mission['missionexpense'] ??
                  mission['expenses'] ??
                  [])
              as List;

      final base = [
        index + 1,
        mission['created_at'] ?? '',
        mission['vehicle_number'] ?? '',
        mission['charged_liters'] ?? 0,
        mission['fuel_type'] ?? '',
        mission['driver_name'] ?? '',
        mission['driver_job_number'] ?? '',
        mission['direction'] ?? '',
        mission['order_number'] ?? '',
        mission['order_date'] ?? '',
        mission['start_odometer'] ?? '',
        mission['end_odometer'] ?? '',
        mission['notes'] ?? '',
        mission['status'] ?? '',
      ];

      if (expenses.isEmpty) {
        sheet.appendRow([
          ...base,
          '',
          '',
          '',
          '',
          '',
        ]);
        continue;
      }

      for (var expenseIndex = 0;
          expenseIndex < expenses.length;
          expenseIndex++) {
        final expense =
            Map<String, dynamic>.from(
          expenses[expenseIndex] as Map,
        );

        sheet.appendRow([
          ...(expenseIndex == 0
              ? base
              : List<Object?>.filled(
                  base.length,
                  '',
                )),
          expense['date'] ?? '',
          expense['odometer'] ?? '',
          expense['liters'] ?? 0,
          expense['receipt_data'] ?? '',
          expense['notes'] ?? '',
        ]);
      }
    }

    final bytes = workbook.encode();

    if (bytes == null) {
      throw StateError('فشل إنشاء ملف Excel');
    }

    return Uint8List.fromList(bytes);
  }

  static Future<Map<String, dynamic>> _rpcMap(
      String function,
      Map<String, dynamic> params,
  ) async {
    final result =
        await _client.rpc(function, params: params);

    final row = result is List
        ? result.first
        : result;

    if (row is! Map) {
      throw StateError(
        'RPC $function أعاد نتيجة غير صالحة.',
      );
    }

    return _map(row);
  }

  static Map<String, dynamic> _map(Object row) =>
      Map<String, dynamic>.from(row as Map);

  static List<Map<String, dynamic>> _maps(Object rows) =>
      (rows as List)
          .map((row) => _map(row))
          .toList();
}
