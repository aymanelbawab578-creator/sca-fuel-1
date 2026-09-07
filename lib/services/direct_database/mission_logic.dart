import 'refuel_logic.dart';

class MissionExpenseLogicInput {
  final DateTime date;
  final double odometer;
  final double liters;

  const MissionExpenseLogicInput({
    required this.date,
    required this.odometer,
    required this.liters,
  });
}

class MissionRefuelLogicResult {
  final MissionExpenseLogicInput expense;
  final RefuelCalculation refuel;

  const MissionRefuelLogicResult({
    required this.expense,
    required this.refuel,
  });
}

class MissionLogic {
  static void validateExpense(MissionExpenseLogicInput expense) {
    if (expense.liters <= 0) {
      throw ArgumentError('كمية التفويلة يجب أن تكون أكبر من صفر');
    }
  }

  static double totalConsumed(List<MissionExpenseLogicInput> expenses) {
    for (final expense in expenses) {
      validateExpense(expense);
    }
    return expenses.fold(0.0, (total, expense) => total + expense.liters);
  }

  static List<MissionRefuelLogicResult> calculateCompletion({
    required List<MissionExpenseLogicInput> expenses,
    required List<RefuelLogicRecord> existingRefuels,
    required double vehicleLastOdometer,
    required DateTime vehicleLastOdometerDate,
    required double standardConsumption,
    bool skipOdometerValidation = false,
  }) {
    final results = <MissionRefuelLogicResult>[];
    final refuels = [...existingRefuels];

    for (final expense in expenses) {
      validateExpense(expense);
      final baseline = RefuelLogic.baselineOdometer(
        records: refuels,
        createdAt: expense.date,
        vehicleLastOdometer: vehicleLastOdometer,
      );
        final isBackdatedBelowLatest =
          expense.date.isBefore(vehicleLastOdometerDate) &&
          expense.odometer < vehicleLastOdometer;

      if (!skipOdometerValidation && !isBackdatedBelowLatest) {
        RefuelLogic.validateSequence(
          records: refuels,
          refuelDate: expense.date,
          currentOdometer: expense.odometer,
        );
      }

      final calculation = RefuelLogic.calculate(
        input: RefuelLogicInput(
          currentOdometer: expense.odometer,
          liters: expense.liters,
          createdAt: expense.date,
        ),
        baselineOdometer: baseline,
        standardConsumption: standardConsumption,
      );
      results.add(MissionRefuelLogicResult(
        expense: expense,
        refuel: calculation,
      ));
      refuels.add(RefuelLogicRecord(
        id: -results.length,
        currentOdometer: expense.odometer,
        createdAt: expense.date,
      ));
    }

    return results;
  }
}