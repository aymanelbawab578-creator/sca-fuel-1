import 'dart:typed_data';

import 'package:excel/excel.dart' hide Border;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart' as pdf;
import 'package:pdf/widgets.dart' as pw;
import 'package:provider/provider.dart';

import '../models/vehicle.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../utils/file_save_helper.dart';
import '../widgets/sca_layout.dart';

class VehicleIdentityChangeScreen extends StatefulWidget {
  const VehicleIdentityChangeScreen({super.key});

  @override
  State<VehicleIdentityChangeScreen> createState() =>
      _VehicleIdentityChangeScreenState();
}

class _VehicleIdentityChangeScreenState
    extends State<VehicleIdentityChangeScreen> {
  final _searchController = TextEditingController();
  final _numberController = TextEditingController();
  final _lettersController = TextEditingController();
  final _oldSearchController = TextEditingController();
  final _newSearchController = TextEditingController();
  final _historySearchController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _dateFormat = DateFormat('dd/MM/yyyy');
  final _newNumberFocus = FocusNode();
  final _newLettersFocus = FocusNode();
  final _saveChangeFocus = FocusNode();

  Vehicle? _selectedVehicle;
  List<Vehicle> _searchResults = [];
  List<Map<String, dynamic>> _changes = [];
  bool _searching = false;
  bool _loadingHistory = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _numberController.dispose();
    _lettersController.dispose();
    _oldSearchController.dispose();
    _newSearchController.dispose();
    _historySearchController.dispose();
    _newNumberFocus.dispose();
    _newLettersFocus.dispose();
    _saveChangeFocus.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    if (token == null) return;
    setState(() {
      _searching = true;
      _error = null;
    });
    try {
      final results = await ApiService.fetchVehicles(token, query);
      if (!mounted) return;
      setState(() {
        _searchResults = results;
        _selectedVehicle = results.length == 1 ? results.first : null;
        if (_selectedVehicle != null) _fillVehicle(_selectedVehicle!);
      });
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  void _fillVehicle(Vehicle vehicle) {
    _numberController.text = vehicle.number;
    _lettersController.text = vehicle.letters ?? '';
  }

  Future<void> _loadHistory() async {
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    if (token == null) return;
    try {
      final changes = await ApiService.listVehiclePlateChanges(token);
      if (mounted) setState(() => _changes = changes);
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _loadingHistory = false);
    }
  }

  Future<void> _editHistoryChange(Map<String, dynamic> change) async {
    final numberController =
        TextEditingController(text: '${change['new_number'] ?? ''}');
    final lettersController =
        TextEditingController(text: '${change['new_letters'] ?? ''}');
    final formKey = GlobalKey<FormState>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('تعديل سجل تغيير السيارة'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: numberController,
                autofocus: true,
                decoration: const InputDecoration(labelText: 'الرقم الجديد'),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'أدخل الرقم الجديد'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: lettersController,
                decoration: const InputDecoration(labelText: 'الحروف الجديدة'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(dialogContext, true);
              }
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
    final changeId = int.tryParse('${change['id']}');
    if (confirmed != true || changeId == null || !mounted) {
      numberController.dispose();
      lettersController.dispose();
      return;
    }

    final token = Provider.of<AuthProvider>(context, listen: false).token;
    if (token == null) return;
    try {
      await ApiService.updateVehiclePlateChange(
        token,
        changeId,
        numberController.text.trim(),
        lettersController.text.trim().isEmpty
            ? null
            : lettersController.text.trim(),
      );
      await _loadHistory();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم تعديل سجل تغيير السيارة')),
        );
      }
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      numberController.dispose();
      lettersController.dispose();
    }
  }

  Future<void> _deleteHistoryChange(Map<String, dynamic> change) async {
    final changeId = int.tryParse('${change['id']}');
    if (changeId == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('حذف سجل التغيير'),
        content: const Text('هل أنت متأكد من حذف هذا السجل؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    if (token == null) return;
    try {
      await ApiService.deleteVehiclePlateChange(token, changeId);
      await _loadHistory();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم حذف سجل تغيير السيارة')),
        );
      }
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    }
  }

  List<Map<String, dynamic>> get _filteredChanges {
    final oldQuery = _oldSearchController.text.trim().toLowerCase();
    final newQuery = _newSearchController.text.trim().toLowerCase();
    final historyQuery = _historySearchController.text.trim().toLowerCase();
    return _changes.where((change) {
      final oldNumber = '${change['old_number']}'.toLowerCase();
      final oldLetters = '${change['old_letters'] ?? ''}'.toLowerCase();
      final newNumber = '${change['new_number']}'.toLowerCase();
      final newLetters = '${change['new_letters'] ?? ''}'.toLowerCase();
      final registry = '${change['registry'] ?? ''}'.toLowerCase();
      return (oldQuery.isEmpty || oldNumber.contains(oldQuery)) &&
          (newQuery.isEmpty || newNumber.contains(newQuery)) &&
          (historyQuery.isEmpty ||
              registry.contains(historyQuery) ||
              oldNumber.contains(historyQuery) ||
              oldLetters.contains(historyQuery) ||
              newNumber.contains(historyQuery) ||
              newLetters.contains(historyQuery));
    }).toList();
  }

  Future<void> _exportToExcel() async {
    final excel = Excel.createExcel();
    final sheet = excel['Vehicle Plate Changes'];
    sheet.appendRow([
      'م',
      'رقم السجل',
      'الرقم القديم',
      'الحروف القديمة',
      'الرقم الجديد',
      'الحروف الجديدة',
      'تاريخ التغيير',
    ]);
    for (var index = 0; index < _filteredChanges.length; index++) {
      final change = _filteredChanges[index];
      sheet.appendRow([
        '${index + 1}',
        '${change['registry'] ?? ''}',
        '${change['old_number'] ?? ''}',
        '${change['old_letters'] ?? ''}',
        '${change['new_number'] ?? ''}',
        '${change['new_letters'] ?? ''}',
        _formatDate(change['changed_at']),
      ]);
    }
    final bytes = excel.encode();
    if (bytes == null) throw Exception('فشل إنشاء ملف Excel');
    await saveBytesAsFile(
      'vehicle_plate_changes_${DateTime.now().millisecondsSinceEpoch}.xlsx',
      Uint8List.fromList(bytes),
    );
  }

  Future<void> _exportToPdf() async {
    final document = pw.Document();
    final font = pw.Font.ttf(await rootBundle.load('assets/fonts/arial.ttf'));
    final data = _filteredChanges.asMap().entries.map((entry) {
      final change = entry.value;
      return [
        '${entry.key + 1}',
        '${change['registry'] ?? ''}',
        '${change['old_number'] ?? ''}',
        '${change['old_letters'] ?? ''}',
        '${change['new_number'] ?? ''}',
        '${change['new_letters'] ?? ''}',
        _formatDate(change['changed_at']),
      ];
    }).toList();
    document.addPage(pw.MultiPage(
      pageFormat: pdf.PdfPageFormat.a4,
      theme: pw.ThemeData.withFont(base: font),
      build: (_) => [
        pw.Directionality(
          textDirection: pw.TextDirection.rtl,
          child: pw.Header(
            level: 0,
            child: pw.Text(
              'سجل تغييرات أرقام السيارات',
              textAlign: pw.TextAlign.right,
              style: pw.TextStyle(font: font),
            ),
          ),
        ),
        pw.Directionality(
          textDirection: pw.TextDirection.rtl,
          child: pw.Table.fromTextArray(
            headers: const [
              'م',
              'رقم السجل',
              'الرقم القديم',
              'الحروف القديمة',
              'الرقم الجديد',
              'الحروف الجديدة',
              'تاريخ التغيير',
            ],
            data: data,
            headerStyle: pw.TextStyle(
                font: font, fontWeight: pw.FontWeight.bold),
            cellStyle: pw.TextStyle(font: font),
            cellAlignment: pw.Alignment.centerRight,
            headerDecoration:
                const pw.BoxDecoration(color: pdf.PdfColors.grey300),
          ),
        ),
      ],
    ));
    await saveBytesAsFile(
      'vehicle_plate_changes_${DateTime.now().millisecondsSinceEpoch}.pdf',
      Uint8List.fromList(await document.save()),
    );
  }

  Future<void> _save() async {
    if (_selectedVehicle == null || !_formKey.currentState!.validate()) return;
    final newNumber = _numberController.text.trim();
    final newLetters = _lettersController.text.trim();
    final oldIdentity =
        '${_selectedVehicle!.number} - ${_selectedVehicle!.letters ?? ''}';
    final newIdentity = '$newNumber - $newLetters';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('تأكيد تغيير بيانات السيارة'),
        content: Text(
          'هل أنت متأكد من تغيير بيانات السيارة؟\n\n'
          'البيانات الحالية:\n$oldIdentity\n\n'
          'البيانات الجديدة:\n$newIdentity',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('تأكيد التغيير'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    if (token == null) return;
    setState(() => _saving = true);
    try {
      final updated = await ApiService.updateVehiclePlate(
        token,
        _selectedVehicle!.id,
        newNumber,
        newLetters.isEmpty ? null : newLetters,
      );
      if (!mounted) return;
      setState(() {
        _selectedVehicle = updated;
        _searchResults = [updated];
        _error = null;
      });
      _fillVehicle(updated);
      await _loadHistory();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('تم تغيير بيانات السيارة وتسجيل العملية')),
        );
      }
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _field(String label, TextEditingController controller,
      {bool enabled = true,
      String? Function(String?)? validator,
      ValueChanged<String>? onChanged,
      FocusNode? focusNode,
      FocusNode? nextFocus,
      FocusNode? previousFocus,
      VoidCallback? onSubmit}) {
    final field = TextFormField(
        controller: controller,
        enabled: enabled,
        validator: validator,
        focusNode: focusNode,
        onChanged: onChanged,
        onFieldSubmitted: (_) {
          if (nextFocus != null) {
            FocusScope.of(context).requestFocus(nextFocus);
          } else {
            onSubmit?.call();
          }
        },
        decoration: InputDecoration(
            labelText: label, border: const OutlineInputBorder()));
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

  Widget _exportIconButton(
      String tooltip, IconData icon, VoidCallback onPressed, Color color) {
    return IconButton.filled(
      tooltip: tooltip,
      onPressed: onPressed,
      icon: Icon(icon, size: 20),
      style: IconButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        minimumSize: const Size(44, 44),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final history = _filteredChanges;
    return Scaffold(
      appBar: ScaAppBar(
        title: 'تغيير رقم السيارة',
        showBack: true,
        showMenu: false,
        onBack: () => Navigator.pop(context),
      ),
      backgroundColor: ScaColors.background,
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(
                width: 220,
                child: _field(
                  'بحث بالرقم القديم',
                  _oldSearchController,
                  onChanged: (_) => setState(() {}),
                ),
              ),
              SizedBox(
                width: 220,
                child: _field(
                  'بحث بالرقم الجديد',
                  _newSearchController,
                  onChanged: (_) => setState(() {}),
                ),
              ),
              SizedBox(
                width: 220,
                child: _field(
                  'بحث بالسجل',
                  _historySearchController,
                  onChanged: (_) => setState(() {}),
                ),
              ),
              _exportIconButton(
                'تصدير Excel',
                Icons.table_view,
                _exportToExcel,
                Colors.green.shade700,
              ),
              _exportIconButton(
                'تصدير PDF',
                Icons.picture_as_pdf,
                _exportToPdf,
                Colors.red.shade700,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _field('رقم السيارة الحالي', _searchController)),
              const SizedBox(width: 8),
              FilledButton.icon(
                onPressed: _searching ? null : _search,
                icon: const Icon(Icons.search),
                label: const Text('بحث'),
              ),
            ],
          ),
          if (_searchResults.length > 1)
            ..._searchResults.map((vehicle) => ListTile(
                  leading: const Icon(Icons.directions_car),
                  title: Text('${vehicle.number} - ${vehicle.letters ?? ''}'),
                  subtitle: Text('Vehicle ID: ${vehicle.id}'),
                  onTap: () => setState(() {
                    _selectedVehicle = vehicle;
                    _fillVehicle(vehicle);
                  }),
                )),
          if (_selectedVehicle != null) ...[
            const SizedBox(height: 12),
            Form(
              key: _formKey,
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: ScaColors.surface,
                  border: Border.all(color: const Color(0xFFdfeaf5)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Vehicle ID: ${_selectedVehicle!.id}',
                        style: const TextStyle(color: Colors.black54)),
                    const SizedBox(height: 10),
                    Row(children: [
                      Expanded(
                          child: _readOnlyValue(
                              'الرقم الحالي', _selectedVehicle!.number)),
                      const SizedBox(width: 8),
                      Expanded(
                          child: _readOnlyValue('الحروف الحالية',
                              _selectedVehicle!.letters ?? '')),
                    ]),
                    const SizedBox(height: 10),
                    Row(children: [
                      Expanded(
                            child: _field('الرقم الجديد', _numberController,
                              focusNode: _newNumberFocus,
                              nextFocus: _newLettersFocus,
                              validator: (value) =>
                                  value == null || value.trim().isEmpty
                                      ? 'أدخل الرقم الجديد'
                                      : null)),
                      const SizedBox(width: 8),
                      Expanded(
                            child: _field('الحروف الجديدة', _lettersController,
                              focusNode: _newLettersFocus,
                              previousFocus: _newNumberFocus,
                              onSubmit: _save)),
                    ]),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerRight,
                      child: FilledButton.icon(
                        focusNode: _saveChangeFocus,
                        onPressed: _saving ? null : _save,
                        icon: const Icon(Icons.save_outlined),
                        label: const Text('حفظ التغيير'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(_error!, style: const TextStyle(color: Colors.red)),
            ),
          const SizedBox(height: 20),
          const Text('سجل تغييرات أرقام السيارات',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          if (_loadingHistory)
            const Center(child: CircularProgressIndicator())
          else if (history.isEmpty)
            const Center(
                child: Padding(
              padding: EdgeInsets.all(20),
              child: Text('لا توجد تغييرات مسجلة'),
            ))
          else
            Card(
              margin: EdgeInsets.zero,
              clipBehavior: Clip.antiAlias,
              elevation: 1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: BorderSide(color: Colors.grey.shade300),
              ),
              child: LayoutBuilder(
                builder: (context, tableConstraints) => SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minWidth: tableConstraints.maxWidth,
                    ),
                    child: DataTable(
                  headingRowColor: WidgetStatePropertyAll(
                    Theme.of(context).colorScheme.primaryContainer,
                  ),
                  dataRowColor: WidgetStateProperty.resolveWith((states) {
                    if (states.contains(WidgetState.hovered)) {
                      return Theme.of(context)
                          .colorScheme
                          .primary
                          .withValues(alpha: 0.08);
                    }
                    return null;
                  }),
                  border: TableBorder(
                    horizontalInside:
                        BorderSide(color: Colors.grey.shade200),
                  ),
                  dividerThickness: 1,
                  horizontalMargin: 16,
                  columnSpacing: 24,
                  dataRowMinHeight: 52,
                  dataRowMaxHeight: 58,
                  headingTextStyle: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  columns: const [
                    DataColumn(label: Text('م')),
                    DataColumn(label: Text('رقم السجل')),
                    DataColumn(label: Text('الرقم القديم')),
                    DataColumn(label: Text('الحروف القديمة')),
                    DataColumn(label: Text('الرقم الجديد')),
                    DataColumn(label: Text('الحروف الجديدة')),
                    DataColumn(label: Text('تاريخ التغيير')),
                    DataColumn(label: Text('إجراءات')),
                  ],
                      rows: [
                    for (var index = 0; index < history.length; index++)
                      DataRow(
                        color: WidgetStatePropertyAll(
                          index.isEven ? Colors.white : Colors.grey.shade50,
                        ),
                        cells: [
                          DataCell(Text('${index + 1}')),
                          _historyCell(history[index]['registry'] ?? ''),
                          _historyCell(history[index]['old_number']),
                          _historyCell(history[index]['old_letters'] ?? ''),
                          _historyCell(
                            history[index]['new_number'],
                            color: Colors.green.shade50,
                            textColor: Colors.green.shade900,
                          ),
                          _historyCell(
                            history[index]['new_letters'] ?? '',
                            color: Colors.green.shade50,
                            textColor: Colors.green.shade900,
                          ),
                          DataCell(
                            Text(_formatDate(history[index]['changed_at'])),
                          ),
                          DataCell(
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  tooltip: 'تعديل',
                                  icon: const Icon(Icons.edit, size: 20),
                                  color: Theme.of(context).colorScheme.primary,
                                  onPressed: () =>
                                      _editHistoryChange(history[index]),
                                ),
                                IconButton(
                                  tooltip: 'حذف',
                                  icon: const Icon(Icons.delete_outline,
                                      size: 20),
                                  color: Colors.red.shade700,
                                  onPressed: () =>
                                      _deleteHistoryChange(history[index]),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _formatDate(dynamic value) {
    final date = DateTime.tryParse('$value');
    return date == null ? '$value' : _dateFormat.format(date.toLocal());
  }

  DataCell _historyCell(dynamic value,
      {Color? color, Color? textColor}) {
    return DataCell(
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: color == null
            ? null
            : BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(5),
              ),
        child: Text(
          '$value',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
      ),
    );
  }

  Widget _readOnlyValue(String label, String value) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        filled: true,
        fillColor: Colors.grey.shade100,
      ),
      child: Text(value),
    );
  }
}
