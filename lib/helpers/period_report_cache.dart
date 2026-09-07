/// تخزين البيانات المحسوبة مسبقاً لتقرير الفترة لتحسين الأداء
class RefuelCache {
  final int index;
  final String date;
  final double liters;
  final double odometer;
  final double? previousOdometer;
  final double ratio;
  final String station;

  RefuelCache({
    required this.index,
    required this.date,
    required this.liters,
    required this.odometer,
    this.previousOdometer,
    required this.ratio,
    required this.station,
  });
}

class VehicleReportCache {
  final int vehicleId;
  final String vehicleNumber;
  final String? vehicleLetters;
  final String vehicleType;
  final List<RefuelCache> refuels;
  
  VehicleReportCache({
    required this.vehicleId,
    required this.vehicleNumber,
    this.vehicleLetters,
    required this.vehicleType,
    required this.refuels,
  });

  double get totalLiters => 
      refuels.fold(0.0, (sum, r) => sum + r.liters);
}

class PeriodReportCache {
  final List<VehicleReportCache> vehicles;
  
  PeriodReportCache({required this.vehicles});

  int get totalVehicles => vehicles.length;
  
  int get totalRefuels => 
      vehicles.fold(0, (sum, v) => sum + v.refuels.length);
  
  double get totalLiters =>
      vehicles.fold(0.0, (sum, v) => sum + v.totalLiters);
}
