class RefuelLogicInput {
  final double currentOdometer;
  final double liters;
  final DateTime createdAt;

  const RefuelLogicInput({
    required this.currentOdometer,
    required this.liters,
    required this.createdAt,
  });
}

class RefuelLogicRecord {
  final int id;
  final double currentOdometer;
  final DateTime createdAt;

  const RefuelLogicRecord({
    required this.id,
    required this.currentOdometer,
    required this.createdAt,
  });
}

class RefuelCalculation {
  final double actualPercentage;
  final bool isExcess;
  final bool isIllogical;

  const RefuelCalculation({
    required this.actualPercentage,
    required this.isExcess,
    required this.isIllogical,
  });
}

class RefuelLogic {
  static RefuelCalculation calculate({
    required RefuelLogicInput input,
    required double baselineOdometer,
    required double standardConsumption,
  }) {
    if (input.liters <= 0) {
      throw ArgumentError('كمية الوقود يجب أن تكون أكبر من صفر');
    }

    final distance = input.currentOdometer - baselineOdometer;
    final actualDistance = distance.abs();
    final actualPercentage = actualDistance > 0
        ? (input.liters / actualDistance) * 100
        : 0.0;

    var isIllogical = false;
    var isExcess = false;
    if (distance <= 0 || standardConsumption <= 0) {
      isIllogical = true;
    } else if (actualPercentage < standardConsumption * 0.5 ||
        actualPercentage > standardConsumption * 2.0) {
      isIllogical = true;
    } else if (actualPercentage > standardConsumption * 1.5) {
      isExcess = true;
    }

    return RefuelCalculation(
      actualPercentage: actualPercentage,
      isExcess: isExcess,
      isIllogical: isIllogical,
    );
  }

  static void validateSequence({
    required List<RefuelLogicRecord> records,
    required DateTime refuelDate,
    required double currentOdometer,
  }) {
    final orderedRecords = [...records]
      ..sort((left, right) {
        final dateComparison = left.createdAt.compareTo(right.createdAt);
        return dateComparison != 0
            ? dateComparison
            : left.id.compareTo(right.id);
      });

    RefuelLogicRecord? previousRecord;
    RefuelLogicRecord? nextRecord;
    for (final record in orderedRecords) {
      if (record.createdAt.isBefore(refuelDate)) {
        previousRecord = record;
      } else if (record.createdAt.isAfter(refuelDate)) {
        nextRecord = record;
        break;
      }
    }

    if (previousRecord != null &&
        currentOdometer < previousRecord.currentOdometer) {
      throw ArgumentError('عداد التفويلة لا يمكن أن يكون أقل من آخر تفويلة سابقة');
    }
    if (nextRecord != null && currentOdometer > nextRecord.currentOdometer) {
      throw ArgumentError('عداد التفويلة لا يمكن أن يكون أكبر من أول تفويلة تالية');
    }
  }

  static double baselineOdometer({
    required List<RefuelLogicRecord> records,
    required DateTime createdAt,
    required double vehicleLastOdometer,
  }) {
    final previousRecords = records
        .where((record) => record.createdAt.isBefore(createdAt))
        .toList()
      ..sort((left, right) {
        final dateComparison = right.createdAt.compareTo(left.createdAt);
        return dateComparison != 0
            ? dateComparison
            : right.id.compareTo(left.id);
      });
    return previousRecords.isEmpty
        ? vehicleLastOdometer
        : previousRecords.first.currentOdometer;
  }
}