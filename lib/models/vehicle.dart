class Vehicle {
  final int id;
  final String number;
  final String? letters;
  final String? registry;
  final String? code;
  final String vehicleType;
  final String fuelType;
  final double standardConsumption;
  final double lastOdometer;
  final String lastOdometerDate;
  final int? manufactureYear;
  final String? brand;
  final String? model;

  Vehicle({
    required this.id,
    required this.number,
    this.letters,
    this.registry,
    this.code,
    required this.vehicleType,
    required this.fuelType,
    required this.standardConsumption,
    required this.lastOdometer,
    required this.lastOdometerDate,
    this.manufactureYear,
    this.brand,
    this.model,
  });

  factory Vehicle.fromJson(Map<String, dynamic> json) {
    return Vehicle(
      id: json['id'],
      number: json['number'],
      letters: json['letters'],
      registry: json['registry'],
      code: json['code'],
      vehicleType: json['vehicle_type'],
      fuelType: json['fuel_type'],
      standardConsumption: (json['standard_consumption'] ?? 0).toDouble(),
      lastOdometer: (json['last_odometer'] ?? 0).toDouble(),
      lastOdometerDate: json['last_odometer_date'] ?? '',
      manufactureYear: json['manufacture_year'] is int ? json['manufacture_year'] as int : int.tryParse('${json['manufacture_year'] ?? ''}'),
      brand: json['brand'],
      model: json['model'],
    );
  }
}
