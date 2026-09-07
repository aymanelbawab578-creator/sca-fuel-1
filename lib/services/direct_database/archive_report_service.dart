import 'package:supabase_flutter/supabase_flutter.dart';

import '../../config/app_config.dart';
import 'temporary_archive_store.dart';

class ArchiveReportService {
  static SupabaseClient get _client {
    if (!AppConfig.isSupabaseConfigured) {
      throw StateError('Supabase غير مهيأ.');
    }

    return Supabase.instance.client;
  }

  // ============================================================
  // Daily
  // ============================================================

  static Future<Map<String, dynamic>> daily(String date) async {
    final result = await _client.rpc(
      'get_daily_report',
      params: {
        'p_date': date,
      },
    );

    final liveReport = _rpcMapResult(
      result,
      'get_daily_report',
    );

    final archiveRefuels = TemporaryArchiveStore.refuels(
      startDate: DateTime.parse(date),
      endDate: DateTime.parse(date),
    );

    if (archiveRefuels.isEmpty) {
      return liveReport;
    }

    final liveRecords = _records(liveReport['records']);

    final archiveRecords = await _enrichArchiveRefuels(
      archiveRefuels,
    );

    final merged = _mergeRefuels(
      archiveRecords,
      liveRecords,
    );

    return {
      ...liveReport,
      'records': merged,
      'count': merged.length,
      'totals': _buildDailyTotals(merged),
      'status_summary': _buildDailyStatusSummary(merged),
    };
  }

  // ============================================================
  // Range
  // ============================================================

  static Future<Map<String, dynamic>> range(
    String startDate,
    String endDate,
  ) async {
    final result = await _client.rpc(
      'get_range_report',
      params: {
        'p_start_date': startDate,
        'p_end_date': endDate,
      },
    );

    final liveReport = _rpcMapResult(
      result,
      'get_range_report',
    );

    final archiveRefuels = TemporaryArchiveStore.refuels(
      startDate: DateTime.parse(startDate),
      endDate: DateTime.parse(endDate),
    );

    if (archiveRefuels.isEmpty) {
      return liveReport;
    }

    final archiveRecords = await _enrichArchiveRefuels(
      archiveRefuels,
    );

    final liveRecords = _records(
      liveReport['records'],
    );

    /*
     * get_range_report already calculates:
     *
     * - live refuels
     * - live gas_records
     * - previous live refuel
     * - distance
     * - consumption ratio
     * - status
     *
     * We therefore keep that calculation intact so gas_records
     * continue to work exactly as they do in the live report.
     *
     * Archived refuels are merged into the returned details/records.
     * Live data remains authoritative when the same refuel ID exists.
     */

    final merged = _mergeRefuels(
      archiveRecords,
      liveRecords,
    );

    /*
     * Recalculate the top-level refuel count from the merged
     * refuel records instead of adding archive count to live count.
     */
    return {
      ...liveReport,
      'records': merged,
      'count': merged.length,
      'vehicle_count': _vehicleCount(merged),
    };
  }

  // ============================================================
  // Station fuel quantities
  // ============================================================

  static Future<Map<String, dynamic>> stationFuelQuantities(
    String startDate,
    String endDate,
  ) async {
    final result = await _client.rpc(
      'get_station_fuel_quantities',
      params: {
        'p_start_date': startDate,
        'p_end_date': endDate,
      },
    );

    final liveReport = _rpcMapResult(
      result,
      'get_station_fuel_quantities',
    );

    final archiveRefuels = TemporaryArchiveStore.refuels(
      startDate: DateTime.parse(startDate),
      endDate: DateTime.parse(endDate),
    );

    if (archiveRefuels.isEmpty) {
      return liveReport;
    }

    final archiveRecords = await _enrichArchiveRefuels(
      archiveRefuels,
    );

    /*
     * We must remove archived records whose ID already exists
     * in the live database. Live is authoritative.
     */
    final liveRecords = await _getLiveRefuels(
      startDate,
      endDate,
    );

    final mergedRefuels = _mergeRefuels(
      archiveRecords,
      liveRecords,
    );

    return _buildStationReportFromRefuels(
      mergedRefuels,
      startDate,
      endDate,
      liveReport,
    );
  }

  // ============================================================
  // Fetch live refuels for exact archive/live merge
  // ============================================================

  static Future<List<Map<String, dynamic>>> _getLiveRefuels(
    String startDate,
    String endDate,
  ) async {
    final rows = await _client
        .from('refuel')
        .select(
          'id,vehicle_id,current_odometer,liters,actual_percentage,'
          'created_at,is_excess,is_illogical,station',
        )
        .gte('created_at', startDate)
        .lte('created_at', endDate);

    if (rows is! List) {
      return [];
    }

    return rows
        .whereType<Map>()
        .map(
          (row) => Map<String, dynamic>.from(row),
        )
        .toList();
  }

  // ============================================================
  // Archive refuels enrichment
  // ============================================================

  static Future<List<Map<String, dynamic>>> _enrichArchiveRefuels(
    List<Map<String, dynamic>> archiveRefuels,
  ) async {
    if (archiveRefuels.isEmpty) {
      return [];
    }

    final vehicleIds = archiveRefuels
        .map((row) => _toInt(row['vehicle_id']))
        .whereType<int>()
        .toSet()
        .toList();

    if (vehicleIds.isEmpty) {
      return archiveRefuels
          .map(_normalizeArchiveRefuel)
          .toList();
    }

    final vehicleResult = await _client
        .from('vehicle')
        .select()
        .inFilter('id', vehicleIds);

    final vehicles = <int, Map<String, dynamic>>{};

    if (vehicleResult is List) {
      for (final item in vehicleResult) {
        if (item is! Map) {
          continue;
        }

        final vehicle = Map<String, dynamic>.from(item);
        final id = _toInt(vehicle['id']);

        if (id != null) {
          vehicles[id] = vehicle;
        }
      }
    }

    return archiveRefuels.map((original) {
      final row = _normalizeArchiveRefuel(original);

      final vehicleId = _toInt(row['vehicle_id']);
      final vehicle =
          vehicleId == null ? null : vehicles[vehicleId];

      if (vehicle == null) {
        return row;
      }

      row['vehicle_number'] ??=
          vehicle['vehicle_number'] ?? vehicle['number'];

      row['vehicle_letters'] ??=
          vehicle['vehicle_letters'] ?? vehicle['letters'];

      row['registry'] ??= vehicle['registry'];

      row['vehicle_type'] ??=
          vehicle['vehicle_type'];

      row['fuel_type'] ??=
          vehicle['fuel_type'];

      return row;
    }).toList();
  }

  // ============================================================
  // Normalize archived refuel
  // ============================================================

  static Map<String, dynamic> _normalizeArchiveRefuel(
    Map<String, dynamic> original,
  ) {
    final row = Map<String, dynamic>.from(original);

    final id = row['id'];

    final actualPercentage =
        _toDouble(row['actual_percentage']) ?? 0;

    row['refuel_id'] ??= id;

    row['odometer'] ??=
        row['current_odometer'];

    row['consumption_ratio'] ??=
        actualPercentage;

    row['status'] ??=
        _archiveStatus(row);

    row['status_code'] ??=
        _archiveStatusCode(row);

    row['source'] = 'archive';

    return row;
  }

  static String _archiveStatus(
    Map<String, dynamic> row,
  ) {
    final isIllogical =
        row['is_illogical'] == true;

    final isExcess =
        row['is_excess'] == true;

    if (isIllogical) {
      return 'نسبة غير منطقية';
    }

    if (isExcess) {
      return 'متجاوز';
    }

    return 'طبيعي';
  }

  static String _archiveStatusCode(
    Map<String, dynamic> row,
  ) {
    final isIllogical =
        row['is_illogical'] == true;

    final isExcess =
        row['is_excess'] == true;

    if (isIllogical) {
      return 'illogical';
    }

    if (isExcess) {
      return 'excess';
    }

    return 'natural';
  }

  // ============================================================
  // Merge archive + live
  // ============================================================

  static List<Map<String, dynamic>> _mergeRefuels(
    List<Map<String, dynamic>> archiveRecords,
    List<Map<String, dynamic>> liveRecords,
  ) {
    final merged =
        <String, Map<String, dynamic>>{};

    /*
     * Archive first.
     */
    for (final record in archiveRecords) {
      final key = _refuelKey(record);

      if (key != null) {
        merged[key] =
            Map<String, dynamic>.from(record);
      } else {
        merged[
                'archive_${merged.length}'] =
            Map<String, dynamic>.from(record);
      }
    }

    /*
     * Live second.
     *
     * Therefore live always wins if the same refuel ID
     * exists in both archive and live.
     */
    for (final record in liveRecords) {
      final key = _refuelKey(record);

      if (key != null) {
        merged[key] =
            Map<String, dynamic>.from(record);
      } else {
        merged[
                'live_${merged.length}'] =
            Map<String, dynamic>.from(record);
      }
    }

    final result = merged.values.toList();

    result.sort((a, b) {
      final aDate = DateTime.tryParse(
        a['created_at']?.toString() ?? '',
      );

      final bDate = DateTime.tryParse(
        b['created_at']?.toString() ?? '',
      );

      if (aDate == null &&
          bDate == null) {
        return 0;
      }

      if (aDate == null) {
        return -1;
      }

      if (bDate == null) {
        return 1;
      }

      return aDate.compareTo(bDate);
    });

    return result;
  }

  static String? _refuelKey(
    Map<String, dynamic> row,
  ) {
    final id =
        row['refuel_id'] ?? row['id'];

    if (id == null) {
      return null;
    }

    return id.toString();
  }

  // ============================================================
  // Daily totals
  // ============================================================

  static Map<String, dynamic> _buildDailyTotals(
    List<Map<String, dynamic>> records,
  ) {
    var solar = 0.0;
    var gasoline92 = 0.0;
    var gasoline95 = 0.0;
    var total = 0.0;

    for (final row in records) {
      final liters =
          _toDouble(row['liters']) ?? 0;

      final fuelType =
          _normalize(row['fuel_type']);

      if (fuelType == 'سولار') {
        solar += liters;
      } else if (fuelType == 'بنزين 92') {
        gasoline92 += liters;
      } else if (fuelType == 'بنزين 95') {
        gasoline95 += liters;
      }

      total += liters;
    }

    return {
      'solar': solar,
      'gasoline_92': gasoline92,
      'gasoline_95': gasoline95,
      'total': total,
    };
  }

  static Map<String, dynamic> _buildDailyStatusSummary(
    List<Map<String, dynamic>> records,
  ) {
    var natural = 0;
    var excess = 0;
    var illogical = 0;

    for (final row in records) {
      final code =
          row['status_code']?.toString();

      if (code == 'illogical') {
        illogical++;
      } else if (code == 'excess') {
        excess++;
      } else {
        natural++;
      }
    }

    return {
      'natural': natural,
      'excess': excess,
      'illogical': illogical,
    };
  }

  // ============================================================
  // Station report
  // ============================================================

  static Map<String, dynamic> _buildStationReportFromRefuels(
    List<Map<String, dynamic>> refuels,
    String startDate,
    String endDate,
    Map<String, dynamic> liveReport,
  ) {
    final stationMap =
        <String, Map<String, dynamic>>{};

    for (final record in refuels) {
      final stationName =
          _normalizeStation(
        record['station'],
      );

      final date =
          _dateOnlyString(
        record['created_at'],
      );

      if (date == null) {
        continue;
      }

      final liters =
          _toDouble(record['liters']) ?? 0;

      final fuelType =
          _normalize(record['fuel_type']);

      /*
       * The live RPC determines fuel type from vehicle.
       *
       * Archived records are enriched from the current vehicle,
       * so fuel_type should normally be available.
       */
      String? bucket;

      if (fuelType == 'سولار') {
        bucket = 'solar';
      } else if (fuelType == 'بنزين 92') {
        bucket = 'gasoline_92';
      } else if (fuelType == 'بنزين 95') {
        bucket = 'gasoline_95';
      }

      if (bucket == null) {
        continue;
      }

      final station =
          stationMap.putIfAbsent(
        stationName,
        () => {
          'station': stationName,
          'rows': <Map<String, dynamic>>[],
          'totals': {
            'solar': 0.0,
            'gasoline_92': 0.0,
            'gasoline_95': 0.0,
            'total': 0.0,
          },
        },
      );

      final rows =
          station['rows'];

      if (rows is! List) {
        continue;
      }

      Map<String, dynamic>? dayRow;

      for (final item in rows) {
        if (item is Map &&
            item['date']?.toString() ==
                date) {
          dayRow =
              Map<String, dynamic>.from(
            item,
          );
          break;
        }
      }

      if (dayRow == null) {
        dayRow = {
          'date': date,
          'solar': 0.0,
          'gasoline_92': 0.0,
          'gasoline_95': 0.0,
          'total': 0.0,
        };

        rows.add(dayRow);
      }

      dayRow[bucket] =
          (_toDouble(dayRow[bucket]) ?? 0) +
              liters;

      dayRow['total'] =
          (_toDouble(dayRow['solar']) ?? 0) +
          (_toDouble(dayRow['gasoline_92']) ?? 0) +
          (_toDouble(dayRow['gasoline_95']) ?? 0);
    }

    var solarTotal = 0.0;
    var gasoline92Total = 0.0;
    var gasoline95Total = 0.0;

    for (final station
        in stationMap.values) {
      final rows =
          station['rows'];

      if (rows is! List) {
        continue;
      }

      rows.sort((a, b) {
        final aDate = a is Map
            ? a['date']?.toString() ?? ''
            : '';

        final bDate = b is Map
            ? b['date']?.toString() ?? ''
            : '';

        return aDate.compareTo(bDate);
      });

      var stationSolar = 0.0;
      var station92 = 0.0;
      var station95 = 0.0;

      for (final item in rows) {
        if (item is! Map) {
          continue;
        }

        stationSolar +=
            _toDouble(
                  item['solar'],
                ) ??
                0;

        station92 +=
            _toDouble(
                  item['gasoline_92'],
                ) ??
                0;

        station95 +=
            _toDouble(
                  item['gasoline_95'],
                ) ??
                0;
      }

      station['totals'] = {
        'solar': stationSolar,
        'gasoline_92': station92,
        'gasoline_95': station95,
        'total':
            stationSolar +
            station92 +
            station95,
      };

      solarTotal += stationSolar;
      gasoline92Total += station92;
      gasoline95Total += station95;
    }

    return {
      ...liveReport,
      'start_date': startDate,
      'end_date': endDate,
      'count': refuels.length,
      'station_count':
          stationMap.length,
      'stations':
          stationMap.values.toList(),
      'totals': {
        'solar': solarTotal,
        'gasoline_92':
            gasoline92Total,
        'gasoline_95':
            gasoline95Total,
        'total':
            solarTotal +
            gasoline92Total +
            gasoline95Total,
      },
    };
  }

  // ============================================================
  // Helpers
  // ============================================================

  static Map<String, dynamic> _rpcMapResult(
    dynamic result,
    String function,
  ) {
    if (result is List) {
      if (result.isEmpty) {
        throw StateError(
          'RPC $function أعادت نتيجة فارغة.',
        );
      }

      final first = result.first;

      if (first is! Map) {
        throw StateError(
          'RPC $function أعادت نتيجة غير صالحة.',
        );
      }

      return Map<String, dynamic>.from(
        first,
      );
    }

    if (result is Map) {
      return Map<String, dynamic>.from(
        result,
      );
    }

    throw StateError(
      'RPC $function أعادت نتيجة غير صالحة.',
    );
  }

  static List<Map<String, dynamic>> _records(
    dynamic value,
  ) {
    if (value is! List) {
      return [];
    }

    return value
        .whereType<Map>()
        .map(
          (row) =>
              Map<String, dynamic>.from(row),
        )
        .toList();
  }

  static int _vehicleCount(
    List<Map<String, dynamic>> records,
  ) {
    return records
        .map(
          (row) => row['vehicle_id'],
        )
        .where(
          (id) => id != null,
        )
        .map(
          (id) => id.toString(),
        )
        .toSet()
        .length;
  }

  static int? _toInt(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is int) {
      return value;
    }

    return int.tryParse(
      value.toString(),
    );
  }

  static double? _toDouble(
    dynamic value,
  ) {
    if (value == null) {
      return null;
    }

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(
      value.toString(),
    );
  }

  static String _normalize(
    dynamic value,
  ) {
    return value
            ?.toString()
            .trim()
            .replaceAll(
              RegExp(r'\s+'),
              ' ',
            )
            .toLowerCase() ??
        '';
  }

  static String _normalizeStation(
    dynamic value,
  ) {
    var station =
        value?.toString().trim() ?? '';

    station = station.replaceAll(
      RegExp(r'\s+'),
      ' ',
    );

    if (station.isEmpty) {
      return 'غير محدد';
    }

    if (station.startsWith('محطة ')) {
      station =
          station.substring(5).trim();
    } else if (station == 'محطة') {
      return 'غير محدد';
    }

    return station;
  }

  static String? _dateOnlyString(
    dynamic value,
  ) {
    if (value == null) {
      return null;
    }

    final parsed =
        DateTime.tryParse(
      value.toString(),
    );

    if (parsed == null) {
      return null;
    }

    return '${parsed.year.toString().padLeft(4, '0')}-'
        '${parsed.month.toString().padLeft(2, '0')}-'
        '${parsed.day.toString().padLeft(2, '0')}';
  }
}
