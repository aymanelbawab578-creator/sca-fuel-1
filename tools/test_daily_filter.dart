void main() {
  final vehicleQuery = '2856';
  final globalFuelType = null; // or 'بنزين 92'

  final apiResult = {
    'date': '2026-06-22',
    'records': [
      {
        'vehicle_number': '2856',
        'vehicle_letters': 'أ',
        'vehicle_type': 'شاحنة',
        'odometer': 12000,
        'liters': 50.0,
        'consumption_ratio': 8.5,
        'fuel_type': 'بنزين 92',
        'registry': '2856',
      },
      {
        'vehicle_number': '1234',
        'vehicle_letters': 'ب',
        'vehicle_type': 'سيارة',
        'odometer': 8000,
        'liters': 30.0,
        'consumption_ratio': 7.0,
        'fuel_type': 'سولار',
        'registry': '1234',
      }
    ]
  };

  final records = (apiResult['records'] as List).cast<Map<String, dynamic>>();
  final filtered = records.where((r) {
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

  print('Date: \\${apiResult['date']}');
  print('Vehicle query: $vehicleQuery');
  print('Filtered records count: \\${filtered.length}');
  for (var r in filtered) {
    print(' - ${r['vehicle_number']} | ${r['vehicle_letters']} | ${r['fuel_type']} | liters=${r['liters']}');
  }
}
