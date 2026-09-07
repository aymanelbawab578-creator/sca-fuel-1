/// دوال helper لتصدير البيانات المحسوبة بكفاءة
/// بدون إعادة الحسابات

import 'package:intl/intl.dart';
import '../helpers/reports_calculations.dart';

class ExportHelper {
  /// تحويل البيانات المحسوبة إلى صفوف Excel
  /// بدون إعادة حساب النسب أو البيانات الأخرى
  static List<List<dynamic>> convertOptimizedDataToExcelRows(
    Map<int, Map<String, dynamic>> vehicleMap,
  ) {
    final rows = <List<dynamic>>[];
    
    for (var vehicle in vehicleMap.values) {
      final refuels = vehicle['refuels'] as List<Map<String, dynamic>>? ?? [];
      
      for (var refuel in refuels) {
        rows.add([
          vehicle['number'],
          vehicle['letters'],
          refuel['station'] ?? 'غير محدد',
          refuel['date'] ?? '',
          refuel['odometer'],
          (refuel['liters'] as num).toStringAsFixed(1),
          (refuel['ratio'] as num) == 0 
              ? 0.0 
              : double.parse((refuel['ratio'] as num).toStringAsFixed(2)),
        ]);
      }
    }
    
    return rows;
  }

  /// تحويل البيانات المحسوبة إلى صفوف PDF
  static List<List<dynamic>> convertOptimizedDataToPdfRows(
    Map<int, Map<String, dynamic>> vehicleMap,
  ) {
    final rows = <List<dynamic>>[];
    
    for (var vehicle in vehicleMap.values) {
      final refuels = vehicle['refuels'] as List<Map<String, dynamic>>? ?? [];
      
      for (var refuel in refuels) {
        rows.add([
          vehicle['number'],
          vehicle['letters'],
          refuel['date'] ?? '',
          refuel['odometer'],
          (refuel['liters'] as num).toStringAsFixed(1),
          (refuel['ratio'] as num) == 0 
              ? '-' 
              : (refuel['ratio'] as num).toStringAsFixed(2),
        ]);
      }
    }
    
    return rows;
  }
}
