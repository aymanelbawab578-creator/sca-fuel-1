import 'package:excel/excel.dart' hide Border;
import 'dart:ui' as dart_ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart' as pdf_lib;
import 'package:pdf/widgets.dart' as pw;
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../utils/file_save_helper.dart';

class InventoryTab extends StatefulWidget {
  const InventoryTab({super.key});

  @override
  State<InventoryTab> createState() => _InventoryTabState();
}

class _InventoryTabState extends State<InventoryTab> {
  static const fuelTypes = ['سولار', 'بنزين 92', 'بنزين 95'];
  final prices = <String, double>{};
  List<Map<String, dynamic>> records = [];
  Map<String, dynamic> balances = {};
  bool loading = true;
  final _recordsFocusNode = FocusNode();
  int? _selectedRecordIndex;

  @override
  void dispose() {
    _recordsFocusNode.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    if (token == null) return;
    setState(() => loading = true);
    try {
      final results = await Future.wait([
        ApiService.listInventoryCounts(token),
        ApiService.fetchStoreBalances(token),
        ApiService.fetchInvoicePrices(token),
      ]);
      final priceData =
          Map<String, dynamic>.from((results[2] as Map)['prices'] ?? {});
      if (!mounted) return;
      setState(() {
        records = results[0] as List<Map<String, dynamic>>;
        balances = results[1] as Map<String, dynamic>;
        for (final fuel in fuelTypes) {
          prices[fuel] = (priceData[fuel] as num?)?.toDouble() ?? 0;
        }
        loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => loading = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('فشل تحميل الجرد: $error')));
    }
  }

  double _balance(String area, String fuel) {
    final key = fuel == 'بنزين 92'
        ? 'gasoline_92'
        : fuel == 'بنزين 95'
            ? 'gasoline_95'
            : 'solar';
    final source = area == 'المخزن' ? balances : (balances['cards'] ?? {});
    return (source[key] as num?)?.toDouble() ?? 0;
  }

  Future<void> _addRecord() async {
    final dateController = TextEditingController(
        text: DateFormat('yyyy-MM-dd').format(DateTime.now()));
    final controllers = <String, TextEditingController>{};
    for (final area in ['المخزن', 'الكروت']) {
      for (final fuel in fuelTypes) {
        controllers['$area|$fuel'] =
            TextEditingController(text: _balance(area, fuel).toString());
      }
    }
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('إضافة جرد'),
        content: SizedBox(
          width: 620,
          child: SingleChildScrollView(
            child: Column(children: [
              TextField(
                  controller: dateController,
                  decoration: const InputDecoration(labelText: 'تاريخ الجرد')),
              const SizedBox(height: 12),
              for (final area in ['المخزن', 'الكروت']) ...[
                Align(
                    alignment: Alignment.centerRight,
                    child: Text('رصيد $area',
                        style: const TextStyle(fontWeight: FontWeight.bold))),
                for (final fuel in fuelTypes)
                  Row(children: [
                    Expanded(child: Text(fuel)),
                    SizedBox(
                        width: 150,
                        child: TextField(
                            controller: controllers['$area|$fuel'],
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            decoration:
                                const InputDecoration(labelText: 'الكمية'))),
                    const SizedBox(width: 8),
                    SizedBox(
                        width: 130, child: Text('${prices[fuel] ?? 0} جنيه')),
                  ]),
                const SizedBox(height: 10),
              ],
            ]),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('إلغاء')),
          ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('حفظ')),
        ],
      ),
    );
    if (result != true) return;
    final details = <Map<String, dynamic>>[];
    var total = 0.0;
    for (final area in ['المخزن', 'الكروت']) {
      for (final fuel in fuelTypes) {
        final quantity = double.tryParse(controllers['$area|$fuel']!.text) ?? 0;
        final price = prices[fuel] ?? 0;
        final value = quantity * price;
        total += value;
        details.add({
          'area': area,
          'fuel_type': fuel,
          'quantity': quantity,
          'price': price,
          'value': value
        });
      }
    }
    final token = Provider.of<AuthProvider>(context, listen: false).token!;
    try {
      await ApiService.createInventoryCount(token, {
        'counted_at': dateController.text,
        'details': details,
        'total_value': total
      });
      await _load();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('فشل حفظ الجرد: $error')));
    }
    dateController.dispose();
    for (final controller in controllers.values) {
      controller.dispose();
    }
  }

  Future<void> _deleteRecord(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف سجل الجرد'),
        content: const Text('هل تريد حذف سجل الجرد؟'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('إلغاء')),
          ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('حذف')),
        ],
      ),
    );
    if (confirmed != true) return;
    final token = Provider.of<AuthProvider>(context, listen: false).token!;
    try {
      await ApiService.deleteInventoryCount(token, id);
      await _load();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('فشل حذف الجرد: $error')));
    }
  }

  Future<void> _showRecordDetails(Map<String, dynamic> record) async {
    final details = _details(record);
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('تفاصيل جرد ${record['counted_at']}'),
        content: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columns: const [
              DataColumn(label: Text('المكان')),
              DataColumn(label: Text('نوع الوقود')),
              DataColumn(label: Text('الكمية')),
              DataColumn(label: Text('السعر')),
              DataColumn(label: Text('القيمة')),
            ],
            rows: details
                .map((item) => DataRow(cells: [
                      DataCell(Text(item['area']?.toString() ?? '-')),
                      DataCell(Text(item['fuel_type']?.toString() ?? '-')),
                      DataCell(Text(_quantityText(item['quantity']))),
                      DataCell(Text('${_moneyText(item['price'])} جنيه')),
                      DataCell(Text('${_moneyText(item['value'])} جنيه')),
                    ]))
                .toList(),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('إغلاق')),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _details(Map<String, dynamic> record) =>
      (record['details'] as List? ?? [])
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList();

  String _quantityText(dynamic value) {
    final quantity = (value as num?)?.toDouble() ?? 0;
    return quantity.round().toString();
  }

  String _moneyText(dynamic value) {
    final amount = (value as num?)?.toDouble() ?? 0;
    return amount.toStringAsFixed(2);
  }

  Widget _buildSummary(List<Map<String, dynamic>> details) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Divider(),
        const Text('الملخص', style: TextStyle(fontWeight: FontWeight.bold)),
        for (final fuel in fuelTypes)
          Builder(builder: (_) {
            final storeQuantity = details
                .where((item) =>
                    item['fuel_type'] == fuel && item['area'] == 'المخزن')
                .fold<double>(0,
                    (sum, item) => sum + (item['quantity'] as num).toDouble());
            final cardQuantity = details
                .where((item) =>
                    item['fuel_type'] == fuel && item['area'] == 'الكروت')
                .fold<double>(0,
                    (sum, item) => sum + (item['quantity'] as num).toDouble());
            final value = details
                .where((item) => item['fuel_type'] == fuel)
                .fold<double>(
                    0, (sum, item) => sum + (item['value'] as num).toDouble());
            return ListTile(
                dense: true,
                title: Text(
                '$fuel: المخزن ${storeQuantity.round()} لتر + الكروت ${cardQuantity.round()} لتر'),
              trailing: Text('${value.toStringAsFixed(2)} جنيه'));
          }),
      ],
    );
  }

  Future<void> _exportExcel() async {
    final book = Excel.createExcel();
    final sheet = book['جرد'];
    const headers = [
      'التاريخ',
      'المكان',
      'المادة',
      'الكمية',
      'السعر',
      'القيمة'
    ];
    for (var index = 0; index < headers.length; index++) {
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: index, rowIndex: 0))
          .value = headers[index];
    }
    var rowIndex = 1;
    for (final record in records) {
      for (final item in _details(record)) {
        final values = [
          record['counted_at'],
          item['area'],
          item['fuel_type'],
          (item['quantity'] as num).toDouble(),
          (item['price'] as num).toDouble(),
          (item['value'] as num).toDouble(),
        ];
        for (var columnIndex = 0; columnIndex < values.length; columnIndex++) {
          sheet
              .cell(CellIndex.indexByColumnRow(
                  columnIndex: columnIndex, rowIndex: rowIndex))
              .value = values[columnIndex];
        }
        rowIndex++;
      }
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex))
          .value = 'الإجمالي';
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: rowIndex))
          .value = (record['total_value'] as num).toDouble();
      rowIndex++;
    }
    await saveBytesAsFile(
        'inventory_counts.xlsx', Uint8List.fromList(book.encode()!));
  }

  Future<void> _exportSummaryExcel() async {
    final book = Excel.createExcel();
    final sheet = book['جرد'];
    const headers = ['م.', 'تاريخ التسوية', 'الإجمالي القيمة'];
    sheet.cell(CellIndex.indexByString('A1')).value = 'ملخص جرد المخزن';
    for (var index = 0; index < headers.length; index++) {
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: index, rowIndex: 2))
          .value = headers[index];
    }
    for (var index = 0; index < records.length; index++) {
      final rowIndex = index + 3;
      final record = records[index];
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex))
          .value = index + 1;
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex))
          .value = record['counted_at']?.toString() ?? '';
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: rowIndex))
          .value = _moneyText(record['total_value']);
    }
    final total = records.fold<double>(
        0, (sum, record) => sum + ((record['total_value'] as num?)?.toDouble() ?? 0));
    sheet.cell(CellIndex.indexByString('A${records.length + 3}')).value =
        'الإجمالي';
    sheet.cell(CellIndex.indexByString('C${records.length + 3}')).value =
        total.toStringAsFixed(2);
    await saveBytesAsFile(
        'inventory_summary.xlsx', Uint8List.fromList(book.encode()!));
  }

  Future<void> _exportSummaryPdf() async {
    final document = pw.Document();
    final font = pw.Font.ttf(await rootBundle.load('assets/fonts/arial.ttf'));
    final total = records.fold<double>(
        0, (sum, record) => sum + ((record['total_value'] as num?)?.toDouble() ?? 0));
    final rows = records.asMap().entries
        .map((entry) => [
              '${entry.key + 1}',
              entry.value['counted_at']?.toString() ?? '',
              _moneyText(entry.value['total_value']),
            ])
        .toList();
    rows.add(['الإجمالي', '', total.toStringAsFixed(2)]);
    document.addPage(pw.Page(
      theme: pw.ThemeData.withFont(base: font),
      build: (_) => pw.Directionality(
        textDirection: pw.TextDirection.rtl,
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            pw.Text('ملخص جرد المخزن',
                textAlign: pw.TextAlign.right,
                style: pw.TextStyle(
                    font: font, fontSize: 18, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 12),
            pw.Table.fromTextArray(
              headers: const ['م.', 'تاريخ التسوية', 'الإجمالي القيمة'],
              data: rows,
              border: pw.TableBorder.all(),
              headerStyle: pw.TextStyle(
                  font: font, fontSize: 10, fontWeight: pw.FontWeight.bold),
              cellStyle: pw.TextStyle(font: font, fontSize: 9),
              cellAlignment: pw.Alignment.centerRight,
              headerDecoration:
                  const pw.BoxDecoration(color: pdf_lib.PdfColors.grey300),
            ),
          ],
        ),
      ),
    ));
    await saveBytesAsFile(
        'inventory_summary.pdf', Uint8List.fromList(await document.save()));
  }

  Future<void> _exportPdf() async {
    final document = pw.Document();
    final font = pw.Font.ttf(await rootBundle.load('assets/fonts/arial.ttf'));
    document.addPage(pw.MultiPage(
        theme: pw.ThemeData.withFont(base: font),
        build: (_) => [
              pw.Directionality(
                textDirection: pw.TextDirection.rtl,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                  children: [
                    pw.Text('تقرير جرد المخزن',
                        textAlign: pw.TextAlign.right,
                        style: pw.TextStyle(
                            font: font,
                            fontSize: 18,
                            fontWeight: pw.FontWeight.bold)),
                    for (final record in records) ...[
                      pw.SizedBox(height: 8),
                      pw.Text(
                          'تاريخ الجرد: ${record['counted_at']}    إجمالي القيمة: ${record['total_value']} جنيه',
                          textAlign: pw.TextAlign.right,
                          style: pw.TextStyle(font: font, fontSize: 10)),
                      pw.Table.fromTextArray(
                        headers: const [
                          'المكان',
                          'نوع الوقود',
                          'الكمية',
                          'السعر',
                          'القيمة'
                        ],
                        data: _details(record)
                            .map((item) => [
                                  item['area']?.toString() ?? '',
                                  item['fuel_type']?.toString() ?? '',
                                  item['quantity']?.toString() ?? '',
                                  item['price']?.toString() ?? '',
                                  item['value']?.toString() ?? '',
                                ])
                            .toList(),
                        border: pw.TableBorder.all(),
                        headerStyle: pw.TextStyle(
                            font: font,
                            fontSize: 9,
                            fontWeight: pw.FontWeight.bold),
                        cellStyle: pw.TextStyle(font: font, fontSize: 8),
                        cellAlignment: pw.Alignment.centerRight,
                        headerDecoration: const pw.BoxDecoration(
                          color: pdf_lib.PdfColors.grey300),
                      ),
                    ],
                  ],
                ),
              ),
            ]));
    await saveBytesAsFile(
        'inventory_counts.pdf', Uint8List.fromList(await document.save()));
  }

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Row(children: [
        ElevatedButton.icon(
            onPressed: loading ? null : _addRecord,
            icon: const Icon(Icons.add_box),
            label: const Text('إضافة جرد')),
        const SizedBox(width: 8),
        IconButton(
            tooltip: 'تصدير Excel',
          onPressed: records.isEmpty ? null : _exportSummaryExcel,
            icon: const Icon(Icons.table_view)),
        IconButton(
            tooltip: 'تصدير PDF',
          onPressed: records.isEmpty ? null : _exportSummaryPdf,
            icon: const Icon(Icons.picture_as_pdf)),
        const Spacer(),
        IconButton(
            tooltip: 'تحديث',
            onPressed: _load,
            icon: const Icon(Icons.refresh)),
      ]),
      const SizedBox(height: 10),
      if (loading)
        const Expanded(child: Center(child: CircularProgressIndicator()))
      else
        Expanded(
            child: records.isEmpty
                ? const Center(child: Text('لا توجد سجلات جرد'))
                : Focus(
                    focusNode: _recordsFocusNode,
                    autofocus: true,
                    onKeyEvent: (node, event) {
                      if (event is! KeyDownEvent || records.isEmpty) {
                        return KeyEventResult.ignored;
                      }
                      if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
                        setState(() => _selectedRecordIndex =
                            ((_selectedRecordIndex ?? -1) + 1)
                                .clamp(0, records.length - 1));
                        return KeyEventResult.handled;
                      }
                      if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
                        setState(() => _selectedRecordIndex =
                            ((_selectedRecordIndex ?? records.length) - 1)
                                .clamp(0, records.length - 1));
                        return KeyEventResult.handled;
                      }
                      if (event.logicalKey == LogicalKeyboardKey.enter &&
                          _selectedRecordIndex != null) {
                        setState(() {});
                        return KeyEventResult.handled;
                      }
                      return KeyEventResult.ignored;
                    },
                    child: LayoutBuilder(
                      builder: (context, constraints) =>
                          SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                              minWidth: constraints.maxWidth),
                          child: DataTable(
                        headingRowColor: WidgetStatePropertyAll(
                            Theme.of(context).colorScheme.primaryContainer),
                        border: TableBorder.all(color: Colors.grey.shade300),
                        horizontalMargin: 16,
                        columnSpacing: 24,
                        headingTextStyle: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.black87),
                        columns: const [
                          DataColumn(label: Text('م.')),
                          DataColumn(label: Text('تاريخ التسوية')),
                          DataColumn(label: Text('الإجمالي القيمة')),
                          DataColumn(label: Text('الإجراءات')),
                        ],
                        rows: records.asMap().entries.map((entry) {
                          final index = entry.key;
                          final record = entry.value;
                          return DataRow(
                            selected: _selectedRecordIndex == index,
                            onSelectChanged: (selected) => setState(() {
                              _selectedRecordIndex =
                                  selected == true ? index : null;
                            }),
                            cells: [
                              DataCell(Text('${index + 1}')),
                              DataCell(Text(record['counted_at']?.toString() ?? '')),
                              DataCell(Text(
                                  '${_moneyText(record['total_value'])} جنيه')),
                              DataCell(Directionality(
                                textDirection: dart_ui.TextDirection.ltr,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                  IconButton(
                                    tooltip: 'حذف',
                                    icon: const Icon(Icons.delete_outline,
                                        color: Colors.red),
                                    onPressed: () =>
                                        _deleteRecord(record['id'] as int),
                                  ),
                                  IconButton(
                                    tooltip: 'معلومات',
                                    icon: const Icon(Icons.info_outline,
                                        color: Colors.blue),
                                    onPressed: () => _showRecordDetails(record),
                                  ),
                                  IconButton(
                                    tooltip: 'تصدير Excel',
                                    icon: const Icon(Icons.table_view,
                                        color: Colors.green),
                                    onPressed: _exportExcel,
                                  ),
                                  IconButton(
                                    tooltip: 'تصدير PDF',
                                    icon: const Icon(Icons.picture_as_pdf,
                                        color: Colors.red),
                                    onPressed: _exportPdf,
                                  ),
                                  ],
                                ),
                              )),
                            ],
                          );
                        }).toList(),
                          ),
                        ),
                      ),
                    ),
                    ),
                      ),
    ]);
  }
}
