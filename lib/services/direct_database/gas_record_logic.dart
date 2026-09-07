class GasRecordLogic {
  static double calculateQuantity({
    required double amount,
    required double gasPrice,
  }) {
    if (gasPrice <= 0) {
      throw ArgumentError('سعر متر الغاز يجب أن يكون أكبر من صفر');
    }
    if (amount < 0) {
      throw ArgumentError('القيمة لا يمكن أن تكون سالبة');
    }

    final quantity = amount / gasPrice;
    return (quantity * 100).roundToDouble() / 100;
  }

  static void validatePeriod({
    required DateTime startDate,
    required DateTime endDate,
  }) {
    if (endDate.isBefore(startDate)) {
      throw ArgumentError('تاريخ النهاية يجب أن يكون بعد أو يساوي تاريخ البداية');
    }
  }
}