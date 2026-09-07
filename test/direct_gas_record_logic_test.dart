import 'package:flutter_test/flutter_test.dart';

import 'package:sca_fuel/services/direct_database/gas_record_logic.dart';

void main() {
  test('calculates gas quantity rounded half-up to two decimals', () {
    final quantity = GasRecordLogic.calculateQuantity(
      amount: 10,
      gasPrice: 3,
    );

    expect(quantity, 3.33);
  });

  test('rejects invalid gas price and negative amount', () {
    expect(
      () => GasRecordLogic.calculateQuantity(amount: 10, gasPrice: 0),
      throwsArgumentError,
    );
    expect(
      () => GasRecordLogic.calculateQuantity(amount: -1, gasPrice: 3),
      throwsArgumentError,
    );
  });

  test('rejects a period whose end precedes its start', () {
    expect(
      () => GasRecordLogic.validatePeriod(
        startDate: DateTime(2026, 6, 2),
        endDate: DateTime(2026, 6, 1),
      ),
      throwsArgumentError,
    );
  });
}