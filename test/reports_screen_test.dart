import 'package:flutter_test/flutter_test.dart';
import 'package:sca_fuel/helpers/reports_calculations.dart';
import 'package:sca_fuel/screens/reports_screen.dart';

void main() {
  test('calculateFuelSummaryTotals sums only the visible report rows', () {
    final records = [
      {'fuel_type': 'بنزين 92', 'total_liters': 10.5},
      {'fuel_type': 'بنزين 95', 'total_liters': 5.0},
      {'fuel_type': 'سولار', 'total_liters': 12.3},
      {'fuel_type': 'بنزين 92', 'total_liters': 3.2},
      {'fuel_type': 'سولار', 'total_liters': 1.0},
      {'fuel_type': 'بنزين 98', 'total_liters': 2.0},
    ];

    final totals = calculateFuelSummaryTotals(records);

    expect(totals['gasoline92'], 13.7);
    expect(totals['gasoline95'], 5.0);
    expect(totals['solar'], 13.3);
  });

  test('calculateRefuelConsumptionRatio uses the odometer distance and handles invalid distance', () {
    expect(ReportsCalculations.calculateRefuelConsumptionRatio(50, 1000, 900), 50.0);
    expect(ReportsCalculations.calculateRefuelConsumptionRatio(20, 1000, null), 0.0);
    expect(ReportsCalculations.calculateRefuelConsumptionRatio(20, 1000, 1200), 0.0);
  });

  test('shortStationName returns the compact display form for supported stations', () {
    expect(ReportsCalculations.shortStationName('بورسعيد'), 'بورسعيد');
    expect(ReportsCalculations.shortStationName('بورفؤاد'), 'بورفؤاد');
    expect(ReportsCalculations.shortStationName('الإسماعيلية'), 'الإسماعيلية');
    expect(ReportsCalculations.shortStationName('السويس'), 'السويس');
    expect(ReportsCalculations.shortStationName('محطة الكارت'), 'كارت');
    expect(ReportsCalculations.shortStationName('محطة أخرى'), 'محطة أخرى');
  });
}
