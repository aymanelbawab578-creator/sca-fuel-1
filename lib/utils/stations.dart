const List<String> fuelStations = [
  'محطة بورسعيد',
  'محطة بورفؤاد',
  'محطة الإسماعيلية',
  'محطة السويس',
  'تموين بالكارت الذكي',
];

String normalizeStationName(String? value) {
  final normalized = (value ?? '').trim();
  if (normalized.isEmpty) {
    return '';
  }

  final withoutPrefix = normalized.startsWith('محطة')
      ? normalized.substring('محطة'.length).trim()
      : normalized;

  return withoutPrefix;
}

bool stationsMatch(String? left, String? right) {
  return normalizeStationName(left).toLowerCase() == normalizeStationName(right).toLowerCase();
}
