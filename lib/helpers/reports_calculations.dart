import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/refuel.dart';
import '../models/vehicle.dart';

class RefuelRecord {
  final int id;
  final int vehicleId;
  final String vehicleNumber;
  final String? vehicleLetters;
  final String vehicleType;
  final double odometer;
  final double liters;
  final double consumptionRatio;
  final bool isExcess;
  final bool isIllogical;
  final DateTime date;

  RefuelRecord({
    required this.id,
    required this.vehicleId,
    required this.vehicleNumber,
    this.vehicleLetters,
    required this.vehicleType,
    required this.odometer,
    required this.liters,
    required this.consumptionRatio,
    required this.isExcess,
    required this.isIllogical,
    required this.date,
  });

  String get status {
    if (isExcess) return 'متجاوز';
    if (isIllogical) return 'نسبة غير منطقية';
    return 'طبيعي';
  }

  Color get statusColor {
    if (isExcess) return const Color(0xFFFF5252); // أحمر
    if (isIllogical) return const Color(0xFFFFC107); // أصفر
    return const Color(0xFF4CAF50); // أخضر
  }
}

class DailyReportResult {
  final List<RefuelRecord> records;
  final int totalRefuels;
  final double totalLiters;
  final int excessCount;
  final int illogicalCount;

  DailyReportResult({
    required this.records,
    required this.totalRefuels,
    required this.totalLiters,
    required this.excessCount,
    required this.illogicalCount,
  });
}

class PeriodReportRecord {
  final int vehicleId;
  final String vehicleNumber;
  final String? vehicleLetters;
  final String vehicleType;
  final double startOdometer;
  final double endOdometer;
  final double distance;
  final double totalLiters;
  final double consumptionRatio;
  final bool isExcess;
  final bool isIllogical;

  PeriodReportRecord({
    required this.vehicleId,
    required this.vehicleNumber,
    this.vehicleLetters,
    required this.vehicleType,
    required this.startOdometer,
    required this.endOdometer,
    required this.distance,
    required this.totalLiters,
    required this.consumptionRatio,
    required this.isExcess,
    required this.isIllogical,
  });

  String get status {
    if (isExcess) return 'متجاوز';
    if (isIllogical) return 'نسبة غير منطقية';
    return 'طبيعي';
  }

  Color get statusColor {
    if (isExcess) return const Color(0xFFFF5252);
    if (isIllogical) return const Color(0xFFFFC107);
    return const Color(0xFF4CAF50);
  }
}

class PeriodReportResult {
  final List<PeriodReportRecord> records;

  PeriodReportResult({required this.records});

  int get totalRecords => records.length;
  double get totalLiters => records.fold(0.0, (sum, r) => sum + r.totalLiters);
}

class QuantityReportRecord {
  final int vehicleId;
  final String vehicleNumber;
  final String? vehicleLetters;
  final List<QuantityDetail> details;

  QuantityReportRecord({
    required this.vehicleId,
    required this.vehicleNumber,
    this.vehicleLetters,
    required this.details,
  });

  int get totalRefuels => details.length;
  double get totalLiters => details.fold(0.0, (sum, d) => sum + d.liters);
}

class QuantityDetail {
  final double liters;
  final DateTime date;

  QuantityDetail({required this.liters, required this.date});

  String get formattedLiters => liters.toStringAsFixed(1);
  String get formattedDate => DateFormat('dd/MM/yyyy').format(date);
}

class QuantityReportResult {
  final List<QuantityReportRecord> records;

  QuantityReportResult({required this.records});

  int get totalRefuels => records.fold(0, (sum, r) => sum + r.totalRefuels);
  double get totalLiters => records.fold(0.0, (sum, r) => sum + r.totalLiters);
}

class ReportsCalculations {
  static String shortStationName(String? stationName) {
    final normalized = (stationName ?? '').trim();
    if (normalized.isEmpty) return 'غير محدد';
    switch (normalized) {
      case 'بورسعيد':
      case 'بورفؤاد':
      case 'الإسماعيلية':
      case 'السويس':
        return normalized;
      case 'محطة الكارت':
        return 'كارت';
      default:
        return normalized;
    }
  }

  // حساب نسبة الاستهلاك (لتر / 100 كم)
  static double calculateConsumptionRatio(double liters, double distance) {
    if (distance == 0) return 0;
    return (liters / distance) * 100;
  }

  static double calculateRefuelConsumptionRatio(double liters, double currentOdometer, double? previousOdometer) {
    if (previousOdometer == null || previousOdometer < 0) return 0;
    final distance = currentOdometer - previousOdometer;
    if (distance <= 0) return 0;
    return (liters / distance) * 100;
  }

  // معايير الفحص
  static bool isExcessConsumption(num ratio, num standardRatio) {
    final double ratioValue = ratio.toDouble();
    final double standardValue = standardRatio.toDouble();
    if (standardValue <= 0) return false;
    return ratioValue > standardValue * 1.5;
  }

  static bool isIllogicalConsumption(num ratio, num standardRatio) {
    final double ratioValue = ratio.toDouble();
    final double standardValue = standardRatio.toDouble();
    if (standardValue <= 0) return true;
    return ratioValue < standardValue * 0.5;
  }

  static String statusLabel(num ratio, num standardRatio) {
    if (isExcessConsumption(ratio, standardRatio)) {
      return 'متجاوز';
    }
    if (isIllogicalConsumption(ratio, standardRatio)) {
      return 'نسبة غير منطقية';
    }
    return 'طبيعي';
  }

  static Color statusColor(String status) {
    final normalized = status.trim();
    if (normalized == 'متجاوز' || normalized == 'تجاوز') {
      return const Color(0xFFFF5252);
    }
    if (normalized == 'نسبة غير منطقية' || normalized == 'غير منطقي') {
      return const Color(0xFFFFC107);
    }
    return const Color(0xFF4CAF50);
  }

  // التقرير اليومي
  static DailyReportResult generateDailyReport(
    DateTime date,
    List<Refuel> refuels,
    Map<int, Vehicle> vehiclesMap,
  ) {
    final dateOnly = DateTime(date.year, date.month, date.day);
    final records = <RefuelRecord>[];
    int excessCount = 0;
    int illogicalCount = 0;
    double totalLiters = 0;

    for (var refuel in refuels) {
      final refuelDate = DateTime.parse(refuel.createdAt);
      final refuelDateOnly = DateTime(refuelDate.year, refuelDate.month, refuelDate.day);

      if (refuelDateOnly == dateOnly) {
        final vehicle = vehiclesMap[refuel.vehicleId];
        if (vehicle != null) {
          final record = RefuelRecord(
            id: refuel.id,
            vehicleId: refuel.vehicleId,
            vehicleNumber: vehicle.number,
            vehicleLetters: vehicle.letters,
            vehicleType: vehicle.vehicleType,
            odometer: refuel.currentOdometer,
            liters: refuel.liters,
            consumptionRatio: refuel.actualPercentage,
            isExcess: refuel.isExcess,
            isIllogical: refuel.isIllogical,
            date: refuelDate,
          );

          records.add(record);
          totalLiters += refuel.liters;

          if (refuel.isExcess) excessCount++;
          if (refuel.isIllogical) illogicalCount++;
        }
      }
    }

    return DailyReportResult(
      records: records,
      totalRefuels: records.length,
      totalLiters: totalLiters,
      excessCount: excessCount,
      illogicalCount: illogicalCount,
    );
  }

  // تقرير الفترة
  static PeriodReportResult generatePeriodReport(
    DateTime startDate,
    DateTime endDate,
    List<Refuel> allRefuels,
    Map<int, Vehicle> vehiclesMap,
  ) {
    // تجميع التفويلات حسب السيارة
    final Map<int, List<Refuel>> refuelsByVehicle = {};

    for (var refuel in allRefuels) {
      final refuelDate = DateTime.parse(refuel.createdAt);
      // التحقق من أن التفويلة ضمن الفترة
      if (!refuelDate.isBefore(startDate) && !refuelDate.isAfter(endDate)) {
        refuelsByVehicle.putIfAbsent(refuel.vehicleId, () => []).add(refuel);
      }
    }

    // ترتيب التفويلات بحسب التاريخ
    for (var list in refuelsByVehicle.values) {
      list.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    }

    final records = <PeriodReportRecord>[];

    for (var vehicleId in refuelsByVehicle.keys) {
      final vehicle = vehiclesMap[vehicleId];
      if (vehicle == null) continue;

      final refuels = refuelsByVehicle[vehicleId]!;
      refuels.sort((a, b) => DateTime.parse(a.createdAt).compareTo(DateTime.parse(b.createdAt)));

      // find the latest refuel before the reporting period
      Refuel? previousRefuel;
      for (var refuel in allRefuels) {
        if (refuel.vehicleId != vehicleId) continue;
        final refuelDate = DateTime.parse(refuel.createdAt);
        if (refuelDate.isBefore(startDate)) {
          if (previousRefuel == null || DateTime.parse(refuel.createdAt).isAfter(DateTime.parse(previousRefuel.createdAt))) {
            previousRefuel = refuel;
          }
        }
      }

      final startOdometer = previousRefuel?.currentOdometer ?? refuels.first.currentOdometer;
      final endOdometer = refuels.last.currentOdometer;
      final distance = (endOdometer - startOdometer).clamp(0.0, double.infinity);
      final totalLiters = refuels.fold(0.0, (sum, r) => sum + r.liters);
      final double ratio = distance > 0 ? (totalLiters / distance) * 100 : 0.0;
      final isExcess = isExcessConsumption(ratio, vehicle.standardConsumption);
      final isIllogical = isIllogicalConsumption(ratio, vehicle.standardConsumption);

      records.add(
        PeriodReportRecord(
          vehicleId: vehicleId,
          vehicleNumber: vehicle.number,
          vehicleLetters: vehicle.letters,
          vehicleType: vehicle.vehicleType,
          startOdometer: startOdometer,
          endOdometer: endOdometer,
          distance: distance,
          totalLiters: totalLiters,
          consumptionRatio: ratio,
          isExcess: isExcess,
          isIllogical: isIllogical,
        ),
      );
    }

    return PeriodReportResult(records: records);
  }

  // تقرير الكميات
  static QuantityReportResult generateQuantityReport(
    DateTime startDate,
    DateTime endDate,
    List<Refuel> allRefuels,
    Map<int, Vehicle> vehiclesMap, {
    int? specificVehicleId,
  }) {
    // تجميع التفويلات حسب السيارة
    final Map<int, List<QuantityDetail>> detailsByVehicle = {};

    for (var refuel in allRefuels) {
      final refuelDate = DateTime.parse(refuel.createdAt);
      // التحقق من أن التفويلة ضمن الفترة
      if (!refuelDate.isBefore(startDate) && !refuelDate.isAfter(endDate)) {
        // إذا تم تحديد سيارة معينة، تصفية التفويلات
        if (specificVehicleId != null && refuel.vehicleId != specificVehicleId) {
          continue;
        }

        detailsByVehicle.putIfAbsent(refuel.vehicleId, () => []).add(
          QuantityDetail(liters: refuel.liters, date: refuelDate),
        );
      }
    }

    // ترتيب التفاصيل بحسب التاريخ (تصاعدي)
    for (var list in detailsByVehicle.values) {
      list.sort((a, b) => a.date.compareTo(b.date));
    }

    final records = <QuantityReportRecord>[];

    for (var vehicleId in detailsByVehicle.keys) {
      final vehicle = vehiclesMap[vehicleId];
      if (vehicle == null) continue;

      records.add(
        QuantityReportRecord(
          vehicleId: vehicleId,
          vehicleNumber: vehicle.number,
          vehicleLetters: vehicle.letters,
          details: detailsByVehicle[vehicleId]!,
        ),
      );
    }

    return QuantityReportResult(records: records);
  }

  /// دالة محسّنة لحساب بيانات تقرير الفترة بدفعة واحدة
  /// تحسب جميع القيم مرة واحدة فقط لتجنب إعادة الحسابات
  static Map<String, dynamic> optimizePeriodReportData(
    Map<String, dynamic> apiResult, {
    String? vehicleQuery,
    String? globalFuelType,
  }) {
    final records = (apiResult['records'] as List?) ?? [];
    
    // تصفية السجلات بناءً على الاستعلام والوقود
    final filteredRecords = records.where((r) {
      if (vehicleQuery != null && vehicleQuery.isNotEmpty) {
        final q = vehicleQuery.toLowerCase();
        final recNumber = (r['vehicle_number'] ?? r['number'] ?? '').toString().toLowerCase();
        final recRegistry = (r['registry'] ?? r['vehicle_registry'] ?? '').toString().toLowerCase();
        if (!recNumber.contains(q) && !recRegistry.contains(q)) return false;
      }
      if (globalFuelType != null) {
        final recFuel = (r['fuel_type'] ?? r['fuelType'] ?? '').toString();
        if (recFuel != globalFuelType) return false;
      }
      return true;
    }).toList();

    // خريطة لتخزين البيانات المحسوبة بحسب السيارة
    final Map<int, Map<String, dynamic>> vehicleMap = {};
    int totalRefuels = 0;
    double totalLitersAll = 0.0;

    // الخطوة 1: تجميع التفويلات وحساب البيانات مرة واحدة
    for (var record in filteredRecords) {
      final vehicleId = record['vehicle_id'] ?? record['vehicleId'] ?? 0;
      
      if (!vehicleMap.containsKey(vehicleId)) {
        vehicleMap[vehicleId] = {
          'number': record['vehicle_number'] ?? record['number'] ?? '',
          'letters': record['vehicle_letters'] ?? record['letters'] ?? '',
          'type': record['vehicle_type'] ?? record['type'] ?? '',
          'gas_quantity': 0.0,
          'refuels': [],
        };
      }

      final details = (record['details'] as List?) ?? [];
      final gasValue = record['gas_quantity'] ?? record['gasQuantity'] ?? 0;
      final gasQuantity = gasValue is num
          ? gasValue.toDouble()
          : double.tryParse(gasValue.toString()) ?? 0.0;
      vehicleMap[vehicleId]!['gas_quantity'] =
          (vehicleMap[vehicleId]!['gas_quantity'] as double) + gasQuantity;
      totalLitersAll += gasQuantity;
      final recordStation = (record['station'] ?? record['station_name'] ?? record['stationName'] ?? 'غير محدد').toString();
      
      for (var detail in details) {
        final detailStation = (detail['station'] ?? detail['station_name'] ?? detail['stationName'] ?? recordStation).toString();
        
        // استخراج البيانات بحذر
        final liters = (detail['liters'] ?? detail['total_liters'] ?? 0) is num
            ? (detail['liters'] ?? detail['total_liters'] ?? 0).toDouble()
            : double.tryParse(detail['liters']?.toString() ?? detail['total_liters']?.toString() ?? '0') ?? 0.0;
        
        final odometer = (detail['odometer'] ?? detail['current_odometer'] ?? 0) is num
            ? (detail['odometer'] ?? detail['current_odometer'] ?? 0).toDouble()
            : double.tryParse(detail['odometer']?.toString() ?? detail['current_odometer']?.toString() ?? '0') ?? 0.0;
        
        final refuelData = {
          'date': detail['date'] ?? detail['created_at'] ?? detail['createdAt'] ?? '',
          'liters': liters,
          'odometer': odometer,
          'station': detailStation,
        };
        
        (vehicleMap[vehicleId]!['refuels'] as List).add(refuelData);
        totalRefuels++;
        totalLitersAll += liters;
      }
    }

    return {
      'vehicleMap': vehicleMap,
      'totalVehicles': vehicleMap.length,
      'totalRefuels': totalRefuels,
      'totalLiters': totalLitersAll,
    };
  }
}
