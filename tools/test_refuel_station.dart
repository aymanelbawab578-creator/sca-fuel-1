import '../lib/models/refuel.dart';

void main() {
  final r = RefuelCreate(vehicleId: 10, currentOdometer: 12345, liters: 40.5, createdAt: DateTime(2026,6,24), station: 'بورسعيد');
  print(r.toJson());
}
