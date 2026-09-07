import 'package:flutter_test/flutter_test.dart';

import 'package:sca_fuel/services/direct_database/mission_logic.dart';
import 'package:sca_fuel/services/direct_database/refuel_logic.dart';

void main() {
  test('validates expense liters and totals completed mission fuel', () {
    final expenses = [
      MissionExpenseLogicInput(
        date: DateTime(2026, 6, 1),
        odometer: 1000,
        liters: 10,
      ),
      MissionExpenseLogicInput(
        date: DateTime(2026, 6, 2),
        odometer: 1100,
        liters: 15,
      ),
    ];

    expect(MissionLogic.totalConsumed(expenses), 25);
    expect(
      () => MissionLogic.validateExpense(
        MissionExpenseLogicInput(
          date: DateTime(2026, 6, 3),
          odometer: 1200,
          liters: 0,
        ),
      ),
      throwsArgumentError,
    );
  });

  test('calculates each completed expense and preserves backend ordering', () {
    final results = MissionLogic.calculateCompletion(
      expenses: [
        MissionExpenseLogicInput(
          date: DateTime(2026, 6, 1),
          odometer: 1000,
          liters: 10,
        ),
        MissionExpenseLogicInput(
          date: DateTime(2026, 6, 2),
          odometer: 1100,
          liters: 10,
        ),
      ],
      existingRefuels: const [],
      vehicleLastOdometer: 900,
      vehicleLastOdometerDate: DateTime(2026, 5, 31),
      standardConsumption: 10,
    );

    expect(results, hasLength(2));
    expect(results[0].refuel.actualPercentage, 10);
    expect(results[1].refuel.actualPercentage, 10);
  });

  test('allows forced completion to skip odometer sequence validation', () {
    final results = MissionLogic.calculateCompletion(
      expenses: [
        MissionExpenseLogicInput(
          date: DateTime(2026, 6, 1),
          odometer: 1200,
          liters: 10,
        ),
      ],
      existingRefuels: [
        RefuelLogicRecord(
          id: 1,
          currentOdometer: 1000,
          createdAt: DateTime(2026, 6, 2),
        ),
      ],
      vehicleLastOdometer: 1000,
      vehicleLastOdometerDate: DateTime(2026, 6, 2),
      standardConsumption: 10,
      skipOdometerValidation: true,
    );

    expect(results, hasLength(1));
    expect(results.single.refuel.isIllogical, isFalse);
  });
}