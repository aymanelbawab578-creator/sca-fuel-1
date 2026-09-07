import 'package:flutter_test/flutter_test.dart';

import 'package:sca_fuel/services/direct_database/refuel_logic.dart';

void main() {
  final firstRefuel = RefuelLogicRecord(
    id: 1,
    currentOdometer: 1000,
    createdAt: DateTime(2026, 6, 1),
  );
  final secondRefuel = RefuelLogicRecord(
    id: 2,
    currentOdometer: 1100,
    createdAt: DateTime(2026, 6, 3),
  );

  test('calculates percentage and flags using backend thresholds', () {
    final result = RefuelLogic.calculate(
      input: RefuelLogicInput(
        currentOdometer: 1100,
        liters: 10,
        createdAt: DateTime(2026, 6, 2),
      ),
      baselineOdometer: 1000,
      standardConsumption: 10,
    );

    expect(result.actualPercentage, 10);
    expect(result.isIllogical, isFalse);
    expect(result.isExcess, isFalse);
  });

  test('rejects an odometer above the next dated refuel', () {
    expect(
      () => RefuelLogic.validateSequence(
        records: [firstRefuel, secondRefuel],
        refuelDate: DateTime(2026, 6, 2),
        currentOdometer: 1200,
      ),
      throwsArgumentError,
    );
  });

  test('uses the latest dated refuel as the baseline', () {
    final baseline = RefuelLogic.baselineOdometer(
      records: [firstRefuel, secondRefuel],
      createdAt: DateTime(2026, 6, 4),
      vehicleLastOdometer: 500,
    );

    expect(baseline, 1100);
  });
}