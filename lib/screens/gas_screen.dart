import 'package:excel/excel.dart' hide Border;
import 'dart:ui' as dart_ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart' as pdf_lib;
import 'package:pdf/widgets.dart' as pw;
import 'package:provider/provider.dart';

import '../models/vehicle.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../utils/file_save_helper.dart';
import '../widgets/sca_layout.dart';
import 'archive_screen.dart';
import 'dashboard_screen.dart';
import 'login_screen.dart';
import 'reports_screen.dart';
import 'settings_screen.dart';
import 'store_screen.dart';
import 'vehicle_data_screen.dart';
import 'vehicle_search_screen.dart';

class GasScreen extends StatefulWidget {
  final int initialTab;

  const GasScreen({super.key, this.initialTab = 0});

  @override
  State<GasScreen> createState() => _GasScreenState();
}

class _GasScreenState extends State<GasScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _displayDateFormat = DateFormat('dd/MM/yyyy');
  final _apiDateFormat = DateFormat('yyyy-MM-dd');
  final _startController = TextEditingController();
  final _endController = TextEditingController();
  final _priceController = TextEditingController();
  final _searchController = TextEditingController();
  final _amountController = TextEditingController();
  final _quantityController = TextEditingController();
  final _startFocus = FocusNode();
  final _endFocus = FocusNode();
  final _priceFocus = FocusNode();
  final _searchFocus = FocusNode();
  final _amountFocus = FocusNode();
  final _quantityFocus = FocusNode();
  Vehicle? _selectedVehicle;
  List<Vehicle> _searchResults = [];
  final List<Map<String, dynamic>> _entries = [];
  List<Map<String, dynamic>> _periods = [];
  bool _saving = false;
  bool _loadingPeriod = false;
  bool _loadingPeriods = false;
  bool _periodLocked = false;
  bool _periodSaved = false;
  final List<int> _deletedEntryIds = [];
  final _periodsFocusNode = FocusNode();
  int? _selectedPeriodIndex;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: widget.initialTab.clamp(0, 2).toInt());
    _loadPeriods();
  }

  Future<void> _loadPeriods() async {
    if (!mounted) return;
    setState(() => _loadingPeriods = true);
    try {
      final token = context.read<AuthProvider>().token;
      if (token == null || token.isEmpty) {
        throw Exception('انتهت جلسة الدخول، يرجى تسجيل الدخول مرة أخرى');
      }
      final records = await ApiService.listGasRecords(token);
      final grouped = <String, Map<String, dynamic>>{};
      for (final record in records) {
        final key = '${record['start_date']}|${record['end_date']}';
        final period = grouped.putIfAbsent(
            key,
            () => {
                  'start_date': record['start_date'],
                  'end_date': record['end_date'],
                  'gas_price': _asDouble(record['gas_price']),
                  'total_amount': 0.0,
                  'total_quantity': 0.0,
                  'record_count': 0,
                  'record_ids': <int>[],
                });
        period['total_amount'] += _asDouble(record['amount']);
        period['total_quantity'] += _asDouble(record['quantity']);
        period['record_count'] += 1;
        (period['record_ids'] as List<int>).add(record['id'] as int);
      }
      final periods = grouped.values.toList()
        ..sort((a, b) => '${b['end_date']}'.compareTo('${a['end_date']}'));
      if (mounted)
        setState(() {
          _periods = periods;
          _loadingPeriods = false;
        });
    } catch (error) {
      if (mounted) {
        setState(() {
          _loadingPeriods = false;
          _error = 'تعذر تحميل سجل الفترات: $error';
        });
      }
    }
  }

  double _asDouble(dynamic value) {
    if (value is num) return value.toDouble();
    final parsed = double.tryParse('$value');
    if (parsed == null) throw FormatException('قيمة رقمية غير صالحة: $value');
    return parsed;
  }

  Future<void> _openPeriod(Map<String, dynamic> period) async {
    _tabController.animateTo(0);
    _startController.text = _displayDateFormat
        .format(DateTime.parse(period['start_date'] as String));
    _endController.text =
        _displayDateFormat.format(DateTime.parse(period['end_date'] as String));
    _priceController.text = '${period['gas_price']}';
    setState(() {
      _periodLocked = true;
      _periodSaved = false;
      _error = null;
    });
    await _loadSavedPeriod();
    if (mounted) setState(() => _periodSaved = false);
  }

  Future<void> _deletePeriod(Map<String, dynamic> period) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('حذف الفترة بالكامل؟'),
        content: Text(
          'سيتم حذف جميع سجلات الفترة من ${_displayDateFormat.format(DateTime.parse(period['start_date'] as String))} إلى ${_displayDateFormat.format(DateTime.parse(period['end_date'] as String))}.',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('إلغاء')),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('حذف الفترة'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _loadingPeriods = true);
    try {
      final token = context.read<AuthProvider>().token!;
      for (final id in period['record_ids'] as List<int>) {
        await ApiService.deleteGasRecord(token, id);
      }
      _clearPeriodForm();
      await _loadPeriods();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تم حذف الفترة بالكامل')));
      }
    } catch (error) {
      if (mounted) {
        setState(() => _error = 'تعذر حذف الفترة: $error');
      }
    }
  }

  void _clearPeriodForm() {
    _startController.clear();
    _endController.clear();
    _priceController.clear();
    _searchController.clear();
    _amountController.clear();
    _quantityController.clear();
    setState(() {
      _entries.clear();
      _deletedEntryIds.clear();
      _selectedVehicle = null;
      _searchResults = [];
      _periodLocked = false;
      _periodSaved = false;
      _error = null;
    });
  }

  Future<void> _exportPeriodsExcel() async {
    final book = Excel.createExcel();
    final sheet = book['فترات الغاز'];
    const headers = [
      'م',
      'من',
      'إلى',
      'سعر المتر',
      'إجمالي القيمة',
      'إجمالي الكمية (م³)'
    ];
    for (var index = 0; index < headers.length; index++) {
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: index, rowIndex: 0))
          .value = headers[index];
    }
    for (var index = 0; index < _periods.length; index++) {
      final period = _periods[index];
      final values = [
        index + 1,
        _displayDateFormat
            .format(DateTime.parse(period['start_date'] as String)),
        _displayDateFormat.format(DateTime.parse(period['end_date'] as String)),
        period['gas_price'] as double,
        period['total_amount'] as double,
        period['total_quantity'] as double,
      ];
      for (var column = 0; column < values.length; column++) {
        sheet
            .cell(CellIndex.indexByColumnRow(
                columnIndex: column, rowIndex: index + 1))
            .value = values[column];
      }
    }
    await saveBytesAsFile(
        'gas_periods.xlsx', Uint8List.fromList(book.encode()!));
  }

  Future<void> _exportPeriodsPdf() async {
    final font = pw.Font.ttf(await rootBundle.load('assets/fonts/arial.ttf'));
    final document = pw.Document();
    final rows = _periods.asMap().entries.map((item) {
      final period = item.value;
      return [
        '${item.key + 1}',
        _displayDateFormat
            .format(DateTime.parse(period['start_date'] as String)),
        _displayDateFormat.format(DateTime.parse(period['end_date'] as String)),
        (period['gas_price'] as double).toStringAsFixed(2),
        (period['total_amount'] as double).toStringAsFixed(2),
        (period['total_quantity'] as double).toStringAsFixed(4),
      ];
    }).toList();
    document.addPage(pw.MultiPage(
      pageFormat: pdf_lib.PdfPageFormat.a4,
      theme: pw.ThemeData.withFont(base: font),
      build: (_) => [
        pw.Directionality(
          textDirection: pw.TextDirection.rtl,
          child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.stretch,
              children: [
                pw.Text('سجل فترات الغاز',
                    textAlign: pw.TextAlign.right,
                    style: pw.TextStyle(
                        font: font,
                        fontSize: 18,
                        fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 12),
                pw.Table.fromTextArray(
                  headers: const [
                    'م',
                    'من',
                    'إلى',
                    'سعر المتر',
                    'إجمالي القيمة',
                    'إجمالي الكمية (م³)'
                  ],
                  data: rows,
                  border: pw.TableBorder.all(),
                  headerStyle: pw.TextStyle(
                      font: font, fontSize: 9, fontWeight: pw.FontWeight.bold),
                  cellStyle: pw.TextStyle(font: font, fontSize: 8),
                  cellAlignment: pw.Alignment.centerRight,
                ),
              ]),
        ),
      ],
    ));
    await saveBytesAsFile(
        'gas_periods.pdf', Uint8List.fromList(await document.save()));
  }

  Future<List<Map<String, dynamic>>> _loadPeriodDetails(
      Map<String, dynamic> period) async {
    final token = context.read<AuthProvider>().token;
    if (token == null || token.isEmpty) {
      throw Exception('انتهت جلسة الدخول، يرجى تسجيل الدخول مرة أخرى');
    }
    return ApiService.getGasReport(
      token,
      fromDate: period['start_date'] as String,
      toDate: period['end_date'] as String,
    );
  }

  String _periodFileDate(Map<String, dynamic> period) =>
      '${period['start_date']}_${period['end_date']}';

  Future<void> _exportPeriodDetailsExcel(
      Map<String, dynamic> period) async {
    try {
      final rows = await _loadPeriodDetails(period);
      final book = Excel.createExcel();
      final sheet = book['تفاصيل فترة الغاز'];
      const headers = [
        'م',
        'رقم السيارة',
        'بيانات السيارة',
        'إجمالي القيمة',
        'إجمالي الكمية (م³)',
      ];
      for (var index = 0; index < headers.length; index++) {
        sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: index, rowIndex: 0))
            .value = headers[index];
      }
      for (var rowIndex = 0; rowIndex < rows.length; rowIndex++) {
        final row = rows[rowIndex];
        final values = [
          rowIndex + 1,
          '${row['vehicle_number'] ?? ''} ${row['letters'] ?? ''}'.trim(),
          '${row['brand'] ?? ''} ${row['model'] ?? ''}'.trim(),
          _asDouble(row['total_amount']),
          _asDouble(row['total_quantity']),
        ];
        for (var columnIndex = 0;
            columnIndex < values.length;
            columnIndex++) {
          sheet
              .cell(CellIndex.indexByColumnRow(
                  columnIndex: columnIndex, rowIndex: rowIndex + 1))
              .value = values[columnIndex];
        }
      }
      await saveBytesAsFile('gas_period_${_periodFileDate(period)}.xlsx',
          Uint8List.fromList(book.encode()!));
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('فشل تصدير تفاصيل الفترة: $error')));
      }
    }
  }

  Future<void> _exportPeriodDetailsPdf(Map<String, dynamic> period) async {
    try {
      final rows = await _loadPeriodDetails(period);
      final font =
          pw.Font.ttf(await rootBundle.load('assets/fonts/arial.ttf'));
      final document = pw.Document();
      final tableRows = rows.asMap().entries.map((entry) {
        final row = entry.value;
        return [
          '${entry.key + 1}',
          '${row['vehicle_number'] ?? ''} ${row['letters'] ?? ''}'.trim(),
          '${row['brand'] ?? ''} ${row['model'] ?? ''}'.trim(),
          _asDouble(row['total_amount']).toStringAsFixed(2),
          _asDouble(row['total_quantity']).toStringAsFixed(4),
        ];
      }).toList();
      document.addPage(pw.MultiPage(
        pageFormat: pdf_lib.PdfPageFormat.a4,
        theme: pw.ThemeData.withFont(base: font),
        build: (_) => [
          pw.Directionality(
            textDirection: pw.TextDirection.rtl,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.stretch,
              children: [
                pw.Text(
                  'تفاصيل فترة الغاز',
                  textAlign: pw.TextAlign.right,
                  style: pw.TextStyle(
                      font: font,
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold),
                ),
                pw.Text(
                  'الفترة: ${_displayDateFormat.format(DateTime.parse(period['start_date'] as String))} إلى ${_displayDateFormat.format(DateTime.parse(period['end_date'] as String))}',
                  textAlign: pw.TextAlign.right,
                  style: pw.TextStyle(font: font, fontSize: 10),
                ),
                pw.SizedBox(height: 12),
                pw.Table.fromTextArray(
                  headers: const [
                    'م',
                    'رقم السيارة',
                    'بيانات السيارة',
                    'إجمالي القيمة',
                    'إجمالي الكمية (م³)',
                  ],
                  data: tableRows,
                  border: pw.TableBorder.all(),
                  headerStyle: pw.TextStyle(
                      font: font, fontSize: 9, fontWeight: pw.FontWeight.bold),
                  cellStyle: pw.TextStyle(font: font, fontSize: 8),
                  cellAlignment: pw.Alignment.centerRight,
                ),
              ],
            ),
          ),
        ],
      ));
      await saveBytesAsFile('gas_period_${_periodFileDate(period)}.pdf',
          Uint8List.fromList(await document.save()));
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('فشل تصدير تفاصيل الفترة: $error')));
      }
    }
  }

  String get _quantity {
    final amount = double.tryParse(_amountController.text);
    final price = double.tryParse(_priceController.text);
    if (amount == null || price == null || price <= 0) return '';
    return (amount / price).toStringAsFixed(2);
  }

  DateTime? _parseDate(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return null;
    try {
      return trimmed.contains('/')
          ? _displayDateFormat.parseStrict(trimmed)
          : _apiDateFormat.parseStrict(trimmed);
    } catch (_) {
      return null;
    }
  }

  String _formatDateForApi(String value) =>
      _apiDateFormat.format(_parseDate(value)!);

  Future<void> _pickDate(TextEditingController controller) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _parseDate(controller.text) ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime(DateTime.now().year + 10),
      locale: const Locale('ar'),
    );
    if (picked != null) {
      controller.text = _displayDateFormat.format(picked);
      await _loadSavedPeriod();
    }
  }

  Future<void> _loadSavedPeriod() async {
    final startDate = _parseDate(_startController.text);
    final endDate = _parseDate(_endController.text);
    if (startDate == null || endDate == null || endDate.isBefore(startDate))
      return;

    setState(() {
      _loadingPeriod = true;
      _error = null;
    });
    try {
      final token = context.read<AuthProvider>().token!;
      final records = await ApiService.listGasRecords(
        token,
        startDate: _apiDateFormat.format(startDate),
        endDate: _apiDateFormat.format(endDate),
      );
      final loadedEntries = await Future.wait(records.map((record) async {
        final vehicle = await ApiService.getVehicleDetail(
            token, record['vehicle_id'] as int);
        return <String, dynamic>{
          'id': record['id'],
          'vehicle_id': record['vehicle_id'],
          'vehicle': vehicle,
          'amount': _asDouble(record['amount']),
          'gas_price': _asDouble(record['gas_price']),
          'quantity': _asDouble(record['quantity']),
        };
      }));
      if (mounted) {
        setState(() {
          _entries
            ..clear()
            ..addAll(loadedEntries)
            ..sort(_compareEntriesByVehicleNumber);
          _deletedEntryIds.clear();
          if (loadedEntries.isNotEmpty) {
            _priceController.text = '${loadedEntries.first['gas_price']}';
            _periodLocked = true;
            _periodSaved = true;
          } else {
            _periodLocked = false;
            _periodSaved = false;
          }
          _loadingPeriod = false;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _loadingPeriod = false;
          _error = 'تعذر تحميل سجلات الفترة: $error';
        });
      }
    }
  }

  Future<void> _searchVehicle(String value) async {
    if (value.trim().isEmpty) {
      setState(() => _searchResults = []);
      return;
    }
    try {
      final results = await ApiService.fetchVehicles(
          context.read<AuthProvider>().token!, value.trim());
      final queryText = value.trim().toLowerCase();
      final matches = results.where((vehicle) {
        final fullNumber =
            '${vehicle.number} ${vehicle.letters ?? ''}'.trim().toLowerCase();
        final digitsText = vehicle.number.toLowerCase();
        return fullNumber == queryText ||
            digitsText == queryText ||
            fullNumber.contains(queryText) ||
            digitsText.contains(queryText);
      }).toList()
        ..sort(_compareVehiclesByNumber);
      if (!mounted) return;
      if (matches.length == 1) {
        await _selectVehicle(matches.first);
      } else {
        setState(() => _searchResults = matches);
      }
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    }
  }

  int _compareVehiclesByNumber(Vehicle first, Vehicle second) {
    final firstNumber = int.tryParse(first.number);
    final secondNumber = int.tryParse(second.number);
    if (firstNumber != null && secondNumber != null) {
      return firstNumber.compareTo(secondNumber);
    }
    return first.number.compareTo(second.number);
  }

  Future<void> _selectVehicle(Vehicle vehicle) async {
    setState(() {
      _selectedVehicle = vehicle;
      _searchController.text =
          '${vehicle.number} ${vehicle.letters ?? ''}'.trim();
      _searchResults = [];
    });

    final existingIndex =
        _entries.indexWhere((entry) => entry['vehicle_id'] == vehicle.id);
    if (existingIndex == -1) return;

    final editExisting = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        content: const Text('السيارة موجودة بالفعل، هل تريد تعديل بياناتها؟'),
        actions: [
          TextButton(
            onPressed: () {
              _searchController.clear();
              Navigator.of(dialogContext).pop(false);
            },
            child: const Text('تراجع'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('تعديل'),
          ),
        ],
      ),
    );
    if (!mounted) return;
    if (editExisting == true) {
      await _editEntry(existingIndex);
    }
    if (!mounted) return;
    setState(() {
      _selectedVehicle = null;
      _searchController.clear();
      _searchResults = [];
    });
  }

  int _compareEntriesByVehicleNumber(
      Map<String, dynamic> first, Map<String, dynamic> second) {
    final firstVehicle = first['vehicle'] as Vehicle;
    final secondVehicle = second['vehicle'] as Vehicle;
    final firstNumber = int.tryParse(firstVehicle.number);
    final secondNumber = int.tryParse(secondVehicle.number);
    if (firstNumber != null && secondNumber != null) {
      return firstNumber.compareTo(secondNumber);
    }
    return firstVehicle.number.compareTo(secondVehicle.number);
  }

  Future<void> _addEntry() async {
    if (!_periodLocked) {
      setState(() => _error = 'ثبت التاريخ والسعر أولًا قبل إضافة السيارات');
      return;
    }
    final amount = double.tryParse(_amountController.text);
    final price = double.tryParse(_priceController.text);
    final startDate = _parseDate(_startController.text);
    final endDate = _parseDate(_endController.text);
    if (_selectedVehicle == null ||
        startDate == null ||
        endDate == null ||
        endDate.isBefore(startDate) ||
        amount == null ||
        amount < 0 ||
        price == null ||
        price <= 0) {
      setState(() => _error = 'أدخل الفترة والسعر والسيارة والقيمة بشكل صحيح');
      return;
    }
    final existingIndex = _entries
        .indexWhere((entry) => entry['vehicle_id'] == _selectedVehicle!.id);
    if (existingIndex != -1) {
      final editExisting = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          content: const Text('السيارة موجودة بالفعل، هل تريد تعديل بياناتها؟'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('تراجع'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('تعديل'),
            ),
          ],
        ),
      );
      if (!mounted) return;
      if (editExisting == true) {
        await _editEntry(existingIndex);
      }
      setState(() {
        _selectedVehicle = null;
        _searchController.clear();
        _amountController.clear();
        _searchResults = [];
      });
      return;
    }
    setState(() {
      _entries.add({
        'vehicle_id': _selectedVehicle!.id,
        'vehicle': _selectedVehicle,
        'amount': amount,
        'gas_price': price,
        'quantity': double.parse((amount / price).toStringAsFixed(2))
      });
      _entries.sort(_compareEntriesByVehicleNumber);
      _selectedVehicle = null;
      _searchController.clear();
      _amountController.clear();
      _searchResults = [];
      _error = null;
    });
    // عودة تلقائية إلى حقل البحث عن رقم السيارة
    Future.delayed(const Duration(milliseconds: 100), () {
      _searchFocus.requestFocus();
    });
  }

  Future<void> _savePeriod() async {
    final startDate = _parseDate(_startController.text);
    final endDate = _parseDate(_endController.text);
    if ((_entries.isEmpty && _deletedEntryIds.isEmpty) ||
        startDate == null ||
        endDate == null ||
        endDate.isBefore(startDate) ||
        double.tryParse(_priceController.text) == null) {
      setState(() => _error = 'أضف سيارة واحدة على الأقل وأكمل بيانات الفترة');
      return;
    }
    setState(() => _saving = true);
    try {
      final token = context.read<AuthProvider>().token!;
      final periodPrice = double.parse(_priceController.text);
      for (final id in _deletedEntryIds) {
        await ApiService.deleteGasRecord(token, id);
      }
      for (final entry in _entries) {
        final payload = {
          'vehicle_id': entry['vehicle_id'],
          'start_date': _formatDateForApi(_startController.text),
          'end_date': _formatDateForApi(_endController.text),
          'gas_price': periodPrice,
          'amount': entry['amount'],
        };
        if (entry['id'] == null) {
          final saved = await ApiService.createGasRecord(token, payload);
          entry['id'] = saved['id'];
        } else {
          await ApiService.updateGasRecord(token, entry['id'] as int, payload);
        }
        entry['gas_price'] = periodPrice;
        entry['quantity'] =
            double.parse((entry['amount'] / periodPrice).toStringAsFixed(2));
      }
      _deletedEntryIds.clear();
      await _loadPeriods();
      if (mounted) {
        setState(() {
          _saving = false;
          _periodSaved = true;
          _selectedVehicle = null;
          _searchResults = [];
          _searchController.clear();
          _amountController.clear();
          _quantityController.clear();
          _error = null;
        });
      }
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('تم حفظ الفترة')));
    } catch (error) {
      if (mounted)
        setState(() {
          _saving = false;
          _error = error.toString();
        });
    }
  }

  void _togglePeriodLock() {
    if (_periodLocked) {
      setState(() {
        _periodLocked = false;
        _periodSaved = false;
        _selectedVehicle = null;
        _searchResults = [];
        _searchController.clear();
        _amountController.clear();
        _quantityController.clear();
      });
      return;
    }
    final startDate = _parseDate(_startController.text);
    final endDate = _parseDate(_endController.text);
    final price = double.tryParse(_priceController.text);
    if (startDate == null ||
        endDate == null ||
        endDate.isBefore(startDate) ||
        price == null ||
        price <= 0) {
      setState(() => _error = 'أدخل التاريخين وسعر متر الغاز بشكل صحيح أولًا');
      return;
    }
    setState(() {
      _periodLocked = true;
      _error = null;
    });
  }

  Future<void> _deleteEntry(int index) async {
    final id = _entries[index]['id'];
    if (id != null) _deletedEntryIds.add(id as int);
    if (mounted) setState(() => _entries.removeAt(index));
  }

  Future<void> _editEntry(int index) async {
    final entry = _entries[index];
    final amountController = TextEditingController(text: '${entry['amount']}');
    final result = await showDialog<double>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تعديل سجل الغاز'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(
              controller: amountController,
              decoration: const InputDecoration(labelText: 'القيمة')),
        ]),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء')),
          ElevatedButton(
              onPressed: () {
                final amount = double.tryParse(amountController.text);
                if (amount != null && amount >= 0)
                  Navigator.pop(context, amount);
              },
              child: const Text('حفظ'))
        ],
      ),
    );
    amountController.dispose();
    if (result == null || !mounted) return;
    final price = double.parse(_priceController.text);
    setState(() {
      entry['amount'] = result;
      entry['gas_price'] = price;
      entry['quantity'] = double.parse((result / price).toStringAsFixed(2));
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    for (final controller in [
      _startController,
      _endController,
      _priceController,
      _searchController,
      _amountController,
      _quantityController
    ]) {
      controller.dispose();
    }
    for (final focusNode in [
      _startFocus,
      _endFocus,
      _priceFocus,
      _searchFocus,
      _amountFocus,
    ]) {
      focusNode.dispose();
    }
    _periodsFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const ScaAppBar(title: 'الغاز'),
      drawer: ScaDrawer(
        currentRoute: 'gas',
        onDashboard: () => Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const DashboardScreen()),
            (route) => false),
        onVehicleSearch: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const VehicleSearchScreen())),
        onStore: () => Navigator.of(context)
            .push(MaterialPageRoute(builder: (_) => const StoreScreen())),
        onStoreTab: (index) => Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => StoreScreen(initialTab: index))),
        onGas: () {},
        onGasTab: (index) => _tabController.animateTo(index),
        onVehicleData: () => Navigator.of(context)
            .push(MaterialPageRoute(builder: (_) => const VehicleDataScreen())),
        onReports: () => Navigator.of(context)
            .push(MaterialPageRoute(builder: (_) => const ReportsScreen())),
        onReportTab: (index) => Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => ReportsScreen(initialTab: index))),
        onSettings: () => Navigator.of(context)
            .push(MaterialPageRoute(builder: (_) => const SettingsScreen())),
        onArchive: () => Navigator.of(context)
            .push(MaterialPageRoute(builder: (_) => const ArchiveScreen())),
        onLogout: () async {
          final authProvider = context.read<AuthProvider>();
          await authProvider.logout();
          if (!context.mounted) return;
          Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const LoginScreen()),
              (route) => false);
        },
      ),
      body: Column(
          children: [
            ScaKeyboardTabBar(controller: _tabController, tabs: const [
              Tab(text: 'تسجيل الغاز'),
              Tab(text: 'تقرير الغاز'),
              Tab(text: 'سجل الفترات'),
            ]),
            Expanded(
                child: TabBarView(
                  controller: _tabController,
                  physics: (defaultTargetPlatform == TargetPlatform.android ||
                      defaultTargetPlatform == TargetPlatform.iOS)
                    ? const NeverScrollableScrollPhysics()
                    : null,
                  children: [
              _buildRegistrationView(),
              const GasReportTab(),
              _buildPeriodsView(),
            ])),
          ],
        ),
    );
  }

  Widget _buildRegistrationView() {
    return Directionality(
      textDirection: dart_ui.TextDirection.rtl,
      child: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          Card(
              child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(children: [
                    Expanded(
                        child: _field('من تاريخ', _startController,
                            hint: 'dd/MM/yyyy',
                          focusNode: _startFocus,
                          nextFocus: _endFocus,
                            readOnly: true,
                            onTap: _periodLocked
                                ? null
                                : () => _pickDate(_startController))),
                    const SizedBox(width: 10),
                    Expanded(
                        child: _field('إلى تاريخ', _endController,
                            hint: 'dd/MM/yyyy',
                          focusNode: _endFocus,
                          nextFocus: _priceFocus,
                          previousFocus: _startFocus,
                            readOnly: true,
                            onTap: _periodLocked
                                ? null
                                : () => _pickDate(_endController))),
                    const SizedBox(width: 10),
                    Expanded(
                        child: _field('سعر متر الغاز', _priceController,
                          focusNode: _priceFocus,
                          previousFocus: _endFocus,
                            readOnly: _periodLocked, onChanged: (_) {
                      _quantityController.text = _quantity;
                      setState(() {});
                    })),
                    const SizedBox(width: 10),
                    Expanded(
                        child: SizedBox(
                            height: 56,
                            child: ElevatedButton.icon(
                                onPressed: _saving || _loadingPeriod
                                    ? null
                                    : _togglePeriodLock,
                                icon: Icon(_periodLocked
                                    ? Icons.lock
                                    : Icons.lock_open),
                                label: Text(_periodLocked
                                    ? 'تعديل الفترة'
                                    : 'تثبيت الفترة')))),
                  ]))),
          const SizedBox(height: 12),
          if (_periodLocked && !_periodSaved)
            Card(
                child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(children: [
                            Expanded(
                                child: _field(
                                    'بحث عن رقم العربية', _searchController,
                                  focusNode: _searchFocus,
                                  nextFocus: _amountFocus,
                                    onChanged: _searchVehicle)),
                            const SizedBox(width: 10),
                            Expanded(
                                child: _field('القيمة', _amountController,
                                  focusNode: _amountFocus,
                                  previousFocus: _searchFocus,
                                  onSubmit: _addEntry,
                                    onChanged: (_) {
                              _quantityController.text = _quantity;
                              setState(() {});
                            })),
                            const SizedBox(width: 10),
                            Expanded(
                                child: _field(
                                    'الكمية المحسوبة', _quantityController,
                                    readOnly: true)),
                            const SizedBox(width: 10),
                            Expanded(
                                child: SizedBox(
                                    height: 56,
                                    child: ElevatedButton.icon(
                                        onPressed: _addEntry,
                                        icon: const Icon(Icons.add),
                                        label: const Text('إضافة')))),
                          ]),
                          if (_searchResults.length > 1)
                            ..._searchResults.map((vehicle) => ListTile(
                                  title: Text(
                                      '${vehicle.number} ${vehicle.letters ?? ''}'
                                          .trim()),
                                  subtitle: Text(
                                      'نوع الوقود: ${vehicle.fuelType} • السجل: ${vehicle.registry ?? '-'}'),
                                  onTap: () => _selectVehicle(vehicle),
                                )),
                        ]))),
          if (_periodLocked && !_periodSaved && _selectedVehicle != null)
            Text(
                'السيارة المختارة: ${_selectedVehicle!.number} ${_selectedVehicle!.letters ?? ''}'),
          if (_error != null)
            Padding(
                padding: const EdgeInsets.only(top: 8),
                child:
                    Text(_error!, style: const TextStyle(color: Colors.red))),
          if (_entries.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildEntriesTable(),
            const SizedBox(height: 16),
            if (_loadingPeriod)
              const Center(
                  child: Padding(
                      padding: EdgeInsets.all(12),
                      child: CircularProgressIndicator())),
            Align(
                alignment: Alignment.center,
                child: ElevatedButton.icon(
                    onPressed: _saving || _loadingPeriod ? null : _savePeriod,
                    icon: const Icon(Icons.save),
                    label: Text(_saving ? 'جار الحفظ...' : 'حفظ الفترة'))),
          ],
        ],
      ),
    );
  }

  Widget _buildPeriodsView() {
    return Directionality(
      textDirection: dart_ui.TextDirection.rtl,
      child: ListView(
        padding: const EdgeInsets.all(12),
        children: [_buildPeriodsTable()],
      ),
    );
  }

  Widget _buildEntriesTable() {
    final rows = _entries.asMap().entries.map((item) {
      final index = item.key;
      final entry = item.value;
      final vehicle = entry['vehicle'] as Vehicle;
      return DataRow(cells: [
        DataCell(Text('${index + 1}')),
        DataCell(Text(vehicle.number)),
        DataCell(Text('${vehicle.brand ?? ''} ${vehicle.model ?? ''}')),
        DataCell(Text((entry['amount'] as double).toStringAsFixed(2))),
        DataCell(Text((entry['gas_price'] as double).toStringAsFixed(2))),
        DataCell(Text((entry['quantity'] as double).toStringAsFixed(2))),
        DataCell(Row(children: [
          IconButton(
              icon: const Icon(Icons.edit, color: Colors.blue),
              onPressed: entry['id'] == null ? null : () => _editEntry(index)),
          IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _deleteEntry(index)),
        ])),
      ]);
    }).toList();
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowColor: WidgetStatePropertyAll(
            Theme.of(context).colorScheme.primaryContainer),
        dataRowColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.hovered)) {
            return Theme.of(context)
                .colorScheme
                .primary
                .withValues(alpha: 0.08);
          }
          return null;
        }),
        border: TableBorder.all(color: Colors.grey.shade300),
        horizontalMargin: 16,
        columnSpacing: 24,
        headingTextStyle: const TextStyle(
            fontWeight: FontWeight.bold, color: Colors.black87),
        columns: const [
          DataColumn(label: Text('م')),
          DataColumn(label: Text('رقم العربية')),
          DataColumn(label: Text('العربية / بياناتها')),
          DataColumn(label: Text('القيمة')),
          DataColumn(label: Text('سعر المتر')),
          DataColumn(label: Text('الكمية')),
          DataColumn(label: Text('إجراءات')),
        ],
        rows: rows,
      ),
    );
  }

  Widget _buildPeriodsTable() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Expanded(
                    child: Text('سجل الفترات',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold))),
                OutlinedButton.icon(
                  onPressed: _periods.isEmpty ? null : _exportPeriodsExcel,
                  icon: const Icon(Icons.table_view),
                  label: const Text('Excel'),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: _periods.isEmpty ? null : _exportPeriodsPdf,
                  icon: const Icon(Icons.picture_as_pdf),
                  label: const Text('PDF'),
                ),
              ],
            ),
            if (_loadingPeriods)
              const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator()))
            else if (_periods.isEmpty)
              const Padding(
                  padding: EdgeInsets.all(12),
                  child: Text('لا توجد فترات محفوظة'))
            else
              LayoutBuilder(
                builder: (context, tableConstraints) {
                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minWidth: tableConstraints.maxWidth,
                      ),
                      child: Focus(
                        focusNode: _periodsFocusNode,
                        autofocus: true,
                        onKeyEvent: (node, event) {
                          if (event is! KeyDownEvent || _periods.isEmpty) {
                            return KeyEventResult.ignored;
                          }
                          if (event.logicalKey ==
                              LogicalKeyboardKey.arrowDown) {
                            setState(() => _selectedPeriodIndex =
                                ((_selectedPeriodIndex ?? -1) + 1)
                                    .clamp(0, _periods.length - 1));
                            return KeyEventResult.handled;
                          }
                          if (event.logicalKey ==
                              LogicalKeyboardKey.arrowUp) {
                            setState(() => _selectedPeriodIndex =
                                ((_selectedPeriodIndex ?? _periods.length) - 1)
                                    .clamp(0, _periods.length - 1));
                            return KeyEventResult.handled;
                          }
                          if (event.logicalKey ==
                                  LogicalKeyboardKey.enter &&
                              _selectedPeriodIndex != null) {
                            _openPeriod(_periods[_selectedPeriodIndex!]);
                            return KeyEventResult.handled;
                          }
                          return KeyEventResult.ignored;
                        },
                        child: DataTable(
                        headingRowColor: WidgetStatePropertyAll(
                            Theme.of(context).colorScheme.primaryContainer),
                        dataRowColor:
                            WidgetStateProperty.resolveWith((states) {
                          if (states.contains(WidgetState.hovered)) {
                            return Theme.of(context)
                                .colorScheme
                                .primary
                                .withValues(alpha: 0.08);
                          }
                          return null;
                        }),
                        border: TableBorder.all(color: Colors.grey.shade300),
                        horizontalMargin: 16,
                        columnSpacing: 24,
                        headingTextStyle: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.black87),
                  columns: const [
                    DataColumn(label: Text('م')),
                    DataColumn(label: Text('من')),
                    DataColumn(label: Text('إلى')),
                    DataColumn(label: Text('سعر المتر')),
                    DataColumn(label: Text('إجمالي القيمة')),
                    DataColumn(label: Text('إجمالي الكمية (م³)')),
                    DataColumn(label: Text('إجراءات')),
                  ],
                    rows: _periods.asMap().entries.map((item) {
                    final period = item.value;
                    return DataRow(
                      selected: _selectedPeriodIndex == item.key,
                      onSelectChanged: (selected) => setState(() {
                        _selectedPeriodIndex = selected == true ? item.key : null;
                      }),
                      cells: [
                      DataCell(Text('${item.key + 1}')),
                      DataCell(Text(_displayDateFormat.format(
                          DateTime.parse(period['start_date'] as String)))),
                      DataCell(Text(_displayDateFormat.format(
                          DateTime.parse(period['end_date'] as String)))),
                      DataCell(Text(
                          (period['gas_price'] as double).toStringAsFixed(2))),
                      DataCell(Text((period['total_amount'] as double)
                          .toStringAsFixed(2))),
                      DataCell(Text((period['total_quantity'] as double)
                          .toStringAsFixed(2))),
                      DataCell(Row(children: [
                        IconButton(
                          tooltip: 'فتح الفترة للتعديل',
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          onPressed: () => _openPeriod(period),
                        ),
                        IconButton(
                          tooltip: 'تصدير تفاصيل السيارات Excel',
                          icon: const Icon(Icons.table_view, color: Colors.green),
                          onPressed: () => _exportPeriodDetailsExcel(period),
                        ),
                        IconButton(
                          tooltip: 'تصدير تفاصيل السيارات PDF',
                          icon: const Icon(Icons.picture_as_pdf,
                              color: Colors.deepOrange),
                          onPressed: () => _exportPeriodDetailsPdf(period),
                        ),
                        IconButton(
                          tooltip: 'حذف الفترة بالكامل',
                          icon: const Icon(Icons.delete_forever,
                              color: Colors.red),
                          onPressed: () => _deletePeriod(period),
                        ),
                      ])),
                    ]);
                  }).toList(),
                      ),
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _field(String label, TextEditingController controller,
          {String? hint,
          ValueChanged<String>? onChanged,
          VoidCallback? onTap,
          bool readOnly = false,
          FocusNode? focusNode,
          FocusNode? nextFocus,
          FocusNode? previousFocus,
          VoidCallback? onSubmit}) {
    final field = TextField(
        controller: controller,
        readOnly: readOnly,
        focusNode: focusNode,
        onTap: onTap,
        onChanged: onChanged,
        onSubmitted: (_) {
          if (nextFocus != null) {
            FocusScope.of(context).requestFocus(nextFocus);
          } else {
            onSubmit?.call();
          }
        },
        decoration: InputDecoration(
            labelText: label,
            hintText: hint,
            border: const OutlineInputBorder(),
            suffixIcon:
                onTap == null ? null : const Icon(Icons.calendar_today)));
    if (focusNode == null) return field;
    return Focus(
      onKeyEvent: (node, event) {
        if (event is! KeyDownEvent) return KeyEventResult.ignored;
        if (event.logicalKey == LogicalKeyboardKey.enter) {
          if (nextFocus != null) {
            FocusScope.of(context).requestFocus(nextFocus);
          } else {
            onSubmit?.call();
          }
          return KeyEventResult.handled;
        }
        if ((event.logicalKey == LogicalKeyboardKey.arrowRight ||
                event.logicalKey == LogicalKeyboardKey.arrowDown) &&
            nextFocus != null) {
          FocusScope.of(context).requestFocus(nextFocus);
          return KeyEventResult.handled;
        }
        if ((event.logicalKey == LogicalKeyboardKey.arrowLeft ||
                event.logicalKey == LogicalKeyboardKey.arrowUp) &&
            previousFocus != null) {
          FocusScope.of(context).requestFocus(previousFocus);
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: field,
    );
  }
}

class GasReportTab extends StatefulWidget {
  const GasReportTab({super.key});

  @override
  State<GasReportTab> createState() => _GasReportTabState();
}

class _GasReportTabState extends State<GasReportTab> {
  final _displayDateFormat = DateFormat('dd/MM/yyyy');
  final _apiDateFormat = DateFormat('yyyy-MM-dd');
  final _fromController = TextEditingController();
  final _toController = TextEditingController();
  final _vehicleController = TextEditingController();
  List<Map<String, dynamic>> _rows = [];
  bool _loading = false;
  String? _error;
  final _fromFocus = FocusNode();
  final _toFocus = FocusNode();
  final _vehicleFocus = FocusNode();
  final _reportTableFocus = FocusNode();
  int? _selectedReportRow;

  double _number(Map<String, dynamic> row, String key) =>
      (row[key] as num?)?.toDouble() ?? double.tryParse('${row[key]}') ?? 0;

  double get _totalAmount =>
      _rows.fold(0, (sum, row) => sum + _number(row, 'total_amount'));
  double get _totalQuantity =>
      _rows.fold(0, (sum, row) => sum + _number(row, 'total_quantity'));

  DateTime? _parseDate(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return null;
    try {
      return trimmed.contains('/')
          ? _displayDateFormat.parseStrict(trimmed)
          : _apiDateFormat.parseStrict(trimmed);
    } catch (_) {
      return null;
    }
  }

  Future<void> _pickDate(TextEditingController controller) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _parseDate(controller.text) ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime(DateTime.now().year + 10),
      locale: const Locale('ar'),
    );
    if (picked != null) controller.text = _displayDateFormat.format(picked);
  }

  Future<void> _search() async {
    final fromDate = _parseDate(_fromController.text);
    final toDate = _parseDate(_toController.text);
    if (fromDate == null || toDate == null || toDate.isBefore(fromDate)) {
      setState(() => _error = 'أدخل تاريخ البداية والنهاية');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final rows = await ApiService.getGasReport(
        context.read<AuthProvider>().token!,
        fromDate: _apiDateFormat.format(fromDate),
        toDate: _apiDateFormat.format(toDate),
        vehicleNumber: _vehicleController.text,
      );
      if (mounted)
        setState(() {
          _rows = rows;
          _loading = false;
        });
    } catch (error) {
      if (mounted)
        setState(() {
          _loading = false;
          _error = error.toString();
          _rows = [];
        });
    }
  }

  Future<void> _exportExcel() async {
    final book = Excel.createExcel();
    final sheet = book['تقرير الغاز'];
    const headers = [
      'رقم السيارة',
      'بيانات السيارة',
      'إجمالي القيمة',
      'إجمالي الكمية'
    ];
    for (var index = 0; index < headers.length; index++) {
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: index, rowIndex: 0))
          .value = headers[index];
    }
    for (var rowIndex = 0; rowIndex < _rows.length; rowIndex++) {
      final row = _rows[rowIndex];
      final values = [
        '${row['vehicle_number'] ?? ''} ${row['letters'] ?? ''}'.trim(),
        '${row['brand'] ?? ''} ${row['model'] ?? ''}'.trim(),
        _number(row, 'total_amount'),
        _number(row, 'total_quantity'),
      ];
      for (var columnIndex = 0; columnIndex < values.length; columnIndex++) {
        sheet
            .cell(CellIndex.indexByColumnRow(
                columnIndex: columnIndex, rowIndex: rowIndex + 1))
            .value = values[columnIndex];
      }
    }
    final totalRow = _rows.length + 1;
    sheet
        .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: totalRow))
        .value = 'الإجمالي';
    sheet
        .cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: totalRow))
        .value = _totalAmount;
    sheet
        .cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: totalRow))
        .value = _totalQuantity;
    await saveBytesAsFile(
        'gas_report.xlsx', Uint8List.fromList(book.encode()!));
  }

  Future<void> _exportPdf() async {
    final font = pw.Font.ttf(await rootBundle.load('assets/fonts/arial.ttf'));
    final document = pw.Document();
    final rows = _rows
        .map((row) => [
              '${row['vehicle_number'] ?? ''} ${row['letters'] ?? ''}'.trim(),
              '${row['brand'] ?? ''} ${row['model'] ?? ''}'.trim(),
              _number(row, 'total_amount').toStringAsFixed(2),
              _number(row, 'total_quantity').toStringAsFixed(4),
            ])
        .toList();
    document.addPage(pw.MultiPage(
      pageFormat: pdf_lib.PdfPageFormat.a4,
      theme: pw.ThemeData.withFont(base: font),
      build: (_) => [
        pw.Directionality(
          textDirection: pw.TextDirection.rtl,
          child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.stretch,
              children: [
                pw.Text('تقرير الغاز',
                    textAlign: pw.TextAlign.right,
                    style: pw.TextStyle(
                        font: font,
                        fontSize: 18,
                        fontWeight: pw.FontWeight.bold)),
                pw.Text(
                    'الفترة: ${_fromController.text} إلى ${_toController.text}',
                    textAlign: pw.TextAlign.right,
                    style: pw.TextStyle(font: font, fontSize: 10)),
                pw.SizedBox(height: 12),
                pw.Table.fromTextArray(
                  headers: const [
                    'رقم السيارة',
                    'بيانات السيارة',
                    'إجمالي القيمة',
                    'إجمالي الكمية'
                  ],
                  data: rows,
                  border: pw.TableBorder.all(),
                  headerStyle: pw.TextStyle(
                      font: font, fontSize: 9, fontWeight: pw.FontWeight.bold),
                  cellStyle: pw.TextStyle(font: font, fontSize: 8),
                  cellAlignment: pw.Alignment.centerRight,
                ),
                pw.SizedBox(height: 12),
                pw.Text(
                    'إجمالي قيمة الغاز: ${_totalAmount.toStringAsFixed(2)} جنيه',
                    textAlign: pw.TextAlign.right,
                    style: pw.TextStyle(font: font, fontSize: 10)),
                pw.Text(
                    'إجمالي كمية الغاز: ${_totalQuantity.toStringAsFixed(4)} متر مكعب',
                    textAlign: pw.TextAlign.right,
                    style: pw.TextStyle(font: font, fontSize: 10)),
              ]),
        ),
      ],
    ));
    await saveBytesAsFile(
        'gas_report.pdf', Uint8List.fromList(await document.save()));
  }

  @override
  void dispose() {
    _fromController.dispose();
    _toController.dispose();
    _vehicleController.dispose();
    _fromFocus.dispose();
    _toFocus.dispose();
    _vehicleFocus.dispose();
    _reportTableFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: dart_ui.TextDirection.rtl,
      child: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          Card(
              child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(children: [
                    Expanded(child: _reportField('من تاريخ', _fromController,
                      focusNode: _fromFocus, nextFocus: _toFocus)),
                    const SizedBox(width: 10),
                    Expanded(child: _reportField('إلى تاريخ', _toController,
                      focusNode: _toFocus,
                      nextFocus: _vehicleFocus,
                      previousFocus: _fromFocus)),
                    const SizedBox(width: 10),
                    Expanded(
                        child: _reportField(
                            'بحث برقم السيارة', _vehicleController,
                        dateField: false,
                        focusNode: _vehicleFocus,
                        previousFocus: _toFocus,
                        onSubmit: _search)),
                    const SizedBox(width: 10),
                    ElevatedButton.icon(
                        onPressed: _loading ? null : _search,
                        icon: const Icon(Icons.search),
                        label: const Text('بحث')),
                  ]))),
          const SizedBox(height: 12),
          Card(
              child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text('تقرير الغاز',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold)),
                        if (_loading)
                          const Padding(
                              padding: EdgeInsets.all(20),
                              child: Center(child: CircularProgressIndicator()))
                        else if (_error != null)
                          Padding(
                              padding: const EdgeInsets.all(12),
                              child: Text(_error!,
                                  style: const TextStyle(color: Colors.red)))
                        else if (_rows.isEmpty)
                          const Padding(
                              padding: EdgeInsets.all(20),
                              child: Center(
                                  child: Text(
                                      'لا توجد بيانات غاز خلال الفترة المحددة.')))
                        else
                          _buildReportTable(),
                        if (_rows.isNotEmpty) ...[
                          const Divider(),
                          Text(
                              'إجمالي قيمة الغاز: ${_totalAmount.toStringAsFixed(2)} جنيه'),
                          Text(
                              'إجمالي كمية الغاز: ${_totalQuantity.toStringAsFixed(4)} متر مكعب'),
                          const SizedBox(height: 12),
                          Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                ElevatedButton.icon(
                                    onPressed: _exportExcel,
                                    icon: const Icon(Icons.table_view),
                                    label: const Text('تصدير Excel')),
                                const SizedBox(width: 10),
                                ElevatedButton.icon(
                                    onPressed: _exportPdf,
                                    icon: const Icon(Icons.picture_as_pdf),
                                    label: const Text('تصدير PDF')),
                              ]),
                        ],
                      ]))),
        ],
      ),
    );
  }

  Widget _buildReportTable() {
    return LayoutBuilder(builder: (context, tableConstraints) {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: ConstrainedBox(
          constraints: BoxConstraints(minWidth: tableConstraints.maxWidth),
          child: Focus(
            focusNode: _reportTableFocus,
            autofocus: true,
            onKeyEvent: (node, event) {
              if (event is! KeyDownEvent || _rows.isEmpty) {
                return KeyEventResult.ignored;
              }
              if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
                setState(() => _selectedReportRow =
                    ((_selectedReportRow ?? -1) + 1).clamp(0, _rows.length - 1));
                return KeyEventResult.handled;
              }
              if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
                setState(() => _selectedReportRow =
                    ((_selectedReportRow ?? _rows.length) - 1).clamp(0, _rows.length - 1));
                return KeyEventResult.handled;
              }
              return KeyEventResult.ignored;
            },
            child: DataTable(
          headingRowColor: WidgetStatePropertyAll(
              Theme.of(context).colorScheme.primaryContainer),
          dataRowColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.hovered)) {
              return Theme.of(context)
                  .colorScheme
                  .primary
                  .withValues(alpha: 0.08);
            }
            return null;
          }),
          border: TableBorder.all(color: Colors.grey.shade300),
          horizontalMargin: 16,
          columnSpacing: 24,
          headingTextStyle: const TextStyle(
              fontWeight: FontWeight.bold, color: Colors.black87),
          columns: const [
            DataColumn(label: Text('م')),
            DataColumn(label: Text('رقم السيارة')),
            DataColumn(label: Text('السيارة')),
            DataColumn(label: Text('إجمالي القيمة (جنيه)')),
            DataColumn(label: Text('إجمالي الكمية (متر مكعب)')),
          ],
          rows: _rows.asMap().entries.map((item) {
            final row = item.value;
            return DataRow(selected: _selectedReportRow == item.key, cells: [
              DataCell(Text('${item.key + 1}')),
              DataCell(Text(
                  '${row['vehicle_number'] ?? ''} ${row['letters'] ?? ''}'
                      .trim())),
              DataCell(
                  Text('${row['brand'] ?? ''} ${row['model'] ?? ''}'.trim())),
              DataCell(Text(_number(row, 'total_amount').toStringAsFixed(2))),
              DataCell(Text(_number(row, 'total_quantity').toStringAsFixed(4))),
            ]);
          }).toList(),
          ),
          ),
        ),
      );
    });
  }

  Widget _reportField(String label, TextEditingController controller,
      {bool dateField = true,
      FocusNode? focusNode,
      FocusNode? nextFocus,
      FocusNode? previousFocus,
      VoidCallback? onSubmit}) {
    final field = TextField(
        controller: controller,
        readOnly: dateField,
        focusNode: focusNode,
        onSubmitted: (_) => nextFocus != null
            ? FocusScope.of(context).requestFocus(nextFocus)
            : onSubmit?.call(),
        onTap: dateField ? () => _pickDate(controller) : null,
        decoration: InputDecoration(
          labelText: label,
          hintText:
              dateField ? _displayDateFormat.format(DateTime.now()) : null,
          border: const OutlineInputBorder(),
          suffixIcon: dateField ? const Icon(Icons.calendar_today) : null,
        ),
      );
    if (focusNode == null) return field;
    return Focus(
      onKeyEvent: (node, event) {
        if (event is! KeyDownEvent) return KeyEventResult.ignored;
        if (event.logicalKey == LogicalKeyboardKey.enter) {
          if (nextFocus != null) {
            FocusScope.of(context).requestFocus(nextFocus);
          } else {
            onSubmit?.call();
          }
          return KeyEventResult.handled;
        }
        if ((event.logicalKey == LogicalKeyboardKey.arrowRight ||
                event.logicalKey == LogicalKeyboardKey.arrowDown) &&
            nextFocus != null) {
          FocusScope.of(context).requestFocus(nextFocus);
          return KeyEventResult.handled;
        }
        if ((event.logicalKey == LogicalKeyboardKey.arrowLeft ||
                event.logicalKey == LogicalKeyboardKey.arrowUp) &&
            previousFocus != null) {
          FocusScope.of(context).requestFocus(previousFocus);
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: field,
    );
  }
}
