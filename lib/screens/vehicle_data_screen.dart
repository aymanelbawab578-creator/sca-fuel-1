import 'dart:typed_data';

import 'package:excel/excel.dart' hide Border;
import '../utils/file_picker_wrapper.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:provider/provider.dart';

import '../utils/file_read_helper.dart';
import '../utils/file_save_helper.dart';
import '../helpers/report_pdf_export.dart';

import '../models/vehicle.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../widgets/sca_layout.dart';
import 'dashboard_screen.dart';
import 'login_screen.dart';
import 'reports_screen.dart';
import 'gas_screen.dart';
import 'settings_screen.dart';
import 'archive_screen.dart';
import 'vehicle_search_screen.dart';
import 'store_screen.dart';
import 'vehicle_identity_change_screen.dart';

class VehicleDataScreen extends StatefulWidget {
  final Vehicle? vehicle;

  const VehicleDataScreen({super.key, this.vehicle});

  @override
  State<VehicleDataScreen> createState() => _VehicleDataScreenState();
}

class _VehicleDataScreenState extends State<VehicleDataScreen> {
  final _searchController = TextEditingController();
  final _vehicleNumberSearchController = TextEditingController();
  final _registrySearchController = TextEditingController();
  final _scrollController = ScrollController();
  final _formKey = GlobalKey<FormState>();
  final int _pageSize = 20;

  List<Vehicle> _vehicles = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  bool _isSaving = false;
  String? _errorMessage;
  String? _successMessage;
  String _currentQuery = '';
  Vehicle? _selectedVehicle;
  final _vehicleListFocus = FocusNode();
  int? _selectedVehicleIndex;

  static const String _defaultOdometerDate = '04/09/1989';
  final DateFormat _displayDateFormat = DateFormat('dd/MM/yyyy');
  final DateFormat _apiDateFormat = DateFormat('yyyy-MM-dd');

  final _numberController = TextEditingController();
  final _lettersController = TextEditingController();
  final _registryController = TextEditingController();
  final _codeController = TextEditingController();
  final _vehicleTypeController = TextEditingController();
  final _fuelTypeController = TextEditingController();
  final _odometerSearchController = TextEditingController();
  final _brandController = TextEditingController();
  final _modelController = TextEditingController();
  final _lastOdometerController = TextEditingController();
  final _lastOdometerDateController = TextEditingController();
  final _standardConsumptionController = TextEditingController();
  final _manufactureYearController = TextEditingController();

  final _numberFocus = FocusNode();
  final _lettersFocus = FocusNode();
  final _registryFocus = FocusNode();
  final _codeFocus = FocusNode();
  final _vehicleTypeFocus = FocusNode();
  final _fuelTypeFocus = FocusNode();
  final _odometerSearchFocus = FocusNode();
  final _vehicleNumberSearchFocus = FocusNode();
  final _registrySearchFocus = FocusNode();
  final _brandFocus = FocusNode();
  final _modelFocus = FocusNode();
  final _lastOdometerFocus = FocusNode();
  final _lastOdometerDateFocus = FocusNode();
  final _standardConsumptionFocus = FocusNode();
  final _manufactureYearFocus = FocusNode();
  final _saveButtonFocus = FocusNode();
  final _deleteButtonFocus = FocusNode();

  static const List<String> _fuelTypes = ['بنزين 92', 'بنزين 95', 'سولار'];

  List<Vehicle> _odometerSearchResults = [];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    if (widget.vehicle != null) {
      _selectVehicle(widget.vehicle!);
    }
    _loadVehicles(reset: true);
  }

  @override
  void dispose() {
    _vehicleListFocus.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchController.dispose();
    _vehicleNumberSearchController.dispose();
    _registrySearchController.dispose();
    _numberController.dispose();
    _lettersController.dispose();
    _registryController.dispose();
    _codeController.dispose();
    _vehicleTypeController.dispose();
    _fuelTypeController.dispose();
    _brandController.dispose();
    _modelController.dispose();
    _lastOdometerController.dispose();
    _lastOdometerDateController.dispose();
    _standardConsumptionController.dispose();
    _manufactureYearController.dispose();
    _odometerSearchController.dispose();
    _numberFocus.dispose();
    _lettersFocus.dispose();
    _registryFocus.dispose();
    _codeFocus.dispose();
    _vehicleTypeFocus.dispose();
    _fuelTypeFocus.dispose();
    _brandFocus.dispose();
    _modelFocus.dispose();
    _lastOdometerFocus.dispose();
    _lastOdometerDateFocus.dispose();
    _standardConsumptionFocus.dispose();
    _manufactureYearFocus.dispose();
    _saveButtonFocus.dispose();
    _deleteButtonFocus.dispose();
    _odometerSearchFocus.dispose();
    _vehicleNumberSearchFocus.dispose();
    _registrySearchFocus.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients ||
        _isLoadingMore ||
        _isLoading ||
        !_hasMore) {
      return;
    }
    if (_scrollController.position.pixels + 200 >=
        _scrollController.position.maxScrollExtent) {
      _loadVehicles();
    }
  }

  Future<void> _loadVehicles({bool reset = false}) async {
    if (_isLoadingMore || _isLoading) return;
    if (reset) {
      _vehicles = [];
      _hasMore = true;
      _errorMessage = null;
      _successMessage = null;
    }
    if (!_hasMore) return;

    setState(() {
      if (reset) {
        _isLoading = true;
      } else {
        _isLoadingMore = true;
      }
    });

    try {
      final token = Provider.of<AuthProvider>(context, listen: false).token;
      if (token == null) {
        throw Exception('غير مسجل الدخول');
      }

      final offset = reset ? 0 : _vehicles.length;
      final fetched = await ApiService.listVehicles(
        token,
        query: _currentQuery.isEmpty ? null : _currentQuery,
        limit: _pageSize,
        offset: offset,
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () =>
            throw Exception('انتهت المهلة الزمنية لتحميل المركبات'),
      );

      if (!mounted) return;

      setState(() {
        if (reset) {
          _vehicles = fetched;
        } else {
          _vehicles.addAll(fetched);
        }
        _hasMore = fetched.length >= _pageSize;
      });

      if (reset && _selectedVehicle != null) {
        final refreshedVehicle = fetched
            .where((vehicle) => vehicle.id == _selectedVehicle!.id)
            .firstOrNull;
        if (refreshedVehicle != null) {
          _selectVehicle(refreshedVehicle);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'فشل تحميل المركبات: ${e.toString()}';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isLoadingMore = false;
        });
      }
    }
  }

  Future<void> _onSearch() async {
    final vehicleNumberQuery = _vehicleNumberSearchController.text.trim();
    final registrySearchQuery = _registrySearchController.text.trim();
    final odometerQuery = _odometerSearchController.text.trim();

    // إذا وُجدت قيمة لرقم المركبة فقم بالبحث بها أولاً
    if (vehicleNumberQuery.isNotEmpty) {
      _currentQuery = vehicleNumberQuery;
      await _loadVehicles(reset: true);
      _vehicleNumberSearchController.clear();
      _registrySearchController.clear();
      _odometerSearchController.clear();
      setState(() {});
      FocusScope.of(context).unfocus();
      return;
    }

    // إذا وُجدت قيمة لرقم السجل فقم بالبحث بها كأولوية ثانية
    if (registrySearchQuery.isNotEmpty) {
      _currentQuery = registrySearchQuery;
      await _loadVehicles(reset: true);
      _vehicleNumberSearchController.clear();
      _registrySearchController.clear();
      _odometerSearchController.clear();
      setState(() {});
      FocusScope.of(context).unfocus();
      return;
    }

    // البحث الذكي: إذا كان المدخل رقماً (عداد)، ابحث عن العدادات القريبة
    if (odometerQuery.isNotEmpty && double.tryParse(odometerQuery) != null) {
      final searchOdometer = double.parse(odometerQuery);
      try {
        final token = Provider.of<AuthProvider>(context, listen: false).token;
        if (token == null) throw Exception('غير مسجل الدخول');

        final allVehicles = await ApiService.listVehicles(token, limit: 500);
        _odometerSearchResults = allVehicles.where((v) {
          final lastOdometer = v.lastOdometer;
          return (lastOdometer - searchOdometer).abs() <= 1000;
        }).toList();

        if (_odometerSearchResults.isNotEmpty) {
          _odometerSearchResults.sort((a, b) {
            final diffA = (a.lastOdometer - searchOdometer).abs();
            final diffB = (b.lastOdometer - searchOdometer).abs();
            return diffA.compareTo(diffB);
          });
          await _showOdometerSearchDialog(searchOdometer);
          _vehicleNumberSearchController.clear();
          _odometerSearchController.clear();
          setState(() {});
          FocusScope.of(context).unfocus();
          return;
        }
      } catch (_) {
        // فشل البحث الذكي: استمر في البحث العادي
      }
    }

    // البحث العادي
    _currentQuery = _searchController.text.trim();
    await _loadVehicles(reset: true);
    _vehicleNumberSearchController.clear();
    _odometerSearchController.clear();
    setState(() {});
    FocusScope.of(context).unfocus();
  }

  Future<void> _showOdometerSearchDialog(double searchOdometer) async {
    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title:
              Text('نتائج بحث العداد (${searchOdometer.toStringAsFixed(0)})'),
          content: SizedBox(
            width: double.maxFinite,
            child: _odometerSearchResults.isEmpty
                ? const Text('لا توجد نتائج')
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: _odometerSearchResults.length,
                    itemBuilder: (context, index) {
                      final v = _odometerSearchResults[index];
                      final diff = (v.lastOdometer - searchOdometer).abs();
                      return ListTile(
                        title: Text(
                            '${v.number} ${v.letters ?? ''} - ${v.lastOdometer.toStringAsFixed(0)}'),
                        subtitle: Text('فرق: ${diff.toStringAsFixed(0)}'),
                        onTap: () {
                          Navigator.of(context).pop();
                          _selectVehicle(v);
                        },
                      );
                    },
                  ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('إغلاق')),
          ],
        );
      },
    );
  }

  Future<void> _openFuelMenu(BuildContext fieldContext) async {
    final renderBox = fieldContext.findRenderObject() as RenderBox?;
    final overlay =
        Overlay.of(fieldContext).context.findRenderObject() as RenderBox?;
    RelativeRect position;
    if (renderBox != null && overlay != null) {
      final offset = renderBox.localToGlobal(Offset.zero, ancestor: overlay);
      position = RelativeRect.fromLTRB(
          offset.dx,
          offset.dy + renderBox.size.height,
          offset.dx + renderBox.size.width,
          offset.dy);
    } else {
      position = const RelativeRect.fromLTRB(100, 100, 100, 100);
    }

    final selected = await showMenu<String>(
      context: fieldContext,
      position: position,
      items: _fuelTypes
          .map((t) => PopupMenuItem(value: t, child: Text(t)))
          .toList(),
    );
    if (selected != null) {
      setState(() {
        _fuelTypeController.text = selected;
      });
      FocusScope.of(context).requestFocus(_brandFocus);
    }
  }

  Future<void> _refresh() async {
    await _loadVehicles(reset: true);
  }

  void _goToDashboard() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const DashboardScreen()),
      (route) => false,
    );
  }

  void _selectVehicle(Vehicle vehicle) {
    _selectedVehicle = vehicle;
    _numberController.text = vehicle.number;
    _lettersController.text = vehicle.letters ?? '';
    _registryController.text = vehicle.registry ?? '';
    _codeController.text = vehicle.code ?? '';
    _vehicleTypeController.text = vehicle.vehicleType;
    _fuelTypeController.text = _fuelTypes.contains(vehicle.fuelType)
        ? vehicle.fuelType
        : _fuelTypes[0];
    _brandController.text = vehicle.brand ?? '';
    _lastOdometerController.text = vehicle.lastOdometer.toString();
    _lastOdometerDateController.text =
        _formatDateForDisplay(vehicle.lastOdometerDate);
    _standardConsumptionController.text =
        vehicle.standardConsumption.toString();
    _manufactureYearController.text = vehicle.manufactureYear?.toString() ?? '';
    setState(() {
      _successMessage = null;
      _errorMessage = null;
    });
  }

  void _clearForm({bool preserveMessages = false}) {
    _selectedVehicle = null;
    _numberController.clear();
    _lettersController.clear();
    _registryController.clear();
    _codeController.clear();
    _vehicleTypeController.clear();
    _fuelTypeController.clear();
    _brandController.clear();
    _modelController.clear();
    _lastOdometerController.clear();
    _lastOdometerDateController.clear();
    _standardConsumptionController.clear();
    _manufactureYearController.clear();
    setState(() {
      if (!preserveMessages) {
        _successMessage = null;
        _errorMessage = null;
      }
    });
  }

  DateTime? _parseDate(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return null;
    try {
      if (trimmed.contains('/')) {
        return _displayDateFormat.parseStrict(trimmed);
      }
      return DateTime.parse(trimmed);
    } catch (_) {
      return null;
    }
  }

  String _formatDateForDisplay(String rawDate) {
    final date = _parseDate(rawDate) ?? _parseDate(_defaultOdometerDate);
    return _displayDateFormat.format(date!);
  }

  String _formatDateForApi(String displayDate) {
    final date = _parseDate(displayDate) ?? _parseDate(_defaultOdometerDate);
    return _apiDateFormat.format(date!);
  }

  Future<void> _pickDate(
      BuildContext context, TextEditingController controller) async {
    final initialDate = _parseDate(controller.text) ?? DateTime.now();
    final firstDate = DateTime(1900);
    final lastDate = DateTime(DateTime.now().year + 10);
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
      locale: const Locale('ar'),
      builder: (context, child) {
        return child ?? const SizedBox.shrink();
      },
    );
    if (picked != null) {
      controller.text = _displayDateFormat.format(picked);
    }
  }

  Map<String, dynamic> _vehicleFormJson() {
    return {
      'number': _numberController.text.trim(),
      'letters': _lettersController.text.trim().isEmpty
          ? null
          : _lettersController.text.trim(),
      'registry': _registryController.text.trim().isEmpty
          ? null
          : _registryController.text.trim(),
      'code': _codeController.text.trim().isEmpty
          ? null
          : _codeController.text.trim(),
      'vehicle_type': _vehicleTypeController.text.trim().isEmpty
          ? 'سيارة'
          : _vehicleTypeController.text.trim(),
      'fuel_type': _fuelTypeController.text.trim().isEmpty
          ? _fuelTypes[0]
          : _fuelTypeController.text.trim(),
      'brand': _brandController.text.trim().isEmpty
          ? null
          : _brandController.text.trim(),
      'model': _modelController.text.trim().isEmpty
          ? null
          : _modelController.text.trim(),
      'last_odometer': double.tryParse(_lastOdometerController.text) ?? 0.0,
      'last_odometer_date': _formatDateForApi(
          _lastOdometerDateController.text.trim().isEmpty
              ? _defaultOdometerDate
              : _lastOdometerDateController.text.trim()),
      'standard_consumption':
          double.tryParse(_standardConsumptionController.text) ?? 0.0,
      'manufacture_year': int.tryParse(_manufactureYearController.text.trim()),
    };
  }

  Future<Vehicle?> _findDuplicateVehicle(String registry, String code) async {
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    if (token == null) return null;

    final allVehicles = await ApiService.listVehicles(token, limit: 1000);
    final registryValue = registry.trim().toLowerCase();
    final codeValue = code.trim().toLowerCase();

    for (final vehicle in allVehicles) {
      if (_selectedVehicle != null && vehicle.id == _selectedVehicle!.id) {
        continue;
      }
      if (registryValue.isNotEmpty &&
          vehicle.registry != null &&
          vehicle.registry!.trim().toLowerCase() == registryValue) {
        return vehicle;
      }
      if (codeValue.isNotEmpty &&
          vehicle.code != null &&
          vehicle.code!.trim().toLowerCase() == codeValue) {
        return vehicle;
      }
    }
    return null;
  }

  Future<void> _saveVehicle() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isSaving = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      final token = Provider.of<AuthProvider>(context, listen: false).token;
      if (token == null) throw Exception('غير مسجل الدخول');

      final vehicleJson = _vehicleFormJson();
      final registry = vehicleJson['registry'] as String? ?? '';
      final code = vehicleJson['code'] as String? ?? '';
      final duplicate = await _findDuplicateVehicle(registry, code);
      if (duplicate != null) {
        final duplicateField = duplicate.registry != null &&
                duplicate.registry!.trim().toLowerCase() ==
                    registry.trim().toLowerCase()
            ? 'رقم السجل'
            : 'الكود';
        await showDialog<void>(
          context: context,
          builder: (dialogContext) {
            return AlertDialog(
              title: const Text('تكرار في بيانات المركبة'),
              content: Text(
                  'يوجد مركبة أخرى مسجلة بنفس $duplicateField. لا يمكن حفظ البيانات.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('حسناً'),
                ),
              ],
            );
          },
        );
        setState(() {
          _errorMessage = 'مركبة بنفس $duplicateField موجودة بالفعل.';
        });
        return;
      }

      if (_selectedVehicle == null) {
        final created = await ApiService.createVehicle(token, vehicleJson);
        setState(() {
          _vehicles.insert(0, created);
          _selectedVehicle = created;
          _successMessage = 'تم إضافة المركبة بنجاح';
        });
      } else {
        final updated = await ApiService.updateVehicle(
            token, _selectedVehicle!.id, vehicleJson);
        final index = _vehicles.indexWhere((v) => v.id == updated.id);
        if (index != -1) {
          _vehicles[index] = updated;
        }
        _selectedVehicle = updated;
        setState(() {
          _successMessage = 'تم حفظ بيانات المركبة بنجاح';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'فشل الحفظ: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  Future<void> _importVehicles() async {
    setState(() {
      _successMessage = "تم الضغط على زر الاستيراد";
      _errorMessage = null;
    });

    // Use platform-safe wrapper for picking files.
    final picked = await pickExcelFile();
    if (picked == null || picked.bytes == null) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      final bytes = picked.bytes!;
      final excel = Excel.decodeBytes(bytes);
      final sheet = excel.sheets.values.first;
      final rows = sheet.rows;
      if (rows.isEmpty) throw Exception('ملف الإكسل لا يحتوي على بيانات');

      final headerRow = rows.first;
      final supportedHeaders = {
        'رقم السيارة': 'number',
        'الأحرف': 'letters',
        'رقم السجل': 'registry',
        'الكود': 'code',
        'نوع السيارة': 'vehicle_type',
        'نوع الوقود': 'fuel_type',
        'الماركة': 'brand',
        'عداد آخر تفويلة': 'last_odometer',
        'تاريخ آخر تفويلة': 'last_odometer_date',
        'النسبة القياسية': 'standard_consumption',
        'سنة الصنع': 'manufacture_year',
      };
      final actualHeaders =
          headerRow.map((cell) => '${cell?.value ?? ''}'.trim()).toList();
      final headerIndex = <String, int>{};
      for (var i = 0; i < actualHeaders.length; i++) {
        final header = actualHeaders[i];
        if (supportedHeaders.containsKey(header) &&
            !headerIndex.containsKey(header)) {
          headerIndex[header] = i;
        }
      }
      if (!headerIndex.containsKey('رقم السيارة')) {
        throw Exception(
            'ملف الإكسل يجب أن يحتوي على عمود "رقم السيارة" على الأقل');
      }

      final token = Provider.of<AuthProvider>(context, listen: false).token;
      if (token == null) throw Exception('غير مسجل الدخول');

      String cellValue(List<Data?> row, String headerName) {
        final index = headerIndex[headerName];
        if (index == null || index >= row.length) return '';
        return '${row[index]?.value ?? ''}'.trim();
      }

      final vehiclesJson = <Map<String, dynamic>>[];
      for (final row in rows.skip(1)) {
        if (row.isEmpty ||
            row.every((cell) =>
                cell?.value == null || '${cell?.value}'.trim().isEmpty))
          continue;
        vehiclesJson.add({
          'number': cellValue(row, 'رقم السيارة'),
          'letters': cellValue(row, 'الأحرف'),
          'registry': cellValue(row, 'رقم السجل'),
          'code': cellValue(row, 'الكود'),
          'vehicle_type': cellValue(row, 'نوع السيارة').isNotEmpty
              ? cellValue(row, 'نوع السيارة')
              : 'سيارة',
          'fuel_type': cellValue(row, 'نوع الوقود').isNotEmpty
              ? cellValue(row, 'نوع الوقود')
              : 'بنزين 92',
          'brand': cellValue(row, 'الماركة'),
          'standard_consumption': double.tryParse(
                  cellValue(row, 'النسبة القياسية').isNotEmpty
                      ? cellValue(row, 'النسبة القياسية')
                      : '0') ??
              0.0,
          'last_odometer': double.tryParse(
                  cellValue(row, 'عداد آخر تفويلة').isNotEmpty
                      ? cellValue(row, 'عداد آخر تفويلة')
                      : '0') ??
              0.0,
          'last_odometer_date':
              _formatDateForApi(cellValue(row, 'تاريخ آخر تفويلة')),
          'manufacture_year': int.tryParse(cellValue(row, 'سنة الصنع')),
        });
      }

      if (vehiclesJson.isEmpty)
        throw Exception('ملف الإكسل لا يحتوي على بيانات صالحة');
      final createdVehicles =
          await ApiService.createVehicles(token, vehiclesJson);
      setState(() {
        _vehicles.insertAll(0, createdVehicles);
        _successMessage = 'تم استيراد المركبات بنجاح';
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'فشل الاستيراد: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _exportToExcel() async {
    final excel = Excel.createExcel();
    final sheet = excel['Vehicles'];
    sheet.appendRow([
      'م',
      'رقم السيارة',
      'الأحرف',
      'رقم السجل',
      'الكود',
      'نوع السيارة',
      'نوع الوقود',
      'الماركة',
      'عداد آخر تفويلة',
      'تاريخ آخر تفويلة',
      'النسبة القياسية',
      'سنة الصنع',
    ]);
    for (var i = 0; i < _vehicles.length; i++) {
      final v = _vehicles[i];
      sheet.appendRow([
        (i + 1).toString(),
        v.number,
        v.letters ?? '',
        v.registry ?? '',
        v.code ?? '',
        v.vehicleType,
        v.fuelType ?? '',
        v.brand ?? '',
        v.lastOdometer,
        _formatDateForDisplay(v.lastOdometerDate),
        v.standardConsumption,
        v.manufactureYear?.toString() ?? '',
      ]);
    }

    final bytes = excel.encode();
    if (bytes == null) throw Exception('فشل إنشاء ملف Excel');
    final filename =
        'vehicle_export_${DateTime.now().millisecondsSinceEpoch}.xlsx';
    await saveBytesAsFile(filename, Uint8List.fromList(bytes));
    setState(() {
      _successMessage = 'تم حفظ Excel باسم $filename';
    });
  }

  Future<void> _exportToPdf() async {
    final fontData = await rootBundle.load('assets/fonts/arial.ttf');
    final headers = [
      'م',
      'رقم السيارة',
      'الأحرف',
      'رقم السجل',
      'الكود',
      'نوع السيارة',
      'نوع الوقود',
      'الماركة',
      'عداد آخر تفويلة',
      'تاريخ آخر تفويلة',
      'النسبة القياسية',
      'سنة الصنع',
    ];
    final data = <List<String>>[];
    for (var i = 0; i < _vehicles.length; i++) {
      final v = _vehicles[i];
      data.add([
        (i + 1).toString(),
        v.number,
        v.letters ?? '',
        v.registry ?? '',
        v.code ?? '',
        v.vehicleType,
        v.fuelType ?? '',
        v.brand ?? '',
        v.lastOdometer.toString(),
        _formatDateForDisplay(v.lastOdometerDate),
        v.standardConsumption.toString(),
        v.manufactureYear?.toString() ?? '',
      ]);
    }

    final pdfBytes = await buildReportPdfBytes(
      headers: headers,
      rows: data,
      title: 'تقرير مركبات SCA Fuel',
      fontData: fontData.buffer.asUint8List(),
    );

    final filename =
        'vehicle_export_${DateTime.now().millisecondsSinceEpoch}.pdf';
    await saveBytesAsFile(filename, pdfBytes);
    setState(() {
      _successMessage = 'تم حفظ PDF باسم $filename';
    });
  }

  Future<void> _logout() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.logout();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  Future<void> _confirmDeleteVehicle() async {
    if (_selectedVehicle == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('هل أنت متأكد من حذف المركبة؟'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('لا'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('نعم'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      await _deleteVehicle();
    }
  }

  Future<void> _deleteVehicle() async {
    if (_selectedVehicle == null) return;
    setState(() {
      _isSaving = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      final token = Provider.of<AuthProvider>(context, listen: false).token;
      if (token == null) throw Exception('غير مسجل الدخول');
      final vehicleId = _selectedVehicle?.id;
      if (vehicleId == null) throw Exception('لا توجد مركبة محددة للحذف');
      await ApiService.deleteVehicle(token, vehicleId);
      setState(() {
        _vehicles.removeWhere((v) => v.id == vehicleId);
        _successMessage = 'تم حذف المركبة بنجاح';
      });
      _clearForm(preserveMessages: true);
    } catch (e) {
      final detail = e.toString().replaceFirst('Exception: ', '');
      setState(() {
        _errorMessage = 'فشل حذف المركبة: $detail';
      });
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  // Builds a single vehicle row with serial and fuel type
  Widget _buildVehicleRow(BuildContext context, Vehicle vehicle, int index) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: () => _selectVehicle(vehicle),
      child: Container(
        color: _selectedVehicleIndex == index || _selectedVehicle?.id == vehicle.id
            ? (isDarkMode ? const Color(0xFF3A3A3A) : Colors.blue.shade50)
            : (isDarkMode ? const Color(0xFF2D2D2D) : Colors.white),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        child: Row(
          children: [
            _tableCell(context, (index + 1).toString(), flex: 1),
            _tableCell(context, vehicle.number, flex: 2),
            _tableCell(context, vehicle.letters ?? '-', flex: 1),
            _tableCell(context, vehicle.registry ?? '-', flex: 2),
            _tableCell(context, vehicle.code ?? '-', flex: 1),
            _tableCell(context, vehicle.vehicleType, flex: 2),
            _fuelTypeCell(context, vehicle.fuelType ?? '', flex: 1),
            _tableCell(context, vehicle.brand ?? '-', flex: 2),
            _tableCell(context, vehicle.lastOdometer.toString(), flex: 2),
            _tableCell(context, _formatDateForDisplay(vehicle.lastOdometerDate),
                flex: 2),
            _tableCell(context, vehicle.standardConsumption.toString(),
                flex: 1),
            _tableCell(context, vehicle.manufactureYear?.toString() ?? '-',
                flex: 1),
          ],
        ),
      ),
    );
  }

  Widget _fuelTypeCell(BuildContext context, String fuelType,
      {required int flex}) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final color = _fuelColor(fuelType);
    return Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 4),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 4),
          decoration: BoxDecoration(
            color: color.withOpacity(isDarkMode ? 0.3 : 0.12),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: color.withOpacity(0.6)),
          ),
          child: Align(
            alignment: Alignment.center,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                fuelType.isEmpty ? '-' : fuelType,
                maxLines: 1,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isDarkMode ? Colors.white : Colors.black87,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Color _fuelColor(String fuelType) {
    switch (fuelType) {
      case 'بنزين 92':
        return Colors.orange;
      case 'بنزين 95':
        return Colors.red;
      case 'سولار':
        return Colors.blueGrey;
      default:
        return Colors.grey;
    }
  }

  Widget _tableCell(BuildContext context, String text, {required int flex}) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: isDarkMode ? Colors.white : Colors.black87,
          ),
        ),
      ),
    );
  }

  Widget _tableHeaderCell(BuildContext context, String text,
      {required int flex}) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: isDarkMode ? const Color(0xFFEAEAEA) : Colors.black87,
          ),
        ),
      ),
    );
  }

  Widget _buildTableHeader(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Container(
      color: isDarkMode ? const Color(0xFF2D2D2D) : const Color(0xFFF3F3F3),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        children: [
          _tableHeaderCell(context, 'م', flex: 1),
          _tableHeaderCell(context, 'رقم السيارة', flex: 2),
          _tableHeaderCell(context, 'الأحرف', flex: 1),
          _tableHeaderCell(context, 'رقم السجل', flex: 2),
          _tableHeaderCell(context, 'الكود', flex: 1),
          _tableHeaderCell(context, 'نوع السيارة', flex: 2),
          _tableHeaderCell(context, 'نوع الوقود', flex: 1),
          _tableHeaderCell(context, 'الماركة', flex: 2),
          _tableHeaderCell(context, 'عداد آخر تفويلة', flex: 2),
          _tableHeaderCell(context, 'تاريخ آخر تفويلة', flex: 2),
          _tableHeaderCell(context, 'النسبة القياسية', flex: 1),
          _tableHeaderCell(context, 'سنة الصنع', flex: 1),
        ],
      ),
    );
  }

  Widget _buildHeaderButton(String label, IconData icon, VoidCallback onPressed,
      {Color? backgroundColor}) {
    return FilledButton.icon(
      icon: Icon(icon, size: 18),
      label: Text(label),
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        backgroundColor: backgroundColor ?? const Color(0xFF1565C0),
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildHeaderIconButton(String tooltip, IconData icon,
      VoidCallback onPressed, {Color? backgroundColor}) {
    return IconButton.filled(
      tooltip: tooltip,
      onPressed: onPressed,
      icon: Icon(icon, size: 20),
      style: IconButton.styleFrom(
        backgroundColor: backgroundColor ?? const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        minimumSize: const Size(44, 44),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
      appBar: ScaAppBar(
          title: 'بيانات المركبات', showBack: true, onBack: _goToDashboard),
      drawer: ScaDrawer(
        currentRoute: 'vehicle_data',
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
          Navigator.of(context)
              .push(MaterialPageRoute(builder: (_) => StoreScreen(initialTab: index)));
        },
        onGasTab: (index) {
          Navigator.of(context)
              .push(MaterialPageRoute(builder: (_) => GasScreen(initialTab: index)));
        },
        onVehicleData: () {},
        onReports: () {
          Navigator.of(context)
              .push(MaterialPageRoute(builder: (_) => const ReportsScreen()));
        },
        onReportTab: (index) {
          Navigator.of(context)
              .push(MaterialPageRoute(builder: (_) => ReportsScreen(initialTab: index)));
        },
        onArchive: () {
          Navigator.of(context)
              .push(MaterialPageRoute(builder: (_) => const ArchiveScreen()));
        },
        onSettings: () {
          Navigator.of(context)
              .push(MaterialPageRoute(builder: (_) => const SettingsScreen()));
        },
        onLogout: _logout,
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: _odometerSearchController,
                    focusNode: _odometerSearchFocus,
                    decoration: InputDecoration(
                      labelText: 'بحث بالعداد (قريب)',
                      border: const OutlineInputBorder(),
                      suffixIcon: _odometerSearchController.text.isEmpty
                          ? null
                          : IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _odometerSearchController.clear();
                                _odometerSearchFocus.requestFocus();
                                setState(() {});
                              },
                            ),
                    ),
                    textInputAction: TextInputAction.search,
                    onSubmitted: (_) => _onSearch(),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 1,
                  child: TextField(
                    controller: _vehicleNumberSearchController,
                    focusNode: _vehicleNumberSearchFocus,
                    decoration: InputDecoration(
                      labelText: 'بحث برقم السيارة',
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.directions_car),
                      suffixIcon: _vehicleNumberSearchController.text.isEmpty
                          ? null
                          : IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _vehicleNumberSearchController.clear();
                                _vehicleNumberSearchFocus.requestFocus();
                                setState(() {});
                              },
                            ),
                    ),
                    textInputAction: TextInputAction.search,
                    onSubmitted: (_) => _onSearch(),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 1,
                  child: TextField(
                    controller: _registrySearchController,
                    focusNode: _registrySearchFocus,
                    decoration: InputDecoration(
                      labelText: 'بحث برقم السجل',
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.badge),
                      suffixIcon: _registrySearchController.text.isEmpty
                          ? null
                          : IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _registrySearchController.clear();
                                _registrySearchFocus.requestFocus();
                                setState(() {});
                              },
                            ),
                    ),
                    textInputAction: TextInputAction.search,
                    onSubmitted: (_) => _onSearch(),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 12),
                _buildHeaderIconButton('بحث', Icons.search, _onSearch),
                const SizedBox(width: 8),
                _buildHeaderIconButton(
                  'إضافة مركبة', Icons.add, _clearForm),
                const SizedBox(width: 8),
                _buildHeaderIconButton(
                  'استيراد المركبات', Icons.upload_file, _importVehicles),
                const SizedBox(width: 8),
                _buildHeaderIconButton('تصدير Excel', Icons.table_view,
                  _exportToExcel, backgroundColor: Colors.green.shade700),
                const SizedBox(width: 8),
                _buildHeaderIconButton('تصدير PDF', Icons.picture_as_pdf,
                  _exportToPdf, backgroundColor: Colors.red.shade700),
                const SizedBox(width: 8),
                _buildHeaderButton('تغيير رقم السيارة', Icons.edit_road, () {
                  Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => const VehicleIdentityChangeScreen()));
                }, backgroundColor: const Color(0xFF00897B)),
              ],
            ),
            const SizedBox(height: 12),
            if (_errorMessage != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8)),
                child: Text(_errorMessage!,
                    style: const TextStyle(color: Colors.red)),
              ),
            if (_successMessage != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8)),
                child: Text(_successMessage!,
                    style: TextStyle(color: Colors.green.shade900)),
              ),
            const SizedBox(height: 12),
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Card(
                      color:
                          isDarkMode ? const Color(0xFF2D2D2D) : Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(
                              color: isDarkMode
                                  ? const Color(0xFF212121)
                                  : const Color(0xFFF2F2F2),
                              borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(12)),
                            ),
                            child: Text(
                              'قائمة المركبات',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: isDarkMode
                                    ? const Color(0xFFEAEAEA)
                                    : Colors.black87,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _buildTableHeader(context),
                                const SizedBox(height: 4),
                                Expanded(
                                  child: Focus(
                                    focusNode: _vehicleListFocus,
                                    autofocus: true,
                                    onKeyEvent: (node, event) {
                                      if (event is! KeyDownEvent ||
                                          _vehicles.isEmpty) {
                                        return KeyEventResult.ignored;
                                      }
                                      if (event.logicalKey ==
                                          LogicalKeyboardKey.arrowDown) {
                                        setState(() => _selectedVehicleIndex =
                                            ((_selectedVehicleIndex ?? -1) + 1)
                                                .clamp(0, _vehicles.length - 1));
                                        return KeyEventResult.handled;
                                      }
                                      if (event.logicalKey ==
                                          LogicalKeyboardKey.arrowUp) {
                                        setState(() => _selectedVehicleIndex =
                                            ((_selectedVehicleIndex ?? _vehicles.length) - 1)
                                                .clamp(0, _vehicles.length - 1));
                                        return KeyEventResult.handled;
                                      }
                                      if (event.logicalKey ==
                                              LogicalKeyboardKey.enter &&
                                          _selectedVehicleIndex != null) {
                                        _selectVehicle(
                                            _vehicles[_selectedVehicleIndex!]);
                                        return KeyEventResult.handled;
                                      }
                                      return KeyEventResult.ignored;
                                    },
                                    child: RefreshIndicator(
                                    onRefresh: _refresh,
                                    child: _isLoading && _vehicles.isEmpty
                                        ? const Center(
                                            child: CircularProgressIndicator())
                                        : ListView.builder(
                                            controller: _scrollController,
                                            itemCount: _vehicles.length +
                                                (_hasMore ? 1 : 0),
                                            itemBuilder: (context, index) {
                                              if (index >= _vehicles.length) {
                                                return const Padding(
                                                  padding: EdgeInsets.symmetric(
                                                      vertical: 24),
                                                  child: Center(
                                                      child:
                                                          CircularProgressIndicator()),
                                                );
                                              }
                                              return _buildVehicleRow(context,
                                                  _vehicles[index], index);
                                            },
                                          ),
                                  ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 12),
                            decoration: const BoxDecoration(
                              color: Color(0xFFF2F2F2),
                              borderRadius: BorderRadius.vertical(
                                  bottom: Radius.circular(12)),
                            ),
                            child: Row(
                              children: [
                                Text(
                                    'عرض ${_vehicles.length} من ${_hasMore ? 'أكثر من ' : ''} ${_vehicles.length}',
                                    style: const TextStyle(fontSize: 12)),
                                const Spacer(),
                                Text('صفحة 20 عنصر / تحميل ذكي',
                                    style: const TextStyle(
                                        fontSize: 12, color: Colors.black54)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 1,
                    child: Card(
                      color:
                          isDarkMode ? const Color(0xFF2D2D2D) : Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Form(
                          key: _formKey,
                          child: FocusTraversalGroup(
                            child: SingleChildScrollView(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Text('تفاصيل المركبة',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color: isDarkMode
                                              ? const Color(0xFFEAEAEA)
                                              : Colors.black87)),
                                  const SizedBox(height: 12),
                                  _buildTextField(
                                      context, 'رقم السيارة', _numberController,
                                      focusNode: _numberFocus,
                                      nextFocus: _lettersFocus,
                                      required: true),
                                  const SizedBox(height: 10),
                                  _buildTextField(
                                      context, 'الأحرف', _lettersController,
                                      focusNode: _lettersFocus,
                                      nextFocus: _registryFocus,
                                      required: true),
                                  const SizedBox(height: 10),
                                  _buildTextField(
                                      context, 'رقم السجل', _registryController,
                                      focusNode: _registryFocus,
                                      nextFocus: _codeFocus,
                                      required: true),
                                  const SizedBox(height: 10),
                                  _buildTextField(
                                    context,
                                    'الكود',
                                    _codeController,
                                    focusNode: _codeFocus,
                                    nextFocus: _vehicleTypeFocus,
                                    required: true,
                                  ),
                                  const SizedBox(height: 10),
                                  _buildTextField(
                                    context,
                                    'نوع السيارة',
                                    _vehicleTypeController,
                                    focusNode: _vehicleTypeFocus,
                                    nextFocus: _fuelTypeFocus,
                                    required: true,
                                    enableSuggestions: false,
                                    autocorrect: false,
                                  ),
                                  const SizedBox(height: 10),
                                  // Custom focusable fuel type field with keyboard support
                                  Focus(
                                    focusNode: _fuelTypeFocus,
                                    onKey: (node, event) {
                                      if (event is RawKeyDownEvent) {
                                        if (event.logicalKey ==
                                                LogicalKeyboardKey.enter ||
                                            event.logicalKey ==
                                                LogicalKeyboardKey.space ||
                                            event.logicalKey ==
                                                LogicalKeyboardKey.arrowDown) {
                                          _openFuelMenu(context);
                                          return KeyEventResult.handled;
                                        }
                                      }
                                      return KeyEventResult.ignored;
                                    },
                                    child: Builder(builder: (fieldContext) {
                                      final selected =
                                          _fuelTypeController.text.isNotEmpty &&
                                                  _fuelTypes.contains(
                                                      _fuelTypeController.text)
                                              ? _fuelTypeController.text
                                              : _fuelTypes[0];
                                      return GestureDetector(
                                        behavior: HitTestBehavior.opaque,
                                        onTap: () =>
                                            _openFuelMenu(fieldContext),
                                        child: InputDecorator(
                                          decoration: InputDecoration(
                                            labelText: 'نوع الوقود',
                                            border: OutlineInputBorder(
                                              borderSide: BorderSide(
                                                  color: isDarkMode
                                                      ? Colors.grey.shade700
                                                      : Colors.grey.shade400),
                                            ),
                                            filled: true,
                                            fillColor: isDarkMode
                                                ? const Color(0xFF2D2D2D)
                                                : Colors.white,
                                          ),
                                          child: Row(
                                            children: [
                                              Expanded(child: Text(selected)),
                                              const Icon(Icons.arrow_drop_down),
                                            ],
                                          ),
                                        ),
                                      );
                                    }),
                                  ),
                                  const SizedBox(height: 10),
                                  _buildTextField(
                                      context, 'الماركة', _brandController,
                                      focusNode: _brandFocus,
                                      nextFocus: _lastOdometerFocus),
                                  const SizedBox(height: 10),
                                  _buildTextField(context, 'عداد آخر تفويلة',
                                      _lastOdometerController,
                                      focusNode: _lastOdometerFocus,
                                      nextFocus: _lastOdometerDateFocus,
                                      keyboardType: TextInputType.number),
                                  const SizedBox(height: 10),
                                  _buildTextField(
                                    context,
                                    'تاريخ آخر تفويلة',
                                    _lastOdometerDateController,
                                    focusNode: _lastOdometerDateFocus,
                                    nextFocus: _standardConsumptionFocus,
                                    hintText: _displayDateFormat
                                        .format(DateTime.now()),
                                    isDate: true,
                                  ),
                                  const SizedBox(height: 10),
                                  _buildTextField(context, 'النسبة القياسية',
                                      _standardConsumptionController,
                                      focusNode: _standardConsumptionFocus,
                                      nextFocus: _manufactureYearFocus,
                                      keyboardType: TextInputType.number),
                                  const SizedBox(height: 10),
                                  _buildTextField(context, 'سنة الصنع',
                                      _manufactureYearController,
                                      focusNode: _manufactureYearFocus,
                                      nextFocus: _saveButtonFocus,
                                      keyboardType: TextInputType.number),
                                  const SizedBox(height: 18),
                                  Focus(
                                    focusNode: _saveButtonFocus,
                                    onKey: (node, event) {
                                      if (event is RawKeyDownEvent &&
                                          (event.logicalKey ==
                                                  LogicalKeyboardKey.enter ||
                                              event.logicalKey ==
                                                  LogicalKeyboardKey.space)) {
                                        if (!_isSaving) {
                                          _saveVehicle();
                                        }
                                        return KeyEventResult.handled;
                                      }
                                      return KeyEventResult.ignored;
                                    },
                                    child: FilledButton.icon(
                                      icon: const Icon(Icons.save),
                                      label: Text(
                                          _isSaving ? 'جارٍ الحفظ...' : 'حفظ'),
                                      onPressed:
                                          _isSaving ? null : _saveVehicle,
                                      style: FilledButton.styleFrom(
                                          backgroundColor:
                                              const Color(0xFF1565C0),
                                          foregroundColor: Colors.white),
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  if (_selectedVehicle != null)
                                    Focus(
                                      focusNode: _deleteButtonFocus,
                                      onKey: (node, event) {
                                        if (event is RawKeyDownEvent &&
                                            (event.logicalKey ==
                                                    LogicalKeyboardKey.enter ||
                                                event.logicalKey ==
                                                    LogicalKeyboardKey.space)) {
                                          _confirmDeleteVehicle();
                                          return KeyEventResult.handled;
                                        }
                                        return KeyEventResult.ignored;
                                      },
                                      child: FilledButton.icon(
                                        icon: const Icon(Icons.delete),
                                        label: const Text('حذف'),
                                        onPressed: _confirmDeleteVehicle,
                                        style: FilledButton.styleFrom(
                                            backgroundColor:
                                                const Color(0xFFD32F2F),
                                            foregroundColor: Colors.white),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(
    BuildContext context,
    String label,
    TextEditingController controller, {
    FocusNode? focusNode,
    FocusNode? nextFocus,
    String? hintText,
    bool required = false,
    bool isDate = false,
    TextInputType keyboardType = TextInputType.text,
    bool enableSuggestions = true,
    bool autocorrect = true,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      keyboardType: isDate ? TextInputType.datetime : keyboardType,
      enableSuggestions: enableSuggestions,
      autocorrect: autocorrect,
      textInputAction:
          nextFocus != null ? TextInputAction.next : TextInputAction.done,
      onFieldSubmitted: (_) {
        if (nextFocus != null) {
          FocusScope.of(context).requestFocus(nextFocus);
        } else {
          FocusScope.of(context).unfocus();
        }
      },
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: isDarkMode ? Colors.white : Colors.black87,
      ),
      readOnly: false,
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        border: OutlineInputBorder(
          borderSide: BorderSide(
              color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade400),
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(
              color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade400),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: const Color(0xFF1565C0), width: 1.8),
        ),
        filled: true,
        fillColor: isDarkMode ? const Color(0xFF2D2D2D) : Colors.white,
        labelStyle: TextStyle(
            color: isDarkMode ? const Color(0xFFEAEAEA) : Colors.black87),
        suffixIcon: isDate
            ? IconButton(
                icon: const Icon(Icons.calendar_today),
                onPressed: () async {
                  await _pickDate(context, controller);
                },
              )
            : null,
      ),
      validator: (value) {
        if (required && (value == null || value.trim().isEmpty)) {
          return 'هذا الحقل مطلوب';
        }
        if (isDate &&
            value != null &&
            value.trim().isNotEmpty &&
            _parseDate(value.trim()) == null) {
          return 'يرجى إدخال تاريخ صالحًا بتنسيق ${_displayDateFormat.pattern} أو yyyy-MM-dd';
        }
        return null;
      },
    );
  }
}
