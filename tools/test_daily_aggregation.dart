void main() {
  final apiResult = {
    'date': '2026-06-22',
    'count': 3,
    'records': [
      {'vehicle_number': '2856', 'fuel_type': 'بنزين 92', 'liters': 50.0},
      {'vehicle_number': '2856', 'fuel_type': 'بنزين 95', 'liters': 20.0},
      {'vehicle_number': '1234', 'fuel_type': 'سولار', 'liters': 30.0},
    ]
  };

  final records = (apiResult['records'] as List).cast<Map<String, dynamic>>();
  double total92 = 0.0, total95 = 0.0, totalSolar = 0.0;
  for (var r in records) {
    final recFuel = (r['fuel_type'] ?? r['fuelType'] ?? '').toString();
    final litersRaw = r['liters'] ?? r['total_liters'] ?? 0;
    final liters = litersRaw is num ? litersRaw.toDouble() : double.tryParse(litersRaw.toString()) ?? 0.0;
    if (recFuel == 'بنزين 92') total92 += liters;
    else if (recFuel == 'بنزين 95') total95 += liters;
    else if (recFuel == 'سولار') totalSolar += liters;
  }

  print('Totals for ${apiResult['date']}:');
  print('بنزين 92 = ${total92.toStringAsFixed(1)}');
  print('بنزين 95 = ${total95.toStringAsFixed(1)}');
  print('سولار   = ${totalSolar.toStringAsFixed(1)}');
}
