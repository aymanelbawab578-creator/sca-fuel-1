import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' hide Border;
import 'package:flutter/material.dart' as material;
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:excel/excel.dart';
import 'package:pdf/pdf.dart' as pdf;
import 'package:pdf/widgets.dart' as pw;

import '../utils/file_save_helper.dart';
import '../providers/auth_provider.dart';
import '../helpers/reports_calculations.dart';
import '../helpers/report_pdf_export.dart';
import '../models/refuel.dart';
import '../models/vehicle.dart';
import '../services/api_service.dart';
import '../utils/stations.dart';
import '../widgets/sca_keyboard_dialog.dart';
import '../widgets/sca_layout.dart';
import 'dashboard_screen.dart';
import 'vehicle_search_screen.dart';
import 'vehicle_data_screen.dart';
import 'archive_screen.dart';
import 'store_screen.dart';
import 'login_screen.dart';
import 'settings_screen.dart';
import 'gas_screen.dart';
import 'card_delivery_tab.dart';

class QuantityReportResult {
  final List<QuantityReportRecord> records;
  QuantityReportResult({required this.records});

  int get totalRefuels =>
      records.fold(0, (sum, item) => sum + item.details.length);
  double get totalLiters =>
      records.fold(0.0, (sum, item) => sum + item.totalLiters);
}

class QuantityReportRecord {
  final int vehicleId;
  final String vehicleNumber;
  final String? vehicleLetters;
  final List<QuantityDetail> details;

  QuantityReportRecord({
    required this.vehicleId,
    required this.vehicleNumber,
    this.vehicleLetters,
    required this.details,
  });

  double get totalLiters => details.fold(0.0, (sum, item) => sum + item.liters);
}

class QuantityDetail {
  final double liters;
  final DateTime date;
  QuantityDetail({required this.liters, required this.date});

  String get formattedLiters => liters.toStringAsFixed(1);
  String get formattedDate => DateFormat('dd/MM/yyyy').format(date);
}

List<Map<String, dynamic>> filterInvoicesByDateRange(
    List<Map<String, dynamic>> invoices,
    DateTime? startDate,
    DateTime? endDate) {
  if (startDate == null || endDate == null) return invoices;

  final normalizedStart =
      DateTime(startDate.year, startDate.month, startDate.day);
  final normalizedEnd = DateTime(endDate.year, endDate.month, endDate.day);

  return invoices.where((invoice) {
    final startValue = invoice['start_date']?.toString();
    final endValue = invoice['end_date']?.toString();
    if (startValue == null ||
        startValue.isEmpty ||
        endValue == null ||
        endValue.isEmpty) {
      return false;
    }

    final invoiceStart = DateTime.tryParse(startValue);
    final invoiceEnd = DateTime.tryParse(endValue);
    if (invoiceStart == null || invoiceEnd == null) {
      return false;
    }

    final normalizedInvoiceStart =
        DateTime(invoiceStart.year, invoiceStart.month, invoiceStart.day);
    final normalizedInvoiceEnd =
        DateTime(invoiceEnd.year, invoiceEnd.month, invoiceEnd.day);

    return !normalizedInvoiceStart.isBefore(normalizedStart) &&
        !normalizedInvoiceEnd.isAfter(normalizedEnd);
  }).toList();
}

class ReportsScreen extends StatefulWidget {
  final int initialTab;

  const ReportsScreen({super.key, this.initialTab = 0});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Vehicle> _vehicles = [];
  List<Refuel> _allRefuels = [];
  bool _isLoading = false;
  String? _error;
  late AuthProvider _authProvider;
  final TextEditingController _globalVehicleController =
      TextEditingController();
  String? _globalFuelType;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 6,
      vsync: this,
      initialIndex: widget.initialTab.clamp(0, 5).toInt(),
    )
      ..addListener(() {
        if (mounted) setState(() {});
      });
    _loadInitialData();
  }

  @override
  void dispose() {
    _globalVehicleController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    _authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      String? token = _authProvider.token;
      int waitAttempts = 0;
      while (token == null && waitAttempts < 6) {
        await Future.delayed(const Duration(milliseconds: 250));
        token = _authProvider.token;
        waitAttempts++;
      }
      if (token == null) {
        throw Exception('لم يتم العثور على رمز المصادقة. يرجى تسجيل الدخول مرة أخرى.');
      }

      final vehicles =
          await ApiService.listVehicles(token, limit: 200);
      if (!mounted) return;
      setState(() {
        _vehicles = vehicles;
        _allRefuels = [];
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'خطأ في تحميل البيانات: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  void _goToDashboard() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const DashboardScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:
          ScaAppBar(title: 'التقارير', showBack: true, onBack: _goToDashboard),
      drawer: ScaDrawer(
        currentRoute: 'reports',
        onDashboard: _goToDashboard,
        onVehicleSearch: () {
          Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const VehicleSearchScreen()));
        },
        onStore: () {
          Navigator.of(context)
              .push(MaterialPageRoute(builder: (_) => const StoreScreen()));
        },
        onStoreTab: (index) {
          Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => StoreScreen(initialTab: index)));
        },
        onVehicleData: () {
          Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const VehicleDataScreen()));
        },
        onReports: () {},
        onReportTab: (index) => _tabController.animateTo(index),
        onGasTab: (index) {
          Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => GasScreen(initialTab: index)));
        },
        onArchive: () {
          Navigator.of(context)
              .push(MaterialPageRoute(builder: (_) => const ArchiveScreen()));
        },
        onSettings: () {
          Navigator.of(context)
              .push(MaterialPageRoute(builder: (_) => const SettingsScreen()));
        },
        onLogout: () async {
          final authProvider =
              Provider.of<AuthProvider>(context, listen: false);
          await authProvider.logout();
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const LoginScreen()),
            (route) => false,
          );
        },
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_error!, textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadInitialData,
                        child: const Text('إعادة محاولة'),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    if (_tabController.index != 3 && _tabController.index != 4 && _tabController.index != 5)
                      Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final isNarrow = constraints.maxWidth < 720;
                            return isNarrow
                                ? Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      TextField(
                                        controller: _globalVehicleController,
                                        decoration: const InputDecoration(
                                          labelText:
                                              'بحث برقم السيارة أو السجل (اختياري)',
                                          border: OutlineInputBorder(),
                                          prefixIcon: Icon(Icons.search),
                                        ),
                                        onChanged: (v) => setState(() {}),
                                      ),
                                      const SizedBox(height: 12),
                                      DropdownButtonFormField<String?>(
                                        value: _globalFuelType,
                                        decoration: const InputDecoration(
                                            labelText: 'نوع الوقود (اختياري)',
                                            border: OutlineInputBorder()),
                                        items: const [
                                          DropdownMenuItem(
                                              value: null,
                                              child: Text('كل أنواع الوقود')),
                                          DropdownMenuItem(
                                              value: 'بنزين 92',
                                              child: Text('بنزين 92')),
                                          DropdownMenuItem(
                                              value: 'بنزين 95',
                                              child: Text('بنزين 95')),
                                          DropdownMenuItem(
                                              value: 'سولار',
                                              child: Text('سولار')),
                                        ],
                                        onChanged: (v) =>
                                            setState(() => _globalFuelType = v),
                                      ),
                                    ],
                                  )
                                : Row(
                                    children: [
                                      Expanded(
                                        child: TextField(
                                          controller: _globalVehicleController,
                                          decoration: const InputDecoration(
                                            labelText:
                                                'بحث برقم السيارة أو السجل (اختياري)',
                                            border: OutlineInputBorder(),
                                            prefixIcon: Icon(Icons.search),
                                          ),
                                          onChanged: (v) => setState(() {}),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      SizedBox(
                                        width: 220,
                                        child: DropdownButtonFormField<String?>(
                                          value: _globalFuelType,
                                          decoration: const InputDecoration(
                                              labelText: 'نوع الوقود (اختياري)',
                                              border: OutlineInputBorder()),
                                          items: const [
                                            DropdownMenuItem(
                                                value: null,
                                                child: Text('كل أنواع الوقود')),
                                            DropdownMenuItem(
                                                value: 'بنزين 92',
                                                child: Text('بنزين 92')),
                                            DropdownMenuItem(
                                                value: 'بنزين 95',
                                                child: Text('بنزين 95')),
                                            DropdownMenuItem(
                                                value: 'سولار',
                                                child: Text('سولار')),
                                          ],
                                          onChanged: (v) => setState(
                                              () => _globalFuelType = v),
                                        ),
                                      ),
                                    ],
                                  );
                          },
                        ),
                      ),
                    ScaKeyboardTabBar(
                      controller: _tabController,
                      tabs: const [
                        Tab(text: 'التقرير اليومي'),
                        Tab(text: 'تقرير النسبة'),
                        Tab(text: 'تقرير الفترة'),
                        Tab(text: 'تقرير كميات الوقود'),
                        Tab(text: 'حاسبة الفواتير'),
                        Tab(text: 'تسليم كارت'),
                      ],
                    ),
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        physics: (defaultTargetPlatform == TargetPlatform.android ||
                                defaultTargetPlatform == TargetPlatform.iOS)
                            ? const NeverScrollableScrollPhysics()
                            : null,
                        children: [
                          DailyReportTab(
                            vehicles: _vehicles,
                            allRefuels: _allRefuels,
                            vehicleQuery: _globalVehicleController.text.isEmpty
                                ? null
                                : _globalVehicleController.text.trim(),
                            globalFuelType: _globalFuelType,
                          ),
                          QuantityReportTab(
                            vehicles: _vehicles,
                            allRefuels: _allRefuels,
                            vehicleQuery: _globalVehicleController.text.isEmpty
                                ? null
                                : _globalVehicleController.text.trim(),
                            globalFuelType: _globalFuelType,
                          ),
                          PeriodReportTab(
                            vehicles: _vehicles,
                            allRefuels: _allRefuels,
                            vehicleQuery: _globalVehicleController.text.isEmpty
                                ? null
                                : _globalVehicleController.text.trim(),
                            globalFuelType: _globalFuelType,
                          ),
                          FuelStationQuantityReportTab(
                            vehicles: _vehicles,
                            allRefuels: _allRefuels,
                            vehicleQuery: _globalVehicleController.text.isEmpty
                                ? null
                                : _globalVehicleController.text.trim(),
                            globalFuelType: _globalFuelType,
                          ),
                          const InvoiceCalculatorTab(),
                          const CardDeliveryTab(),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }
}

class DailyReportTab extends StatefulWidget {
  final List<Vehicle> vehicles;
  final List<Refuel> allRefuels;
  final String? vehicleQuery;
  final String? globalFuelType;

  const DailyReportTab({
    required this.vehicles,
    required this.allRefuels,
    this.vehicleQuery,
    this.globalFuelType,
    super.key,
  });

  @override
  State<DailyReportTab> createState() => _DailyReportTabState();
}

class _DailyReportTabState extends State<DailyReportTab> {
  DateTime? _selectedDate;
  Map<String, dynamic>? _apiResult;
  bool _isLoading = false;
  String? _selectedStation;
  int? _selectedRefuelId;
  final FocusNode _dailyReportTableFocusNode =
      FocusNode(debugLabel: 'daily-report-table');
  int? _highlightedRowIndex;

  Widget _buildStickyHeaderCell(String label,
      {required double width, bool isNumeric = false}) {
    return SizedBox(
      width: width,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        child: Align(
          alignment: isNumeric ? Alignment.center : Alignment.centerRight,
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            textAlign: isNumeric ? TextAlign.center : TextAlign.start,
            overflow: TextOverflow.ellipsis,
            maxLines: 2,
          ),
        ),
      ),
    );
  }

  Widget _buildTableCell(String value,
      {required double width, bool isNumeric = false, Widget? child}) {
    final theme = Theme.of(context);
    final baseTextStyle = theme.textTheme.bodyMedium?.copyWith(
      fontSize: 13,
      color: theme.colorScheme.onSurface,
      height: 1.3,
    );

    final textWidget = child ??
        Text(
          value,
          textAlign: isNumeric ? TextAlign.center : TextAlign.start,
          overflow: TextOverflow.ellipsis,
          maxLines: 2,
          softWrap: true,
        );

    return SizedBox(
      width: width,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        child: Align(
          alignment: isNumeric ? Alignment.center : Alignment.centerRight,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 24),
            child: DefaultTextStyle.merge(
              style: baseTextStyle,
              child: textWidget,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      locale: const Locale('ar'),
    );
    if (pickedDate != null) {
      setState(() {
        _selectedDate = pickedDate;
        _apiResult = null;
      });
    }
  }

  Future<void> _generateReport() async {
    if (_selectedDate == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('يرجى تحديد تاريخ')));
      return;
    }
    setState(() {
      _isLoading = true;
      _selectedRefuelId = null;
    });
    try {
      final token = Provider.of<AuthProvider>(context, listen: false).token;
      if (token == null) throw Exception('unauth');
      final apiResult = await ApiService.getDailyReport(token, _selectedDate!)
          .timeout(const Duration(seconds: 10),
              onTimeout: () =>
                  throw Exception('انتهت المهلة الزمنية لتحميل التقرير'));
      if (!mounted) return;
      setState(() {
        _apiResult = apiResult;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('خطأ: ${e.toString()}')));
    }
  }

  Future<void> _editSelectedRefuel() async {
    if (_selectedRefuelId == null || _apiResult == null) return;

    final selectedRecord = ((_apiResult!['records'] as List?) ?? [])
        .cast<Map<String, dynamic>>()
        .firstWhere(
          (record) => (record['refuel_id'] as int?) == _selectedRefuelId,
          orElse: () => <String, dynamic>{},
        );
    if (selectedRecord.isEmpty) return;

    final vehicle = _vehicleForRecord(selectedRecord);
    final odometerController = TextEditingController(
        text: (selectedRecord['odometer'] ?? '').toString());
    final litersController = TextEditingController(
        text: (selectedRecord['liters'] ?? '').toString());
    final selectedDate =
        DateTime.tryParse(selectedRecord['created_at']?.toString() ?? '') ??
            _selectedDate ??
            DateTime.now();
    final currentStation = (selectedRecord['station'] ?? '').toString();
    String? selectedStation = fuelStations.cast<String?>().firstWhere(
      (station) => stationsMatch(station, currentStation),
      orElse: () => null,
    );
    bool isSaving = false;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return ScaKeyboardDialog(
              child: AlertDialog(
                title: const Text('تعديل التفويلة'),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: odometerController,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        decoration: const InputDecoration(
                            labelText: 'العداد الحالي',
                            border: OutlineInputBorder()),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: litersController,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        decoration: const InputDecoration(
                            labelText: 'اللترات', border: OutlineInputBorder()),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: selectedStation,
                        decoration: const InputDecoration(
                            labelText: 'جهة التموين',
                            border: OutlineInputBorder()),
                        items: fuelStations
                            .map((station) => DropdownMenuItem<String>(
                                  value: station,
                                  child: Text(station),
                                ))
                            .toList(),
                        onChanged: (value) {
                          setDialogState(() => selectedStation = value);
                        },
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.of(dialogContext).pop(),
                      child: const Text('إلغاء')),
                  ElevatedButton(
                    autofocus: true,
                    onPressed: isSaving
                        ? null
                        : () async {
                            final parsedOdometer =
                                double.tryParse(odometerController.text);
                            final parsedLiters =
                                double.tryParse(litersController.text);
                            if (parsedOdometer == null ||
                                parsedLiters == null ||
                                parsedLiters <= 0) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content:
                                          Text('تحقق من قيم العداد واللترات')));
                              return;
                            }

                            setDialogState(() => isSaving = true);
                            try {
                              final token = Provider.of<AuthProvider>(context,
                                      listen: false)
                                  .token;
                              if (token == null) throw Exception('unauth');
                              final updatedRefuel =
                                  await ApiService.updateRefuel(
                                token,
                                _selectedRefuelId!,
                                RefuelCreate(
                                  vehicleId:
                                      (selectedRecord['vehicle_id'] as int?) ??
                                          vehicle?.id ??
                                          0,
                                  currentOdometer: parsedOdometer,
                                  liters: parsedLiters,
                                  createdAt: selectedDate,
                                    station: selectedStation,
                                ),
                              );
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content:
                                          Text('تم تعديل التفويلة بنجاح')));
                              Navigator.of(dialogContext).pop();
                              await _generateReport();
                            } catch (e) {
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                  content: Text(
                                      'فشل تعديل التفويلة: ${e.toString()}')));
                            } finally {
                              if (mounted)
                                setDialogState(() => isSaving = false);
                            }
                          },
                    child: isSaving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text('حفظ'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _deleteSelectedRefuel() async {
    if (_selectedRefuelId == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return ScaKeyboardDialog(
          child: AlertDialog(
            title: const Text('حذف التفويلة'),
            content: const Text('هل أنت متأكد من حذف هذه التفويلة؟'),
            actions: [
              TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: const Text('إلغاء')),
              ElevatedButton(
                  autofocus: true,
                  onPressed: () => Navigator.of(dialogContext).pop(true),
                  child: const Text('حذف')),
            ],
          ),
        );
      },
    );
    if (confirmed != true) return;

    try {
      final token = Provider.of<AuthProvider>(context, listen: false).token;
      if (token == null) throw Exception('unauth');
      await ApiService.deleteRefuel(token, _selectedRefuelId!);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('تم حذف التفويلة بنجاح')));
      await _generateReport();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('فشل حذف التفويلة: ${e.toString()}')));
    }
  }

  Vehicle? _vehicleForRecord(Map record) {
    final vehicleId = record['vehicle_id'] ?? record['vehicleId'];
    if (vehicleId is int) {
      final matches = widget.vehicles.where((v) => v.id == vehicleId).toList();
      return matches.isEmpty ? null : matches.first;
    }
    return null;
  }

  double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  Map<String, Object> _dailyStatusFromRecord(Map record) {
    final apiStatus = (record['status'] ?? '').toString().trim();
    if (apiStatus.isNotEmpty && apiStatus != 'null') {
      final color = apiStatus == 'متجاوز'
          ? const Color(0xFFFF5252)
          : apiStatus == 'نسبة غير منطقية'
              ? const Color(0xFFFFC107)
              : const Color(0xFF4CAF50);
      return {'status': apiStatus, 'color': color};
    }

    final apiCode =
        (record['status_code'] ?? '').toString().trim().toLowerCase();
    if (apiCode.isNotEmpty && apiCode != 'null') {
      final status = apiCode == 'excess'
          ? 'متجاوز'
          : apiCode == 'illogical'
              ? 'نسبة غير منطقية'
              : 'طبيعي';
      final color = apiCode == 'excess'
          ? const Color(0xFFFF5252)
          : apiCode == 'illogical'
              ? const Color(0xFFFFC107)
              : const Color(0xFF4CAF50);
      return {'status': status, 'color': color};
    }

    final vehicle = _vehicleForRecord(record);
    final standard = vehicle?.standardConsumption ?? 0.0;
    final actualRatio =
        _toDouble(record['consumption_ratio'] ?? record['ratio'] ?? 0);
    final status = ReportsCalculations.statusLabel(actualRatio, standard);
    return {'status': status, 'color': ReportsCalculations.statusColor(status)};
  }

  void _clearTableSelection() {
    setState(() {
      _selectedRefuelId = null;
      _highlightedRowIndex = null;
    });
  }

  void _moveTableSelection(int delta, List<Map<String, dynamic>> filtered) {
    if (filtered.isEmpty) return;

    final nextIndex = _highlightedRowIndex == null
        ? (delta > 0 ? 0 : filtered.length - 1)
        : (_highlightedRowIndex! + delta).clamp(0, filtered.length - 1);
    final selectedRecord = filtered[nextIndex];

    setState(() {
      _highlightedRowIndex = nextIndex;
      _selectedRefuelId = selectedRecord['refuel_id'] as int?;
    });
  }

  void _handleTableKey(RawKeyEvent event) {
    if (event is! RawKeyDownEvent) return;

    final filtered = ((_apiResult!['records'] as List?) ?? [])
        .cast<Map<String, dynamic>>()
        .where((record) {
      if (widget.vehicleQuery != null && widget.vehicleQuery!.isNotEmpty) {
        final q = widget.vehicleQuery!.toLowerCase();
        final recNumber = (record['vehicle_number'] ?? record['number'] ?? '')
            .toString()
            .toLowerCase();
        final recRegistry =
            (record['registry'] ?? record['vehicle_registry'] ?? '')
                .toString()
                .toLowerCase();
        if (!recNumber.contains(q) && !recRegistry.contains(q)) return false;
      }
      if (widget.globalFuelType != null) {
        final recFuel =
            (record['fuel_type'] ?? record['fuelType'] ?? '').toString();
        if (recFuel != widget.globalFuelType) return false;
      }
      if (_selectedStation != null && _selectedStation!.isNotEmpty) {
        final recStation = (record['station'] ?? 'غير محدد').toString();
        if (recStation != _selectedStation) return false;
      }
      return true;
    }).toList();

    if (filtered.isEmpty) return;

    if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      _moveTableSelection(1, filtered);
    } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      _moveTableSelection(-1, filtered);
    } else if (event.logicalKey == LogicalKeyboardKey.enter &&
        _selectedRefuelId != null) {
      _editSelectedRefuel();
    }
  }

  @override
  void dispose() {
    _dailyReportTableFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            children: [
              const SizedBox.shrink(),
              const SizedBox(height: 12),
              Focus(
                onKeyEvent: (node, event) {
                  if (event is KeyDownEvent &&
                      event.logicalKey == LogicalKeyboardKey.enter) {
                    if (!_isLoading) _generateReport();
                    return KeyEventResult.handled;
                  }
                  return KeyEventResult.ignored;
                },
                child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final isCompact = constraints.maxWidth < 720;
                          return isCompact
                              ? Column(
                                  children: [
                                    TextButton.icon(
                                      icon: const Icon(Icons.calendar_today),
                                      label: Text(
                                        _selectedDate != null
                                            ? DateFormat('dd/MM/yyyy')
                                                .format(_selectedDate!)
                                            : 'اختر التاريخ',
                                      ),
                                      onPressed: () => _selectDate(context),
                                    ),
                                  ],
                                )
                              : Row(
                                  children: [
                                    Expanded(
                                      child: TextButton.icon(
                                        icon: const Icon(Icons.calendar_today),
                                        label: Text(
                                          _selectedDate != null
                                              ? DateFormat('dd/MM/yyyy')
                                                  .format(_selectedDate!)
                                              : 'اختر التاريخ',
                                        ),
                                        onPressed: () => _selectDate(context),
                                      ),
                                    ),
                                  ],
                                );
                        },
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.search),
                          label: const Text('عرض التقرير'),
                          onPressed: _isLoading ? null : _generateReport,
                        ),
                      ),
                    ],
                  ),
                ),
                ),
              ),
              if (_isLoading) ...[
                const SizedBox(height: 32),
                const CircularProgressIndicator(),
              ] else if (_apiResult != null) ...[
                const SizedBox(height: 24),
                _DailyApiSummary(result: _apiResult!),
                const SizedBox(height: 12),
                Builder(builder: (context) {
                  final records = (_apiResult!['records'] as List?) ?? [];
                  final recordsTyped = records.cast<Map<String, dynamic>>();

                  // استخراج قائمة المحطات الفريدة
                  final stations = <String>{};
                  for (var r in recordsTyped) {
                    final station = (r['station'] ?? 'غير محدد').toString();
                    stations.add(station);
                  }
                  final stationsList = stations.toList()..sort();

                  // تطبيق الفلاتر
                  final filtered = recordsTyped.where((r) {
                    if (widget.vehicleQuery != null &&
                        widget.vehicleQuery!.isNotEmpty) {
                      final q = widget.vehicleQuery!.toLowerCase();
                      final recNumber =
                          (r['vehicle_number'] ?? r['number'] ?? '')
                              .toString()
                              .toLowerCase();
                      final recRegistry =
                          (r['registry'] ?? r['vehicle_registry'] ?? '')
                              .toString()
                              .toLowerCase();
                      if (!recNumber.contains(q) && !recRegistry.contains(q))
                        return false;
                    }
                    if (widget.globalFuelType != null) {
                      final recFuel =
                          (r['fuel_type'] ?? r['fuelType'] ?? '').toString();
                      if (recFuel != widget.globalFuelType) return false;
                    }
                    if (_selectedStation != null &&
                        _selectedStation!.isNotEmpty) {
                      final recStation =
                          (r['station'] ?? 'غير محدد').toString();
                      if (recStation != _selectedStation) return false;
                    }
                    return true;
                  }).toList();

                  return TapRegion(
                    onTapOutside: (_) => _clearTableSelection(),
                    child: Column(
                      children: [
                        if (_selectedRefuelId != null)
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: LayoutBuilder(
                                builder: (context, constraints) {
                                  final isCompact = constraints.maxWidth < 640;
                                  return isCompact
                                      ? Column(
                                          children: [
                                            SizedBox(
                                              width: double.infinity,
                                              child: ElevatedButton.icon(
                                                icon: const Icon(Icons.edit),
                                                label: const Text(
                                                    'تعديل التفويلة'),
                                                onPressed: _editSelectedRefuel,
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            SizedBox(
                                              width: double.infinity,
                                              child: OutlinedButton.icon(
                                                icon: const Icon(Icons.delete),
                                                label:
                                                    const Text('حذف التفويلة'),
                                                onPressed:
                                                    _deleteSelectedRefuel,
                                              ),
                                            ),
                                          ],
                                        )
                                      : Row(
                                          children: [
                                            Expanded(
                                              child: ElevatedButton.icon(
                                                icon: const Icon(Icons.edit),
                                                label: const Text(
                                                    'تعديل التفويلة'),
                                                onPressed: _editSelectedRefuel,
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: OutlinedButton.icon(
                                                icon: const Icon(Icons.delete),
                                                label:
                                                    const Text('حذف التفويلة'),
                                                onPressed:
                                                    _deleteSelectedRefuel,
                                              ),
                                            ),
                                          ],
                                        );
                                },
                              ),
                            ),
                          ),
                        if (_selectedRefuelId != null)
                          const SizedBox(height: 12),
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                final isCompact = constraints.maxWidth < 620;
                                final stationFilter = DropdownButtonFormField<String?>(
                                  value: _selectedStation,
                                  decoration: const InputDecoration(
                                    labelText: 'فلتر جهة التموين',
                                    border: OutlineInputBorder(),
                                    prefixIcon: Icon(Icons.local_gas_station),
                                  ),
                                  items: [
                                    const DropdownMenuItem(
                                        value: null, child: Text('كل المحطات')),
                                    ...stationsList
                                        .map((station) => DropdownMenuItem(
                                              value: station,
                                              child: Text(station),
                                            )),
                                  ],
                                  onChanged: (v) =>
                                      setState(() => _selectedStation = v),
                                );
                                final exportButtons = _ExportButtons(
                                  reportType: 'يومي',
                                  date: _selectedDate,
                                  iconOnly: true,
                                  onExportExcel: () async {
                                    final headers = [
                                      'رقم السيارة',
                                      'الأحرف',
                                      'النوع',
                                      'جهة التموين',
                                      'العداد',
                                      'اللترات',
                                      'النسبة',
                                      'الحالة'
                                    ];
                                    final rows = filtered.map((r) {
                                      final statusInfo =
                                          _dailyStatusFromRecord(r);
                                      return [
                                        r['vehicle_number'] ?? r['number'] ?? '',
                                        r['vehicle_letters'] ?? r['letters'] ?? '',
                                        r['vehicle_type'] ?? r['type'] ?? '',
                                        r['station'] ?? 'غير محدد',
                                        (r['odometer'] ?? r['last_odometer'] ?? 0)
                                            .toString(),
                                        (r['liters'] ?? 0).toString(),
                                        (r['consumption_ratio'] ?? r['ratio'] ?? 0)
                                            .toString(),
                                        statusInfo['status'] as String,
                                      ];
                                    }).toList();
                                    await _writeExcelFile(
                                        context,
                                        headers,
                                        rows,
                                        'daily_${_selectedDate!.toIso8601String().split('T').first}');
                                  },
                                  onExportPdf: () async {
                                    final headers = [
                                      'رقم السيارة',
                                      'الأحرف',
                                      'النوع',
                                      'جهة التموين',
                                      'العداد',
                                      'اللترات',
                                      'النسبة',
                                      'الحالة'
                                    ];
                                    final rows = filtered.map((r) {
                                      final statusInfo =
                                          _dailyStatusFromRecord(r);
                                      return [
                                        r['vehicle_number'] ?? r['number'] ?? '',
                                        r['vehicle_letters'] ?? r['letters'] ?? '',
                                        r['vehicle_type'] ?? r['type'] ?? '',
                                        r['station'] ?? 'غير محدد',
                                        (r['odometer'] ?? r['last_odometer'] ?? 0)
                                            .toString(),
                                        (r['liters'] ?? 0).toString(),
                                        (r['consumption_ratio'] ?? r['ratio'] ?? 0)
                                            .toString(),
                                        statusInfo['status'] as String,
                                      ];
                                    }).toList();
                                    await _writePdfFile(
                                        context,
                                        headers,
                                        rows,
                                        'daily_${_selectedDate!.toIso8601String().split('T').first}');
                                  },
                                );
                                return isCompact
                                    ? Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.stretch,
                                        children: [
                                          stationFilter,
                                          const SizedBox(height: 8),
                                          Align(
                                              alignment: Alignment.centerRight,
                                              child: exportButtons),
                                        ],
                                      )
                                    : Row(
                                        children: [
                                          Expanded(child: stationFilter),
                                          const SizedBox(width: 12),
                                          exportButtons,
                                        ],
                                      );
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        // عرض الإجمالي للمحطة المختارة
                        if (_selectedStation != null &&
                            _selectedStation!.isNotEmpty)
                          _StationSummary(
                              records: filtered.cast<Map<String, dynamic>>(),
                              stationName: _selectedStation!)
                        else
                          const SizedBox.shrink(),
                        if (_selectedStation != null &&
                            _selectedStation!.isNotEmpty)
                          const SizedBox(height: 12)
                        else
                          const SizedBox.shrink(),
                        GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () =>
                              _dailyReportTableFocusNode.requestFocus(),
                          child: RawKeyboardListener(
                            focusNode: _dailyReportTableFocusNode,
                            onKey: _handleTableKey,
                            child: LayoutBuilder(
                              builder: (context, constraints) =>
                                  SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: ConstrainedBox(
                                  constraints: BoxConstraints(
                                    minWidth: constraints.maxWidth,
                                  ),
                                  child: Card(
                                  margin: EdgeInsets.zero,
                                  elevation: 1,
                                  clipBehavior: Clip.antiAlias,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    side: BorderSide(color: Colors.grey.shade300),
                                  ),
                                  child: DataTable(
                                  headingRowColor: WidgetStatePropertyAll(
                                      Theme.of(context)
                                          .colorScheme
                                          .primaryContainer),
                                  dataRowColor: WidgetStateProperty.resolveWith(
                                      (states) => states.contains(WidgetState.hovered)
                                          ? Theme.of(context)
                                              .colorScheme
                                              .primary
                                              .withValues(alpha: 0.08)
                                          : null),
                                  border: TableBorder(
                                    horizontalInside:
                                        BorderSide(color: Colors.grey.shade200),
                                    verticalInside:
                                        BorderSide(color: Colors.grey.shade200),
                                    top: BorderSide(color: Colors.grey.shade300),
                                    bottom: BorderSide(color: Colors.grey.shade300),
                                  ),
                                  columnSpacing: 12,
                                  headingRowHeight: 48,
                                  dataRowMinHeight: 48,
                                  dataRowMaxHeight: 56,
                                  columns: const [
                                    DataColumn(label: Text('رقم السيارة')),
                                    DataColumn(label: Text('الأحرف')),
                                    DataColumn(label: Text('النوع')),
                                    DataColumn(label: Text('جهة التموين')),
                                    DataColumn(label: Text('العداد')),
                                    DataColumn(label: Text('اللترات')),
                                    DataColumn(label: Text('النسبة')),
                                    DataColumn(label: Text('الحالة')),
                                  ],
                                  rows: filtered.asMap().entries.map((entry) {
                                    final index = entry.key;
                                    final r = entry.value;
                                    final statusInfo =
                                        _dailyStatusFromRecord(r);
                                    final statusColor =
                                        statusInfo['color'] as Color;
                                    final statusText =
                                        statusInfo['status'] as String;
                                    final isSelected =
                                        (_selectedRefuelId != null &&
                                            _selectedRefuelId ==
                                                (r['refuel_id'] as int?));

                                    return DataRow(
                                      selected: isSelected,
                                      onSelectChanged: (_) {
                                        setState(() {
                                          _highlightedRowIndex = index;
                                          _selectedRefuelId = isSelected
                                              ? null
                                              : (r['refuel_id'] as int?);
                                        });
                                      },
                                      cells: [
                                        DataCell(Text(
                                            '${r['vehicle_number'] ?? r['number'] ?? ''}')),
                                        DataCell(Text(
                                            '${r['vehicle_letters'] ?? r['letters'] ?? '-'}')),
                                        DataCell(Text(
                                            '${r['vehicle_type'] ?? r['type'] ?? ''}')),
                                        DataCell(Text(ReportsCalculations
                                            .shortStationName(
                                                '${r['station'] ?? 'غير محدد'}'))),
                                        DataCell(Text((r['odometer'] ??
                                                r['last_odometer'] ??
                                                0)
                                            .toString())),
                                        DataCell(Text((r['liters'] ??
                                                r['total_liters'] ??
                                                0)
                                            .toString())),
                                        DataCell(Text(
                                            '${(r['consumption_ratio'] ?? r['ratio'] ?? 0).toString()}')),
                                        DataCell(
                                          SizedBox(
                                            width: 118,
                                            height: 32,
                                            child: Container(
                                            decoration: BoxDecoration(
                                              color: statusColor,
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            alignment: Alignment.center,
                                            child: FittedBox(
                                              fit: BoxFit.scaleDown,
                                              child: Text(
                                                statusText,
                                                style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 12),
                                              ),
                                            ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    );
                                  }).toList(),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _DailyApiSummary extends StatelessWidget {
  final Map<String, dynamic> result;
  const _DailyApiSummary({required this.result});

  @override
  Widget build(BuildContext context) {
    final count = result['count'] ?? 0;
    final date = result['date'] ?? '';

    final records = (result['records'] as List?) ?? [];
    double total92 = 0.0, total95 = 0.0, totalSolar = 0.0;
    for (var r in records) {
      final recFuel = (r['fuel_type'] ?? r['fuelType'] ?? '').toString();
      final litersRaw = r['liters'] ?? r['total_liters'] ?? 0;
      final liters = litersRaw is num
          ? litersRaw.toDouble()
          : double.tryParse(litersRaw.toString()) ?? 0.0;
      if (recFuel == 'بنزين 92') {
        total92 += liters;
      } else if (recFuel == 'بنزين 95') {
        total95 += liters;
      } else if (recFuel == 'سولار') {
        totalSolar += liters;
      }
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('تقرير ليوم $date',
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, constraints) {
                final isNarrow = constraints.maxWidth < 720;
                final tileWidth = isNarrow
                    ? constraints.maxWidth
                    : (constraints.maxWidth - 36) / 4;
                return Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    SizedBox(
                        width: tileWidth,
                        child: _MetricTile(
                            label: 'عدد التفويلات', value: count.toString())),
                    SizedBox(
                        width: tileWidth,
                        child: _MetricTile(
                            label: 'بنزين 92',
                            value: '${total92.toStringAsFixed(1)} لتر')),
                    SizedBox(
                        width: tileWidth,
                        child: _MetricTile(
                            label: 'بنزين 95',
                            value: '${total95.toStringAsFixed(1)} لتر')),
                    SizedBox(
                        width: tileWidth,
                        child: _MetricTile(
                            label: 'سولار',
                            value: '${totalSolar.toStringAsFixed(1)} لتر')),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  final String label;
  final String value;
  const _MetricTile({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey)),
        const SizedBox(height: 6),
        Text(value,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ],
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _SummaryRow(
      {required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value,
              style: TextStyle(fontWeight: FontWeight.bold, color: valueColor)),
        ],
      ),
    );
  }
}

class InvoiceCalculatorTab extends StatefulWidget {
  const InvoiceCalculatorTab({super.key});

  @override
  State<InvoiceCalculatorTab> createState() => _InvoiceCalculatorTabState();
}

class _InvoiceCalculatorTabState extends State<InvoiceCalculatorTab> {
  final TextEditingController _stationController = TextEditingController();
  final TextEditingController _invoiceNumberController =
      TextEditingController();
  final TextEditingController _invoiceNumberSearchController =
      TextEditingController();
  DateTime? _startDate;
  DateTime? _endDate;
  DateTime? _searchStartDate;
  DateTime? _searchEndDate;
  String _invoiceSearchMode = 'period';
  final Map<String, TextEditingController> _priceControllers = {};
  bool _isLoading = false;
  bool _isSavingPrices = false;
  bool _isSavingInvoice = false;
  bool _isPriceEditing = false;
  bool _isInvoiceSearchLoading = false;
  String? _error;
  Map<String, dynamic>? _calculationResult;
  List<Map<String, dynamic>> _savedInvoices = [];
  int? _selectedInvoiceId;

  @override
  void initState() {
    super.initState();
    _loadInvoicePrices();
    _loadInvoices();
  }

  @override
  void dispose() {
    _stationController.dispose();
    _invoiceNumberController.dispose();
    _invoiceNumberSearchController.dispose();
    for (final controller in _priceControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _loadInvoicePrices() async {
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    if (token == null) return;
    try {
      final result = await ApiService.fetchInvoicePrices(token);
      if (!mounted) return;
      setState(() {
        for (final controller in _priceControllers.values) {
          controller.dispose();
        }
        _priceControllers.clear();
        final prices = Map<String, dynamic>.from(result['prices'] ?? {});
        for (final entry in prices.entries.toList()
          ..sort((a, b) => a.key.compareTo(b.key))) {
          _priceControllers[entry.key] =
              TextEditingController(text: entry.value.toString());
        }
        _isPriceEditing = false;
      });
    } catch (_) {}
  }

  Future<void> _loadInvoices(
      {String? invoiceNumber, DateTime? date, int? month, int? year}) async {
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    if (token == null) return;
    setState(() => _isInvoiceSearchLoading = true);
    try {
      final invoices = await ApiService.listInvoices(
        token,
        invoiceNumber: invoiceNumber,
        date: date,
        month: month,
        year: year,
      );
      if (!mounted) return;
      setState(() => _savedInvoices = invoices);
    } catch (_) {
      if (mounted) setState(() => _savedInvoices = []);
    } finally {
      if (mounted) setState(() => _isInvoiceSearchLoading = false);
    }
  }

  void _enablePriceEditing() {
    setState(() => _isPriceEditing = true);
  }

  Future<void> _searchInvoices() async {
    if (_invoiceSearchMode == 'period') {
      if (_searchStartDate == null || _searchEndDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('يرجى اختيار الفترة للبحث')));
        return;
      }

      final token = Provider.of<AuthProvider>(context, listen: false).token;
      if (token == null) return;

      setState(() => _isInvoiceSearchLoading = true);
      try {
        final invoices = await ApiService.listInvoices(token);
        if (!mounted) return;
        setState(() => _savedInvoices = filterInvoicesByDateRange(
            invoices, _searchStartDate, _searchEndDate));
      } catch (_) {
        if (mounted) setState(() => _savedInvoices = []);
      } finally {
        if (mounted) setState(() => _isInvoiceSearchLoading = false);
      }
      return;
    }

    if (_invoiceSearchMode == 'number') {
      final invoiceNumber = _invoiceNumberSearchController.text.trim();
      if (invoiceNumber.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('يرجى إدخال رقم الفاتورة')));
        return;
      }
      await _loadInvoices(invoiceNumber: invoiceNumber);
      return;
    }
  }

  Future<void> _pickSearchDate(bool isStart) async {
    final picked = await showDatePicker(
      context: context,
      initialDate:
          (isStart ? _searchStartDate : _searchEndDate) ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      locale: const Locale('ar'),
    );
    if (picked == null) return;
    setState(() {
      if (isStart) {
        _searchStartDate = picked;
      } else {
        _searchEndDate = picked;
      }
    });
  }

  Future<void> _pickDate(bool isStart) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: (isStart ? _startDate : _endDate) ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      locale: const Locale('ar'),
    );
    if (picked == null) return;
    setState(() {
      if (isStart) {
        _startDate = picked;
      } else {
        _endDate = picked;
      }
    });
  }

  Map<String, double> _currentPrices() {
    return {
      for (final entry in _priceControllers.entries)
        entry.key: double.tryParse(entry.value.text) ?? 0.0,
    };
  }

  Future<void> _savePrices() async {
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('يرجى تسجيل الدخول أولاً')));
      return;
    }
    setState(() => _isSavingPrices = true);
    try {
      await ApiService.saveInvoicePrices(token, _currentPrices());
      if (!mounted) return;
      await _loadInvoicePrices();
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('تم حفظ أسعار الوقود')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('فشل حفظ الأسعار: ${e.toString()}')));
    } finally {
      if (mounted)
        setState(() {
          _isSavingPrices = false;
          _isPriceEditing = false;
        });
    }
  }

  Future<void> _calculateInvoice() async {
    final station = _stationController.text.trim();
    if (station.isEmpty || _startDate == null || _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('يرجى إدخال جهة التموين وتاريخ البداية والنهاية')));
      return;
    }
    if (_endDate!.isBefore(_startDate!)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('تاريخ النهاية يجب أن يكون بعد البداية')));
      return;
    }

    final token = Provider.of<AuthProvider>(context, listen: false).token;
    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('يرجى تسجيل الدخول أولاً')));
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final result = await ApiService.calculateInvoice(
        token,
        station: station,
        startDate:
            DateTime(_startDate!.year, _startDate!.month, _startDate!.day)
                .toIso8601String()
                .split('T')
                .first,
        endDate: DateTime(_endDate!.year, _endDate!.month, _endDate!.day)
            .toIso8601String()
            .split('T')
            .first,
        prices: _currentPrices(),
      );
      if (!mounted) return;
      setState(() {
        _calculationResult = result;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _saveInvoice() async {
    final result = _calculationResult;
    if (result == null) return;

    final token = Provider.of<AuthProvider>(context, listen: false).token;
    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('يرجى تسجيل الدخول أولاً')));
      return;
    }

    setState(() => _isSavingInvoice = true);
    try {
      final payload = {
        'station': result['station'],
        'start_date': result['start_date'],
        'end_date': result['end_date'],
        'created_at': result['end_date'],
        'invoice_number': _invoiceNumberController.text.trim(),
        'total_amount': result['summary']['total_amount'],
        'items': result['summary']['items'],
        'prices': result['summary']['prices'],
      };
      final savedInvoice = await ApiService.createInvoice(token, payload);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('تم حفظ الفاتورة')));
      await _loadInvoices();
      setState(() => _selectedInvoiceId = savedInvoice['id'] as int?);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('فشل حفظ الفاتورة: ${e.toString()}')));
    } finally {
      if (mounted) setState(() => _isSavingInvoice = false);
    }
  }

  Future<void> _updateInvoice() async {
    final result = _calculationResult;
    final selectedId = _selectedInvoiceId;
    if (result == null || selectedId == null) return;

    final token = Provider.of<AuthProvider>(context, listen: false).token;
    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('يرجى تسجيل الدخول أولاً')));
      return;
    }

    try {
      final payload = {
        'station': result['station'],
        'start_date': result['start_date'],
        'end_date': result['end_date'],
        'created_at': result['end_date'],
        'invoice_number': _invoiceNumberController.text.trim(),
        'total_amount': result['summary']['total_amount'],
        'items': result['summary']['items'],
        'prices': result['summary']['prices'],
      };
      await ApiService.updateInvoice(token, selectedId, payload);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('تم تحديث الفاتورة')));
      await _loadInvoices();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('فشل تحديث الفاتورة: ${e.toString()}')));
    }
  }

  Future<void> _deleteInvoice(int invoiceId) async {
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    if (token == null) return;
    try {
      await ApiService.deleteInvoice(token, invoiceId);
      if (!mounted) return;
      await _loadInvoices();
      if (_selectedInvoiceId == invoiceId)
        setState(() => _selectedInvoiceId = null);
    } catch (_) {}
  }


  Future<void> _showInvoiceInfo(Map<String, dynamic> invoice) async {
    final items = (invoice['items'] as List? ?? [])
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('الفاتورة ${invoice['invoice_number'] ?? ''}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('جهة التموين: ${invoice['station'] ?? ''}'),
            const SizedBox(height: 8),
            Text('التاريخ: ${invoice['end_date'] ?? invoice['created_at'] ?? ''}'),
            const SizedBox(height: 8),
            Text('الفترة: ${invoice['start_date'] ?? ''} إلى ${invoice['end_date'] ?? ''}'),
            const SizedBox(height: 8),
            if (items.isNotEmpty) ...[
              const Text('تفاصيل الوقود:',
                style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  horizontalMargin: 8,
                  columnSpacing: 16,
                  dataRowMinHeight: 32,
                  dataRowMaxHeight: 36,
                  headingRowHeight: 34,
                  columns: const [
                    DataColumn(label: Text('الوقود')),
                    DataColumn(label: Text('الكمية')),
                    DataColumn(label: Text('السعر')),
                    DataColumn(label: Text('الإجمالي')),
                  ],
                  rows: items.map((item) => DataRow(cells: [
                    DataCell(Text(item['fuel_type']?.toString() ?? '')),
                    DataCell(Text(item['quantity']?.toString() ?? '')),
                    DataCell(Text(item['price']?.toString() ?? '')),
                    DataCell(Text(item['total']?.toString() ?? '')),
                  ])).toList(),
                ),
              ),
            ],
            if (items.isNotEmpty) const SizedBox(height: 4),
            Text('الإجمالي: ${invoice['total_amount'] ?? ''}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('إغلاق'),
          ),
        ],
      ),
    );
  }
  Future<void> _loadInvoiceDetails(Map<String, dynamic> invoice) async {
    final id = invoice['id'];
    if (id is! int) return;
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    if (token == null) return;
    try {
      final details = await ApiService.getInvoice(token, id);
      if (!mounted) return;
      setState(() {
        _selectedInvoiceId = id;
        _stationController.text = details['station']?.toString() ?? '';
        _invoiceNumberController.text =
            details['invoice_number']?.toString() ?? '';
        _startDate = DateTime.tryParse(details['start_date']?.toString() ?? '');
        _endDate = DateTime.tryParse(details['end_date']?.toString() ?? '');
        _calculationResult = {
          'station': details['station'],
          'start_date': details['start_date'],
          'end_date': details['end_date'],
          'summary': {
            'items': details['items'],
            'total_amount': details['total_amount'],
            'prices': details['prices'],
          },
        };
      });
    } catch (_) {}
  }

  Future<void> _exportInvoice() async {
    final result = _calculationResult;
    if (result == null) return;
    final rows = <List<dynamic>>[];
    for (final item
        in (result['summary']['items'] as List<dynamic>? ?? <dynamic>[])) {
      final map = Map<String, dynamic>.from(item as Map<String, dynamic>);
      rows.add([
        map['fuel_type'],
        map['quantity'],
        map['price'],
        map['total'],
      ]);
    }
    rows.add(['الإجمالي', '', '', result['summary']['total_amount']]);
    await _writeExcelFile(
        context,
        ['نوع الوقود', 'الكمية', 'السعر', 'الإجمالي'],
        rows,
        'invoice_${result['station']}');
  }

  List<Map<String, dynamic>> _sortedSavedInvoices() {
    final invoices = List<Map<String, dynamic>>.from(_savedInvoices);
    invoices.sort((a, b) {
        final aDate = DateTime.tryParse(
          (a['end_date'] ?? a['created_at'] ?? a['start_date'] ?? '').toString());
        final bDate = DateTime.tryParse(
          (b['end_date'] ?? b['created_at'] ?? b['start_date'] ?? '').toString());
        if (aDate == null && bDate != null) return 1;
        if (aDate != null && bDate == null) return -1;
        final dateComparison = aDate?.compareTo(bDate!) ?? 0;
      if (dateComparison != 0) return dateComparison;

      final aNumber = a['invoice_number']?.toString() ?? '';
      final bNumber = b['invoice_number']?.toString() ?? '';
      final aNumeric = int.tryParse(aNumber);
      final bNumeric = int.tryParse(bNumber);
      if (aNumeric != null && bNumeric != null) {
        return aNumeric.compareTo(bNumeric);
      }
      return aNumber.compareTo(bNumber);
    });
    return invoices;
  }

  double _invoiceNumberValue(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0.0;
  }

  List<List<dynamic>> _invoiceTableRows() {
    final totals = List<double>.filled(12, 0);
    final rows = <List<dynamic>>[];
    for (final invoice in _sortedSavedInvoices()) {
      final quantities = <String, double>{};
      final prices = <String, double>{};
      final values = <String, double>{};
      for (final item in (invoice['items'] as List? ?? [])) {
        final itemMap = Map<String, dynamic>.from(item as Map);
        final fuel = itemMap['fuel_type']?.toString() ?? '';
        quantities[fuel] = _invoiceNumberValue(itemMap['quantity']);
        prices[fuel] = _invoiceNumberValue(itemMap['price']);
        values[fuel] = _invoiceNumberValue(itemMap['total']);
      }
      final row = <dynamic>[
        invoice['end_date'] ?? invoice['created_at'] ?? invoice['start_date'] ?? '',
        invoice['invoice_number'] ?? '',
        quantities['سولار'] ?? 0,
        prices['سولار'] ?? 0,
        values['سولار'] ?? 0,
        quantities['بنزين 92'] ?? 0,
        prices['بنزين 92'] ?? 0,
        values['بنزين 92'] ?? 0,
        quantities['بنزين 95'] ?? 0,
        prices['بنزين 95'] ?? 0,
        values['بنزين 95'] ?? 0,
        _invoiceNumberValue(invoice['total_amount']),
      ];
      for (var index = 0; index < row.length; index++) {
        if (index == 2 || index == 4 || index == 5 || index == 7 || index == 8 || index == 10 || index == 11) {
          totals[index] += _invoiceNumberValue(row[index]);
        }
      }
      rows.add(row);
    }
    rows.add([
      'الإجمالي',
      '',
      totals[2],
      '',
      totals[4],
      totals[5],
      '',
      totals[7],
      totals[8],
      '',
      totals[10],
      totals[11],
    ]);
    return rows;
  }

  List<String> _invoiceExportHeaders() => const [
        'تاريخ الفاتورة',
        'رقم الفاتورة',
        'كمية سولار',
        'سعر سولار',
        'قيمة سولار',
        'كمية بنزين 92',
        'سعر بنزين 92',
        'قيمة بنزين 92',
        'كمية بنزين 95',
        'سعر بنزين 95',
        'قيمة بنزين 95',
        'إجمالي القيمة',
      ];

  Future<void> _exportSavedInvoicesExcel() async {
    await _writeExcelFile(context, _invoiceExportHeaders(),
        _invoiceTableRows(), 'saved_invoices');
  }

  Future<void> _exportSavedInvoicesPdf() async {
    await _writePdfFile(context, _invoiceExportHeaders(),
        _invoiceTableRows(), 'saved_invoices');
  }

  @override
  Widget build(BuildContext context) {
    final hasResult = _calculationResult != null;
    final items = (_calculationResult?['summary']['items'] as List<dynamic>? ??
        <dynamic>[]);
    final hasInvoiceItems = items.isNotEmpty;
    final emptyMessage = _calculationResult?['message']?.toString();
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Expanded(
                        child: Text(
                          'إدارة أسعار الوقود',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.edit),
                        label: const Text('تعديل'),
                        onPressed: _isPriceEditing ? null : _enablePriceEditing,
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.save),
                        label: const Text('حفظ تعديل'),
                        onPressed: _isSavingPrices ? null : _savePrices,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      for (final entry
                          in _priceControllers.entries.toList()
                            ..sort((a, b) => a.key.compareTo(b.key)))
                        SizedBox(
                          width: 180,
                          child: TextField(
                            controller: entry.value,
                            enabled: _isPriceEditing,
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            decoration: InputDecoration(
                              labelText: entry.key,
                              border: const OutlineInputBorder(),
                              suffixIcon: !_isPriceEditing
                                  ? const Icon(Icons.lock_outline)
                                  : null,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('إنشاء الفاتورة',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: _stationController.text.isEmpty
                        ? null
                        : _stationController.text,
                    decoration: const InputDecoration(
                        labelText: 'جهة التفويل', border: OutlineInputBorder()),
                    hint: const Text('اختر جهة التفويل'),
                    items: [
                      const DropdownMenuItem(
                          value: null, child: Text('اختر جهة التفويل')),
                      ...fuelStations.map((station) => DropdownMenuItem(
                          value: station, child: Text(station))),
                    ],
                    onChanged: (value) =>
                        setState(() => _stationController.text = value ?? ''),
                  ),
                  const SizedBox(height: 12),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isCompact = constraints.maxWidth < 720;
                      return isCompact
                          ? Column(
                              children: [
                                TextButton.icon(
                                  icon: const Icon(Icons.calendar_today),
                                  label: Text(_startDate != null
                                      ? DateFormat('dd/MM/yyyy')
                                          .format(_startDate!)
                                      : 'من تاريخ'),
                                  onPressed: () => _pickDate(true),
                                ),
                                const SizedBox(height: 8),
                                TextButton.icon(
                                  icon: const Icon(Icons.calendar_today),
                                  label: Text(_endDate != null
                                      ? DateFormat('dd/MM/yyyy')
                                          .format(_endDate!)
                                      : 'إلى تاريخ'),
                                  onPressed: () => _pickDate(false),
                                ),
                              ],
                            )
                          : Row(
                              children: [
                                Expanded(
                                  child: TextButton.icon(
                                    icon: const Icon(Icons.calendar_today),
                                    label: Text(_startDate != null
                                        ? DateFormat('dd/MM/yyyy')
                                            .format(_startDate!)
                                        : 'من تاريخ'),
                                    onPressed: () => _pickDate(true),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: TextButton.icon(
                                    icon: const Icon(Icons.calendar_today),
                                    label: Text(_endDate != null
                                        ? DateFormat('dd/MM/yyyy')
                                            .format(_endDate!)
                                        : 'إلى تاريخ'),
                                    onPressed: () => _pickDate(false),
                                  ),
                                ),
                              ],
                            );
                    },
                  ),
                  const SizedBox(height: 12),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _invoiceNumberController,
                    decoration: const InputDecoration(
                        labelText: 'رقم الفاتورة',
                        border: OutlineInputBorder()),
                    textDirection: material.TextDirection.rtl,
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.receipt_long),
                      label: const Text('إنشاء فاتورة'),
                      onPressed: _isLoading ? null : _calculateInvoice,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: const TextStyle(color: Colors.red)),
          ],
          if (hasResult) ...[
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('رقم الفاتورة',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    TextField(
                      controller: _invoiceNumberController,
                      decoration: const InputDecoration(
                          hintText: 'اكتب رقم الفاتورة يدويًا',
                          border: OutlineInputBorder()),
                      textDirection: material.TextDirection.rtl,
                    ),
                    const SizedBox(height: 12),
                    Text('جهة التفويل: ${_calculationResult!['station']}',
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Text(
                        'من ${_calculationResult!['start_date']} إلى ${_calculationResult!['end_date']}'),
                    const SizedBox(height: 12),
                    if (hasInvoiceItems)
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          columns: const [
                            DataColumn(label: Text('النوع')),
                            DataColumn(label: Text('الكمية')),
                            DataColumn(label: Text('السعر')),
                            DataColumn(label: Text('الإجمالي')),
                          ],
                          rows: [
                            for (final item in items)
                              DataRow(cells: [
                                DataCell(Text(
                                    (item as Map<String, dynamic>)['fuel_type']
                                        .toString())),
                                DataCell(Text((item)['quantity'].toString())),
                                DataCell(Text((item)['price'].toString())),
                                DataCell(Text((item)['total'].toString())),
                              ]),
                          ],
                        ),
                      )
                    else if (emptyMessage != null)
                      Text(emptyMessage,
                          style: const TextStyle(
                              color: Colors.orange,
                              fontWeight: FontWeight.w600)),
                    const SizedBox(height: 12),
                    if (hasInvoiceItems)
                      Text(
                          'إجمالي قيمة الفاتورة = ${_calculationResult!['summary']['total_amount']}',
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    if (hasInvoiceItems)
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          ElevatedButton.icon(
                            icon: const Icon(Icons.save),
                            label: const Text('حفظ الفاتورة'),
                            onPressed: _isSavingInvoice ? null : _saveInvoice,
                          ),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.update),
                            label: const Text('تحديث المختار'),
                            onPressed: _selectedInvoiceId == null
                                ? null
                                : _updateInvoice,
                          ),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.download),
                            label: const Text('تصدير'),
                            onPressed: _exportInvoice,
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('استدعاء الفواتير',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      ChoiceChip(
                        label: const Text('حسب الفترة'),
                        selected: _invoiceSearchMode == 'period',
                        onSelected: (selected) {
                          if (selected)
                            setState(() => _invoiceSearchMode = 'period');
                        },
                      ),
                      ChoiceChip(
                        label: const Text('حسب رقم الفاتورة'),
                        selected: _invoiceSearchMode == 'number',
                        onSelected: (selected) {
                          if (selected)
                            setState(() => _invoiceSearchMode = 'number');
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (_invoiceSearchMode == 'period')
                    Column(
                      children: [
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final isCompact = constraints.maxWidth < 720;
                            return isCompact
                                ? Column(
                                    children: [
                                      TextButton.icon(
                                        icon: const Icon(Icons.calendar_today),
                                        label: Text(_searchStartDate != null
                                            ? DateFormat('dd/MM/yyyy')
                                                .format(_searchStartDate!)
                                            : 'من تاريخ'),
                                        onPressed: () => _pickSearchDate(true),
                                      ),
                                      const SizedBox(height: 8),
                                      TextButton.icon(
                                        icon: const Icon(Icons.calendar_today),
                                        label: Text(_searchEndDate != null
                                            ? DateFormat('dd/MM/yyyy')
                                                .format(_searchEndDate!)
                                            : 'إلى تاريخ'),
                                        onPressed: () => _pickSearchDate(false),
                                      ),
                                    ],
                                  )
                                : Row(
                                    children: [
                                      Expanded(
                                        child: TextButton.icon(
                                          icon:
                                              const Icon(Icons.calendar_today),
                                          label: Text(_searchStartDate != null
                                              ? DateFormat('dd/MM/yyyy')
                                                  .format(_searchStartDate!)
                                              : 'من تاريخ'),
                                          onPressed: () =>
                                              _pickSearchDate(true),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: TextButton.icon(
                                          icon:
                                              const Icon(Icons.calendar_today),
                                          label: Text(_searchEndDate != null
                                              ? DateFormat('dd/MM/yyyy')
                                                  .format(_searchEndDate!)
                                              : 'إلى تاريخ'),
                                          onPressed: () =>
                                              _pickSearchDate(false),
                                        ),
                                      ),
                                    ],
                                  );
                          },
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(child: const SizedBox.shrink()),
                            ElevatedButton.icon(
                              icon: const Icon(Icons.search),
                              label: const Text('بحث'),
                              onPressed: _isInvoiceSearchLoading
                                  ? null
                                  : _searchInvoices,
                            ),
                          ],
                        ),
                      ],
                    )
                  else
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _invoiceNumberSearchController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                                labelText: 'رقم الفاتورة',
                                border: OutlineInputBorder()),
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.search),
                          label: const Text('بحث'),
                          onPressed:
                              _isInvoiceSearchLoading ? null : _searchInvoices,
                        ),
                      ],
                    ),
                  const SizedBox(height: 12),
                  if (_isInvoiceSearchLoading)
                    const Center(child: CircularProgressIndicator())
                  else
                    const SizedBox.shrink(),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Text('الفواتير المحفوظة',
                    style: Theme.of(context).textTheme.titleMedium),
              ),
              _ExportButtons(
                reportType: 'الفواتير المحفوظة',
                onExportExcel: _savedInvoices.isEmpty
                    ? null
                    : _exportSavedInvoicesExcel,
                onExportPdf: _savedInvoices.isEmpty
                    ? null
                    : _exportSavedInvoicesPdf,
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (_savedInvoices.isEmpty)
            const Text('لا توجد فواتير محفوظة')
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowColor: WidgetStatePropertyAll(
                  Theme.of(context).colorScheme.surfaceContainerHighest),
                border: TableBorder.all(
                  color: Theme.of(context).dividerColor.withOpacity(0.35)),
                dataRowMinHeight: 36,
                dataRowMaxHeight: 40,
                headingRowHeight: 38,
                columnSpacing: 20,
                horizontalMargin: 12,
                columns: const [
                  DataColumn(label: Text('تاريخ الفاتورة')),
                  DataColumn(label: Text('رقم الفاتورة')),
                  DataColumn(label: Text('جهة التموين')),
                  DataColumn(label: Text('الفترة')),
                  DataColumn(label: Text('الإجمالي')),
                  DataColumn(label: Text('الإجراءات')),
                ],
                rows: _sortedSavedInvoices().map((invoice) {
                  final invoiceId = invoice['id'] as int;
                  final openDetails = () => _loadInvoiceDetails(invoice);
                  return DataRow(cells: [
                    DataCell(
                        Text(invoice['end_date']?.toString() ??
                          invoice['created_at']?.toString() ??
                          invoice['start_date']?.toString() ?? ''),
                      onTap: openDetails,
                    ),
                    DataCell(
                      Text(invoice['invoice_number']?.toString() ?? ''),
                      onTap: openDetails,
                    ),
                    DataCell(
                      Text(invoice['station']?.toString() ?? ''),
                      onTap: openDetails,
                    ),
                    DataCell(
                      Text('${invoice['start_date'] ?? ''} إلى '
                          '${invoice['end_date'] ?? ''}'),
                      onTap: openDetails,
                    ),
                    DataCell(
                      Text(invoice['total_amount']?.toString() ?? ''),
                      onTap: openDetails,
                    ),
                    DataCell(Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          tooltip: 'معلومات الفاتورة',
                          icon: const Icon(Icons.info_outline),
                          onPressed: () => _showInvoiceInfo(invoice),
                        ),
                        IconButton(
                          tooltip: 'تعديل الفاتورة',
                          icon: const Icon(Icons.edit_outlined),
                          onPressed: openDetails,
                        ),
                        IconButton(
                          tooltip: 'حذف الفاتورة',
                          color: Colors.red,
                          icon: const Icon(Icons.delete_forever_outlined),
                          onPressed: () => _deleteInvoice(invoiceId),
                        ),
                      ],
                    )),
                  ]);
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }
}

class PeriodReportTab extends StatefulWidget {
  final List<Vehicle> vehicles;
  final List<Refuel> allRefuels;
  final String? vehicleQuery;
  final String? globalFuelType;

  const PeriodReportTab(
      {required this.vehicles,
      required this.allRefuels,
      this.vehicleQuery,
      this.globalFuelType,
      super.key});

  @override
  State<PeriodReportTab> createState() => _PeriodReportTabState();
}

class _PeriodReportTabState extends State<PeriodReportTab> {
  DateTime? _startDate;
  DateTime? _endDate;
  Map<String, dynamic>? _apiResult;
  Map<String, dynamic>? _optimizedData; // تخزين البيانات المحسوبة
  bool _isLoading = false;
  int? _filterVehicleId;
  String? _lastVehicleQuery;
  String? _lastGlobalFuelType;
  
  final Map<int, FocusNode> _vehicleTableFocusNodes = {};
  final Map<int, int?> _highlightedRefuelIndexes = {};

  void _handleVehicleTableKey(
      KeyEvent event, int vehicleId, int rowCount) {
    if (event is! KeyDownEvent || rowCount == 0) return;

    final currentIndex = _highlightedRefuelIndexes[vehicleId];
    int? nextIndex;
    if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      nextIndex = ((currentIndex ?? -1) + 1).clamp(0, rowCount - 1);
    } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      nextIndex = ((currentIndex ?? rowCount) - 1).clamp(0, rowCount - 1);
    } else if (event.logicalKey == LogicalKeyboardKey.enter) {
      nextIndex = currentIndex ?? 0;
    }

    if (nextIndex != null) {
      setState(() => _highlightedRefuelIndexes[vehicleId] = nextIndex);
    }
  }

  void _updateOptimizedDataWithCurrentFilters() {
    if (_apiResult == null || _optimizedData == null) return;
    
    final optimizedData = ReportsCalculations.optimizePeriodReportData(
      _apiResult!,
      vehicleQuery: widget.vehicleQuery,
      globalFuelType: widget.globalFuelType,
    );
    
    setState(() {
      _optimizedData = optimizedData;
      _lastVehicleQuery = widget.vehicleQuery;
      _lastGlobalFuelType = widget.globalFuelType;
    });
  }

  @override
  void didUpdateWidget(PeriodReportTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // إذا تغير الفلتر (vehicleQuery أو globalFuelType)، أعد حساب البيانات تلقائياً
    if ((oldWidget.vehicleQuery != widget.vehicleQuery ||
        oldWidget.globalFuelType != widget.globalFuelType) &&
        _apiResult != null) {
      _updateOptimizedDataWithCurrentFilters();
    }
  }

  Future<void> _selectDate(BuildContext context, bool isStart) async {
    final picked = await showDatePicker(
        context: context,
        initialDate: DateTime.now(),
        firstDate: DateTime(2020),
        lastDate: DateTime.now(),
        locale: const Locale('ar'));
    if (picked != null)
      setState(() => isStart ? _startDate = picked : _endDate = picked);
  }

  Future<void> _generateReport() async {
    if (_startDate == null || _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('يرجى تحديد تاريخ البداية والنهاية')));
      return;
    }
    if (_endDate!.isBefore(_startDate!)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('تاريخ النهاية يجب أن يكون بعد تاريخ البداية')));
      return;
    }
    setState(() => _isLoading = true);
    try {
      final token = Provider.of<AuthProvider>(context, listen: false).token;
      if (token == null) throw Exception('unauth');
      final apiResult =
          await ApiService.getRangeReport(token, _startDate!, _endDate!);
      if (!mounted) return;
      
      // استخدام دالة محسّنة لحساب البيانات مرة واحدة فقط
      // بدلاً من إعادة الحسابات في render و export
      final optimizedData = ReportsCalculations.optimizePeriodReportData(
        apiResult,
        vehicleQuery: widget.vehicleQuery,
        globalFuelType: widget.globalFuelType,
      );
      
      setState(() {
        _apiResult = apiResult;
        _optimizedData = optimizedData; // تخزين البيانات المحسوبة
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('خطأ: ${e.toString()}')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final vehicles = widget.vehicles;
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const SizedBox.shrink(),
                const SizedBox(height: 12),
                Focus(
                  onKeyEvent: (node, event) {
                    if (event is KeyDownEvent &&
                        event.logicalKey == LogicalKeyboardKey.enter) {
                      if (!_isLoading) _generateReport();
                      return KeyEventResult.handled;
                    }
                    return KeyEventResult.ignored;
                  },
                  child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(children: [
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final isCompact = constraints.maxWidth < 720;
                          return isCompact
                              ? Column(
                                  children: [
                                    TextButton.icon(
                                        icon: const Icon(Icons.calendar_today),
                                        label: Text(_startDate != null
                                            ? DateFormat('dd/MM/yyyy')
                                                .format(_startDate!)
                                            : 'من تاريخ'),
                                        onPressed: () => _selectDate(context, true)),
                                    const SizedBox(height: 8),
                                    TextButton.icon(
                                        icon: const Icon(Icons.calendar_today),
                                        label: Text(_endDate != null
                                            ? DateFormat('dd/MM/yyyy').format(_endDate!)
                                            : 'إلى تاريخ'),
                                        onPressed: () => _selectDate(context, false)),
                                  ],
                                )
                              : Row(
                                  children: [
                                    Expanded(
                                        child: TextButton.icon(
                                            icon: const Icon(Icons.calendar_today),
                                            label: Text(_startDate != null
                                                ? DateFormat('dd/MM/yyyy')
                                                    .format(_startDate!)
                                                : 'من تاريخ'),
                                            onPressed: () =>
                                                _selectDate(context, true))),
                                    const SizedBox(width: 8),
                                    Expanded(
                                        child: TextButton.icon(
                                            icon: const Icon(Icons.calendar_today),
                                            label: Text(_endDate != null
                                                ? DateFormat('dd/MM/yyyy')
                                                    .format(_endDate!)
                                                : 'إلى تاريخ'),
                                            onPressed: () =>
                                                _selectDate(context, false))),
                                  ],
                                );
                        },
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                              icon: const Icon(Icons.search),
                              label: const Text('عرض التقرير'),
                              onPressed: _isLoading ? null : _generateReport)),
                    ]),
                  ),
                  ),
                ),
                const SizedBox(height: 12),
                if (_isLoading)
                  const CircularProgressIndicator()
                else if (_optimizedData != null) ...[
                  const SizedBox(height: 12),
                  Builder(
                    builder: (context) {
                      final vehicleMap =
                          (_optimizedData!['vehicleMap'] as Map<int, Map<String, dynamic>>?) ??
                              {};
                      final totalVehicles = _optimizedData!['totalVehicles'] as int? ?? 0;
                      final totalRefuels = _optimizedData!['totalRefuels'] as int? ?? 0;
                      final totalLiters =
                          (_optimizedData!['totalLiters'] as num?)?.toDouble() ?? 0.0;

                      if (vehicleMap.isEmpty) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Text(
                            'لا توجد بيانات للفترة المختارة',
                            style: TextStyle(fontSize: 14, color: Colors.grey),
                          ),
                        );
                      }

                      double totalLitersAll = 0;
                      for (final vehicle in vehicleMap.values) {
                        final refuels = vehicle['refuels'] as List? ?? const [];
                        for (final refuel in refuels) {
                          totalLitersAll += ((refuel['liters'] ?? 0.0) as num).toDouble();
                        }
                      }

                      return Card(
                        elevation: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'ملخص التقرير',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  _ExportButtons(
                                    reportType: 'كميات',
                                    dateRange: _startDate != null && _endDate != null
                                        ? "${DateFormat('dd-MM-yyyy').format(_startDate!)}_to_${DateFormat('dd-MM-yyyy').format(_endDate!)}"
                                        : null,
                                    onExportExcel: () async {
                                      final headers = [
                                        'رقم السيارة',
                                        'الأحرف',
                                        'المحطة',
                                        'التاريخ',
                                        'العداد',
                                        'اللترات',
                                        'النسبة الفعلية',
                                      ];
                                      final rows = <List<dynamic>>[];
                                      for (final vehicle in vehicleMap.values) {
                                        final refuels = vehicle['refuels'] as List? ?? const [];
                                        for (var index = 0; index < refuels.length; index++) {
                                          final refuel = refuels[index] as Map<String, dynamic>;
                                          final currentOdometer = ((refuel['odometer'] ?? refuel['current_odometer'] ?? 0) is num)
                                              ? (refuel['odometer'] ?? refuel['current_odometer'] ?? 0).toDouble()
                                              : double.tryParse(refuel['odometer']?.toString() ?? refuel['current_odometer']?.toString() ?? '0') ?? 0.0;
                                          final previousOdometer = index > 0
                                              ? (((refuels[index - 1]['odometer'] ?? refuels[index - 1]['current_odometer'] ?? 0) is num)
                                                  ? (refuels[index - 1]['odometer'] ?? refuels[index - 1]['current_odometer'] ?? 0).toDouble()
                                                  : double.tryParse(refuels[index - 1]['odometer']?.toString() ?? refuels[index - 1]['current_odometer']?.toString() ?? '0') ?? 0.0)
                                              : null;
                                          final liters = ((refuel['liters'] ?? refuel['total_liters'] ?? 0) is num)
                                              ? (refuel['liters'] ?? refuel['total_liters'] ?? 0).toDouble()
                                              : double.tryParse(refuel['liters']?.toString() ?? refuel['total_liters']?.toString() ?? '0') ?? 0.0;
                                          final ratio = ReportsCalculations.calculateRefuelConsumptionRatio(
                                            liters,
                                            currentOdometer,
                                            previousOdometer,
                                          );
                                          rows.add([
                                            vehicle['number'],
                                            vehicle['letters'],
                                            refuel['station'] ?? 'غير محدد',
                                            refuel['date'] ?? refuel['created_at'] ?? refuel['createdAt'] ?? '',
                                            currentOdometer,
                                            liters,
                                            ratio == 0 ? 0.0 : double.parse(ratio.toStringAsFixed(2)),
                                          ]);
                                        }
                                      }
                                      await _writeExcelFile(
                                        context,
                                        headers,
                                        rows,
                                        'quantity_${_startDate!.toIso8601String().split('T').first}_${_endDate!.toIso8601String().split('T').first}',
                                      );
                                    },
                                    onExportPdf: () async {
                                      final headers = [
                                        'رقم السيارة',
                                        'الأحرف',
                                        'التاريخ',
                                        'العداد',
                                        'اللترات',
                                        'النسبة الفعلية',
                                      ];
                                      final rows = <List<dynamic>>[];
                                      for (final vehicle in vehicleMap.values) {
                                        final refuels = vehicle['refuels'] as List? ?? const [];
                                        for (var index = 0; index < refuels.length; index++) {
                                          final refuel = refuels[index] as Map<String, dynamic>;
                                          final currentOdometer = ((refuel['odometer'] ?? refuel['current_odometer'] ?? 0) is num)
                                              ? (refuel['odometer'] ?? refuel['current_odometer'] ?? 0).toDouble()
                                              : double.tryParse(refuel['odometer']?.toString() ?? refuel['current_odometer']?.toString() ?? '0') ?? 0.0;
                                          final previousOdometer = index > 0
                                              ? (((refuels[index - 1]['odometer'] ?? refuels[index - 1]['current_odometer'] ?? 0) is num)
                                                  ? (refuels[index - 1]['odometer'] ?? refuels[index - 1]['current_odometer'] ?? 0).toDouble()
                                                  : double.tryParse(refuels[index - 1]['odometer']?.toString() ?? refuels[index - 1]['current_odometer']?.toString() ?? '0') ?? 0.0)
                                              : null;
                                          final liters = ((refuel['liters'] ?? refuel['total_liters'] ?? 0) is num)
                                              ? (refuel['liters'] ?? refuel['total_liters'] ?? 0).toDouble()
                                              : double.tryParse(refuel['liters']?.toString() ?? refuel['total_liters']?.toString() ?? '0') ?? 0.0;
                                          final ratio = ReportsCalculations.calculateRefuelConsumptionRatio(
                                            liters,
                                            currentOdometer,
                                            previousOdometer,
                                          );
                                          rows.add([
                                            vehicle['number'],
                                            vehicle['letters'],
                                            refuel['date'] ?? refuel['created_at'] ?? refuel['createdAt'] ?? '',
                                            currentOdometer.toString(),
                                            liters.toString(),
                                            ratio == 0 ? '-' : ratio.toStringAsFixed(2),
                                          ]);
                                        }
                                      }
                                      await _writePdfFile(
                                        context,
                                        headers,
                                        rows,
                                        'quantity_${_startDate!.toIso8601String().split('T').first}_${_endDate!.toIso8601String().split('T').first}',
                                      );
                                    },
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                  border: material.Border.all(color: Colors.blue.shade200),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(Icons.directions_car, color: Colors.blue.shade700),
                                        const SizedBox(width: 8),
                                        Text(
                                          'عدد السيارات: $totalVehicles',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.blue.shade900,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Icon(Icons.local_gas_station, color: Colors.blue.shade700),
                                        const SizedBox(width: 8),
                                        Text(
                                          'إجمالي التفويلات: $totalRefuels',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.blue.shade900,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Icon(Icons.opacity, color: Colors.green.shade700),
                                        const SizedBox(width: 8),
                                        Text(
                                          'إجمالي اللترات: ${totalLitersAll.toStringAsFixed(1)} لتر',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.green.shade900,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ],
            ),
          ),
        ),
        if (_optimizedData != null)
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final vehicleMap =
                      (_optimizedData!['vehicleMap'] as Map<int, Map<String, dynamic>>?) ??
                          {};
                  final vehicleEntries = vehicleMap.entries.toList();
                  
                  if (index >= vehicleEntries.length) return null;
                  
                  final entry = vehicleEntries[index];
                  final vehicleId = entry.key;
                  final vehicle = entry.value;
                  final refuels = vehicle['refuels'] as List? ?? const [];
                  final focusNode = _vehicleTableFocusNodes.putIfAbsent(
                    vehicleId,
                    () => FocusNode(debugLabel: 'period-vehicle-$vehicleId'),
                  );
                  final highlightedIndex = _highlightedRefuelIndexes[vehicleId];
                  double vehicleTotalLiters = 0;
                  for (final refuel in refuels) {
                    vehicleTotalLiters += ((refuel['liters'] ?? 0.0) as num).toDouble();
                  }

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Card(
                      elevation: 1,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: const BorderSide(color: Color(0xFFE0E0E0), width: 0.5),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '${vehicle['number']} ${vehicle['letters']}',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue.shade900,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.green.shade100,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      'إجمالي: ${vehicleTotalLiters.toStringAsFixed(1)} لتر',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green.shade800,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () => focusNode.requestFocus(),
                              child: Focus(
                                focusNode: focusNode,
                                onKeyEvent: (node, event) {
                                  _handleVehicleTableKey(event, vehicleId, refuels.length);
                                  return KeyEventResult.handled;
                                },
                                child: LayoutBuilder(
                                  builder: (context, constraints) {
                                    return SingleChildScrollView(
                                      scrollDirection: Axis.horizontal,
                                      child: ConstrainedBox(
                                        constraints: BoxConstraints(
                                          minWidth: constraints.maxWidth,
                                        ),
                                        child: DataTable(
                                          headingRowColor: WidgetStateColor.resolveWith(
                                            (states) => Colors.grey.shade100,
                                          ),
                                          headingRowHeight: 44,
                                          dataRowHeight: 46,
                                          dataTextStyle: const TextStyle(fontSize: 14),
                                          columnSpacing: 22,
                                          border: TableBorder(
                                            horizontalInside: BorderSide(
                                              color: Colors.grey.shade300,
                                              width: 0.5,
                                            ),
                                            top: BorderSide(
                                              color: Colors.grey.shade300,
                                              width: 0.5,
                                            ),
                                            bottom: BorderSide(
                                              color: Colors.grey.shade300,
                                              width: 0.5,
                                            ),
                                          ),
                                          columns: [
                                            DataColumn(
                                              label: Text('م', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.grey.shade700)),
                                            ),
                                            DataColumn(
                                              label: Text('التاريخ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.grey.shade700)),
                                            ),
                                            DataColumn(
                                              label: Text('العداد', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.grey.shade700)),
                                              numeric: true,
                                            ),
                                            DataColumn(
                                              label: Text('اللترات', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.grey.shade700)),
                                              numeric: true,
                                            ),
                                            DataColumn(
                                              label: Text('النسبة', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.grey.shade700)),
                                              numeric: true,
                                            ),
                                            DataColumn(
                                              label: Text('المحطة', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.grey.shade700)),
                                            ),
                                          ],
                                          rows: refuels.asMap().entries.map((entry) {
                                            final index = entry.key;
                                            final refuel = entry.value as Map<String, dynamic>;
                                            final dateValue = refuel['date'] ?? refuel['created_at'] ?? refuel['createdAt'] ?? '-';
                                            final litersValue = refuel['liters'] ?? refuel['total_liters'] ?? 0;
                                            final odometerValue = refuel['odometer'] ?? refuel['current_odometer'] ?? 0;
                                            final previousOdometer = index > 0
                                                ? (((refuels[index - 1]['odometer'] ?? refuels[index - 1]['current_odometer'] ?? 0) is num)
                                                        ? (refuels[index - 1]['odometer'] ?? refuels[index - 1]['current_odometer'] ?? 0).toDouble()
                                                        : double.tryParse(refuels[index - 1]['odometer']?.toString() ?? refuels[index - 1]['current_odometer']?.toString() ?? '0') ?? 0.0)
                                                : null;
                                            final ratioValue = ReportsCalculations.calculateRefuelConsumptionRatio(
                                              litersValue is num
                                                  ? litersValue.toDouble()
                                                  : double.tryParse(litersValue.toString()) ?? 0.0,
                                              odometerValue is num
                                                  ? odometerValue.toDouble()
                                                  : double.tryParse(odometerValue.toString()) ?? 0.0,
                                              previousOdometer,
                                            );
                                            final isEvenRow = index % 2 == 0;
                                            return DataRow(
                                              selected: highlightedIndex == index,
                                              onSelectChanged: (selected) {
                                                setState(() {
                                                  _highlightedRefuelIndexes[vehicleId] =
                                                      selected == true ? index : null;
                                                });
                                                if (selected == true) {
                                                  focusNode.requestFocus();
                                                }
                                              },
                                              color: WidgetStateColor.resolveWith(
                                                (states) => states.contains(WidgetState.selected)
                                                    ? Colors.blue.shade50
                                                    : isEvenRow
                                                        ? const Color(0xFFFAFAFA)
                                                        : Colors.white,
                                              ),
                                              cells: [
                                                DataCell(Text('${index + 1}', style: const TextStyle(fontSize: 14))),
                                                DataCell(Text(dateValue.toString(), style: const TextStyle(fontSize: 14))),
                                                DataCell(Text((odometerValue is num ? odometerValue : int.tryParse(odometerValue.toString()) ?? 0).toString(), style: const TextStyle(fontSize: 14))),
                                                DataCell(Text((litersValue is num ? litersValue : double.tryParse(litersValue.toString()) ?? 0).toString(), style: const TextStyle(fontSize: 14))),
                                                DataCell(Text(ratioValue == 0 ? '-' : ratioValue.toStringAsFixed(2), style: const TextStyle(fontSize: 14))),
                                                DataCell(Text(ReportsCalculations.shortStationName((refuel['station'] ?? 'غير محدد').toString()), style: const TextStyle(fontSize: 14))),
                                              ],
                                            );
                                          }).toList(),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
                childCount: (_optimizedData!['vehicleMap'] as Map<int, Map<String, dynamic>>?)?.length ?? 0,
              ),
            ),
          ),
      ],
    );
  }

  @override
  void dispose() {
    for (final node in _vehicleTableFocusNodes.values) {
      node.dispose();
    }
    super.dispose();
  }
}

class FuelStationQuantityReportTab extends StatefulWidget {
  final List<Vehicle> vehicles;
  final List<Refuel> allRefuels;
  final String? vehicleQuery;
  final String? globalFuelType;

  const FuelStationQuantityReportTab({
    required this.vehicles,
    required this.allRefuels,
    this.vehicleQuery,
    this.globalFuelType,
    super.key,
  });

  @override
  State<FuelStationQuantityReportTab> createState() =>
      _FuelStationQuantityReportTabState();
}

class _FuelStationQuantityReportTabState
    extends State<FuelStationQuantityReportTab> {
  DateTime? _startDate;
  DateTime? _endDate;
  Map<String, dynamic>? _reportData;
  bool _isLoading = false;
  String? _selectedStation;
  final Map<String, FocusNode> _stationFocusNodes = {};
  final Map<String, int?> _highlightedRowIndexes = {};

  Future<void> _selectDate(BuildContext context, bool isStart) async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: (isStart ? _startDate : _endDate) ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      locale: const Locale('ar'),
    );
    if (pickedDate != null) {
      setState(() {
        if (isStart) {
          _startDate = pickedDate;
        } else {
          _endDate = pickedDate;
        }
        _reportData = null;
      });
    }
  }

  Future<void> _generateReport() async {
    if (_startDate == null || _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('يرجى تحديد تاريخ البداية والنهاية')));
      return;
    }
    if (_endDate!.isBefore(_startDate!)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('تاريخ النهاية يجب أن يكون بعد تاريخ البداية')));
      return;
    }

    setState(() => _isLoading = true);
    try {
      final token = Provider.of<AuthProvider>(context, listen: false).token;
      if (token == null) throw Exception('unauth');
      final result = await ApiService.getStationFuelQuantityReport(
          token, _startDate!, _endDate!);
      if (!mounted) return;
      setState(() {
        _reportData = result;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('خطأ: ${e.toString()}')));
    }
  }

  String _formatValue(dynamic value) {
    final parsed = value is num
        ? value.toDouble()
        : double.tryParse(value.toString()) ?? 0.0;
    return parsed.toStringAsFixed(1);
  }

  List<Map<String, dynamic>> _filteredStationRows() {
    final stations = ((_reportData?['stations'] as List?) ?? [])
        .cast<Map<String, dynamic>>();
    return stations.where((station) {
      final stationName = (station['station'] ?? '').toString();
      return _selectedStation == null ||
          stationsMatch(stationName, _selectedStation);
    }).toList();
  }

  Future<void> _exportStationReport(bool excel) async {
    if (_reportData == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('يرجى عرض التقرير أولًا قبل التصدير')));
      return;
    }
    final stations = _filteredStationRows();
    if (stations.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('لا توجد بيانات للتصدير حسب الفلتر الحالي')));
      return;
    }
    final headers = ['التاريخ', 'سولار', 'بنزين 92', 'بنزين 95'];
    final rows = <List<dynamic>>[];
    for (final station in stations) {
      rows.add(['محطة ${station['station']}', 0, 0, 0]);
      for (final row in (station['rows'] as List)) {
        final values = row as Map<String, dynamic>;
        rows.add([
          values['date'] ?? '',
          values['solar'] ?? 0.0,
          values['gasoline_92'] ?? 0.0,
          values['gasoline_95'] ?? 0.0,
        ]);
      }
      final totals = station['totals'] as Map<String, dynamic>;
      rows.add([
        'إجمالي الفترة للمحطة',
        totals['solar'] ?? 0.0,
        totals['gasoline_92'] ?? 0.0,
        totals['gasoline_95'] ?? 0.0,
      ]);
      rows.add(['', 0, 0, 0]);
    }
    final dateSuffix =
        '${_startDate?.toIso8601String().split('T').first}_${_endDate?.toIso8601String().split('T').first}';
    if (excel) {
      await _writeExcelFile(context, headers, rows,
          'station_fuel_quantity_$dateSuffix');
    } else {
      await _writePdfFile(
          context, headers, rows, 'station_fuel_quantity_$dateSuffix');
    }
  }

  @override
  void dispose() {
    for (final node in _stationFocusNodes.values) {
      node.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextButton.icon(
                          icon: const Icon(Icons.calendar_today),
                          label: Text(_startDate != null
                              ? DateFormat('dd/MM/yyyy').format(_startDate!)
                              : 'من تاريخ'),
                          onPressed: () => _selectDate(context, true),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton.icon(
                          icon: const Icon(Icons.calendar_today),
                          label: Text(_endDate != null
                              ? DateFormat('dd/MM/yyyy').format(_endDate!)
                              : 'إلى تاريخ'),
                          onPressed: () => _selectDate(context, false),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String?>(
                          value: _selectedStation,
                          decoration: const InputDecoration(
                            labelText: 'فلتر جهة التموين',
                            border: OutlineInputBorder(),
                          ),
                          items: [
                            const DropdownMenuItem(
                                value: null, child: Text('كل الجهات')),
                            ...fuelStations.map((station) => DropdownMenuItem(
                                value: station, child: Text(station))),
                          ],
                          onChanged: (value) =>
                              setState(() => _selectedStation = value),
                        ),
                      ),
                      const SizedBox(width: 12),
                      _ExportButtons(
                        reportType: 'كميات الوقود',
                        dateRange: _startDate != null && _endDate != null
                            ? '${DateFormat('dd-MM-yyyy').format(_startDate!)}_to_${DateFormat('dd-MM-yyyy').format(_endDate!)}'
                            : null,
                        onExportExcel: () => _exportStationReport(true),
                        onExportPdf: () => _exportStationReport(false),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.search),
                      label: const Text('عرض التقرير'),
                      onPressed: _isLoading ? null : _generateReport,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_isLoading) ...[
            const SizedBox(height: 24),
            const CircularProgressIndicator(),
          ] else if (_reportData != null) ...[
            const SizedBox(height: 24),
            Builder(builder: (context) {
              final stations = ((_reportData!['stations'] as List?) ?? [])
                  .cast<Map<String, dynamic>>();
              final filteredStations = stations.where((station) {
                final stationName = (station['station'] ?? '').toString();
                return _selectedStation == null ||
                    stationsMatch(stationName, _selectedStation);
              }).toList();
              if (filteredStations.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Text('لا توجد بيانات لهذه الجهة خلال الفترة المحددة',
                      style: TextStyle(fontSize: 14, color: Colors.grey)),
                );
              }

              final overallTotals = filteredStations.fold<Map<String, double>>(
                {'solar': 0.0, 'gasoline_92': 0.0, 'gasoline_95': 0.0},
                (acc, station) {
                  final totals = (station['totals'] as Map<String, dynamic>);
                  acc['solar'] = (acc['solar'] ?? 0.0) +
                      ((totals['solar'] ?? 0.0) as num).toDouble();
                  acc['gasoline_92'] = (acc['gasoline_92'] ?? 0.0) +
                      ((totals['gasoline_92'] ?? 0.0) as num).toDouble();
                  acc['gasoline_95'] = (acc['gasoline_95'] ?? 0.0) +
                      ((totals['gasoline_95'] ?? 0.0) as num).toDouble();
                  return acc;
                },
              );
              return TapRegion(
                onTapOutside: (_) =>
                    setState(() => _highlightedRowIndexes.clear()),
                child: Column(
                  children: [
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('إجمالي الفترة المختارة',
                                style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 12),
                            LayoutBuilder(
                              builder: (context, constraints) {
                                final isNarrow = constraints.maxWidth < 720;
                                final tileWidth = isNarrow
                                    ? constraints.maxWidth
                                    : (constraints.maxWidth - 24) / 3;
                                return Wrap(
                                  spacing: 12,
                                  runSpacing: 12,
                                  children: [
                                    SizedBox(
                                        width: tileWidth,
                                        child: _MetricTile(
                                            label: 'سولار',
                                            value:
                                                '${overallTotals['solar']!.toStringAsFixed(1)} لتر')),
                                    SizedBox(
                                        width: tileWidth,
                                        child: _MetricTile(
                                            label: 'بنزين 92',
                                            value:
                                                '${overallTotals['gasoline_92']!.toStringAsFixed(1)} لتر')),
                                    SizedBox(
                                        width: tileWidth,
                                        child: _MetricTile(
                                            label: 'بنزين 95',
                                            value:
                                                '${overallTotals['gasoline_95']!.toStringAsFixed(1)} لتر')),
                                  ],
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ...filteredStations.map((station) {
                      final stationRows = (station['rows'] as List)
                          .cast<Map<String, dynamic>>();
                      final totals =
                          (station['totals'] as Map<String, dynamic>);
                      final stationKey =
                          (station['station'] ?? 'station').toString();
                      final focusNode = _stationFocusNodes.putIfAbsent(
                          stationKey,
                          () => FocusNode(debugLabel: 'station-$stationKey'));
                      final highlightedIndex =
                          _highlightedRowIndexes[stationKey];
                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('محطة ${station['station']}',
                                  style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold)),
                              const SizedBox(height: 12),
                              SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Focus(
                                  focusNode: focusNode,
                                  onKeyEvent: (node, event) {
                                    if (event is KeyDownEvent &&
                                        stationRows.isNotEmpty) {
                                      if (event.logicalKey ==
                                          LogicalKeyboardKey.arrowDown) {
                                        final nextIndex =
                                            (highlightedIndex ?? -1) + 1;
                                        final safeIndex =
                                            nextIndex < stationRows.length
                                                ? nextIndex
                                                : stationRows.length - 1;
                                        setState(() =>
                                            _highlightedRowIndexes[stationKey] =
                                                safeIndex);
                                        return KeyEventResult.handled;
                                      }
                                      if (event.logicalKey ==
                                          LogicalKeyboardKey.arrowUp) {
                                        final prevIndex =
                                            (highlightedIndex ?? 0) - 1;
                                        final safeIndex =
                                            prevIndex >= 0 ? prevIndex : 0;
                                        setState(() =>
                                            _highlightedRowIndexes[stationKey] =
                                                safeIndex);
                                        return KeyEventResult.handled;
                                      }
                                    }
                                    return KeyEventResult.ignored;
                                  },
                                  child: GestureDetector(
                                    behavior: HitTestBehavior.opaque,
                                    onTap: () => focusNode.requestFocus(),
                                    child: ConstrainedBox(
                                      constraints: BoxConstraints(
                                        minWidth:
                                            MediaQuery.sizeOf(context).width -
                                                56,
                                      ),
                                      child: DataTable(
                                        columnSpacing:
                                          MediaQuery.sizeOf(context).width >= 720
                                            ? 72
                                            : 40,
                                      dataTextStyle: const TextStyle(
                                        fontSize: 15,
                                      ),
                                      columns: const [
                                        DataColumn(label: Text('التاريخ')),
                                        DataColumn(
                                            label: Text('سولار'),
                                            numeric: true),
                                        DataColumn(
                                            label: Text('بنزين 92'),
                                            numeric: true),
                                        DataColumn(
                                            label: Text('بنزين 95'),
                                            numeric: true),
                                      ],
                                      rows: [
                                        ...stationRows
                                            .asMap()
                                            .entries
                                            .map((entry) {
                                          final index = entry.key;
                                          final row = entry.value;
                                          final isSelected =
                                              highlightedIndex == index;
                                          return DataRow(
                                            selected: isSelected,
                                            color: isSelected
                                                ? WidgetStatePropertyAll<Color>(
                                                    Colors.blue.shade50)
                                                : null,
                                            onSelectChanged: (selected) {
                                              if (selected == true) {
                                                setState(() {
                                                  _highlightedRowIndexes[
                                                      stationKey] = index;
                                                });
                                                focusNode.requestFocus();
                                              } else {
                                                setState(() {
                                                  _highlightedRowIndexes
                                                      .remove(stationKey);
                                                });
                                              }
                                            },
                                            cells: [
                                              DataCell(Text(
                                                  row['date']?.toString() ??
                                                      '')),
                                              DataCell(Text(
                                                  _formatValue(row['solar']))),
                                              DataCell(Text(_formatValue(
                                                  row['gasoline_92']))),
                                              DataCell(Text(_formatValue(
                                                  row['gasoline_95']))),
                                            ],
                                          );
                                        }),
                                        DataRow(cells: [
                                          DataCell(Text('إجمالي الفترة للمحطة',
                                              style: const TextStyle(
                                                  fontWeight:
                                                  FontWeight.bold,
                                                color: Color(0xFF0D47A1)))),
                                          DataCell(Text(
                                              _formatValue(totals['solar']),
                                              style: const TextStyle(
                                                  fontWeight:
                                                  FontWeight.bold,
                                                color: Color(0xFF0D47A1)))),
                                          DataCell(Text(
                                              _formatValue(
                                                  totals['gasoline_92']),
                                              style: const TextStyle(
                                                  fontWeight:
                                                  FontWeight.bold,
                                                color: Color(0xFF0D47A1)))),
                                          DataCell(Text(
                                              _formatValue(
                                                  totals['gasoline_95']),
                                              style: const TextStyle(
                                                  fontWeight:
                                                  FontWeight.bold,
                                                color: Color(0xFF0D47A1)))),
                                        ]),
                                      ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }
}

Map<String, double> calculateFuelSummaryTotals(
    List<Map<String, dynamic>> records) {
  double gasoline92 = 0.0;
  double gasoline95 = 0.0;
  double solar = 0.0;
  double gas = 0.0;

  for (final record in records) {
    final recFuel =
        (record['fuel_type'] ?? record['fuelType'] ?? '').toString();
    final litersRaw = record['liters'] ??
        record['total_liters'] ??
        record['totalLiters'] ??
        0;
    final liters = litersRaw is num
        ? litersRaw.toDouble()
        : double.tryParse(litersRaw.toString()) ?? 0.0;

    final gasRaw = record['gas_quantity'] ??
        record['gasQuantity'] ??
        record['quantity'] ??
        0;
    final gasQuantity = gasRaw is num
        ? gasRaw.toDouble()
        : double.tryParse(gasRaw.toString()) ?? 0.0;

    if (recFuel == 'بنزين 92') {
      gasoline92 += liters - gasQuantity;
    } else if (recFuel == 'بنزين 95') {
      gasoline95 += liters;
    } else if (recFuel == 'سولار') {
      solar += liters;
    }

    if (recFuel == 'غاز' || gasQuantity > 0) {
      gas += gasQuantity;
    }
  }

  return {
    'gasoline92': gasoline92.clamp(0.0, double.infinity),
    'gasoline95': gasoline95,
    'solar': solar,
    'gas': gas,
  };
}

class QuantityReportTab extends StatefulWidget {
  final List<Vehicle> vehicles;
  final List<Refuel> allRefuels;
  final String? vehicleQuery;
  final String? globalFuelType;

  const QuantityReportTab({
    required this.vehicles,
    required this.allRefuels,
    this.vehicleQuery,
    this.globalFuelType,
    super.key,
  });

  @override
  State<QuantityReportTab> createState() => _QuantityReportTabState();
}

class _QuantityReportTabState extends State<QuantityReportTab> {
  DateTime? _startDate;
  DateTime? _endDate;
  int? _selectedVehicleId;
  String? _selectedStatusFilter;
  Map<String, dynamic>? _apiResult;
  Map<String, dynamic>? _optimizedData;
  bool _isLoading = false;
  String? _lastVehicleQuery;
  String? _lastGlobalFuelType;
  final FocusNode _quantityTableFocusNode = FocusNode();
  int? _highlightedRowIndex;

  void _updateOptimizedDataWithCurrentFilters() {
    if (_apiResult == null || _optimizedData == null) return;
    
    final filtered = _filteredQuantityRecords();
    
    setState(() {
      _optimizedData = {
        'records': filtered,
        'totalRecords': filtered.length,
      };
      _lastVehicleQuery = widget.vehicleQuery;
      _lastGlobalFuelType = widget.globalFuelType;
    });
  }

  @override
  void didUpdateWidget(QuantityReportTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if ((oldWidget.vehicleQuery != widget.vehicleQuery ||
        oldWidget.globalFuelType != widget.globalFuelType) &&
        _apiResult != null) {
      _updateOptimizedDataWithCurrentFilters();
    }
  }

  Vehicle? _vehicleForRecord(Map<String, dynamic> record) {
    final vehicleId = record['vehicle_id'] ?? record['vehicleId'];
    final parsedVehicleId = vehicleId is int
        ? vehicleId
        : int.tryParse(vehicleId?.toString() ?? '');
    if (parsedVehicleId != null) {
      final matches =
          widget.vehicles.where((vehicle) => vehicle.id == parsedVehicleId);
      return matches.isEmpty ? null : matches.first;
    }
    return null;
  }

  bool _matchesStatusFilter(Map<String, dynamic> record) {
    final selectedValue = _selectedStatusFilter;
    if (selectedValue == null || selectedValue.isEmpty) {
      return true;
    }

    final status = (record['status'] ?? '').toString().trim();
    final statusCode =
        (record['status_code'] ?? '').toString().trim().toLowerCase();

    switch (selectedValue) {
      case 'natural':
        return status == 'طبيعي' || statusCode == 'natural';
      case 'excess':
        return status == 'تجاوز' ||
            status == 'متجاوز' ||
            statusCode == 'excess';
      case 'illogical':
        return status == 'غير منطقي' ||
            status == 'نسبة غير منطقية' ||
            status == 'مراجعة' ||
            statusCode == 'illogical';
      default:
        return true;
    }
  }

  List<Map<String, dynamic>> _filteredQuantityRecords() {
    final records = ((_apiResult?['records'] as List?) ?? [])
        .cast<Map<String, dynamic>>();
    return records.where((record) {
      if (widget.vehicleQuery != null && widget.vehicleQuery!.isNotEmpty) {
        final query = widget.vehicleQuery!.toLowerCase();
        final number = (record['vehicle_number'] ?? record['number'] ?? '')
            .toString()
            .toLowerCase();
        final registry =
            (record['registry'] ?? record['vehicle_registry'] ?? '')
                .toString()
                .toLowerCase();
        if (!number.contains(query) && !registry.contains(query)) return false;
      }
      if (widget.globalFuelType != null &&
          (record['fuel_type'] ?? record['fuelType'] ?? '') !=
              widget.globalFuelType) {
        return false;
      }
      return _matchesStatusFilter(record);
    }).toList();
  }

  ({List<String> headers, List<List<dynamic>> rows})
      _buildFuelingDetailsSheet(List<Map<String, dynamic>> records) {
    final stations = <String>[...fuelStations];
    for (final record in records) {
      final details = (record['details'] as List?) ?? [];
      for (final detail in details) {
        final station = (detail['station'] ??
                detail['station_name'] ??
                detail['stationName'] ??
                'غير محدد')
            .toString()
            .trim();
        if (station.isNotEmpty &&
          !stationsMatch(station, 'غاز') &&
          !stationsMatchAny(station, stations)) {
          stations.add(station);
        }
      }
    }

    final headers = [
      'م',
      'رقم السيارة',
      ...stations,
      'غاز',
      'الإجمالي',
      'نوع البنزين',
    ];
    final rows = records.asMap().entries.map((entry) {
      final record = entry.value;
      final stationTotals = <String, double>{};
      final details = (record['details'] as List?) ?? [];
      for (final detail in details) {
        final station = (detail['station'] ??
                detail['station_name'] ??
                detail['stationName'] ??
                'غير محدد')
            .toString()
            .trim();
        final liters = _numberValue(
          detail['liters'] ?? detail['total_liters'],
        );
        final matchingStation = stations.firstWhere(
          (knownStation) => stationsMatch(knownStation, station),
          orElse: () => station,
        );
        stationTotals[matchingStation] =
            (stationTotals[matchingStation] ?? 0) + liters;
      }

      final gas = _numberValue(
        record['gas_quantity'] ?? record['gasQuantity'],
      );
      final stationTotal =
          stationTotals.values.fold(0.0, (sum, value) => sum + value);
      final total = record['total_liters'] == null
          ? stationTotal + gas
          : _numberValue(record['total_liters']);
      return [
        entry.key + 1,
        record['vehicle_number'] ?? record['number'] ?? '',
        ...stations.map((station) => stationTotals[station] ?? 0.0),
        gas,
        total,
        record['fuel_type'] ?? record['fuelType'] ?? '',
      ];
    }).toList();

    final totals = <double>[...stations.map((station) {
      return rows.fold(0.0, (sum, row) {
        final stationIndex = 2 + stations.indexOf(station);
        return sum + _numberValue(row[stationIndex]);
      });
    }), 0.0, 0.0];
    for (final row in rows) {
      totals[stations.length] += _numberValue(row[2 + stations.length]);
      totals[stations.length + 1] +=
          _numberValue(row[3 + stations.length]);
    }
    rows.add([
      '',
      'إجمالي الكمية',
      ...totals,
      '',
    ]);

    return (headers: headers, rows: rows);
  }

  Future<void> _exportQuantityReport(BuildContext context, bool excel) async {
    final records = _filteredQuantityRecords();
    final headers = [
      'م',
      'رقم السجل',
      'رقم السيارة',
      'الأحرف',
      'الكمية الإجمالية',
      'عداد البداية',
      'آخر عداد بالفترة',
      'المسافة',
      'النسبة',
      'النسبة القياسية',
      'نسبة التجاوز',
      'الحالة',
    ];
    final rows = records.asMap().entries.map((entry) {
      final record = entry.value;
      final actualRatio = _numberValue(
        record['consumption_ratio'] ?? record['ratio'],
      );
      final standardRatio = _standardRatioForRecord(record);
      final excessRatio = _isExcessRecord(record)
          ? double.parse((actualRatio - standardRatio).toStringAsFixed(2))
          : null;
      final values = [
        entry.key + 1,
        record['registry'] ?? record['vehicle_registry'] ?? '',
        record['vehicle_number'] ?? record['number'] ?? '',
        record['vehicle_letters'] ?? record['letters'] ?? '',
        record['total_liters'] ?? 0,
        record['start_odometer'] ?? 0,
        record['end_odometer'] ?? 0,
        record['distance'] ?? 0,
        actualRatio,
        standardRatio,
        excessRatio,
        record['status'] ?? 'طبيعي',
      ];
      return excel
          ? values.map(_excelCellValue).toList()
          : values.map((value) => value.toString()).toList();
    }).toList();
    final dateSuffix =
        '${_startDate?.toIso8601String().split('T').first}_${_endDate?.toIso8601String().split('T').first}';
    if (excel) {
      final fuelingDetails = _buildFuelingDetailsSheet(records);
      await _writeExcelFile(
        context,
        headers,
        rows,
        'ratio_$dateSuffix',
        additionalSheets: [
          _ExcelSheetData(
            name: 'تفاصيل التموينات',
            headers: fuelingDetails.headers,
            rows: fuelingDetails.rows,
          ),
        ],
      );
    } else {
      await _writePdfFile(context, headers, rows, 'ratio_$dateSuffix');
    }
  }

  Future<void> _selectDate(BuildContext context, bool isStart) async {
    final initialDate = isStart ? _startDate : _endDate;
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      locale: const Locale('ar'),
    );
    if (pickedDate != null) {
      setState(() {
        if (isStart) {
          _startDate = pickedDate;
        } else {
          _endDate = pickedDate;
        }
        _apiResult = null;
      });
    }
  }

  Future<void> _generateReport() async {
    if (_startDate == null || _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('يرجى تحديد تاريخ البداية والنهاية')));
      return;
    }

    if (_endDate!.isBefore(_startDate!)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('تاريخ النهاية يجب أن يكون بعد تاريخ البداية')));
      return;
    }

    setState(() => _isLoading = true);
    try {
      final token = Provider.of<AuthProvider>(context, listen: false).token;
      if (token == null) throw Exception('unauth');
      final apiResult =
          await ApiService.getRangeReport(token, _startDate!, _endDate!)
              .timeout(const Duration(seconds: 15),
                  onTimeout: () =>
                      throw Exception('انتهت المهلة الزمنية لتحميل التقرير'));
      if (!mounted) return;
      
      // حساب البيانات المحسّنة
      final filtered = ((apiResult['records'] as List?) ?? [])
          .cast<Map<String, dynamic>>()
          .where((record) {
            if (widget.vehicleQuery != null && widget.vehicleQuery!.isNotEmpty) {
              final query = widget.vehicleQuery!.toLowerCase();
              final number = (record['vehicle_number'] ?? record['number'] ?? '')
                  .toString()
                  .toLowerCase();
              final registry =
                  (record['registry'] ?? record['vehicle_registry'] ?? '')
                      .toString()
                      .toLowerCase();
              if (!number.contains(query) && !registry.contains(query)) return false;
            }
            if (widget.globalFuelType != null &&
                (record['fuel_type'] ?? record['fuelType'] ?? '') !=
                    widget.globalFuelType) {
              return false;
            }
            return _matchesStatusFilter(record);
          })
          .toList();
      
      setState(() {
        _apiResult = apiResult;
        _optimizedData = {
          'records': filtered,
          'totalRecords': filtered.length,
        };
        _lastVehicleQuery = widget.vehicleQuery;
        _lastGlobalFuelType = widget.globalFuelType;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('خطأ: ${e.toString()}')));
    }
  }

  double _numberValue(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse('$value') ?? 0.0;
  }

  double _standardRatioForRecord(Map<String, dynamic> record) {
    final recordStandard = record['standard_consumption'] ??
        record['standardConsumption'] ??
        record['standard_ratio'];
    final standardRatio = _numberValue(recordStandard);
    if (standardRatio > 0) return standardRatio;
    return _vehicleForRecord(record)?.standardConsumption ?? 0.0;
  }

  bool _isExcessRecord(Map<String, dynamic> record) {
    final status = (record['status'] ?? '').toString().trim();
    final statusCode =
        (record['status_code'] ?? '').toString().trim().toLowerCase();
    return status == 'متجاوز' ||
        status == 'تجاوز' ||
        statusCode == 'excess' ||
        ReportsCalculations.isExcessConsumption(
          _numberValue(record['consumption_ratio'] ?? record['ratio']),
          _standardRatioForRecord(record),
        );
  }

  Future<void> _showConsumptionDetails(Map<String, dynamic> record) async {
    final sourceRows = ((record['fuel_sources'] as List?) ?? [])
        .whereType<Map>()
        .map((source) => {
              'source': (source['source'] ?? 'غير محدد').toString(),
              'liters': _numberValue(source['liters']),
            })
        .where((source) => (source['liters'] as double) > 0)
        .toList();
    final fuelLiters = _numberValue(record['fuel_liters']) != 0
        ? _numberValue(record['fuel_liters'])
        : sourceRows.fold<double>(
            0.0, (sum, source) => sum + (source['liters'] as double));
    final gasQuantity = _numberValue(record['gas_quantity']);
    final vehicleNumber =
        (record['vehicle_number'] ?? record['number'] ?? '').toString();
    final startLabel =
        _startDate == null ? '-' : DateFormat('dd/MM/yyyy').format(_startDate!);
    final endLabel =
        _endDate == null ? '-' : DateFormat('dd/MM/yyyy').format(_endDate!);

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('تفاصيل استهلاك السيارة'),
        content: SizedBox(
          width: 520,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('السيارة: $vehicleNumber'),
                Text('الفترة: $startLabel → $endLabel'),
                const SizedBox(height: 16),
                Text(
                  'إجمالي الوقود: ${fuelLiters.toStringAsFixed(1)} لتر',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                if (sourceRows.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      border: material.Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DataTable(
                      headingRowColor: WidgetStatePropertyAll(
                          Theme.of(context).colorScheme.primaryContainer),
                      columns: const [
                        DataColumn(label: Text('جهة التموين')),
                        DataColumn(label: Text('المسحوبات'), numeric: true),
                      ],
                      rows: sourceRows
                          .map((source) => DataRow(cells: [
                                DataCell(Text(source['source'] as String)),
                                DataCell(Text(
                                    '${(source['liters'] as double).toStringAsFixed(1)} لتر')),
                              ]))
                          .toList(),
                    ),
                  ),
                ],
                if (gasQuantity > 0) ...[
                  const Divider(),
                  Text(
                    'إجمالي الغاز: ${gasQuantity.toStringAsFixed(2)} م³',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: const Text('الغاز'),
                    trailing: Text('${gasQuantity.toStringAsFixed(2)} م³'),
                  ),
                ],
                if (sourceRows.isEmpty && gasQuantity <= 0)
                  const Padding(
                    padding: EdgeInsets.only(top: 12),
                    child: Text('لا توجد تفاصيل استهلاك مسجلة.'),
                  ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('إغلاق'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _quantityTableFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final optimizedRecords = _optimizedData?['records'] as List<Map<String, dynamic>>? ?? [];
    
    return CustomScrollView(
      slivers: [
        // Header with filters
        SliverToBoxAdapter(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Focus(
                  onKeyEvent: (node, event) {
                    if (event is KeyDownEvent &&
                        event.logicalKey == LogicalKeyboardKey.enter) {
                      if (!_isLoading) _generateReport();
                      return KeyEventResult.handled;
                    }
                    return KeyEventResult.ignored;
                  },
                  child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: TextButton.icon(
                                icon: const Icon(Icons.calendar_today),
                                label: Text(_startDate != null
                                    ? DateFormat('dd/MM/yyyy').format(_startDate!)
                                    : 'من تاريخ'),
                                onPressed: () => _selectDate(context, true),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: TextButton.icon(
                                icon: const Icon(Icons.calendar_today),
                                label: Text(_endDate != null
                                    ? DateFormat('dd/MM/yyyy').format(_endDate!)
                                    : 'إلى تاريخ'),
                                onPressed: () => _selectDate(context, false),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<String?>(
                                value: _selectedStatusFilter,
                                decoration: const InputDecoration(
                                    labelText: 'الحالة',
                                    border: OutlineInputBorder(),
                                    prefixIcon: Icon(Icons.filter_alt)),
                                items: const [
                                  DropdownMenuItem(
                                      value: null, child: Text('الكل (الافتراضي)')),
                                  DropdownMenuItem(
                                      value: 'natural', child: Text('طبيعي')),
                                  DropdownMenuItem(
                                      value: 'excess', child: Text('متجاوز')),
                                  DropdownMenuItem(
                                      value: 'illogical', child: Text('غير منطقي')),
                                ],
                                onChanged: (value) =>
                                    setState(() => _selectedStatusFilter = value),
                              ),
                            ),
                            const SizedBox(width: 12),
                            _ExportButtons(
                              reportType: 'نسبة',
                              dateRange: 'ratio',
                              iconOnly: true,
                              onExportExcel: () =>
                                  _exportQuantityReport(context, true),
                              onExportPdf: () =>
                                  _exportQuantityReport(context, false),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.search),
                            label: const Text('عرض التقرير'),
                            onPressed: _isLoading ? null : _generateReport,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              ),
              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 32),
                  child: CircularProgressIndicator(),
                ),
            ],
          ),
        ),
        // Report content
        if (_apiResult != null && !_isLoading) ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Builder(builder: (context) {
                if (optimizedRecords.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Text('لا توجد بيانات لمركبة في هذه الفترة',
                        style: TextStyle(fontSize: 14, color: Colors.grey)),
                  );
                }

                final summaryTotals = calculateFuelSummaryTotals(optimizedRecords);

                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('ملخص كميات الوقود',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 12),
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final isNarrow = constraints.maxWidth < 720;
                            final tileWidth = isNarrow
                                ? constraints.maxWidth
                                : (constraints.maxWidth - 48) / 4;
                            return Wrap(
                              spacing: 12,
                              runSpacing: 12,
                              children: [
                                SizedBox(
                                    width: tileWidth,
                                    child: _MetricTile(
                                        label: 'إجمالي بنزين 92',
                                        value:
                                            '${summaryTotals['gasoline92']!.toStringAsFixed(1)} لتر')),
                                SizedBox(
                                    width: tileWidth,
                                    child: _MetricTile(
                                        label: 'إجمالي غاز',
                                        value:
                                            '${summaryTotals['gas']!.toStringAsFixed(2)} م³')),
                                SizedBox(
                                    width: tileWidth,
                                    child: _MetricTile(
                                        label: 'إجمالي بنزين 95',
                                        value:
                                            '${summaryTotals['gasoline95']!.toStringAsFixed(1)} لتر')),
                                SizedBox(
                                    width: tileWidth,
                                    child: _MetricTile(
                                        label: 'إجمالي سولار',
                                        value:
                                            '${summaryTotals['solar']!.toStringAsFixed(1)} لتر')),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
          // Data table - single table with all rows
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TapRegion(
                onTapOutside: (_) {
                  setState(() {
                    _highlightedRowIndex = null;
                    _quantityTableFocusNode.unfocus();
                  });
                },
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => _quantityTableFocusNode.requestFocus(),
                  child: RawKeyboardListener(
                    focusNode: _quantityTableFocusNode,
                    onKey: (event) {
                      if (event is RawKeyDownEvent) {
                        if (event.logicalKey ==
                            LogicalKeyboardKey.arrowDown) {
                          setState(() {
                            if (_highlightedRowIndex == null) {
                              _highlightedRowIndex = 0;
                            } else {
                              _highlightedRowIndex =
                                  (_highlightedRowIndex! + 1)
                                      .clamp(0, optimizedRecords.length - 1);
                            }
                          });
                        } else if (event.logicalKey ==
                            LogicalKeyboardKey.arrowUp) {
                          setState(() {
                            if (_highlightedRowIndex == null) {
                              _highlightedRowIndex =
                                  optimizedRecords.length - 1;
                            } else {
                              _highlightedRowIndex =
                                  (_highlightedRowIndex! - 1)
                                      .clamp(0, optimizedRecords.length - 1);
                            }
                          });
                        } else if (event.logicalKey ==
                                LogicalKeyboardKey.enter &&
                            _highlightedRowIndex != null &&
                            _highlightedRowIndex! < optimizedRecords.length) {
                          _showConsumptionDetails(
                              optimizedRecords[_highlightedRowIndex!]);
                        }
                      }
                    },
                    child: LayoutBuilder(
                      builder: (context, constraints) =>
                          SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minWidth: constraints.maxWidth,
                          ),
                          child: Card(
                            margin: EdgeInsets.zero,
                            elevation: 1,
                            clipBehavior: Clip.antiAlias,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                              side: BorderSide(color: Colors.grey.shade300),
                            ),
                            child: DataTable(
                              headingRowColor: WidgetStatePropertyAll(
                                  Theme.of(context)
                                      .colorScheme
                                      .primaryContainer),
                              dataRowColor: WidgetStateProperty.resolveWith(
                                  (states) =>
                                      states.contains(WidgetState.hovered)
                                          ? Theme.of(context)
                                              .colorScheme
                                              .primary
                                              .withValues(alpha: 0.08)
                                          : null),
                              border: TableBorder(
                                horizontalInside: BorderSide(
                                    color: Colors.grey.shade200),
                                verticalInside:
                                    BorderSide(color: Colors.grey.shade200),
                                top: BorderSide(color: Colors.grey.shade300),
                                bottom:
                                    BorderSide(color: Colors.grey.shade300),
                              ),
                              columnSpacing: 14,
                              headingRowHeight: 48,
                              dataRowMinHeight: 48,
                              dataRowMaxHeight: 56,
                              columns: const [
                                DataColumn(label: Text('م')),
                                DataColumn(label: Text('رقم السجل')),
                                DataColumn(label: Text('رقم السيارة')),
                                DataColumn(label: Text('الأحرف')),
                                DataColumn(
                                    label: Text('الكمية الإجمالية'),
                                    numeric: true),
                                DataColumn(
                                    label: Text('عداد البداية'),
                                    numeric: true),
                                DataColumn(
                                    label: Text('آخر عداد بالفترة'),
                                    numeric: true),
                                DataColumn(
                                    label: Text('المسافة'),
                                    numeric: true),
                                DataColumn(
                                    label: Text('النسبة'),
                                    numeric: true),
                                DataColumn(label: Text('الحالة')),
                                DataColumn(label: Text('التحذيرات')),
                                DataColumn(label: Text('معلومات')),
                              ],
                              rows: optimizedRecords.asMap().entries.map((entry) {
                                final recordIndex = entry.key;
                                final record = entry.value;
                                final status =
                                    (record['status'] ?? 'طبيعي').toString();
                                final statusColor =
                                    ReportsCalculations.statusColor(status);
                                final warning =
                                    (record['warning'] ?? '').toString();
                                final warningColor = warning == 'مراجعة' ||
                                        warning == 'غير منطقي' ||
                                        warning == 'نسبة غير منطقية'
                                    ? const Color(0xFFFFC107)
                                    : warning == 'تجاوز' ||
                                            warning == 'متجاوز'
                                        ? const Color(0xFFFF5252)
                                        : null;
                                final isSelected =
                                    _highlightedRowIndex == recordIndex;

                                return DataRow(
                                  selected: isSelected,
                                  onSelectChanged: (selected) {
                                    setState(() {
                                      _highlightedRowIndex = selected == true
                                          ? recordIndex
                                          : null;
                                      if (selected == true) {
                                        _quantityTableFocusNode.requestFocus();
                                      }
                                    });
                                  },
                                  cells: [
                                    DataCell(Text('${recordIndex + 1}')),
                                    DataCell(Text(
                                        '${record['registry'] ?? record['vehicle_registry'] ?? '-'}')),
                                    DataCell(Text(
                                      '${record['vehicle_number'] ?? record['number'] ?? ''}')),
                                    DataCell(Text(
                                        '${record['vehicle_letters'] ?? record['letters'] ?? ''}')),
                                    DataCell(Text((record['total_liters'] ?? 0)
                                        .toStringAsFixed(1))),
                                    DataCell(Text(
                                        (record['start_odometer'] ?? 0)
                                            .toString())),
                                    DataCell(Text(
                                        (record['end_odometer'] ?? 0)
                                            .toString())),
                                    DataCell(Text((record['distance'] ?? 0)
                                        .toStringAsFixed(1))),
                                    DataCell(Text(
                                        (record['consumption_ratio'] ?? 0)
                                            .toString())),
                                    DataCell(
                                      SizedBox(
                                        width: 118,
                                        height: 32,
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: statusColor,
                                            borderRadius:
                                                BorderRadius.circular(4),
                                          ),
                                          alignment: Alignment.center,
                                          child: FittedBox(
                                            fit: BoxFit.scaleDown,
                                            child: Text(
                                              status,
                                              style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 12),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    DataCell(
                                      SizedBox(
                                        width: 64,
                                        child: Center(
                                          child: warningColor == null
                                              ? const SizedBox.shrink()
                                              : Tooltip(
                                                  message: warning,
                                                  child: Container(
                                                    width: 10,
                                                    height: 10,
                                                    decoration: BoxDecoration(
                                                      color: warningColor,
                                                      shape: BoxShape.circle,
                                                    ),
                                                  ),
                                                ),
                                        ),
                                      ),
                                    ),
                                    DataCell(
                                      IconButton.filledTonal(
                                        tooltip: 'تفاصيل استهلاك السيارة',
                                        icon: const Icon(Icons.info_outline),
                                        onPressed: () =>
                                            _showConsumptionDetails(record),
                                      ),
                                    ),
                                  ],
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
        ],
      ],
    );
  }
}

class _QuantityReportSummary extends StatelessWidget {
  final QuantityReportResult result;
  const _QuantityReportSummary({required this.result});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('ملخص التقرير',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _SummaryRow(
                label: 'إجمالي عدد التفويلات',
                value: result.totalRefuels.toString()),
            _SummaryRow(
                label: 'إجمالي اللترات',
                value: '${result.totalLiters.toStringAsFixed(1)} لتر',
                valueColor: Colors.green),
          ],
        ),
      ),
    );
  }
}

class _StationSummary extends StatelessWidget {
  final List<Map<String, dynamic>> records;
  final String stationName;

  const _StationSummary({required this.records, required this.stationName});

  @override
  Widget build(BuildContext context) {
    double total92 = 0.0, total95 = 0.0, totalSolar = 0.0;
    int totalRefuels = 0;

    for (var r in records) {
      final recFuel = (r['fuel_type'] ?? r['fuelType'] ?? '').toString();
      final litersRaw = r['liters'] ?? r['total_liters'] ?? 0;
      final liters = litersRaw is num
          ? litersRaw.toDouble()
          : double.tryParse(litersRaw.toString()) ?? 0.0;

      if (recFuel == 'بنزين 92') {
        total92 += liters;
      } else if (recFuel == 'بنزين 95') {
        total95 += liters;
      } else if (recFuel == 'سولار') {
        totalSolar += liters;
      }
      totalRefuels++;
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ملخص محطة $stationName',
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, constraints) {
                final isNarrow = constraints.maxWidth < 720;
                return Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    SizedBox(
                        width: isNarrow
                            ? constraints.maxWidth
                            : (constraints.maxWidth - 36) / 4,
                        child: _MetricTile(
                            label: 'عدد التفويلات',
                            value: totalRefuels.toString())),
                    SizedBox(
                        width: isNarrow
                            ? constraints.maxWidth
                            : (constraints.maxWidth - 36) / 4,
                        child: _MetricTile(
                            label: 'بنزين 92',
                            value: '${total92.toStringAsFixed(1)} لتر')),
                    SizedBox(
                        width: isNarrow
                            ? constraints.maxWidth
                            : (constraints.maxWidth - 36) / 4,
                        child: _MetricTile(
                            label: 'بنزين 95',
                            value: '${total95.toStringAsFixed(1)} لتر')),
                    SizedBox(
                        width: isNarrow
                            ? constraints.maxWidth
                            : (constraints.maxWidth - 36) / 4,
                        child: _MetricTile(
                            label: 'سولار',
                            value: '${totalSolar.toStringAsFixed(1)} لتر')),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ExportButtons extends StatelessWidget {
  final String reportType;
  final DateTime? date;
  final String? dateRange;
  final bool iconOnly;
  final Future<void> Function()? onExportExcel;
  final Future<void> Function()? onExportPdf;

  const _ExportButtons(
      {required this.reportType,
      this.date,
      this.dateRange,
      this.iconOnly = false,
      this.onExportExcel,
      this.onExportPdf});

  void _showExportDialog(BuildContext context, String format) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text('سيتم تصدير التقرير بصيغة $format قريباً'),
          duration: const Duration(seconds: 2)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final excelButton = IconButton(
      tooltip: 'تصدير Excel',
      icon: const Icon(Icons.table_view, color: Colors.blue, size: 24),
      onPressed: onExportExcel != null
          ? () async => await onExportExcel!()
          : () => _showExportDialog(context, 'Excel'),
    );
    final pdfButton = IconButton(
      tooltip: 'تصدير PDF',
      icon: const Icon(Icons.picture_as_pdf_outlined, color: Colors.red, size: 24),
      onPressed: onExportPdf != null
          ? () async => await onExportPdf!()
          : () => _showExportDialog(context, 'PDF'),
    );
    
    return Align(
      alignment: Alignment.centerRight,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [excelButton, pdfButton],
      ),
    );
  }
}

dynamic _excelCellValue(dynamic value) {
  if (value is num) return value;
  if (value is String) return double.tryParse(value) ?? value;
  return value ?? '';
}

bool stationsMatchAny(String station, List<String> knownStations) {
  return knownStations.any(
      (knownStation) => stationsMatch(station, knownStation));
}

class _ExcelSheetData {
  final String name;
  final List<String> headers;
  final List<List<dynamic>> rows;

  const _ExcelSheetData({
    required this.name,
    required this.headers,
    required this.rows,
  });
}

Future<void> _writeExcelFile(BuildContext context, List<String> headers,
    List<List<dynamic>> rows, String filenameSuffix,
    {List<_ExcelSheetData> additionalSheets = const []}) async {
  final excel = Excel.createExcel();
  final sheet = excel['Report'];
  sheet.appendRow(headers);
  for (final r in rows) sheet.appendRow(r);
  for (final additionalSheet in additionalSheets) {
    final sheet = excel[additionalSheet.name];
    sheet.appendRow(additionalSheet.headers);
    for (final row in additionalSheet.rows) sheet.appendRow(row);
  }
  final bytes = excel.encode();
  if (bytes == null) {
    throw Exception('فشل إنشاء ملف Excel');
  }
  final filename =
      '${filenameSuffix}_${DateTime.now().millisecondsSinceEpoch}.xlsx';
  await saveBytesAsFile(filename, Uint8List.fromList(bytes));
  if (!context.mounted) return;
  ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text('تم حفظ Excel باسم $filename')));
}

Future<void> _writePdfFile(BuildContext context, List<String> headers,
    List<List<dynamic>> rows, String filenameSuffix) async {
  final fontData = await rootBundle.load('assets/fonts/arial.ttf');
  final pdfBytes = await compute(
    (params) => buildReportPdfBytes(
      headers: params.headers,
      rows: params.rows,
      title: 'تقرير',
      fontData: params.fontData,
    ),
    _PdfBuildParams(
      headers: headers,
      rows: rows,
      fontData: fontData.buffer.asUint8List(),
    ),
  );

  final filename =
      '${filenameSuffix}_${DateTime.now().millisecondsSinceEpoch}.pdf';
  await saveBytesAsFile(filename, pdfBytes);
  if (!context.mounted) return;
  ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text('تم حفظ PDF باسم $filename')));
}

class _PdfBuildParams {
  final List<String> headers;
  final List<List<dynamic>> rows;
  final Uint8List fontData;

  _PdfBuildParams({
    required this.headers,
    required this.rows,
    required this.fontData,
  });
}
