import 'package:flutter_test/flutter_test.dart';
import 'package:sca_fuel/utils/stations.dart';

void main() {
  group('station filtering', () {
    test('normalizes station names so filter matches report values', () {
      expect(normalizeStationName('محطة بورسعيد'), 'بورسعيد');
      expect(normalizeStationName('بورسعيد'), 'بورسعيد');
      expect(stationsMatch('محطة بورسعيد', 'بورسعيد'), isTrue);
      expect(stationsMatch('محطة بورفؤاد', 'بورفؤاد'), isTrue);
      expect(stationsMatch('تموين بالكارت الذكي', 'تموين بالكارت الذكي'), isTrue);
    });
  });
}
