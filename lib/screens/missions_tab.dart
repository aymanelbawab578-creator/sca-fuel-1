import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:provider/provider.dart';

import '../models/vehicle.dart';
import '../providers/auth_provider.dart';
import '../helpers/report_pdf_export.dart';
import '../services/api_service.dart';
import '../utils/file_save_helper.dart';
import 'mission_detail.dart';
import 'package:intl/intl.dart';

class MissionsTab extends StatefulWidget {
  final List<Vehicle> vehicles;
  final Future<void> Function()? onBalanceChanged;
  const MissionsTab({super.key, required this.vehicles, this.onBalanceChanged});

  @override
  State<MissionsTab> createState() => _MissionsTabState();
}

class _MissionsTabState extends State<MissionsTab> {
  Map<String, dynamic>? _balances;
  List<Map<String, dynamic>> _missions = [];
  DateTime? _filterStartDate;
  DateTime? _filterEndDate;
  final _vehicleFilterController = TextEditingController();
  bool _loading = false;
  bool _isCardBalancesExpanded = true;
  final _missionsTableFocus = FocusNode();
  int? _selectedMissionIndex;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _loadBalances();
      _loadMissions();
    });
  }

  @override
  void dispose() {
    _missionsTableFocus.dispose();
    _vehicleFilterController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _visibleMissions {
    final vehicleQuery = _vehicleFilterController.text.trim().toLowerCase();
    return _missions.where((mission) {
      final missionDate =
          DateTime.tryParse(mission['created_at']?.toString() ?? '');
      final dateMatches = missionDate == null ||
          ((_filterStartDate == null ||
                  !missionDate.isBefore(_filterStartDate!)) &&
              (_filterEndDate == null ||
                  !missionDate.isAfter(_filterEndDate!)));
      final vehicleNumber =
          mission['vehicle_number']?.toString().toLowerCase() ?? '';
      return dateMatches &&
          (vehicleQuery.isEmpty || vehicleNumber.contains(vehicleQuery));
    }).toList();
  }

  Future<void> _pickFilterDate(bool start) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: (start ? _filterStartDate : _filterEndDate) ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      locale: const Locale('ar'),
    );
    if (picked == null || !mounted) return;
    setState(() {
      if (start) {
        _filterStartDate = picked;
      } else {
        _filterEndDate = picked;
      }
    });
  }

  void _clearMissionFilters() {
    setState(() {
      _filterStartDate = null;
      _filterEndDate = null;
      _vehicleFilterController.clear();
    });
  }

  Future<void> _exportMissionsPdf() async {
    final missions = _visibleMissions;
    if (missions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('لا توجد مأموريات للتصدير حسب الفلتر الحالي')));
      return;
    }
    const headers = [
      'م',
      'تاريخ الإنشاء',
      'رقم السيارة',
      'اللترات المشحونة',
      'نوع الوقود',
      'اسم السائق',
      'الرقم الوظيفي للسائق',
      'الاتجاه',
      'رقم الأمر',
      'تاريخ الأمر',
      'عداد البداية',
      'عداد النهاية',
      'ملاحظات المأمورية',
      'الحالة',
      'تاريخ التفويل',
      'عداد التفويل',
      'لترات التفويل',
      'بيانات الإيصال',
      'ملاحظات التفويل',
    ];
    final rows = <List<dynamic>>[];
    for (var index = 0; index < missions.length; index++) {
      final mission = missions[index];
      final missionValues = [
        index + 1,
        mission['created_at'] ?? '',
        mission['vehicle_number'] ?? '',
        mission['charged_liters'] ?? 0,
        mission['fuel_type'] ?? '',
        mission['driver_name'] ?? '',
        mission['driver_job_number'] ?? '',
        mission['direction'] ?? '',
        mission['order_number'] ?? '',
        mission['order_date'] ?? '',
        mission['start_odometer'] ?? '',
        mission['end_odometer'] ?? '',
        mission['notes'] ?? '',
        mission['status'] ?? '',
      ];
      final expenses = (mission['expenses'] as List? ?? []);
      if (expenses.isEmpty) {
        rows.add(missionValues + ['', '', '', '', '']);
        continue;
      }
      for (var expenseIndex = 0; expenseIndex < expenses.length; expenseIndex++) {
        final expense = Map<String, dynamic>.from(expenses[expenseIndex] as Map);
        rows.add((expenseIndex == 0 ? missionValues : List<dynamic>.filled(14, '')) + [
          expense['date'] ?? '',
          expense['odometer'] ?? '',
          expense['liters'] ?? '',
          expense['receipt_data'] ?? '',
          expense['notes'] ?? '',
        ]);
      }
    }
    try {
      final fontData = await rootBundle.load('assets/fonts/arial.ttf');
      final bytes = await buildReportPdfBytes(
        headers: headers,
        rows: rows.map((row) => row.map((value) => value.toString()).toList()).toList(),
        title: 'تقرير المأموريات والتفويلات',
        fontData: Uint8List.fromList(fontData.buffer.asUint8List()),
        landscape: true,
        columnWidths: {
          3: const pw.FixedColumnWidth(48),
          14: const pw.FixedColumnWidth(70),
          16: const pw.FixedColumnWidth(48),
        },
      );
      await saveBytesAsFile('missions.pdf', bytes);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('تم تنزيل ملف المأموريات بصيغة PDF')));
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('فشل تصدير PDF: $error')));
      }
    }
  }

  Widget _filterDateButton(String label, DateTime? value, bool start) {
    return OutlinedButton.icon(
      onPressed: () => _pickFilterDate(start),
      icon: const Icon(Icons.calendar_today, size: 18),
      label: Text(value == null
          ? label
          : '$label: ${DateFormat('yyyy-MM-dd').format(value)}'),
    );
  }

  Future<void> _showCardTopupDialog() async {
    String selectedFuel = 'سولار';
    final litersController = TextEditingController();
    final messenger = ScaffoldMessenger.of(context);
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('شحن رصيد كارت'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              initialValue: selectedFuel,
              items: ['سولار', 'بنزين 92', 'بنزين 95']
                  .map((f) => DropdownMenuItem(value: f, child: Text(f)))
                  .toList(),
              onChanged: (v) {
                if (v != null) selectedFuel = v;
              },
              decoration: const InputDecoration(
                  labelText: 'نوع الوقود', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: litersController,
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                  labelText: 'الكمية (لتر)', border: OutlineInputBorder()),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('إلغاء')),
          ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('شحن')),
        ],
      ),
    );
    if (result != true) return;
    final liters = double.tryParse(litersController.text) ?? 0.0;
    if (liters <= 0) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('الكمية غير صالحة')));
      return;
    }
    final token = Provider.of<AuthProvider>(context, listen: false).token!;
    try {
      await ApiService.cardTopup(
          token, {'fuel_type': selectedFuel, 'liters': liters});
      await _loadBalances();
      if (widget.onBalanceChanged != null) {
        await widget.onBalanceChanged!();
      }
      if (!mounted) return;
      messenger.showSnackBar(const SnackBar(content: Text('تم الشحن بنجاح')));
    } catch (e) {
      if (!mounted) return;
      messenger
          .showSnackBar(SnackBar(content: Text('فشل الشحن: ${e.toString()}')));
    }
  }

  Future<void> _showCardDeductDialog() async {
    String selectedFuel = 'سولار';
    final litersController = TextEditingController();
    final messenger = ScaffoldMessenger.of(context);
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('خصم من رصيد كارت'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              initialValue: selectedFuel,
              items: ['سولار', 'بنزين 92', 'بنزين 95']
                  .map((f) => DropdownMenuItem(value: f, child: Text(f)))
                  .toList(),
              onChanged: (v) {
                if (v != null) selectedFuel = v;
              },
              decoration: const InputDecoration(
                  labelText: 'نوع الوقود', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: litersController,
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                  labelText: 'الكمية (لتر)', border: OutlineInputBorder()),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('إلغاء')),
          ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('خصم')),
        ],
      ),
    );
    if (result != true) return;
    final liters = double.tryParse(litersController.text) ?? 0.0;
    if (liters <= 0) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('الكمية غير صالحة')));
      return;
    }
    final token = Provider.of<AuthProvider>(context, listen: false).token!;
    try {
      await ApiService.cardDeduct(
          token, {'fuel_type': selectedFuel, 'liters': liters});
      await _loadBalances();
      if (widget.onBalanceChanged != null) {
        await widget.onBalanceChanged!();
      }
      if (!mounted) return;
      messenger.showSnackBar(
          const SnackBar(content: Text('تم إرجاع الرصيد للمخزن بنجاح')));
    } catch (e) {
      if (!mounted) return;
      messenger
          .showSnackBar(SnackBar(content: Text('فشل الخصم: ${e.toString()}')));
    }
  }

  Future<void> _loadMissions() async {
    if (!mounted) return;
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    if (token == null) return;
    try {
      final res = await ApiService.listMissions(token);
      if (!mounted) return;
      setState(() {
        _missions = res;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ عند جلب المأموريّات: ${e.toString()}')));
    }
  }

  Future<void> _loadBalances() async {
    if (!mounted) return;
    setState(() => _loading = true);
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    if (token == null) {
      if (!mounted) return;
      setState(() => _loading = false);
      return;
    }
    try {
      final res = await ApiService.fetchStoreBalances(token);
      if (!mounted) return;
      setState(() {
        _balances = res;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ عند جلب الأرصدة: ${e.toString()}')));
    }
  }

  Widget _buildCardBalanceIndicator(String fuelType, dynamic value) {
    final amount = value is num ? value.toDouble() : 0.0;
    final displayValue =
        amount % 1 == 0 ? amount.toStringAsFixed(0) : amount.toStringAsFixed(1);
    Color iconColor = Colors.blue;
    if (fuelType.contains('سولار')) {
      iconColor = const Color(0xFF1E88E5);
    } else if (fuelType.contains('بنزين 92')) {
      iconColor = const Color(0xFFEF6C00);
    } else if (fuelType.contains('بنزين 95')) {
      iconColor = const Color(0xFF2E7D32);
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10)),
              child: Icon(Icons.water_drop, color: iconColor, size: 22),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(fuelType.replaceAll('رصيد ', ''),
                      style: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text('$displayValue لتر',
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _loading
                  ? const Center(child: CircularProgressIndicator())
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        LayoutBuilder(
                          builder: (context, actionConstraints) {
                            final showSingleRow =
                                actionConstraints.maxWidth > 700;

                            final buttons = <Widget>[
                              ElevatedButton.icon(
                                onPressed: _showCreateMissionDialog,
                                icon: const Icon(Icons.add),
                                label: const Text('إضافة مأمورية'),
                                style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 14, horizontal: 10)),
                              ),
                              ElevatedButton.icon(
                                onPressed: _showCardTopupDialog,
                                icon: const Icon(Icons.credit_card),
                                label: const Text('شحن رصيد'),
                                style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 14, horizontal: 10)),
                              ),
                              ElevatedButton.icon(
                                onPressed: _showCardDeductDialog,
                                icon: const Icon(Icons.undo),
                                label: const Text('خصم رصيد'),
                                style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 14, horizontal: 10)),
                              ),
                            ];

                            return showSingleRow
                                ? Row(
                                    children: [
                                      for (var index = 0;
                                          index < buttons.length;
                                          index++) ...[
                                        if (index > 0)
                                          const SizedBox(width: 8),
                                        Expanded(child: buttons[index]),
                                      ],
                                    ],
                                  )
                                : Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: buttons.map((button) {
                                      return SizedBox(
                                        width:
                                            (actionConstraints.maxWidth - 16) /
                                                2,
                                        child: button,
                                      );
                                    }).toList(),
                                  );
                          },
                        ),
                        const SizedBox(height: 8),
                        if (_balances != null)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: Colors.grey.shade300),
                              boxShadow: [
                                BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.03),
                                    blurRadius: 10,
                                    offset: const Offset(0, 3))
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Row(
                                  children: [
                                    const Text('رصيد الكروت',
                                        style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold)),
                                    const Spacer(),
                                    GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          _isCardBalancesExpanded =
                                              !_isCardBalancesExpanded;
                                        });
                                      },
                                      child: Icon(
                                        _isCardBalancesExpanded
                                            ? Icons.keyboard_arrow_up
                                            : Icons.keyboard_arrow_down,
                                        size: 22,
                                        color: Colors.grey.shade700,
                                      ),
                                    ),
                                  ],
                                ),
                                if (_isCardBalancesExpanded) ...[
                                  const SizedBox(height: 10),
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                          child: _buildCardBalanceIndicator(
                                              'سولار',
                                              _balances?['display']?['cards']
                                                      ?['solar'] ??
                                                  _balances?['cards']
                                                      ?['solar'])),
                                      const SizedBox(width: 10),
                                      Expanded(
                                          child: _buildCardBalanceIndicator(
                                              'بنزين 92',
                                              _balances?['display']?['cards']
                                                      ?['gasoline_92'] ??
                                                  _balances?['cards']
                                                      ?['gasoline_92'])),
                                      const SizedBox(width: 10),
                                      Expanded(
                                          child: _buildCardBalanceIndicator(
                                              'بنزين 95',
                                              _balances?['display']?['cards']
                                                      ?['gasoline_95'] ??
                                                  _balances?['cards']
                                                      ?['gasoline_95'])),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                      ],
                    ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                  _filterDateButton('من تاريخ', _filterStartDate, true),
                  _filterDateButton('إلى تاريخ', _filterEndDate, false),
                  SizedBox(
                    width: 180,
                    child: TextField(
                      controller: _vehicleFilterController,
                      onChanged: (_) => setState(() {}),
                      decoration: const InputDecoration(
                        labelText: 'رقم السيارة',
                        prefixIcon: Icon(Icons.directions_car),
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ),
                  IconButton.filledTonal(
                    tooltip: 'مسح الفلاتر',
                    onPressed: _clearMissionFilters,
                    icon: const Icon(Icons.cleaning_services),
                  ),
                  IconButton.filledTonal(
                    tooltip: 'تصدير Excel',
                    onPressed: () async {
                    final token =
                        Provider.of<AuthProvider>(context, listen: false)
                            .token!;
                    try {
                      final bytes = await ApiService.exportMissions(
                        token,
                        startDate: _filterStartDate,
                        endDate: _filterEndDate,
                        vehicleNumber: _vehicleFilterController.text.trim(),
                      );
                      await saveBytesAsFile('missions.xlsx', bytes);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          content: Text('تم تنزيل ملف المأموريّات')));
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text('فشل التصدير: ${e.toString()}')));
                    }
                    },
                    style: IconButton.styleFrom(
                      foregroundColor: Colors.green.shade700,
                    ),
                    icon: const Icon(Icons.table_view),
                  ),
                  IconButton.filledTonal(
                    tooltip: 'تصدير PDF',
                    onPressed: _exportMissionsPdf,
                    style: IconButton.styleFrom(
                      foregroundColor: Colors.red.shade700,
                    ),
                    icon: const Icon(Icons.picture_as_pdf_outlined),
                  ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: _visibleMissions.isEmpty
                    ? const Center(child: Text('لا توجد مأموريّات'))
                    : RefreshIndicator(
                        onRefresh: _loadMissions,
                        child: LayoutBuilder(
                          builder: (context, tableConstraints) {
                            final minTableWidth = tableConstraints.maxWidth > 700
                              ? tableConstraints.maxWidth
                              : 700.0;

                            return SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                                child: Focus(
                                  focusNode: _missionsTableFocus,
                                  autofocus: true,
                                  onKeyEvent: (node, event) {
                                    if (event is! KeyDownEvent ||
                                        _visibleMissions.isEmpty) {
                                      return KeyEventResult.ignored;
                                    }
                                    if (event.logicalKey ==
                                        LogicalKeyboardKey.arrowDown) {
                                      setState(() => _selectedMissionIndex =
                                          ((_selectedMissionIndex ?? -1) + 1)
                                              .clamp(0, _visibleMissions.length - 1));
                                      return KeyEventResult.handled;
                                    }
                                    if (event.logicalKey ==
                                        LogicalKeyboardKey.arrowUp) {
                                      setState(() => _selectedMissionIndex =
                                            ((_selectedMissionIndex ?? _visibleMissions.length) - 1)
                                              .clamp(0, _visibleMissions.length - 1));
                                      return KeyEventResult.handled;
                                    }
                                    if (event.logicalKey ==
                                            LogicalKeyboardKey.enter &&
                                        _selectedMissionIndex != null) {
                                      Navigator.of(context).push(
                                          MaterialPageRoute(
                                              builder: (_) =>
                                                  MissionDetailScreen(
                                                      missionId: _visibleMissions[
                                                          _selectedMissionIndex!]['id'])));
                                      return KeyEventResult.handled;
                                    }
                                    return KeyEventResult.ignored;
                                  },
                                  child: SizedBox(
                                width: minTableWidth,
                                child: SingleChildScrollView(
                                  child: DataTable(
                                    headingRowColor: WidgetStatePropertyAll(
                                        Theme.of(context)
                                            .colorScheme
                                            .primaryContainer),
                                    dataRowColor:
                                        WidgetStateProperty.resolveWith(
                                            (states) {
                                      if (states.contains(WidgetState.hovered)) {
                                        return Theme.of(context)
                                            .colorScheme
                                            .primary
                                            .withValues(alpha: 0.08);
                                      }
                                      return null;
                                    }),
                                    border: TableBorder.all(
                                        color: Colors.grey.shade300),
                                    dividerThickness: 1,
                                    horizontalMargin: 16,
                                    columnSpacing: 24,
                                    dataRowMinHeight: 32,
                                    dataRowMaxHeight: 40,
                                    headingTextStyle: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87),
                                    columns: const [
                                      DataColumn(label: Text('م.')),
                                      DataColumn(label: Text('التاريخ')),
                                      DataColumn(label: Text('رقم السيارة')),
                                      DataColumn(label: Text('الوجهة')),
                                      DataColumn(label: Text('كمية الشحن')),
                                      DataColumn(label: Text('الحالة')),
                                      DataColumn(label: Text('تعديل')),
                                      DataColumn(label: Text('حذف')),
                                    ],
                                    rows:
                                        _visibleMissions.asMap().entries.map((entry) {
                                      final idx = entry.key;
                                      final m = entry.value;
                                      final created = m['created_at'] ?? '';
                                      final createdDate = created.isNotEmpty
                                          ? DateTime.tryParse(created)
                                          : null;
                                      final status =
                                          m['status']?.toString() ?? 'open';
                                      final statusText = status == 'completed'
                                          ? 'مكتملة'
                                          : 'مفتوحة';
                                      final statusColor = status == 'completed'
                                          ? Colors.green
                                          : Colors.orange;
                                      final totalExpenseLiters =
                                          (m['expenses'] as List? ?? [])
                                              .fold<double>(0.0,
                                                  (sum, expense) {
                                        final liters = expense is Map
                                            ? (expense['liters'] ?? 0.0)
                                            : 0.0;
                                        return sum +
                                            (liters is num
                                                ? liters.toDouble()
                                                : 0.0);
                                      });
                                      return DataRow(
                                        selected: _selectedMissionIndex == idx,
                                        onSelectChanged: (selected) => setState(() {
                                          _selectedMissionIndex =
                                              selected == true ? idx : null;
                                        }),
                                        cells: [
                                        DataCell(Text((idx + 1).toString())),
                                        DataCell(Text(createdDate != null
                                            ? DateFormat('yyyy-MM-dd')
                                                .format(createdDate)
                                            : '')),
                                        DataCell(Text(
                                            m['vehicle_number']?.toString() ??
                                                '')),
                                        DataCell(Text(
                                            m['direction']?.toString() ?? '')),
                                        DataCell(Text(totalExpenseLiters
                                            .toStringAsFixed(2))),
                                        DataCell(Chip(
                                          label: Text(statusText,
                                              style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 12)),
                                          backgroundColor: statusColor,
                                        )),
                                        DataCell(IconButton(
                                          tooltip: 'تعديل المأمورية',
                                          icon:
                                              const Icon(Icons.edit, size: 20),
                                          onPressed: () async {
                                            Navigator.of(context)
                                                .push(MaterialPageRoute(
                                                    builder: (_) =>
                                                        MissionDetailScreen(
                                                            missionId:
                                                                m['id'])))
                                                .then((_) async {
                                              await _loadMissions();
                                              if (!mounted) return;
                                              await _loadBalances();
                                            });
                                          },
                                        )),
                                        DataCell(IconButton(
                                          tooltip: 'حذف المأمورية',
                                          icon: const Icon(Icons.delete_outline,
                                              size: 20),
                                          onPressed: () async {
                                            final navigator =
                                                Navigator.of(context);
                                            final messenger =
                                                ScaffoldMessenger.of(context);
                                            final should =
                                                await showDialog<bool>(
                                              context: context,
                                              builder: (ctx) => AlertDialog(
                                                title:
                                                    const Text('حذف المأمورية'),
                                                content: const Text(
                                                    'هل أنت متأكد من حذف هذه المأمورية؟ سيتم حذفها من الواجهة.'),
                                                actions: [
                                                  TextButton(
                                                      onPressed: () =>
                                                          Navigator.of(ctx)
                                                              .pop(false),
                                                      child:
                                                          const Text('إلغاء')),
                                                  ElevatedButton(
                                                      onPressed: () =>
                                                          Navigator.of(ctx)
                                                              .pop(true),
                                                      child: const Text('حذف')),
                                                ],
                                              ),
                                            );
                                            if (should != true) return;
                                            final token =
                                                Provider.of<AuthProvider>(
                                                        context,
                                                        listen: false)
                                                    .token!;
                                            try {
                                              await ApiService.deleteMission(
                                                  token, m['id']);
                                              if (!mounted) return;
                                              await _loadMissions();
                                              if (!mounted) return;
                                              await _loadBalances();
                                              if (!mounted) return;
                                              messenger.showSnackBar(const SnackBar(
                                                  content: Text(
                                                      'تم حذف المأمورية وتحديث الأرصدة')));
                                            } catch (e) {
                                              if (!mounted) return;
                                              messenger.showSnackBar(SnackBar(
                                                  content: Text(
                                                      'فشل الحذف: ${e.toString()}')));
                                            }
                                          },
                                        )),
                                      ]);
                                    }).toList(),
                                  ),
                                  ),
                              ),
                              ),
                            );
                          },
                        ),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showCreateMissionDialog() async {
    final dateController = TextEditingController(
        text: DateFormat('yyyy-MM-dd').format(DateTime.now()));
    final directionController = TextEditingController();
    final vehicleNumberController = TextEditingController();

    Future<void> openMissionForVehicle(Vehicle vehicle) async {
      final token = Provider.of<AuthProvider>(context, listen: false).token!;
      if (token.isEmpty) return;
      final fullVehicleNumber =
          '${vehicle.number} ${vehicle.letters ?? ''}'.trim();
      final payload = {
        'vehicle_id': vehicle.id,
        'vehicle_number': fullVehicleNumber,
        'charged_liters': 0.0,
        'fuel_type': vehicle.fuelType,
        'status': 'open',
        'direction': directionController.text,
        'created_at': dateController.text,
      };

      try {
        final createdMission = await ApiService.createMission(token, payload);
        if (!mounted) return;
        Navigator.of(context).pop();
        await _loadMissions();
        if (!mounted) return;
        Navigator.of(context)
            .push(MaterialPageRoute(
                builder: (_) =>
                    MissionDetailScreen(missionId: createdMission['id'])))
            .then((_) async {
          await _loadMissions();
          await _loadBalances();
        });
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('فشل إنشاء المأمورية: ${e.toString()}')));
      }
    }

    final dateFocus = FocusNode();
    final directionFocus = FocusNode();
    final vehicleFocus = FocusNode();

    void submitVehicle() {
      final token = Provider.of<AuthProvider>(context, listen: false).token!;
      if (token.isEmpty) return;
      final vehicleNumber = vehicleNumberController.text.trim();
      if (vehicleNumber.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('يرجى إدخال رقم السيارة')));
        return;
      }

      final matches = widget.vehicles.where((vehicle) {
        final fullNumber =
            '${vehicle.number} ${vehicle.letters ?? ''}'.trim().toLowerCase();
        final digitsText = vehicle.number.toLowerCase();
        final queryText = vehicleNumber.toLowerCase();
        return fullNumber == queryText ||
            digitsText == queryText ||
            fullNumber.contains(queryText) ||
            digitsText.contains(queryText);
      }).toList();

      if (matches.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('لم يتم العثور على سيارة بهذا الرقم')));
        return;
      }
      if (matches.length == 1) {
        openMissionForVehicle(matches.first);
        return;
      }

      showDialog<void>(
        context: context,
        builder: (choiceContext) {
          var selectedIndex = 0;
          return StatefulBuilder(
            builder: (context, setDialogState) => Focus(
              autofocus: true,
              onKeyEvent: (node, event) {
                if (event is! KeyDownEvent) return KeyEventResult.ignored;
                if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
                  setDialogState(() => selectedIndex =
                      (selectedIndex + 1).clamp(0, matches.length - 1));
                  return KeyEventResult.handled;
                }
                if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
                  setDialogState(() => selectedIndex =
                      (selectedIndex - 1).clamp(0, matches.length - 1));
                  return KeyEventResult.handled;
                }
                if (event.logicalKey == LogicalKeyboardKey.enter) {
                  final vehicle = matches[selectedIndex];
                  Navigator.of(choiceContext).pop();
                  openMissionForVehicle(vehicle);
                  return KeyEventResult.handled;
                }
                return KeyEventResult.ignored;
              },
              child: AlertDialog(
                title: const Text('اختر السيارة الصحيحة'),
                content: SizedBox(
                  width: double.maxFinite,
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: matches.length,
                    itemBuilder: (_, index) {
                      final vehicle = matches[index];
                      final fullNumber =
                          '${vehicle.number} ${vehicle.letters ?? ''}'.trim();
                      return ListTile(
                        selected: selectedIndex == index,
                        title: Text(fullNumber),
                        subtitle: Text(
                            'نوع الوقود: ${vehicle.fuelType} • السجل: ${vehicle.registry ?? '-'}'),
                        onTap: () async {
                          Navigator.of(choiceContext).pop();
                          await openMissionForVehicle(vehicle);
                        },
                      );
                    },
                  ),
                ),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.of(choiceContext).pop(),
                      child: const Text('إلغاء')),
                ],
              ),
            ),
          );
        },
      );
    }

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('إضافة مأمورية جديدة'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Focus(
                onKeyEvent: (node, event) {
                  if (event is! KeyDownEvent) return KeyEventResult.ignored;
                  final key = event.logicalKey;
                  if (key == LogicalKeyboardKey.arrowDown ||
                      key == LogicalKeyboardKey.arrowRight) {
                    FocusScope.of(ctx).requestFocus(directionFocus);
                    return KeyEventResult.handled;
                  }
                  if (key == LogicalKeyboardKey.arrowUp ||
                      key == LogicalKeyboardKey.arrowLeft) {
                    return KeyEventResult.ignored;
                  }
                  if (key == LogicalKeyboardKey.enter ||
                      key == LogicalKeyboardKey.numpadEnter) {
                    FocusScope.of(ctx).requestFocus(directionFocus);
                    return KeyEventResult.handled;
                  }
                  return KeyEventResult.ignored;
                },
                child: TextField(
                  controller: dateController,
                  focusNode: dateFocus,
                  autofocus: false,
                  readOnly: true,
                  textInputAction: TextInputAction.next,
                  onSubmitted: (_) =>
                      FocusScope.of(ctx).requestFocus(directionFocus),
                  decoration: const InputDecoration(
                    labelText: 'التاريخ',
                    isDense: true,
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: ctx,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) {
                      dateController.text =
                          DateFormat('yyyy-MM-dd').format(picked);
                    }
                  },
                ),
              ),
              const SizedBox(height: 8),
              Focus(
                onKeyEvent: (node, event) {
                  if (event is! KeyDownEvent) return KeyEventResult.ignored;
                  final key = event.logicalKey;
                  if (key == LogicalKeyboardKey.arrowDown ||
                      key == LogicalKeyboardKey.arrowRight) {
                    FocusScope.of(ctx).requestFocus(dateFocus);
                    return KeyEventResult.handled;
                  }
                  if (key == LogicalKeyboardKey.arrowUp ||
                      key == LogicalKeyboardKey.arrowLeft) {
                    FocusScope.of(ctx).requestFocus(dateFocus);
                    return KeyEventResult.handled;
                  }
                  if (key == LogicalKeyboardKey.enter ||
                      key == LogicalKeyboardKey.numpadEnter) {
                    FocusScope.of(ctx).requestFocus(vehicleFocus);
                    return KeyEventResult.handled;
                  }
                  return KeyEventResult.ignored;
                },
                child: TextField(
                  controller: directionController,
                  focusNode: directionFocus,
                  textInputAction: TextInputAction.next,
                  onSubmitted: (_) =>
                      FocusScope.of(ctx).requestFocus(vehicleFocus),
                  decoration: const InputDecoration(
                    labelText: 'اتجاه المأمورية',
                    isDense: true,
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Focus(
                      onKeyEvent: (node, event) {
                        if (event is! KeyDownEvent)
                          return KeyEventResult.ignored;
                        final key = event.logicalKey;
                        if (key == LogicalKeyboardKey.arrowUp ||
                            key == LogicalKeyboardKey.arrowLeft) {
                          FocusScope.of(ctx).requestFocus(directionFocus);
                          return KeyEventResult.handled;
                        }
                        if (key == LogicalKeyboardKey.enter ||
                            key == LogicalKeyboardKey.numpadEnter) {
                          submitVehicle();
                          return KeyEventResult.handled;
                        }
                        return KeyEventResult.ignored;
                      },
                      child: TextField(
                        controller: vehicleNumberController,
                        focusNode: vehicleFocus,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => submitVehicle(),
                        decoration: const InputDecoration(
                          labelText: 'رقم السيارة',
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    tooltip: 'فتح النموذج الكامل',
                    onPressed: () async {
                      final token =
                          Provider.of<AuthProvider>(context, listen: false)
                              .token!;
                      if (token.isEmpty) return;
                      final vehicleNumber = vehicleNumberController.text.trim();
                      if (vehicleNumber.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('يرجى إدخال رقم السيارة')));
                        return;
                      }

                      try {
                        final vehicles = await ApiService.listVehicles(token,
                            query: vehicleNumber);
                        final matches = vehicles.where((vehicle) {
                          final fullText =
                              '${vehicle.number} ${vehicle.letters ?? ''}'
                                  .trim()
                                  .toLowerCase();
                          final digitsText = vehicle.number.toLowerCase();
                          final queryText = vehicleNumber.toLowerCase();
                          return fullText == queryText ||
                              digitsText == queryText ||
                              fullText.contains(queryText) ||
                              digitsText.contains(queryText);
                        }).toList();

                        if (matches.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text(
                                      'لم يتم العثور على سيارة بهذا الرقم')));
                          return;
                        }

                        if (matches.length == 1) {
                          await openMissionForVehicle(matches.first);
                          return;
                        }

                        await showDialog<void>(
                          context: context,
                          builder: (choiceContext) => AlertDialog(
                            title: const Text('اختر السيارة الصحيحة'),
                            content: SizedBox(
                              width: double.maxFinite,
                              child: ListView.builder(
                                shrinkWrap: true,
                                itemCount: matches.length,
                                itemBuilder: (_, index) {
                                  final vehicle = matches[index];
                                  final fullNumber =
                                      '${vehicle.number} ${vehicle.letters ?? ''}'
                                          .trim();
                                  return ListTile(
                                    title: Text(fullNumber),
                                    subtitle: Text(
                                        'نوع الوقود: ${vehicle.fuelType} • السجل: ${vehicle.registry ?? '-'}'),
                                    onTap: () async {
                                      Navigator.of(choiceContext).pop();
                                      await openMissionForVehicle(vehicle);
                                    },
                                  );
                                },
                              ),
                            ),
                            actions: [
                              TextButton(
                                  onPressed: () =>
                                      Navigator.of(choiceContext).pop(),
                                  child: const Text('إلغاء')),
                            ],
                          ),
                        );
                      } catch (e) {
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content:
                                Text('فشل إنشاء المأمورية: ${e.toString()}')));
                      }
                    },
                    icon: const Icon(Icons.open_in_full),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('إلغاء')),
        ],
      ),
    );

    dateController.dispose();
    directionController.dispose();
    vehicleNumberController.dispose();

    dateFocus.dispose();
    directionFocus.dispose();
    vehicleFocus.dispose();

    if (result == true) {
      await _loadMissions();
    }
  }
}
