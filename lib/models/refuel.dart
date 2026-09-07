class Refuel {
  final int id;
  final int vehicleId;
  final double currentOdometer;
  final double liters;
  final double actualPercentage;
  final bool isExcess;
  final bool isIllogical;
  final String createdAt;
  final String? station;

  Refuel({
    required this.id,
    required this.vehicleId,
    required this.currentOdometer,
    required this.liters,
    required this.actualPercentage,
    required this.isExcess,
    required this.isIllogical,
    required this.createdAt,
    this.station,
  });

  factory Refuel.fromJson(Map<String, dynamic> json) {
    return Refuel(
      id: json['id'] as int,
      vehicleId: json['vehicle_id'] as int,
      currentOdometer: (json['current_odometer'] as num).toDouble(),
      liters: (json['liters'] as num).toDouble(),
      actualPercentage: (json['actual_percentage'] as num).toDouble(),
      isExcess: json['is_excess'] as bool,
      isIllogical: json['is_illogical'] as bool,
      createdAt: json['created_at'] as String,
      station: json['station'] as String?,
    );
  }
}

class RefuelCreate {
  final int vehicleId;
  final double currentOdometer;
  final double liters;
  final DateTime? createdAt;
  final String? station;

  RefuelCreate({
    required this.vehicleId,
    required this.currentOdometer,
    required this.liters,
    this.createdAt,
    this.station,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'vehicle_id': vehicleId,
      'current_odometer': currentOdometer,
      'liters': liters,
    };
    if (createdAt != null) {
      data['created_at'] = createdAt!.toIso8601String().split('T').first;
    }
    if (station != null) {
      data['station'] = station;
    }
    return data;
  }
}
