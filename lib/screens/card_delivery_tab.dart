import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:excel/excel.dart' hide Border;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart' as pdf;
import 'package:pdf/widgets.dart' as pw;
import 'package:provider/provider.dart';

import '../utils/file_save_helper.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';

const _deliveryFuelTypes = ['سولار', 'بنزين 92', 'بنزين 95', 'غاز'];

String _dateText(dynamic value) {
  final date = DateTime.tryParse(value?.toString() ?? '');
  return date == null ? '' : DateFormat('yyyy-MM-dd').format(date);
}

class CardDeliveryTab extends StatefulWidget {
  const CardDeliveryTab({super.key});

  @override
  State<CardDeliveryTab> createState() => _CardDeliveryTabState();
}

class _CardDeliveryTabState extends State<CardDeliveryTab> {
  DateTime? _startDate;
  DateTime? _endDate;
  List<Map<String, dynamic>> _records = [];
  bool _loading = true;
  bool _saving = false;
  String? _error;
  final _recordsFocusNode = FocusNode();
  int? _selectedRecordIndex;

  @override
  void initState() {
    super.initState();
    _loadRecords();
  }

Future<void> _loadRecords() async {
  final token = Provider.of<AuthProvider>(context, listen: false).token;
  if (token == null) return;

  setState(() => _loading = true);

  try {
    final records = await ApiService.listCardDeliveryRecords(token);

    final normalizedRecords = records.map((record) {
      final normalized = Map<String, dynamic>.from(record);

      final rawItems =
          normalized['card_delivery_item'] as List? ?? [];

      final items = rawItems
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();

      final grouped = <String, List<Map<String, dynamic>>>{
        for (final fuel in _deliveryFuelTypes) fuel: [],
      };

      // نحافظ على ترتيب قاعدة البيانات كما هو
      // الإضافة الجديدة تظل في آخر مجموعتها
      for (final item in items) {
        final fuel = item['fuel_type']?.toString() ?? 'سولار';
        grouped.putIfAbsent(fuel, () => []).add(item);
      }

      // ترقيم مستقل لكل نوع وقود
      for (final fuel in grouped.keys) {
        final values = grouped[fuel]!;

        for (var i = 0; i < values.length; i++) {
          values[i]['sequence_number'] = i + 1;
        }
      }

      final orderedItems = <Map<String, dynamic>>[];

      for (final fuel in _deliveryFuelTypes) {
        orderedItems.addAll(grouped[fuel] ?? []);
      }

      final summary = <String, dynamic>{};

      for (final fuel in _deliveryFuelTypes) {
        final values = grouped[fuel] ?? [];

        final delivered =
            values.where((item) => item['delivered'] == true).length;

        summary[fuel] = {
          'total': values.length,
          'delivered': delivered,
          'undelivered': values.length - delivered,
        };
      }

      normalized['items'] = orderedItems;
      normalized['groups'] = grouped;
      normalized['summary'] = summary;

      return normalized;
    }).toList();

    if (!mounted) return;

    setState(() {
      _records = normalizedRecords;
      _loading = false;
    });
  } catch (e) {
    if (!mounted) return;

    setState(() => _loading = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'حدث خطأ أثناء تحميل سجلات تسليم الكروت: $e',
        ),
      ),
    );
  }
}
  @override
  void dispose() {
    _recordsFocusNode.dispose();
    super.dispose();
  }

  Future<void> _pickDate(bool start) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: (start ? _startDate : _endDate) ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      locale: const Locale('ar'),
    );
    if (picked == null || !mounted) return;
    setState(() {
      if (start) {
        _startDate = picked;
      } else {
        _endDate = picked;
      }
    });
  }

  Future<void> _createRecord() async {
  if (_startDate == null || _endDate == null) {
    _message('يرجى اختيار الفترة من وإلى');
    return;
  }

  if (_endDate!.isBefore(_startDate!)) {
    _message('تاريخ النهاية يجب أن يكون بعد أو يساوي تاريخ البداية');
    return;
  }

  final token = Provider.of<AuthProvider>(
    context,
    listen: false,
  ).token;

  if (token == null) return;

  setState(() => _saving = true);

  try {
    await ApiService.createCardDeliveryRecord(
      token,
      _startDate!,
      _endDate!,
    );

    if (!mounted) return;

    // إعادة تحميل السجلات من قاعدة البيانات
    // لضمان تحميل items و summary بالشكل الصحيح.
    await _loadRecords();

    if (!mounted) return;

    _message('تم إنشاء سجل التسليم');
  } catch (error) {
    if (mounted) {
      _message(error.toString());
    }
  } finally {
    if (mounted) {
      setState(() => _saving = false);
    }
  }
}

  void _message(String message) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(message)));

  Future<void> _openDetails(Map<String, dynamic> record) async {
    final changed = await Navigator.of(context).push<bool>(MaterialPageRoute(
        builder: (_) => CardDeliveryDetailsScreen(record: record)));
    if (changed == true) _loadRecords();
  }

  Future<void> _deleteRecord(Map<String, dynamic> record) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('مسح سجل التسليم'),
        content:
            const Text('سيتم حذف سجل الفترة وتفاصيله فقط. هل تريد المتابعة؟'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('إلغاء')),
          FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('مسح')),
        ],
      ),
    );
    if (confirmed != true) return;
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    if (token == null) return;
    try {
      await ApiService.deleteCardDeliveryRecord(token, record['id'] as int);
      if (mounted) {
        _message('تم مسح سجل التسليم');
        _loadRecords();
      }
    } catch (error) {
      if (mounted) _message(error.toString());
    }
  }

  Future<void> _showInfo(Map<String, dynamic> record) async {
    final summary = Map<String, dynamic>.from(record['summary'] as Map? ?? {});
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
            'ملخص ${_dateText(record['start_date'])} إلى ${_dateText(record['end_date'])}'),
        content: SingleChildScrollView(
          child: Column(
              children: _deliveryFuelTypes.map((fuel) {
            final values =
                Map<String, dynamic>.from(summary[fuel] as Map? ?? {});
            return Card(
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(fuel,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16)),
                      _SummaryValue('إجمالي الكروت', values['total'] ?? 0),
                      _SummaryValue('تم التسليم', values['delivered'] ?? 0,
                          color: Colors.green),
                      _SummaryValue(
                          'لم يتم التسليم', values['undelivered'] ?? 0,
                          color: Colors.red),
                    ]),
              ),
            );
          }).toList()),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('إغلاق'))
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text(_error!, textAlign: TextAlign.center),
        const SizedBox(height: 12),
        ElevatedButton(
            onPressed: _loadRecords, child: const Text('إعادة المحاولة'))
      ]));
    }
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Wrap(
                spacing: 12,
                runSpacing: 10,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  _DateButton(
                      label: 'الفترة من',
                      value: _startDate,
                      onPressed: () => _pickDate(true)),
                  _DateButton(
                      label: 'الفترة إلى',
                      value: _endDate,
                      onPressed: () => _pickDate(false)),
                  FilledButton.icon(
                      onPressed: _saving ? null : _createRecord,
                      icon: const Icon(Icons.save),
                      label: const Text('حفظ')),
                ]),
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: _records.isEmpty
              ? const Center(child: Text('لا توجد سجلات تسليم'))
              : Focus(
                  focusNode: _recordsFocusNode,
                  autofocus: true,
                  onKeyEvent: (node, event) {
                    if (event is! KeyDownEvent || _records.isEmpty) {
                      return KeyEventResult.ignored;
                    }
                    if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
                      setState(() => _selectedRecordIndex =
                          ((_selectedRecordIndex ?? -1) + 1)
                              .clamp(0, _records.length - 1));
                      return KeyEventResult.handled;
                    }
                    if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
                      setState(() => _selectedRecordIndex =
                          ((_selectedRecordIndex ?? _records.length) - 1)
                              .clamp(0, _records.length - 1));
                      return KeyEventResult.handled;
                    }
                    if (event.logicalKey == LogicalKeyboardKey.enter &&
                        _selectedRecordIndex != null) {
                      _openDetails(_records[_selectedRecordIndex!]);
                      return KeyEventResult.handled;
                    }
                    return KeyEventResult.ignored;
                  },
                  child: SingleChildScrollView(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Card(
                        child: DataTable(
                          columns: const [
                            DataColumn(label: Text('م')),
                            DataColumn(label: Text('الفترة من')),
                            DataColumn(label: Text('الفترة إلى')),
                            DataColumn(label: Text('مسلم')),
                            DataColumn(label: Text('غير مسلم')),
                            DataColumn(label: Text('الإجراءات'))
                          ],
                          rows: _records.asMap().entries.map((entry) {
                            final record = entry.value;
                            final isSelected =
                                _selectedRecordIndex == entry.key;
                            final summary = Map<String, dynamic>.from(
                                record['summary'] as Map? ?? {});
                            final delivered = summary.values.fold<int>(
                              0,
                              (sum, value) =>
                                sum +
                                ((value as Map)['delivered'] as num? ?? 0)
                                  .toInt());
                            final undelivered = summary.values.fold<int>(
                                0,
                                (sum, value) =>
                                    sum +
                                    ((value as Map)['undelivered'] as num? ?? 0)
                                        .toInt());
                            return DataRow(
                                selected: isSelected,
                                onSelectChanged: (selected) => setState(() {
                                      _selectedRecordIndex =
                                          selected == true ? entry.key : null;
                                    }),
                                cells: [
                                  DataCell(Text('${entry.key + 1}')),
                                  DataCell(
                                      Text(_dateText(record['start_date']))),
                                  DataCell(Text(_dateText(record['end_date']))),
                                  DataCell(Text('$delivered',
                                      style: const TextStyle(
                                          color: Colors.green,
                                          fontWeight: FontWeight.bold))),
                                  DataCell(Text('$undelivered',
                                      style: TextStyle(
                                          color: undelivered > 0
                                              ? Colors.red
                                              : Colors.green,
                                          fontWeight: FontWeight.bold))),
                                  DataCell(Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                            tooltip: 'تعديل',
                                            icon: const Icon(Icons.edit),
                                            onPressed: () =>
                                                _openDetails(record)),
                                        IconButton(
                                            tooltip: 'معلومات',
                                            icon:
                                                const Icon(Icons.info_outline),
                                            onPressed: () => _showInfo(record)),
                                        IconButton(
                                            tooltip: 'مسح',
                                            icon: const Icon(
                                                Icons.delete_outline,
                                                color: Colors.red),
                                            onPressed: () =>
                                                _deleteRecord(record))
                                      ])),
                                ]);
                          }).toList(),
                        ),
                      ),
                    ),
                  ),
                ),
        ),
      ]),
    );
  }
}

class _DateButton extends StatelessWidget {
  final String label;
  final DateTime? value;
  final VoidCallback onPressed;
  const _DateButton(
      {required this.label, required this.value, required this.onPressed});
  @override
  Widget build(BuildContext context) => OutlinedButton.icon(
      onPressed: onPressed,
      icon: const Icon(Icons.calendar_month),
      label: Text(
          '$label: ${value == null ? 'اختر' : DateFormat('yyyy-MM-dd').format(value!)}'));
}

class _SummaryValue extends StatelessWidget {
  final String label;
  final dynamic value;
  final Color? color;
  const _SummaryValue(this.label, this.value, {this.color});
  @override
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label),
        Text('$value',
            style: TextStyle(color: color, fontWeight: FontWeight.bold))
      ]));
}

class CardDeliveryDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> record;
  const CardDeliveryDetailsScreen({super.key, required this.record});
  @override
  State<CardDeliveryDetailsScreen> createState() =>
      _CardDeliveryDetailsScreenState();
}

class _CardDeliveryDetailsScreenState extends State<CardDeliveryDetailsScreen> {
  late List<Map<String, dynamic>> _items;
  String _fuelFilter = 'الكل';
  String _statusFilter = 'الكل';
  final _searchController = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _items = (widget.record['items'] as List? ?? [])
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _filteredItems {
    final query = _searchController.text.trim().toLowerCase();
    return _items.where((item) {
      final matchesFuel =
          _fuelFilter == 'الكل' || item['fuel_type'] == _fuelFilter;
      final delivered = item['delivered'] == true;
      final matchesStatus = _statusFilter == 'الكل' ||
          (_statusFilter == 'مسلم' ? delivered : !delivered);
      final matchesQuery = query.isEmpty ||
          item['vehicle_number'].toString().toLowerCase().contains(query);
      return matchesFuel && matchesStatus && matchesQuery;
    }).toList();
  }

  Future<void> _save() async {
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    if (token == null) return;
    setState(() => _saving = true);
    var didPop = false;
    try {
      await ApiService.updateCardDeliveryRecord(
          token,
          widget.record['id'] as int,
          _items
              .map((item) =>
                  {'id': item['id'], 'delivered': item['delivered'] == true})
              .toList());
      if (mounted) {
        didPop = true;
        Navigator.pop(context, true);
      }
    } catch (error) {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.toString())));
    } finally {
      if (mounted && !didPop) setState(() => _saving = false);
    }
  }

  void _message(String message) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(message, textDirection: Directionality.of(context))),
      );

  Future<void> _exportExcel() async {
    try {
      final items = _filteredItems;
      final book = Excel.createExcel();
      final sheet = book['تسليم الكارت'];
      const headers = ['رقم السيارة', 'نوع الوقود', 'حالة التسليم'];
      for (var columnIndex = 0; columnIndex < headers.length; columnIndex++) {
        sheet
            .cell(CellIndex.indexByColumnRow(
                columnIndex: columnIndex, rowIndex: 0))
            .value = headers[columnIndex];
      }
      for (var rowIndex = 0; rowIndex < items.length; rowIndex++) {
        final item = items[rowIndex];
        final values = [
          item['vehicle_number']?.toString() ?? '',
          item['fuel_type']?.toString() ?? '',
          item['delivered'] == true ? 'مسلم' : 'لم يسلم',
        ];
        for (var columnIndex = 0; columnIndex < values.length; columnIndex++) {
          sheet
              .cell(CellIndex.indexByColumnRow(
                  columnIndex: columnIndex, rowIndex: rowIndex + 1))
              .value = values[columnIndex];
        }
      }
      final bytes = book.encode();
      if (bytes == null) throw Exception('فشل إنشاء ملف Excel');
      await saveBytesAsFile('card_delivery_${widget.record['id']}.xlsx',
          Uint8List.fromList(bytes));
      if (mounted) _message('تم تصدير سجل تسليم الكارت إلى Excel');
    } catch (error) {
      if (mounted) _message('فشل تصدير Excel: $error');
    }
  }

  Future<void> _exportPdf() async {
    try {
      final document = pw.Document();
      final font = pw.Font.ttf(await rootBundle.load('assets/fonts/arial.ttf'));
      final rows = _filteredItems
          .map((item) => [
                item['vehicle_number']?.toString() ?? '',
                item['fuel_type']?.toString() ?? '',
                item['delivered'] == true ? 'مسلم' : 'لم يسلم',
              ])
          .toList();
      document.addPage(pw.MultiPage(
        pageFormat: pdf.PdfPageFormat.a4,
        theme: pw.ThemeData.withFont(base: font),
        build: (_) => [
          pw.Directionality(
            textDirection: pw.TextDirection.rtl,
            child: pw.Text('سجل تسليم الكارت',
                textAlign: pw.TextAlign.right,
                style: pw.TextStyle(
                    font: font, fontSize: 18, fontWeight: pw.FontWeight.bold)),
          ),
          pw.SizedBox(height: 6),
          pw.Directionality(
            textDirection: pw.TextDirection.rtl,
            child: pw.Text(
                'الفترة: ${_dateText(widget.record['start_date'])} إلى ${_dateText(widget.record['end_date'])}',
                textAlign: pw.TextAlign.right,
                style: pw.TextStyle(font: font, fontSize: 10)),
          ),
          pw.SizedBox(height: 10),
          pw.Directionality(
            textDirection: pw.TextDirection.rtl,
            child: pw.TableHelper.fromTextArray(
              headers: const ['رقم السيارة', 'نوع الوقود', 'حالة التسليم'],
              data: rows,
              border: pw.TableBorder.all(),
              headerStyle: pw.TextStyle(
                  font: font, fontSize: 10, fontWeight: pw.FontWeight.bold),
              cellStyle: pw.TextStyle(font: font, fontSize: 9),
              cellAlignment: pw.Alignment.centerRight,
              headerDecoration:
                  const pw.BoxDecoration(color: pdf.PdfColors.grey300),
            ),
          ),
        ],
      ));
      await saveBytesAsFile('card_delivery_${widget.record['id']}.pdf',
          Uint8List.fromList(await document.save()));
      if (mounted) _message('تم تصدير سجل تسليم الكارت إلى PDF');
    } catch (error) {
      if (mounted) _message('فشل تصدير PDF: $error');
    }
  }

  Future<void> _addVehicle() async {
  final value = await showDialog<String>(
    context: context,
    builder: (_) => const _AddVehicleDialog(),
  );

  if (value == null || value.isEmpty) return;

  final token = Provider.of<AuthProvider>(
    context,
    listen: false,
  ).token;

  if (token == null) return;

  try {
    final result = await ApiService.addCardDeliveryVehicle(
      token,
      widget.record['id'] as int,
      value,
    );

    if (!mounted) return;

    final rawItems = result['items'];

    if (rawItems is List) {
      final items = rawItems
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();

      // إعادة ترقيم السيارات بعد الإضافة
      for (var i = 0; i < items.length; i++) {
        items[i]['sequence_number'] = i + 1;
      }

      setState(() {
        _items = items;
      });
    }

    _message('تمت إضافة السيارة');
  } catch (error) {
    if (mounted) {
      _message(error.toString());
    }
  }
}

  Future<void> _importGasVehicles() async {
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    if (token == null) return;
    try {
      final result = await ApiService.importCardDeliveryGasVehicles(
          token,
          widget.record['id'] as int,
          _dateText(widget.record['start_date']),
          _dateText(widget.record['end_date']));
      if (mounted) {
        setState(() => _items = (result['items'] as List)
            .map((item) => Map<String, dynamic>.from(item as Map))
            .toList());
        _message('تم استيراد كروت الغاز');
      }
    } catch (error) {
      if (mounted) _message(error.toString());
    }
  }

  Future<void> _deleteVehicle(Map<String, dynamic> item) async {
  final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
              title: const Text('حذف السيارة'),
              content: Text(
                  'حذف ${item['vehicle_number']} من سجل التسليم الحالي فقط؟'),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(dialogContext, false),
                    child: const Text('إلغاء')),
                FilledButton(
                    onPressed: () => Navigator.pop(dialogContext, true),
                    child: const Text('حذف'))
              ]));
  if (confirmed != true) return;

  final token = Provider.of<AuthProvider>(context, listen: false).token;
  if (token == null) return;

  try {
    final result = await ApiService.deleteCardDeliveryVehicle(
        token, widget.record['id'] as int, item['id'] as int);

    if (!mounted) return;

    final rawItems = result['items'];

    if (rawItems is List) {
      final items = rawItems
          .whereType<Map>()
          .map((value) => Map<String, dynamic>.from(value))
          .toList();

      // إعادة ترقيم السيارات بعد الحذف
      for (var i = 0; i < items.length; i++) {
        items[i]['sequence_number'] = i + 1;
      }

      setState(() {
        _items = items;
      });
    }

    _message('تم حذف السيارة');
  } catch (error) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    }
  }
}

  @override
  Widget build(BuildContext context) {
    final grouped = <String, List<Map<String, dynamic>>>{
      for (final fuel in _deliveryFuelTypes) fuel: []
    };
    for (final item in _filteredItems) {
      grouped.putIfAbsent(item['fuel_type'].toString(), () => []).add(item);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('تعديل تسليم كارت'),
        centerTitle: false,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
              child: Align(
                alignment: Alignment.centerRight,
                child: Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    IconButton(
                      tooltip: 'إضافة سيارة',
                      icon: const Icon(Icons.add_circle_outline,
                          color: Colors.green),
                      onPressed: _addVehicle,
                    ),
                    IconButton(
                      tooltip: 'تصدير Excel',
                      icon: const Icon(Icons.table_view, color: Colors.blue),
                      onPressed: _exportExcel,
                    ),
                    IconButton(
                      tooltip: 'تصدير PDF',
                      icon: const Icon(Icons.picture_as_pdf_outlined,
                          color: Colors.red),
                      onPressed: _exportPdf,
                    ),
                    IconButton(
                      tooltip: 'استيراد كروت الغاز',
                      icon: const Icon(Icons.local_gas_station,
                          color: Colors.green),
                      onPressed: _importGasVehicles,
                    ),
                    FilledButton.icon(
                      onPressed: _saving ? null : _save,
                      icon: const Icon(Icons.save_outlined),
                      label: const Text('حفظ'),
                    ),
                  ],
                ),
              ),
            ),
            Container(
              width: double.infinity,
              margin: const EdgeInsets.symmetric(horizontal: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: const Color(0xFFdfeaf5)),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 6,
                      offset: const Offset(0, 2)),
                ],
              ),
              child: Wrap(
                spacing: 12,
                runSpacing: 12,
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  SizedBox(
                    width: 220,
                    child: TextField(
                      controller: _searchController,
                      onChanged: (_) => setState(() {}),
                      textDirection: Directionality.of(context),
                      decoration: const InputDecoration(
                        labelText: 'بحث برقم السيارة',
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 180,
                    child: DropdownButtonFormField<String>(
                      value: _fuelFilter,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'نوع الوقود',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      items: ['الكل', ..._deliveryFuelTypes]
                          .map((value) => DropdownMenuItem(
                              value: value, child: Text(value)))
                          .toList(),
                      onChanged: (value) =>
                          setState(() => _fuelFilter = value!),
                    ),
                  ),
                  SizedBox(
                    width: 180,
                    child: DropdownButtonFormField<String>(
                      value: _statusFilter,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'حالة الكارت',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      items: const ['الكل', 'مسلم', 'لم يسلم']
                          .map((value) => DropdownMenuItem(
                              value: value, child: Text(value)))
                          .toList(),
                      onChanged: (value) =>
                          setState(() => _statusFilter = value!),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                children: _deliveryFuelTypes.map((fuel) {
                  final values = grouped[fuel] ?? [];
                  if (values.isEmpty) return const SizedBox.shrink();

                  final rightCount = (values.length / 2).ceil();
                  final rightItems = values.take(rightCount).toList();
                  final leftItems = values.skip(rightCount).toList();

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFdfeaf5)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            fuel,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            textDirection: Directionality.of(context),
                            children: [
                              Expanded(
                                child: Column(
                                  children:
                                      rightItems.asMap().entries.map((entry) {
                                    final item = entry.value;
                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 4),
                                      child: _VehicleDeliveryTile(
                                        key: ValueKey(item['id']),
                                        sequenceNumber:
                                            (item['sequence_number'] as num)
                                                .toInt(),
                                        item: item,
                                        onChanged: (value) => setState(
                                            () => item['delivered'] = value),
                                        onDelete: () => _deleteVehicle(item),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  children:
                                      leftItems.asMap().entries.map((entry) {
                                    final item = entry.value;
                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 4),
                                      child: _VehicleDeliveryTile(
                                        key: ValueKey(item['id']),
                                        sequenceNumber:
                                            (item['sequence_number'] as num)
                                                .toInt(),
                                        item: item,
                                        onChanged: (value) => setState(
                                            () => item['delivered'] = value),
                                        onDelete: () => _deleteVehicle(item),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddVehicleDialog extends StatefulWidget {
  const _AddVehicleDialog();

  @override
  State<_AddVehicleDialog> createState() => _AddVehicleDialogState();
}

class _AddVehicleDialogState extends State<_AddVehicleDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('إضافة سيارة'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        textInputAction: TextInputAction.done,
        onSubmitted: (_) => Navigator.pop(context, _controller.text.trim()),
        decoration: const InputDecoration(labelText: 'رقم السيارة'),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('إلغاء'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _controller.text.trim()),
          child: const Text('إضافة'),
        ),
      ],
    );
  }
}

class _VehicleDeliveryTile extends StatelessWidget {
  final int sequenceNumber;
  final Map<String, dynamic> item;
  final ValueChanged<bool> onChanged;
  final VoidCallback onDelete;

  const _VehicleDeliveryTile({
    super.key,
    required this.sequenceNumber,
    required this.item,
    required this.onChanged,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final delivered = item['delivered'] == true;
    final vehicleNumber = item['vehicle_number'].toString();
    final registry = item['registry']?.toString().trim() ?? '';

    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: delivered
            ? Colors.green.withValues(alpha: 0.08)
            : Colors.red.withValues(alpha: 0.06),
        border:
            Border.all(color: delivered ? Colors.green : Colors.red, width: 1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        textDirection: Directionality.of(context),
        children: [
          Transform.scale(
            scale: 0.7,
            child: Checkbox(
              value: delivered,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: const VisualDensity(horizontal: -3, vertical: -3),
              onChanged: (value) => onChanged(value == true),
            ),
          ),
          const SizedBox(width: 2),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFFE9F0F8),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              'م $sequenceNumber',
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ),
          const SizedBox(width: 5),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  vehicleNumber,
                  textDirection: Directionality.of(context),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color:
                        delivered ? Colors.green.shade800 : Colors.red.shade800,
                    decoration: delivered ? TextDecoration.lineThrough : null,
                  ),
                ),
                if (registry.isNotEmpty)
                  Text(
                    'السجل: $registry',
                    textDirection: Directionality.of(context),
                    style: const TextStyle(fontSize: 9, color: Colors.black87),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 5),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            decoration: BoxDecoration(
              color: delivered ? Colors.green : Colors.red,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              delivered ? 'مسلم' : 'لم يسلم',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 9,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 2),
          SizedBox(
            width: 24,
            child: IconButton(
              onPressed: onDelete,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
              icon:
                  const Icon(Icons.delete_outline, size: 16, color: Colors.red),
              tooltip: 'حذف السيارة',
            ),
          ),
        ],
      ),
    );
  }
}
