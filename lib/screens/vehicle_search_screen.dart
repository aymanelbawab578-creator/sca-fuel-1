import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../helpers/reports_calculations.dart';
import '../models/refuel.dart';
import '../models/vehicle.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../utils/stations.dart';
import '../widgets/sca_keyboard_dialog.dart';
import '../widgets/sca_layout.dart';
import 'dashboard_screen.dart';
import 'login_screen.dart';
import 'reports_screen.dart';
import 'gas_screen.dart';
import 'settings_screen.dart';
import 'archive_screen.dart';
import 'vehicle_data_screen.dart';
import 'store_screen.dart';

class VehicleSearchScreen extends StatefulWidget {
  final void Function(Refuel savedRefuel, Vehicle selectedVehicle)? onRefuelSaved;
  final bool showScaffold;
  final bool showBack;
  final VoidCallback? onBack;

  const VehicleSearchScreen({
    super.key,
    this.onRefuelSaved,
    this.showScaffold = true,
    this.showBack = true,
    this.onBack,
  });

  @override
  State<VehicleSearchScreen> createState() => _VehicleSearchScreenState();
}

class _VehicleSearchScreenState extends State<VehicleSearchScreen> {
  final _searchController = TextEditingController();
  final _dateController = TextEditingController();
  String? _selectedStation;
  final _odometerController = TextEditingController();
  final _litersController = TextEditingController();
  final _searchFocusNode = FocusNode();
  final _odometerFocusNode = FocusNode();
  final _litersFocusNode = FocusNode();
  final _saveButtonFocusNode = FocusNode();

  bool _isLoading = false;
  String? _error;
  Vehicle? _selectedVehicle;
  DateTime _selectedDate = DateTime.now();
  double? _distance;
  double? _displayRatio;
  String? _statusMessage;
  Color _statusColor = Colors.black;
  bool _canSave = false;
  RefuelCreate? _lastSavedEntry;
  Refuel? _lastSavedRefuel;
  List<Refuel> _recentRefuels = [];

  static final List<Vehicle> _mockVehicles = [
    Vehicle(
      id: 1,
      number: '123',
      letters: 'أ',
      registry: '12345',
      code: 'C-001',
      vehicleType: 'سيارة',
      fuelType: 'ديزل',
      standardConsumption: 8.0,
      lastOdometer: 12000,
      lastOdometerDate: '2026-06-10',
    ),
    Vehicle(
      id: 2,
      number: '123',
      letters: 'ب',
      registry: '12346',
      code: 'C-002',
      vehicleType: 'سيارة',
      fuelType: 'بنزين',
      standardConsumption: 10.0,
      lastOdometer: 15000,
      lastOdometerDate: '2026-06-12',
    ),
    Vehicle(
      id: 3,
      number: '456',
      letters: null,
      registry: '45678',
      code: 'C-003',
      vehicleType: 'شاحنة',
      fuelType: 'ديزل',
      standardConsumption: 5.0,
      lastOdometer: 0,
      lastOdometerDate: '0000-00-00',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _dateController.text = _formatDate(_selectedDate);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _dateController.dispose();
    _odometerController.dispose();
    _litersController.dispose();
    _searchFocusNode.dispose();
    _odometerFocusNode.dispose();
    _litersFocusNode.dispose();
    _saveButtonFocusNode.dispose();
    super.dispose();
  }

  String _formatDate(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      locale: const Locale('ar'),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _dateController.text = _formatDate(_selectedDate);
      });
    }
  }

  Future<void> _search() async {
    final rawQuery = _searchController.text.trim();
    final query = rawQuery.replaceAll(RegExp(r'[^0-9]'), '');
    if (query.isEmpty) {
      setState(() {
        _error = 'ادخل رقم المركبة للبحث';
      });
      return;
    }

    if (mounted) {
      setState(() {
        _isLoading = true;
        _error = null;
        _selectedVehicle = null;
        _distance = null;
        _displayRatio = null;
        _statusMessage = null;
        _canSave = false;
      });
    }

    List<Vehicle> vehicles = [];
    try {
      final token = Provider.of<AuthProvider>(context, listen: false).token;
      if (token == null) throw Exception('Unauthorized');
      
      // إضافة timeout للـ API call
      vehicles = await ApiService.fetchVehicles(token, query)
          .timeout(const Duration(seconds: 10), onTimeout: () => throw Exception('انتهت المهلة الزمنية'));
    } catch (_) {
      if (!mounted) return;
      vehicles = _mockVehicles;
    }

    if (!mounted) return;

    final matched = vehicles.where((vehicle) {
      final vehicleNumber = vehicle.number.replaceAll(RegExp(r'[^0-9]'), '');
      return vehicleNumber == query;
    }).toList();

    setState(() {
      _isLoading = false;
    });

    if (matched.isEmpty) {
      _showNotFoundDialog();
      return;
    }

    if (matched.length == 1) {
      _selectVehicle(matched.first);
      return;
    }

    _showVehicleChoiceDialog(matched);
  }

  void _selectVehicle(Vehicle vehicle) {
    setState(() {
      _selectedVehicle = vehicle;
      _odometerController.clear();
      _litersController.clear();
      _distance = null;
      _displayRatio = null;
      _statusMessage = null;
      _statusColor = Colors.black;
      _canSave = false;
      _lastSavedRefuel = null;
      _recentRefuels = [];
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _odometerFocusNode.requestFocus();
      _loadRecentRefuels();
    });
  }

  Future<void> _loadRecentRefuels() async {
    if (_selectedVehicle == null) return;
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    if (token == null) return;

    try {
      final refuels = await ApiService.fetchRefuels(token, _selectedVehicle!.id);
      if (!mounted) return;
      setState(() {
        _recentRefuels = refuels;
        if (refuels.isNotEmpty) {
          _lastSavedRefuel = refuels.first;
        }
      });
    } catch (_) {
      // Ignore fetch failures for history display.
    }
  }

  Future<void> _showVehicleChoiceDialog(List<Vehicle> vehicles) async {
    await showDialog<void>(
      context: context,
      builder: (context) {
        var selectedIndex = 0;
        return ScaKeyboardDialog(
          child: StatefulBuilder(
            builder: (context, setDialogState) => Focus(
              autofocus: true,
              onKeyEvent: (node, event) {
                if (event is! KeyDownEvent) return KeyEventResult.ignored;
                if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
                  setDialogState(() => selectedIndex =
                      (selectedIndex + 1).clamp(0, vehicles.length - 1));
                  return KeyEventResult.handled;
                }
                if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
                  setDialogState(() => selectedIndex =
                      (selectedIndex - 1).clamp(0, vehicles.length - 1));
                  return KeyEventResult.handled;
                }
                if (event.logicalKey == LogicalKeyboardKey.enter) {
                  Navigator.of(context).pop();
                  _selectVehicle(vehicles[selectedIndex]);
                  return KeyEventResult.handled;
                }
                return KeyEventResult.ignored;
              },
              child: AlertDialog(
                title: const Text('يوجد أكثر من سيارة بهذا الرقم'),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: vehicles.asMap().entries.map((entry) {
                      final vehicle = entry.value;
                      return ListTile(
                        selected: selectedIndex == entry.key,
                        title: Text('${vehicle.number} ${vehicle.letters ?? ''}'),
                        subtitle: Text('السجل: ${vehicle.registry ?? '-'} - النوع: ${vehicle.vehicleType}'),
                        onTap: () {
                          Navigator.of(context).pop();
                          _selectVehicle(vehicle);
                        },
                      );
                    }).toList(),
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('إلغاء'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _showNotFoundDialog() async {
    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('السيارة غير موجودة في قاعدة البيانات'),
          content: const Text('الرجاء إضافة المركبة أو تجاهل الرسالة.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('تجاهل'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => const VehicleDataScreen(),
                ));
              },
              child: const Text('الانتقال إلى إضافة مركبة'),
            ),
          ],
        );
      },
    );
  }

  void _goToDashboard() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const DashboardScreen()),
      (route) => false,
    );
  }

  void _calculate() {
    if (_selectedVehicle == null) {
      return;
    }

    final currentOdometer = double.tryParse(_odometerController.text);
    final liters = double.tryParse(_litersController.text);
    if (currentOdometer == null || liters == null || liters <= 0) {
      setState(() {
        _distance = null;
        _displayRatio = null;
        _statusMessage = null;
        _statusColor = Colors.black;
        _canSave = false;
      });
      return;
    }

    final lastOdometer = _selectedVehicle!.lastOdometer;
    final distance = lastOdometer > 0 ? currentOdometer - lastOdometer : currentOdometer;
    if (lastOdometer > 0 && currentOdometer < lastOdometer) {
      setState(() {
        _distance = null;
        _displayRatio = null;
        _statusMessage = 'قراءة العداد أقل من آخر قراءة';
        _statusColor = Colors.orange;
        _canSave = true;
      });
      return;
    }

    if (distance <= 0) {
      setState(() {
        _distance = null;
        _displayRatio = null;
        _statusMessage = 'الرجاء إدخال قراءة صحيحة للعداد';
        _statusColor = Colors.orange;
        _canSave = true;
      });
      return;
    }

    final actualRatioPer100 = liters / distance * 100;
    final standard = _selectedVehicle!.standardConsumption;
    final status = ReportsCalculations.statusLabel(actualRatioPer100, standard);
    final statusColor = ReportsCalculations.statusColor(status);
    final message = status == 'طبيعي'
        ? 'طبيعي'
        : status == 'متجاوز'
            ? 'السيارة متجاوزة للاستهلاك القياسي.'
            : 'نسبة الاستهلاك غير منطقية.';

    setState(() {
      _distance = distance;
      _displayRatio = actualRatioPer100;
      _statusMessage = message;
      _statusColor = statusColor;
      _canSave = true;
    });
  }

  Future<void> _saveRefuel() async {
    if (_selectedVehicle == null || !_canSave) {
      return;
    }

    final currentOdometer = double.tryParse(_odometerController.text);
    final liters = double.tryParse(_litersController.text);
    if (currentOdometer == null || liters == null || liters <= 0) {
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final lastOdometer = _selectedVehicle!.lastOdometer;
    final distance = lastOdometer > 0 ? currentOdometer - lastOdometer : currentOdometer;
    final ratioPer100 = distance > 0 ? liters / distance * 100 : 0.0;
    final standard = _selectedVehicle!.standardConsumption;

    final saveAnyway = await _showSaveConfirmationIfNeeded(
      currentOdometer: currentOdometer,
      liters: liters,
      distance: distance,
      ratio: ratioPer100,
      standard: standard,
      lastOdometer: lastOdometer,
    );
    if (!saveAnyway) {
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final token = authProvider.token;
      if (token == null) throw Exception('Unauthorized');

      final refuelCreate = RefuelCreate(
        vehicleId: _selectedVehicle!.id,
        currentOdometer: currentOdometer,
        liters: liters,
        createdAt: _selectedDate,
        station: _selectedStation,
      );

      final savedRefuel = await ApiService.submitRefuel(token, refuelCreate);
      _lastSavedEntry = refuelCreate;
      _lastSavedRefuel = savedRefuel;
      final currentVehicle = _selectedVehicle;

      setState(() {
        // مسح حقول الإدخال
        _searchController.clear();
        _odometerController.clear();
        _litersController.clear();
        _distance = null;
        _displayRatio = null;
        _statusMessage = null;
        _canSave = false;
        _selectedVehicle = null;
        // الحفاظ على التاريخ والمحطة كما هما
      });

      widget.onRefuelSaved?.call(savedRefuel, currentVehicle!);

      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('تم حفظ التفويلة بنجاح')),
      );

      await _loadRecentRefuels();

      // إعادة التركيز على حقل البحث
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          FocusScope.of(context).requestFocus(_searchFocusNode);
        }
      });
    } catch (_) {
      setState(() {
        _error = 'لم يتم حفظ التفويلة. حاول مرة أخرى.';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<bool> _showSaveConfirmationIfNeeded({
    required double currentOdometer,
    required double liters,
    required double distance,
    required double ratio,
    required double standard,
    required double lastOdometer,
  }) async {
    FocusScope.of(context).unfocus();
    if (lastOdometer > 0 && currentOdometer < lastOdometer) {
      final result = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          return ScaKeyboardDialog(
            child: AlertDialog(
              title: const Text('يوجد تحذير في قراءة العداد'),
              content: const Text('احتمال وجود خطأ في تسجيل العداد.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: const Text('تعديل البيانات'),
                ),
                ElevatedButton(
                  autofocus: true,
                  onPressed: () => Navigator.of(dialogContext).pop(true),
                  child: const Text('حفظ على أي حال'),
                ),
              ],
            ),
          );
        },
      );
      return result ?? false;
    }

    final status = ReportsCalculations.statusLabel(ratio, standard);
    if (status == 'متجاوز') {
      final exceedValue = ratio - standard;
      final result = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          return ScaKeyboardDialog(
            child: AlertDialog(
              title: const Text('السيارة متجاوزة للاستهلاك القياسي'),
              content: Text(
                'النسبة الفعلية: ${ratio.toStringAsFixed(2)} لتر / 100 كم\n'
                'نسبة التجاوز: ${exceedValue.toStringAsFixed(2)} لتر / 100 كم',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: const Text('تعديل البيانات'),
                ),
                ElevatedButton(
                  autofocus: true,
                  onPressed: () => Navigator.of(dialogContext).pop(true),
                  child: const Text('حفظ على أي حال'),
                ),
              ],
            ),
          );
        },
      );
      return result ?? false;
    }

    if (status == 'نسبة غير منطقية') {
      final result = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          return ScaKeyboardDialog(
            child: AlertDialog(
              title: const Text('نسبة الاستهلاك غير منطقية'),
              content: Text(
                'النسبة الفعلية: ${ratio.toStringAsFixed(2)} لتر / 100 كم\n'
                'الرجاء التحقق من قيم العداد أو اللترات قبل الحفظ.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: const Text('تعديل البيانات'),
                ),
                ElevatedButton(
                  autofocus: true,
                  onPressed: () => Navigator.of(dialogContext).pop(true),
                  child: const Text('حفظ على أي حال'),
                ),
              ],
            ),
          );
        },
      );
      return result ?? false;
    }

    return true;
  }

  void _editLastOperation() {
    if (_selectedVehicle == null || _lastSavedEntry == null || _lastSavedEntry!.vehicleId != _selectedVehicle!.id) {
      return;
    }

    setState(() {
      _odometerController.text = _lastSavedEntry!.currentOdometer.toString();
      _litersController.text = _lastSavedEntry!.liters.toString();
    });
    _calculate();
  }

  Widget _buildVehicleInfoCard() {
    if (_selectedVehicle == null) {
      return const SizedBox.shrink();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 720;
        final basicInfo = [
          MapEntry('رقم السيارة', '${_selectedVehicle!.number} ${_selectedVehicle!.letters ?? ''}'),
          MapEntry('السجل', _selectedVehicle!.registry ?? '-'),
          MapEntry('الكود', _selectedVehicle!.code ?? '-'),
        ];
        final fuelInfo = [
          MapEntry('نوع المركبة', _selectedVehicle!.vehicleType),
          MapEntry('نوع الوقود', _selectedVehicle!.fuelType),
          MapEntry('الاستهلاك القياسي', _selectedVehicle!.standardConsumption.toString()),
        ];

        if (isWide) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _buildVehicleInfoPanel('المعلومات الأساسية', basicInfo)),
              const SizedBox(width: 16),
              Expanded(child: _buildVehicleInfoPanel('بيانات الوقود', fuelInfo)),
            ],
          );
        }

        return Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('بيانات المركبة', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                Table(
                  columnWidths: const {
                    0: FlexColumnWidth(2),
                    1: FlexColumnWidth(3),
                  },
                  children: [
                    _buildTableRow('رقم السيارة', '${_selectedVehicle!.number} ${_selectedVehicle!.letters ?? ''}'),
                    _buildTableRow('السجل', _selectedVehicle!.registry ?? '-'),
                    _buildTableRow('الكود', _selectedVehicle!.code ?? '-'),
                    _buildTableRow('نوع المركبة', _selectedVehicle!.vehicleType),
                    _buildTableRow('نوع الوقود', _selectedVehicle!.fuelType),
                    _buildTableRow('الاستهلاك القياسي', _selectedVehicle!.standardConsumption.toString()),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildVehicleInfoPanel(String title, List<MapEntry<String, String>> rows) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 320),
                child: Table(
                  columnWidths: const {
                    0: FlexColumnWidth(2),
                    1: FlexColumnWidth(3),
                  },
                  children: rows.map((entry) => _buildTableRow(entry.key, entry.value)).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLastRefuelCard() {
    if (_selectedVehicle == null) {
      return const SizedBox.shrink();
    }

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('آخر تفويلة', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 320),
                child: Table(
                  columnWidths: const {
                    0: FlexColumnWidth(2),
                    1: FlexColumnWidth(3),
                  },
                  children: [
                    TableRow(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Text('آخر عداد', style: const TextStyle(fontWeight: FontWeight.bold)),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Text(
                            _selectedVehicle!.lastOdometer > 0 ? _selectedVehicle!.lastOdometer.toStringAsFixed(0) : '-',
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue),
                          ),
                        ),
                      ],
                    ),
                    _buildTableRow('تاريخ آخر عداد', _selectedVehicle!.lastOdometerDate.isNotEmpty ? _selectedVehicle!.lastOdometerDate : '-'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentRefuelsCard() {
    if (_selectedVehicle == null) {
      return const SizedBox.shrink();
    }

    final refuels = _recentRefuels.isNotEmpty ? _recentRefuels : (_lastSavedRefuel != null ? [_lastSavedRefuel!] : []);
    if (refuels.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('أحدث التفويلات', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            Column(
              children: refuels.take(3).map((refuel) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(child: Text('${refuel.createdAt} - ${refuel.station ?? 'بدون محطة'}')),
                      Text('${refuel.liters.toStringAsFixed(1)}لتر', style: const TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(width: 12),
                      Text('${refuel.currentOdometer.toStringAsFixed(0)} كم'),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNewRefuelCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('تسجيل التفويلة الجديدة', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            TextField(
              focusNode: _odometerFocusNode,
              controller: _odometerController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'العداد الحالي',
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => _calculate(),
              onSubmitted: (_) => _litersFocusNode.requestFocus(),
            ),
            const SizedBox(height: 12),
            TextField(
              focusNode: _litersFocusNode,
              controller: _litersController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'اللترات',
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => _calculate(),
              onSubmitted: (_) => _saveButtonFocusNode.requestFocus(),
            ),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 320),
                child: Table(
                  columnWidths: const {
                    0: FlexColumnWidth(2),
                    1: FlexColumnWidth(3),
                  },
                  children: [
                    _buildTableRow('المسافة المقطوعة', _distance != null ? '${_distance!.toStringAsFixed(1)} كم' : '-'),
                    _buildTableRow('النسبة', _displayRatio != null ? '${_displayRatio!.toStringAsFixed(2)} لتر / 100 كم' : '-'),
                    _buildTableRow('الحالة', _statusMessage ?? '-'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (_statusMessage != null)
              Text(
                _statusMessage!,
                style: TextStyle(fontWeight: FontWeight.bold, color: _statusColor),
              ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 44,
                    child: ElevatedButton(
                      focusNode: _saveButtonFocusNode,
                      onPressed: _isLoading || !_canSave ? null : _saveRefuel,
                      child: const Text('حفظ'),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  TableRow _buildTableRow(String label, String value) {
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(value),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final content = Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          LayoutBuilder(
            builder: (context, searchConstraints) {
              final isCompact = searchConstraints.maxWidth < 900;

              final searchField = TextField(
                focusNode: _searchFocusNode,
                controller: _searchController,
                textInputAction: TextInputAction.search,
                decoration: const InputDecoration(
                  labelText: 'بحث برقم السيارة',
                  border: OutlineInputBorder(),
                ),
                onSubmitted: (_) => _search(),
              );

              final dateField = SizedBox(
                width: isCompact ? double.infinity : 160,
                child: TextField(
                  controller: _dateController,
                  readOnly: true,
                  decoration: const InputDecoration(
                    labelText: 'التاريخ',
                    border: OutlineInputBorder(),
                    suffixIcon: Icon(Icons.calendar_month),
                  ),
                  onTap: _pickDate,
                ),
              );

              final stationField = SizedBox(
                width: isCompact ? double.infinity : 220,
                child: DropdownButtonFormField<String?>(
                  value: _selectedStation,
                  isExpanded: true,
                  decoration: const InputDecoration(border: OutlineInputBorder(), labelText: 'جهة التموين (اختياري)'),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('كل الجهات')),
                    ...fuelStations.map((station) => DropdownMenuItem(value: station, child: Text(station))),
                  ],
                  onChanged: (v) => setState(() => _selectedStation = v),
                ),
              );

              final searchButton = SizedBox(
                width: isCompact ? double.infinity : 110,
                child: ElevatedButton(onPressed: _isLoading ? null : _search, child: const Text('بحث')),
              );

              if (isCompact) {
                return Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    SizedBox(width: searchConstraints.maxWidth, child: searchField),
                    dateField,
                    stationField,
                    searchButton,
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(child: searchField),
                  const SizedBox(width: 12),
                  dateField,
                  const SizedBox(width: 12),
                  stationField,
                  const SizedBox(width: 12),
                  searchButton,
                ],
              );
            },
          ),
          if (_isLoading) const Padding(
            padding: EdgeInsets.only(top: 12),
            child: LinearProgressIndicator(),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(_error!, style: const TextStyle(color: Colors.red)),
            ),
          const SizedBox(height: 20),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 720;
                return SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (_selectedVehicle != null) ...[
                        if (isWide) ...[
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 2,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    _buildVehicleInfoCard(),
                                    const SizedBox(height: 16),
                                    _buildLastRefuelCard(),
                                    const SizedBox(height: 16),
                                    _buildRecentRefuelsCard(),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                flex: 3,
                                child: _buildNewRefuelCard(),
                              ),
                            ],
                          ),
                        ] else ...[
                          _buildVehicleInfoCard(),
                          const SizedBox(height: 16),
                          _buildLastRefuelCard(),
                          const SizedBox(height: 16),
                          _buildRecentRefuelsCard(),
                          const SizedBox(height: 16),
                          _buildNewRefuelCard(),
                        ],
                      ],
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );

    if (!widget.showScaffold) {
      return content;
    }

    return Scaffold(
      appBar: ScaAppBar(
        title: 'متابعة المركبات',
        showBack: widget.showBack,
        onBack: widget.onBack ?? _goToDashboard,
      ),
      drawer: ScaDrawer(
        currentRoute: 'vehicle_search',
        onDashboard: _goToDashboard,
        onVehicleSearch: () {},
        onStore: () {
          Navigator.of(context).push(MaterialPageRoute(builder: (_) => const StoreScreen()));
        },
        onStoreTab: (index) {
          Navigator.of(context).push(MaterialPageRoute(builder: (_) => StoreScreen(initialTab: index)));
        },
        onGasTab: (index) {
          Navigator.of(context).push(MaterialPageRoute(builder: (_) => GasScreen(initialTab: index)));
        },
        onVehicleData: () {
          Navigator.of(context).push(MaterialPageRoute(builder: (_) => const VehicleDataScreen()));
        },
        onReports: () {
          Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ReportsScreen()));
        },
        onReportTab: (index) {
          Navigator.of(context).push(MaterialPageRoute(builder: (_) => ReportsScreen(initialTab: index)));
        },
        onArchive: () {
          Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ArchiveScreen()));
        },
        onSettings: () {
          Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SettingsScreen()));
        },
        onLogout: () async {
          final authProvider = Provider.of<AuthProvider>(context, listen: false);
          final currentContext = context;
          await authProvider.logout();
          if (!mounted) return;
          Navigator.of(currentContext).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const LoginScreen()),
            (route) => false,
          );
        },
      ),
      body: content,
    );
  }
}

