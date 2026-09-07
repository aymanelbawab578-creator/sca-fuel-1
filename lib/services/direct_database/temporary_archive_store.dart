import 'dart:convert';

class TemporaryArchiveStore {
  static final Map<String, List<Map<String, dynamic>>> _refuels = {};
  static final Map<String, List<Map<String, dynamic>>> _invoices = {};

  static void load({
    required String filename,
    required String content,
  }) {
    if (isLoaded(filename)) {
      throw StateError(
        'هذا الأرشيف محمّل بالفعل في الجلسة الحالية.',
      );
    }

    _refuels[filename] = _parseTable(
      content,
      'refuel',
      const [
        'vehicle_id',
        'current_odometer',
        'liters',
        'actual_percentage',
        'created_at',
        'is_excess',
        'is_illogical',
        'station',
        'id',
        'is_synced',
        'updated_at',
        'source',
      ],
    );

    _invoices[filename] = _parseTable(
      content,
      'invoice',
      const [
        'station',
        'start_date',
        'end_date',
        'created_at',
        'total_amount',
        'items',
        'prices',
        'id',
        'invoice_number',
      ],
    );
  }

  static bool isLoaded(String filename) {
    return _refuels.containsKey(filename);
  }

  static List<String> get filenames {
    return _refuels.keys.toList()..sort();
  }

  static List<Map<String, dynamic>> refuels({
    DateTime? startDate,
    DateTime? endDate,
  }) {
    final result = <Map<String, dynamic>>[];

    for (final rows in _refuels.values) {
      for (final row in rows) {
        final value = _parseDate(row['created_at']);

        if (value == null) {
          continue;
        }

        if (startDate != null && value.isBefore(_dateOnly(startDate))) {
          continue;
        }

        if (endDate != null && value.isAfter(_dateOnly(endDate))) {
          continue;
        }

        result.add(Map<String, dynamic>.from(row));
      }
    }

    return result;
  }

  static List<Map<String, dynamic>> invoices({
    DateTime? date,
    int? month,
    int? year,
    String? station,
    String? invoiceNumber,
  }) {
    final result = <Map<String, dynamic>>[];

    for (final rows in _invoices.values) {
      for (final original in rows) {
        final row = Map<String, dynamic>.from(original);
        final itemDate = _parseDate(row['created_at']);

        if (date != null) {
          if (itemDate == null ||
              !_sameDate(itemDate, _dateOnly(date))) {
            continue;
          }
        }

        if (month != null) {
          if (itemDate == null || itemDate.month != month) {
            continue;
          }
        }

        if (year != null) {
          if (itemDate == null || itemDate.year != year) {
            continue;
          }
        }

        if (station != null && station.isNotEmpty) {
          if (_normalize(row['station']) != _normalize(station)) {
            continue;
          }
        }

        if (invoiceNumber != null && invoiceNumber.isNotEmpty) {
          if (row['invoice_number']?.toString() != invoiceNumber) {
            continue;
          }
        }

        result.add(row);
      }
    }

    return result;
  }

  static void remove(String filename) {
    _refuels.remove(filename);
    _invoices.remove(filename);
  }

  static void clear() {
    _refuels.clear();
    _invoices.clear();
  }

  static Map<String, dynamic> status() {
    return {
      'count': filenames.length,
      'filenames': filenames,
      'loaded': filenames.isNotEmpty,
    };
  }

  static List<Map<String, dynamic>> _parseTable(
    String content,
    String table,
    List<String> columns,
  ) {
    final result = <Map<String, dynamic>>[];

    final pattern = RegExp(
      r'INSERT\s+INTO\s+"'
      + RegExp.escape(table)
      + r'"\s*\((.*?)\)\s*VALUES\s*\((.*?)\);',
      caseSensitive: false,
      multiLine: true,
      dotAll: true,
    );

    for (final match in pattern.allMatches(content)) {
      final valuesText = match.group(2);

      if (valuesText == null) {
        continue;
      }

      final values = _splitValues(valuesText);

      if (values.length != columns.length) {
        continue;
      }

      final row = <String, dynamic>{};

      for (var i = 0; i < columns.length; i++) {
        row[columns[i]] = _parseValue(values[i]);
      }

      row['source'] = 'archive';
      result.add(row);
    }

    return result;
  }

  static List<String> _splitValues(String text) {
    final values = <String>[];
    final current = StringBuffer();

    var inQuote = false;
    var escaped = false;
    var depth = 0;

    for (var i = 0; i < text.length; i++) {
      final char = text[i];

      if (escaped) {
        current.write(char);
        escaped = false;
        continue;
      }

      if (inQuote && char == r'\') {
        current.write(char);
        escaped = true;
        continue;
      }

      if (char == "'") {
        current.write(char);
        inQuote = !inQuote;
        continue;
      }

      if (!inQuote) {
        if (char == '(') {
          depth++;
        } else if (char == ')') {
          depth--;
        }
      }

      if (char == ',' && !inQuote && depth == 0) {
        values.add(current.toString().trim());
        current.clear();
        continue;
      }

      current.write(char);
    }

    values.add(current.toString().trim());

    return values;
  }

  static dynamic _parseValue(String value) {
    final text = value.trim();

    if (text.toUpperCase() == 'NULL') {
      return null;
    }

    if (text.toUpperCase() == 'TRUE') {
      return true;
    }

    if (text.toUpperCase() == 'FALSE') {
      return false;
    }

    if (text.endsWith('::json')) {
      final jsonText = _unquote(
        text.substring(0, text.length - 6).trim(),
      );

      try {
        return jsonDecode(jsonText);
      } catch (_) {
        return jsonText;
      }
    }

    if (text.startsWith("'") && text.endsWith("'")) {
      return _unquote(text);
    }

    final integer = int.tryParse(text);
    if (integer != null) {
      return integer;
    }

    final number = double.tryParse(text);
    if (number != null) {
      return number;
    }

    return text;
  }

  static String _unquote(String value) {
    var text = value.trim();

    if (text.length >= 2 &&
        text.startsWith("'") &&
        text.endsWith("'")) {
      text = text.substring(1, text.length - 1);
    }

    return text
        .replaceAll("''", "'")
        .replaceAll(r"\'", "'");
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) {
      return null;
    }

    return DateTime.tryParse(value.toString());
  }

  static DateTime _dateOnly(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }

  static bool _sameDate(DateTime a, DateTime b) {
    return a.year == b.year &&
        a.month == b.month &&
        a.day == b.day;
  }

  static String _normalize(dynamic value) {
    return value
            ?.toString()
            .trim()
            .replaceAll(RegExp(r'\s+'), ' ')
            .toLowerCase() ??
        '';
  }
}
