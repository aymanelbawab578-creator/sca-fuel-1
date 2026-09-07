import 'dart:convert';
import 'dart:typed_data';

import 'package:excel/excel.dart' hide Border hide Border;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart' as pdf_lib;
import 'package:pdf/widgets.dart' as pw;
import 'package:provider/provider.dart';

import '../models/refuel.dart';
import '../models/vehicle.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../services/direct_database/store_service.dart';
import '../utils/file_save_helper.dart';
import '../widgets/sca_layout.dart';
import 'archive_screen.dart';
import 'dashboard_screen.dart';
import 'login_screen.dart';
import 'reports_screen.dart';
import 'gas_screen.dart';
import 'settings_screen.dart';
import 'vehicle_data_screen.dart';
import 'vehicle_search_screen.dart';
import 'missions_tab.dart';
import 'inventory_tab.dart';

class StoreScreen extends StatefulWidget {
  final int initialTab;

  const StoreScreen({super.key, this.initialTab = 0});

  @override
  State<StoreScreen> createState() => _StoreScreenState();
}

class _StoreScreenState extends State<StoreScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  double _solarBalance = 0.0;
  double _gasoline92Balance = 0.0;
  double _gasoline95Balance = 0.0;
  int _solarBalanceDisplay = 0;
  int _gasoline92BalanceDisplay = 0;
  int _gasoline95BalanceDisplay = 0;
  int _solarCardBalanceDisplay = 0;
  int _gasoline92CardBalanceDisplay = 0;
  int _gasoline95CardBalanceDisplay = 0;
  bool _isLoadingBalances = false;
  bool _isStoreBalanceExpanded = true;
  bool _isLoadingPrices = false;
  bool _isLoadingVehicles = false;
  String? _balancesError;
  String? _pricesError;
  List<Vehicle> _vehicles = [];
  final TextEditingController _invoiceNumberController =
      TextEditingController();
  final TextEditingController _invoiceSearchController =
      TextEditingController();
  DateTime? _invoiceFilterStartDate;
  DateTime? _invoiceFilterEndDate;
  final TextEditingController _settlementStartDateController =
      TextEditingController();
  final TextEditingController _settlementEndDateController =
      TextEditingController();
  final TextEditingController _settlementVehicleNumberController =
      TextEditingController();
  final TextEditingController _priceChangeDateController =
      TextEditingController();
  DateTime _invoiceDate = DateTime.now();
  DateTime _priceChangeDate = DateTime.now();
  DateTime _settlementStartDate =
      DateTime.now().subtract(const Duration(days: 30));
  DateTime _settlementEndDate = DateTime.now();
  String? _settlementFuelType;
  List<Map<String, dynamic>> _invoiceRecords = [];
  bool _isLoadingInvoiceRecords = false;
  String? _invoiceRecordsError;
  bool _isLoadingSettlementReport = false;
  String? _settlementReportError;
  List<Map<String, dynamic>> _settlementRows = [];
  Map<String, dynamic> _settlementSummary = {};
  bool _isLoadingPriceChangeLogs = false;
  String? _priceChangeError;
  final _invoiceTableFocus = FocusNode();
  int? _selectedInvoiceIndex;
  final _settlementTableFocus = FocusNode();
  int? _selectedSettlementIndex;
  List<Map<String, dynamic>> _priceChangeLogs = [];
  final Map<String, TextEditingController> _priceChangeControllers = {
    'سولار': TextEditingController(),
    'بنزين 92': TextEditingController(),
    'بنزين 95': TextEditingController(),
  };
  final Map<String, FocusNode> _priceChangeFocusNodes = {
    'سولار': FocusNode(),
    'بنزين 92': FocusNode(),
    'بنزين 95': FocusNode(),
  };
  final TextEditingController _solarQuantityController =
      TextEditingController();
  final TextEditingController _gasoline92QuantityController =
      TextEditingController();
  final TextEditingController _gasoline95QuantityController =
      TextEditingController();
  double _solarPrice = 0.0;
  double _gasoline92Price = 0.0;
  double _gasoline95Price = 0.0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 6,
      vsync: this,
      initialIndex: widget.initialTab.clamp(0, 5).toInt(),
    );
    _loadStoreBalances();
    _loadInvoicePrices();
    _loadInvoiceRecords();
    _loadPriceChangeLogs();
    _loadVehicles();
    // Initialize settlement date fields so the tab shows default dates immediately
    _settlementStartDateController.text = _formatDate(_settlementStartDate);
    _settlementEndDateController.text = _formatDate(_settlementEndDate);
    _priceChangeDateController.text = _formatDate(_priceChangeDate);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _invoiceNumberController.dispose();
    _invoiceSearchController.dispose();
    _settlementStartDateController.dispose();
    _settlementEndDateController.dispose();
    _settlementVehicleNumberController.dispose();
    _priceChangeDateController.dispose();
    for (final controller in _priceChangeControllers.values) {
      controller.dispose();
    }
    for (final focusNode in _priceChangeFocusNodes.values) {
      focusNode.dispose();
    }
    _solarQuantityController.dispose();
    _gasoline92QuantityController.dispose();
    _gasoline95QuantityController.dispose();
    _invoiceTableFocus.dispose();
    _settlementTableFocus.dispose();
    super.dispose();
  }

  Future<void> _loadVehicles() async {
    setState(() {
      _isLoadingVehicles = true;
    });
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    if (token == null) {
      if (mounted) {
        setState(() {
          _isLoadingVehicles = false;
          _vehicles = [];
        });
      }
      return;
    }
    try {
      final vehicles = await ApiService.listVehicles(token, limit: 200);
      if (!mounted) return;
      setState(() {
        _vehicles = vehicles;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _vehicles = [];
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingVehicles = false;
        });
      }
    }
  }

  Future<void> _loadStoreBalances() async {
  setState(() {
    _isLoadingBalances = true;
    _balancesError = null;
  });

  try {
    final balances = await DirectStoreService.fetchStoreBalances();

    if (!mounted) return;

    setState(() {
      _solarBalance = (balances['solar'] as num?)?.toDouble() ?? 0.0;
      _gasoline92Balance =
          (balances['gasoline_92'] as num?)?.toDouble() ?? 0.0;
      _gasoline95Balance =
          (balances['gasoline_95'] as num?)?.toDouble() ?? 0.0;

      _solarBalanceDisplay =
          (balances['display']?['solar'] as num?)?.toInt() ??
              _solarBalance.round();

      _gasoline92BalanceDisplay =
          (balances['display']?['gasoline_92'] as num?)?.toInt() ??
              _gasoline92Balance.round();

      _gasoline95BalanceDisplay =
          (balances['display']?['gasoline_95'] as num?)?.toInt() ??
              _gasoline95Balance.round();

      _solarCardBalanceDisplay =
          (balances['display']?['cards']?['solar'] as num?)?.toInt() ?? 0;

      _gasoline92CardBalanceDisplay =
          (balances['display']?['cards']?['gasoline_92'] as num?)?.toInt() ?? 0;

      _gasoline95CardBalanceDisplay =
          (balances['display']?['cards']?['gasoline_95'] as num?)?.toInt() ?? 0;
    });
  } catch (e) {
    if (!mounted) return;

    setState(() {
      _balancesError = 'فشل تحميل أرصدة المخزن: $e';
    });
  } finally {
    if (mounted) {
      setState(() {
        _isLoadingBalances = false;
      });
    }
  }
}

  Future<void> _loadInvoicePrices() async {
    setState(() {
      _isLoadingPrices = true;
      _pricesError = null;
    });
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    if (token == null) {
      if (mounted) {
        setState(() {
          _pricesError = 'يرجى تسجيل الدخول أولاً';
          _isLoadingPrices = false;
        });
      }
      return;
    }
    try {
      final result = await ApiService.fetchInvoicePrices(token);
      if (!mounted) return;
      final prices = Map<String, dynamic>.from(result['prices'] ?? {});
      setState(() {
        _solarPrice = (prices['سولار'] as num?)?.toDouble() ?? 0.0;
        _gasoline92Price = (prices['بنزين 92'] as num?)?.toDouble() ?? 0.0;
        _gasoline95Price = (prices['بنزين 95'] as num?)?.toDouble() ?? 0.0;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _pricesError = 'فشل تحميل أسعار الفواتير';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingPrices = false;
        });
      }
    }
  }

  double get _solarTotal {
    final quantity = double.tryParse(_solarQuantityController.text) ?? 0.0;
    return quantity * _solarPrice;
  }

  double get _gasoline92Total {
    final quantity = double.tryParse(_gasoline92QuantityController.text) ?? 0.0;
    return quantity * _gasoline92Price;
  }

  double get _gasoline95Total {
    final quantity = double.tryParse(_gasoline95QuantityController.text) ?? 0.0;
    return quantity * _gasoline95Price;
  }

  double get _invoiceTotal => _solarTotal + _gasoline92Total + _gasoline95Total;

  Future<void> _pickInvoiceDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _invoiceDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      locale: const Locale('ar'),
    );
    if (picked != null) {
      setState(() {
        _invoiceDate = picked;
      });
    }
  }

  Future<void> _showAddInvoiceDialog() async {
    _invoiceNumberController.clear();
    _solarQuantityController.clear();
    _gasoline92QuantityController.clear();
    _gasoline95QuantityController.clear();
    setState(() {});

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        final invoiceNumberFocus = FocusNode();
        final dateFocus = FocusNode();
        final solarFocus = FocusNode();
        final gasoline92Focus = FocusNode();
        final gasoline95Focus = FocusNode();

        return StatefulBuilder(
          builder: (context, setStateDialog) {
            void updateTotals() {
              setStateDialog(() {});
            }

            KeyEventResult handleFieldKey(
                KeyEvent event, FocusNode? next, FocusNode? previous,
                VoidCallback? onSubmit) {
              if (event is! KeyDownEvent) return KeyEventResult.ignored;
              final key = event.logicalKey;
              if (key == LogicalKeyboardKey.enter) {
                if (next != null) {
                  FocusScope.of(context).requestFocus(next);
                } else {
                  onSubmit?.call();
                }
                return KeyEventResult.handled;
              }
              if ((key == LogicalKeyboardKey.arrowRight ||
                      key == LogicalKeyboardKey.arrowDown) &&
                  next != null) {
                FocusScope.of(context).requestFocus(next);
                return KeyEventResult.handled;
              }
              if ((key == LogicalKeyboardKey.arrowLeft ||
                      key == LogicalKeyboardKey.arrowUp) &&
                  previous != null) {
                FocusScope.of(context).requestFocus(previous);
                return KeyEventResult.handled;
              }
              return KeyEventResult.ignored;
            }

            Widget buildFuelRow({
              required String label,
              required TextEditingController quantityController,
              required FocusNode focusNode,
              required FocusNode nextFocus,
              required FocusNode previousFocus,
              required double unitPrice,
              required double total,
            }) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 90,
                      child: Text(label,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 14)),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Focus(
                        onKeyEvent: (node, event) => handleFieldKey(
                          event,
                          focusNode == gasoline95Focus ? null : nextFocus,
                          previousFocus,
                          focusNode == gasoline95Focus
                            ? () => _saveInvoice(dialogContext)
                            : null),
                        child: TextField(
                        controller: quantityController,
                        focusNode: focusNode,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        textInputAction: nextFocus == gasoline95Focus
                            ? TextInputAction.done
                            : TextInputAction.next,
                        onChanged: (_) => updateTotals(),
                        onSubmitted: (_) {
                          if (nextFocus != gasoline95Focus) {
                            FocusScope.of(context).requestFocus(nextFocus);
                          } else {
                            _saveInvoice(dialogContext);
                          }
                        },
                        decoration: const InputDecoration(
                          labelText: 'الكمية',
                          border: OutlineInputBorder(),
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 10, vertical: 12),
                        ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 92,
                      child: _buildReadOnlyField(
                          'السعر', unitPrice.toStringAsFixed(2)),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 112,
                      child: _buildReadOnlyField(
                          'القيمة', total.toStringAsFixed(2),
                          isBold: true),
                    ),
                  ],
                ),
              );
            }

            return AlertDialog(
              title: const Text('إضافة فاتورة'),
              content: SizedBox(
                width: 720,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Focus(
                              onKeyEvent: (node, event) => handleFieldKey(
                                  event, dateFocus, null, null),
                              child: TextField(
                              controller: _invoiceNumberController,
                              focusNode: invoiceNumberFocus,
                              textInputAction: TextInputAction.next,
                              onSubmitted: (_) => FocusScope.of(context)
                                  .requestFocus(dateFocus),
                              decoration: const InputDecoration(
                                labelText: 'رقم الفاتورة',
                                border: OutlineInputBorder(),
                              ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Focus(
                              onKeyEvent: (node, event) => handleFieldKey(
                                  event, solarFocus, invoiceNumberFocus, null),
                              child: TextField(
                              readOnly: true,
                              focusNode: dateFocus,
                              onTap: _pickInvoiceDate,
                              textInputAction: TextInputAction.next,
                              onSubmitted: (_) => FocusScope.of(context)
                                  .requestFocus(solarFocus),
                              decoration: InputDecoration(
                                labelText: 'تاريخ الفاتورة',
                                border: const OutlineInputBorder(),
                                suffixIcon: IconButton(
                                  icon: const Icon(Icons.calendar_month),
                                  onPressed: _pickInvoiceDate,
                                ),
                                hintText: _formatDate(_invoiceDate),
                              ),
                            ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      buildFuelRow(
                        label: 'سولار',
                        quantityController: _solarQuantityController,
                        focusNode: solarFocus,
                        nextFocus: gasoline92Focus,
                        previousFocus: dateFocus,
                        unitPrice: _solarPrice,
                        total: _solarTotal,
                      ),
                      buildFuelRow(
                        label: 'بنزين 92',
                        quantityController: _gasoline92QuantityController,
                        focusNode: gasoline92Focus,
                        nextFocus: gasoline95Focus,
                        previousFocus: solarFocus,
                        unitPrice: _gasoline92Price,
                        total: _gasoline92Total,
                      ),
                      buildFuelRow(
                        label: 'بنزين 95',
                        quantityController: _gasoline95QuantityController,
                        focusNode: gasoline95Focus,
                        nextFocus: gasoline95Focus,
                        previousFocus: gasoline92Focus,
                        unitPrice: _gasoline95Price,
                        total: _gasoline95Total,
                      ),
                      const SizedBox(height: 12),
                      const Divider(),
                      const SizedBox(height: 8),
                      _buildReadOnlyField('إجمالي قيمة الفاتورة',
                          _invoiceTotal.toStringAsFixed(2),
                          isBold: true),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('إلغاء'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    await _saveInvoice(dialogContext);
                  },
                  child: const Text('حفظ الفاتورة'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildReadOnlyField(String label, String value,
      {bool isBold = false}) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      child: Text(
        value,
        style: TextStyle(
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            fontSize: 16),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  Future<void> _pickSettlementStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _settlementStartDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      locale: const Locale('ar'),
    );
    if (picked != null) {
      setState(() {
        _settlementStartDate = picked;
        _settlementStartDateController.text = _formatDate(picked);
      });
    }
  }

  Future<void> _pickSettlementEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _settlementEndDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      locale: const Locale('ar'),
    );
    if (picked != null) {
      setState(() {
        _settlementEndDate = picked;
        _settlementEndDateController.text = _formatDate(picked);
      });
    }
  }

  Future<void> _loadPriceChangeLogs() async {
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    if (token == null) {
      if (!mounted) return;
      setState(() {
        _priceChangeLogs = [];
        _priceChangeError = 'يرجى تسجيل الدخول أولاً';
      });
      return;
    }

    setState(() {
      _isLoadingPriceChangeLogs = true;
      _priceChangeError = null;
    });

    try {
      final logs = await ApiService.fetchPriceChangeLogs(token);
      if (!mounted) return;
      setState(() {
        _priceChangeLogs = logs;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _priceChangeError = e.toString();
        _priceChangeLogs = [];
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingPriceChangeLogs = false;
        });
      }
    }
  }

  Future<void> _pickPriceChangeDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _priceChangeDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      locale: const Locale('ar'),
    );
    if (picked != null) {
      setState(() {
        _priceChangeDate = picked;
        _priceChangeDateController.text = _formatDate(picked);
      });
    }
  }

  Future<void> _deletePriceChangeLog(int logId) async {
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    if (token == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('يرجى تسجيل الدخول أولاً')));
      return;
    }

    try {
      await ApiService.deletePriceChangeLog(token, logId);
      if (!mounted) return;
      await _loadPriceChangeLogs();
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم حذف سجل تغيير السعر')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('فشل حذف سجل تغيير السعر: ${e.toString()}')));
    }
  }

  Future<void> _savePriceChange() async {
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    if (token == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('يرجى تسجيل الدخول أولاً')));
      return;
    }

    final items = <Map<String, dynamic>>[];
    for (final entry in _priceChangeControllers.entries) {
      final fuelType = entry.key;
      final rawValue = entry.value.text.trim();
      if (rawValue.isEmpty) {
        continue;
      }
      final newPrice = double.tryParse(rawValue);
      if (newPrice == null || newPrice <= 0) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('السعر الجديد غير صحيح لنوع الوقود $fuelType')));
        return;
      }
      final oldPrice = _fuelPriceByName(fuelType);
      items.add({
        'fuel_type': fuelType,
        'old_price': oldPrice,
        'new_price': newPrice,
      });
    }

    if (items.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('يرجى إدخال سعر جديد واحد على الأقل')));
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد تغيير السعر'),
        content: const Text(
            'سيؤدي هذا إلى تعديل أرصدة المخزن وأسعار حاسبة الفواتير. هل تريد المتابعة؟'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('إلغاء')),
          ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('تأكيد')),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await ApiService.applyPriceChange(token, {
        'change_date': _formatDate(_priceChangeDate),
        'items': items,
      });
      if (!mounted) return;
      await _loadStoreBalances();
      await _loadInvoicePrices();
      await _loadPriceChangeLogs();
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم حفظ تغيير السعر بنجاح')));
      for (final controller in _priceChangeControllers.values) {
        controller.clear();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('فشل حفظ تغيير السعر: ${e.toString()}')));
    }
  }

  List<Map<String, dynamic>> _priceChangeDetails(
      Map<String, dynamic> log) {
    final apiDetails = log['details'];
    if (apiDetails is List) {
      return apiDetails
          .whereType<Map>()
          .map((detail) => Map<String, dynamic>.from(detail))
          .toList();
    }
    final rawDetails = log['note']?.toString();
    if (rawDetails != null && rawDetails.isNotEmpty) {
      try {
        final decoded = jsonDecode(rawDetails);
        if (decoded is List) {
          return decoded
              .whereType<Map>()
              .map((detail) => Map<String, dynamic>.from(detail))
              .toList();
        }
      } catch (_) {
        // Older logs contain plain text and use the aggregate fields below.
      }
    }
    return [
      {
        'fuel_type': log['fuel_type'],
        'old_quantity': log['old_quantity'],
        'old_price': log['old_price'],
        'new_price': log['new_price'],
        'new_quantity': log['new_quantity'],
      }
    ];
  }

  Future<void> _showPriceChangeDetails(Map<String, dynamic> log) async {
    final details = _priceChangeDetails(log);
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('تفاصيل تغيير السعر'),
        content: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columns: const [
              DataColumn(label: Text('النوع')),
              DataColumn(label: Text('الكمية القديمة')),
              DataColumn(label: Text('السعر القديم')),
              DataColumn(label: Text('السعر الجديد')),
              DataColumn(label: Text('الكمية الجديدة')),
            ],
            rows: details.map((detail) {
              String value(String key) {
                final item = detail[key];
                return item is num ? item.toStringAsFixed(2) : '-';
              }

              return DataRow(cells: [
                DataCell(Text(detail['fuel_type']?.toString() ?? '-')),
                DataCell(Text(value('old_quantity'))),
                DataCell(Text(value('old_price'))),
                DataCell(Text(value('new_price'))),
                DataCell(Text(value('new_quantity'))),
              ]);
            }).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('إغلاق'),
          ),
        ],
      ),
    );
  }

  Future<void> _exportPriceChangeDetails(Map<String, dynamic> log) async {
    final excel = Excel.createExcel();
    final sheet = excel['PriceChange'];
    final headers = [
      'تاريخ التغيير',
      'نوع الوقود',
      'الكمية القديمة',
      'السعر القديم',
      'السعر الجديد',
      'الكمية الجديدة',
    ];
    for (var index = 0; index < headers.length; index++) {
      sheet.cell(CellIndex.indexByString('${String.fromCharCode(65 + index)}1')).value = headers[index];
    }
    final details = _priceChangeDetails(log);
    for (var index = 0; index < details.length; index++) {
      final detail = details[index];
      final row = index + 2;
        sheet.cell(CellIndex.indexByString('A$row')).value =
          _formatDisplayDate(log['changed_at']?.toString());
        sheet.cell(CellIndex.indexByString('B$row')).value =
          detail['fuel_type']?.toString() ?? '-';
        sheet.cell(CellIndex.indexByString('C$row')).value =
          detail['old_quantity']?.toString() ?? '-';
        sheet.cell(CellIndex.indexByString('D$row')).value =
          detail['old_price']?.toString() ?? '-';
        sheet.cell(CellIndex.indexByString('E$row')).value =
          detail['new_price']?.toString() ?? '-';
        sheet.cell(CellIndex.indexByString('F$row')).value =
          detail['new_quantity']?.toString() ?? '-';
    }
    final bytes = excel.encode();
    if (bytes == null) return;
    await saveBytesAsFile(
      'price_change_${DateTime.now().millisecondsSinceEpoch}.xlsx',
      Uint8List.fromList(bytes),
    );
  }

  Future<void> _loadSettlementReport() async {
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    if (token == null) {
      if (!mounted) return;
      setState(() {
        _settlementReportError = 'يرجى تسجيل الدخول أولاً';
      });
      return;
    }

    setState(() {
      _isLoadingSettlementReport = true;
      _settlementReportError = null;
    });

    try {
      final result = await ApiService.getSettlementReport(
        token,
        start: _settlementStartDate,
        end: _settlementEndDate,
        fuelType: _settlementFuelType,
        vehicleNumber: _settlementVehicleNumberController.text.trim(),
      );
      if (!mounted) return;
      setState(() {
        _settlementRows =
            List<Map<String, dynamic>>.from((result['rows'] as List?) ?? []);
        _settlementSummary = Map<String, dynamic>.from(result['summary'] ?? {});
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _settlementReportError = e.toString();
        _settlementRows = [];
        _settlementSummary = {};
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingSettlementReport = false;
        });
      }
    }
  }

  double _fuelPriceByName(String fuelType) {
    if (fuelType == 'سولار') return _solarPrice;
    if (fuelType == 'بنزين 92') return _gasoline92Price;
    if (fuelType == 'بنزين 95') return _gasoline95Price;
    return 0.0;
  }

  Future<void> _exportSettlementReportToExcel() async {
    try {
      final excel = Excel.createExcel();
      final sheet = excel['Settlement'];
      final startLabel = _formatDate(_settlementStartDate);
      final endLabel = _formatDate(_settlementEndDate);
      final filterLabel = _settlementFuelType != null &&
              _settlementFuelType!.isNotEmpty
          ? 'نوع الوقود: $_settlementFuelType'
          : 'نوع الوقود: الكل';
      final vehicleLabel =
          _settlementVehicleNumberController.text.trim().isEmpty
          ? 'رقم السيارة: الكل'
          : 'رقم السيارة: ${_settlementVehicleNumberController.text.trim()}';
      final totalQuantity = _settlementRows.fold<double>(
          0.0,
          (total, row) =>
              total + (double.tryParse(row['quantity']?.toString() ?? '') ?? 0.0));
      sheet.cell(CellIndex.indexByString('A1')).value = 'تقرير التسوية';
      sheet.cell(CellIndex.indexByString('A2')).value =
          'الفترة: $startLabel إلى $endLabel';
      sheet.cell(CellIndex.indexByString('A3')).value =
          '$filterLabel - $vehicleLabel';
      final headers = [
        'م.',
        'رقم السيارة',
        'السجل',
        'الكود',
        'نوع الوقود',
        'الكمية المنصرفة',
        'نوع السيارة',
        'الماركة'
      ];
      for (var col = 0; col < headers.length; col++) {
        sheet
            .cell(CellIndex.indexByString('${String.fromCharCode(65 + col)}5'))
            .value = headers[col];
      }
      for (var index = 0; index < _settlementRows.length; index++) {
        final row = _settlementRows[index];
        final rowIndex = index + 6;
        sheet.cell(CellIndex.indexByString('A$rowIndex')).value =
            (index + 1).toString();
        sheet.cell(CellIndex.indexByString('B$rowIndex')).value =
            row['vehicle_number']?.toString() ?? '';
        sheet.cell(CellIndex.indexByString('C$rowIndex')).value =
            row['registry']?.toString() ?? '';
        sheet.cell(CellIndex.indexByString('D$rowIndex')).value =
            row['code']?.toString() ?? '';
        sheet.cell(CellIndex.indexByString('E$rowIndex')).value =
            row['fuel_type']?.toString() ?? '';
        sheet.cell(CellIndex.indexByString('F$rowIndex')).value =
            (double.tryParse(row['quantity']?.toString() ?? '') ?? 0.0)
                .toStringAsFixed(2);
        sheet.cell(CellIndex.indexByString('G$rowIndex')).value =
            row['vehicle_type']?.toString() ?? '';
        sheet.cell(CellIndex.indexByString('H$rowIndex')).value =
            row['brand']?.toString() ?? '';
      }
      final totalRow = _settlementRows.length + 6;
      sheet.cell(CellIndex.indexByString('A$totalRow')).value =
          'الإجمالي (${_settlementRows.length} سيارة)';
      sheet.cell(CellIndex.indexByString('F$totalRow')).value =
          totalQuantity.toStringAsFixed(2);
      final bytes = excel.encode();
      if (bytes == null) {
        throw Exception('فشل إنشاء ملف Excel');
      }
      final filename =
          'settlement_report_${DateTime.now().millisecondsSinceEpoch}.xlsx';
      await saveBytesAsFile(filename, Uint8List.fromList(bytes));
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('تم حفظ Excel باسم $filename')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('فشل تصدير Excel: ${e.toString()}')));
    }
  }

  Future<void> _exportSettlementReportToPdf() async {
    try {
      final fontData = await rootBundle.load('assets/fonts/arial.ttf');
      final font = pw.Font.ttf(fontData);
      final doc = pw.Document();
      final startLabel = _formatDate(_settlementStartDate);
      final endLabel = _formatDate(_settlementEndDate);
      final filterLabel =
          _settlementFuelType != null && _settlementFuelType!.isNotEmpty
              ? 'نوع الوقود: $_settlementFuelType'
              : 'نوع الوقود: الكل';
      final vehicleLabel = _settlementVehicleNumberController.text
              .trim()
              .isEmpty
          ? 'رقم السيارة: الكل'
          : 'رقم السيارة: ${_settlementVehicleNumberController.text.trim()}';
      final rows = _settlementRows
          .map((row) => [
                (row['vehicle_number']?.toString() ?? ''),
                row['registry']?.toString() ?? '',
                row['code']?.toString() ?? '',
                row['fuel_type']?.toString() ?? '',
                (double.tryParse(row['quantity']?.toString() ?? '') ?? 0.0)
                    .toStringAsFixed(2),
                row['vehicle_type']?.toString() ?? '',
                row['brand']?.toString() ?? '',
              ])
          .toList();
      final totalQuantity = _settlementRows.fold<double>(
          0.0,
          (total, row) =>
              total + (double.tryParse(row['quantity']?.toString() ?? '') ?? 0.0));
      rows.add([
        'الإجمالي (${_settlementRows.length} سيارة)',
        '',
        '',
        '',
        totalQuantity.toStringAsFixed(2),
        '',
        '',
      ]);
      doc.addPage(
        pw.Page(
          pageFormat: pdf_lib.PdfPageFormat.a4,
          build: (context) {
            return pw.Directionality(
              textDirection: pw.TextDirection.rtl,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('تقرير التسوية',
                      style: pw.TextStyle(
                          font: font,
                          fontSize: 22,
                          fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 8),
                  pw.Text('الفترة: $startLabel إلى $endLabel',
                      style: pw.TextStyle(font: font, fontSize: 11)),
                  pw.Text(filterLabel,
                      style: pw.TextStyle(font: font, fontSize: 11)),
                  pw.Text(vehicleLabel,
                      style: pw.TextStyle(font: font, fontSize: 11)),
                  pw.Text(
                      'تاريخ التصدير: ${DateTime.now().toLocal().toString()}',
                      style: pw.TextStyle(font: font, fontSize: 11)),
                  pw.SizedBox(height: 12),
                  pw.Table.fromTextArray(
                    headers: [
                      'رقم السيارة',
                      'السجل',
                      'الكود',
                      'نوع الوقود',
                      'الكمية المنصرفة',
                      'نوع السيارة',
                      'الماركة'
                    ],
                    data: rows,
                    border: pw.TableBorder.all(),
                    headerStyle: pw.TextStyle(
                        font: font,
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold),
                    cellStyle: pw.TextStyle(font: font, fontSize: 9),
                    cellAlignment: pw.Alignment.centerRight,
                    headerDecoration: const pw.BoxDecoration(
                        color: pdf_lib.PdfColors.grey300),
                  ),
                ],
              ),
            );
          },
        ),
      );
      final filename =
          'settlement_report_${DateTime.now().millisecondsSinceEpoch}.pdf';
      await saveBytesAsFile(filename, Uint8List.fromList(await doc.save()));
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('تم حفظ PDF باسم $filename')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('فشل تصدير PDF: ${e.toString()}')));
    }
  }

  Future<void> _saveInvoice(BuildContext dialogContext) async {
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    if (token == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('يرجى تسجيل الدخول أولاً')));
      }
      return;
    }

    final payload = {
      'invoice_number': _invoiceNumberController.text.trim(),
      'created_at': _formatDate(_invoiceDate),
      'solar_quantity': double.tryParse(_solarQuantityController.text) ?? 0.0,
      'solar_price': _solarPrice,
      'gasoline_92_quantity':
          double.tryParse(_gasoline92QuantityController.text) ?? 0.0,
      'gasoline_92_price': _gasoline92Price,
      'gasoline_95_quantity':
          double.tryParse(_gasoline95QuantityController.text) ?? 0.0,
      'gasoline_95_price': _gasoline95Price,
    };

    try {
      await ApiService.createAddInvoice(token, payload);
      if (!mounted) return;
      Navigator.of(dialogContext).pop();
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('تم حفظ الفاتورة بنجاح')));
        await _loadInvoiceRecords();
      await _loadStoreBalances();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('فشل حفظ الفاتورة')));
    }
  }

  Future<void> _loadInvoiceRecords() async {
    setState(() {
      _isLoadingInvoiceRecords = true;
      _invoiceRecordsError = null;
    });
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    if (token == null) {
      if (mounted) {
        setState(() {
          _isLoadingInvoiceRecords = false;
          _invoiceRecordsError = 'يرجى تسجيل الدخول أولاً';
        });
      }
      return;
    }
    try {
      final invoices = await ApiService.listAddInvoices(token);
      if (!mounted) return;
      setState(() {
        _invoiceRecords = invoices;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _invoiceRecordsError = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingInvoiceRecords = false;
        });
      }
    }
  }

  Future<void> _showInvoiceFormDialog({Map<String, dynamic>? invoice}) async {
    final invoiceId = invoice?['id'];
    final initialNumber = invoice?['invoice_number']?.toString() ?? '';
    final initialDate =
        DateTime.tryParse(invoice?['created_at']?.toString() ?? '') ??
            DateTime.now();
    final initialSolarQuantity = invoice?['solar_quantity']?.toString() ?? '';
    final initialGasoline92Quantity =
        invoice?['gasoline_92_quantity']?.toString() ?? '';
    final initialGasoline95Quantity =
        invoice?['gasoline_95_quantity']?.toString() ?? '';

    final numberController = TextEditingController(text: initialNumber);
    final solarController = TextEditingController(text: initialSolarQuantity);
    final gasoline92Controller =
        TextEditingController(text: initialGasoline92Quantity);
    final gasoline95Controller =
        TextEditingController(text: initialGasoline95Quantity);
    DateTime selectedDate = initialDate;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            final solarTotal =
                (double.tryParse(solarController.text) ?? 0.0) * _solarPrice;
            final gasoline92Total =
                (double.tryParse(gasoline92Controller.text) ?? 0.0) *
                    _gasoline92Price;
            final gasoline95Total =
                (double.tryParse(gasoline95Controller.text) ?? 0.0) *
                    _gasoline95Price;
            final invoiceTotal = solarTotal + gasoline92Total + gasoline95Total;

            return AlertDialog(
              title:
                  Text(invoiceId == null ? 'إضافة فاتورة' : 'تعديل الفاتورة'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      controller: numberController,
                      decoration: const InputDecoration(
                          labelText: 'رقم الفاتورة',
                          border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      readOnly: true,
                      decoration: InputDecoration(
                        labelText: 'تاريخ الفاتورة',
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.calendar_month),
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: selectedDate,
                              firstDate: DateTime(2000),
                              lastDate: DateTime(2100),
                              locale: const Locale('ar'),
                            );
                            if (picked != null) {
                              setStateDialog(() => selectedDate = picked);
                            }
                          },
                        ),
                        hintText: _formatDate(selectedDate),
                      ),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                          locale: const Locale('ar'),
                        );
                        if (picked != null) {
                          setStateDialog(() => selectedDate = picked);
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    const Text('سولار',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: solarController,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                          labelText: 'كمية السولار',
                          border: OutlineInputBorder()),
                      onChanged: (_) => setStateDialog(() {}),
                    ),
                    const SizedBox(height: 8),
                    _buildReadOnlyField(
                        'السعر', _solarPrice.toStringAsFixed(2)),
                    const SizedBox(height: 8),
                    _buildReadOnlyField(
                        'إجمالي السولار', solarTotal.toStringAsFixed(2)),
                    const SizedBox(height: 16),
                    const Text('بنزين 92',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: gasoline92Controller,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                          labelText: 'كمية بنزين 92',
                          border: OutlineInputBorder()),
                      onChanged: (_) => setStateDialog(() {}),
                    ),
                    const SizedBox(height: 8),
                    _buildReadOnlyField(
                        'السعر', _gasoline92Price.toStringAsFixed(2)),
                    const SizedBox(height: 8),
                    _buildReadOnlyField(
                        'إجمالي بنزين 92', gasoline92Total.toStringAsFixed(2)),
                    const SizedBox(height: 16),
                    const Text('بنزين 95',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: gasoline95Controller,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                          labelText: 'كمية بنزين 95',
                          border: OutlineInputBorder()),
                      onChanged: (_) => setStateDialog(() {}),
                    ),
                    const SizedBox(height: 8),
                    _buildReadOnlyField(
                        'السعر', _gasoline95Price.toStringAsFixed(2)),
                    const SizedBox(height: 8),
                    _buildReadOnlyField(
                        'إجمالي بنزين 95', gasoline95Total.toStringAsFixed(2)),
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 8),
                    _buildReadOnlyField(
                        'إجمالي قيمة الفاتورة', invoiceTotal.toStringAsFixed(2),
                        isBold: true),
                  ],
                ),
              ),
              actions: [
                TextButton(
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    child: const Text('إلغاء')),
                ElevatedButton(
                  onPressed: () async {
                    final token =
                        Provider.of<AuthProvider>(context, listen: false).token;
                    if (token == null) {
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          content: Text('يرجى تسجيل الدخول أولاً')));
                      return;
                    }
                    final payload = {
                      'invoice_number': numberController.text.trim(),
                      'created_at': _formatDate(selectedDate),
                      'solar_quantity':
                          double.tryParse(solarController.text) ?? 0.0,
                      'solar_price': _solarPrice,
                      'gasoline_92_quantity':
                          double.tryParse(gasoline92Controller.text) ?? 0.0,
                      'gasoline_92_price': _gasoline92Price,
                      'gasoline_95_quantity':
                          double.tryParse(gasoline95Controller.text) ?? 0.0,
                      'gasoline_95_price': _gasoline95Price,
                    };
                    try {
                      Map<String, dynamic>? savedInvoice;
                      if (invoiceId == null) {
                        savedInvoice =
                            await ApiService.createAddInvoice(token, payload);
                      } else {
                        savedInvoice = await ApiService.updateAddInvoice(
                            token, invoiceId, payload);
                      }
                      if (!mounted) return;
                      Navigator.of(dialogContext).pop();
                      setState(() {
                        if (invoiceId == null && savedInvoice != null) {
                          _invoiceRecords = [savedInvoice!, ..._invoiceRecords];
                        } else if (savedInvoice != null) {
                          _invoiceRecords = _invoiceRecords
                              .map((item) => item['id'] == invoiceId
                                  ? savedInvoice!
                                  : item)
                              .toList();
                        }
                      });
                      await _loadStoreBalances();
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          content: Text('تم حفظ الفاتورة بنجاح')));
                    } catch (_) {
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('فشل حفظ الفاتورة')));
                    }
                  },
                  child: const Text('حفظ'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _showInvoiceDetailsDialog(Map<String, dynamic> invoice) async {
    final rows = <Map<String, dynamic>>[
      if ((double.tryParse(invoice['solar_quantity']?.toString() ?? '') ??
              0.0) >
          0)
        {
          'fuel_type': 'سولار',
          'value':
              double.tryParse(invoice['solar_total']?.toString() ?? '') ?? 0.0,
          'price':
              double.tryParse(invoice['solar_price']?.toString() ?? '') ?? 0.0,
          'quantity':
              double.tryParse(invoice['solar_quantity']?.toString() ?? '') ??
                  0.0,
        },
      if ((double.tryParse(invoice['gasoline_92_quantity']?.toString() ?? '') ??
              0.0) >
          0)
        {
          'fuel_type': 'بنزين 92',
          'value':
              double.tryParse(invoice['gasoline_92_total']?.toString() ?? '') ??
                  0.0,
          'price':
              double.tryParse(invoice['gasoline_92_price']?.toString() ?? '') ??
                  0.0,
          'quantity': double.tryParse(
                  invoice['gasoline_92_quantity']?.toString() ?? '') ??
              0.0,
        },
      if ((double.tryParse(invoice['gasoline_95_quantity']?.toString() ?? '') ??
              0.0) >
          0)
        {
          'fuel_type': 'بنزين 95',
          'value':
              double.tryParse(invoice['gasoline_95_total']?.toString() ?? '') ??
                  0.0,
          'price':
              double.tryParse(invoice['gasoline_95_price']?.toString() ?? '') ??
                  0.0,
          'quantity': double.tryParse(
                  invoice['gasoline_95_quantity']?.toString() ?? '') ??
              0.0,
        },
    ];

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text('تفاصيل الفاتورة ${invoice['invoice_number'] ?? ''}'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('رقم الفاتورة: ${invoice['invoice_number'] ?? ''}'),
                const SizedBox(height: 8),
                Text(
                    'تاريخ الفاتورة: ${_formatDisplayDate(invoice['created_at']?.toString())}'),
                const SizedBox(height: 8),
                Text(
                    'إجمالي القيمة: ${double.tryParse(invoice['total_amount']?.toString() ?? '')?.toStringAsFixed(2) ?? '0.00'}'),
                const SizedBox(height: 12),
                if (rows.isEmpty)
                  const Text('لا توجد تفاصيل')
                else
                  ...rows.map((row) => Card(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('النوع: ${row['fuel_type']}'),
                              const SizedBox(height: 4),
                              Text(
                                  'قيمة البند: ${row['value'].toStringAsFixed(2)}'),
                              const SizedBox(height: 4),
                              Text(
                                  'سعر اللتر: ${row['price'].toStringAsFixed(2)}'),
                              const SizedBox(height: 4),
                              Text(
                                  'الكمية: ${row['quantity'].toStringAsFixed(2)}'),
                            ],
                          ),
                        ),
                      )),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('إغلاق'))
          ],
        );
      },
    );
  }

  Future<void> _deleteInvoiceRecord(Map<String, dynamic> invoice) async {
    final invoiceId = invoice['id'];
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('حذف الفاتورة'),
        content: const Text(
            'سيتم إخفاء الفاتورة من الواجهة مع الحفاظ على بياناتها.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('إلغاء')),
          ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('حذف')),
        ],
      ),
    );
    if (shouldDelete != true) return;

    final token = Provider.of<AuthProvider>(context, listen: false).token;
    if (token == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('يرجى تسجيل الدخول أولاً')));
      return;
    }
    try {
      await ApiService.deleteAddInvoice(token, invoiceId as int);
      if (!mounted) return;
      await _loadInvoiceRecords();
      await _loadStoreBalances();
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('تم حذف الفاتورة')));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('فشل حذف الفاتورة')));
    }
  }

  Future<void> _exportInvoiceRecordsToExcel() async {
    final filtered = _filteredInvoiceRecords();
    final excel = Excel.createExcel();
    final sheet = excel['Invoices'];
    sheet.cell(CellIndex.indexByString('A1')).value = 'رقم الفاتورة';
    sheet.cell(CellIndex.indexByString('B1')).value = 'تاريخ الفاتورة';
    sheet.cell(CellIndex.indexByString('C1')).value = 'إجمالي قيمة الفاتورة';
    for (var index = 0; index < filtered.length; index++) {
      final invoice = filtered[index];
      final row = index + 2;
      sheet.cell(CellIndex.indexByString('A$row')).value =
          invoice['invoice_number']?.toString() ?? '';
      sheet.cell(CellIndex.indexByString('B$row')).value =
          _formatDisplayDate(invoice['created_at']?.toString());
      sheet.cell(CellIndex.indexByString('C$row')).value =
          (double.tryParse(invoice['total_amount']?.toString() ?? '') ?? 0.0)
              .toStringAsFixed(2);
    }
    final bytes = excel.encode();
    if (bytes == null) {
      throw Exception('فشل إنشاء ملف Excel');
    }
    await saveBytesAsFile(
      'store_invoices_${DateTime.now().millisecondsSinceEpoch}.xlsx',
      Uint8List.fromList(bytes));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('تم تنزيل ملف فواتير المخزن بصيغة Excel')));
  }

  Future<void> _exportInvoiceRecordsToPdf() async {
    final filtered = _filteredInvoiceRecords();
    final fontData = await rootBundle.load('assets/fonts/arial.ttf');
    final font = pw.Font.ttf(fontData);
    final doc = pw.Document();
    doc.addPage(
      pw.Page(
        pageFormat: pdf_lib.PdfPageFormat.a4,
        build: (context) {
          return pw.Directionality(
            textDirection: pw.TextDirection.rtl,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('تقرير فواتير المخزن',
                    style: pw.TextStyle(font: font, fontSize: 24)),
                pw.SizedBox(height: 10),
                pw.Text(
                    'تاريخ التصدير: ${_formatDisplayDate(DateTime.now().toIso8601String())}',
                    style: pw.TextStyle(font: font, fontSize: 12)),
                pw.SizedBox(height: 16),
                pw.Table.fromTextArray(
                  border: pw.TableBorder.all(),
                  headerStyle: pw.TextStyle(font: font, fontSize: 12),
                  cellStyle: pw.TextStyle(font: font, fontSize: 10),
                  headers: [
                    'رقم الفاتورة',
                    'تاريخ الفاتورة',
                    'إجمالي قيمة الفاتورة'
                  ],
                  data: filtered.map((invoice) {
                    return [
                      invoice['invoice_number']?.toString() ?? '',
                      _formatDisplayDate(invoice['created_at']?.toString()),
                      (double.tryParse(
                                  invoice['total_amount']?.toString() ?? '') ??
                              0.0)
                          .toStringAsFixed(2),
                    ];
                  }).toList(),
                ),
              ],
            ),
          );
        },
      ),
    );
    await saveBytesAsFile(
      'store_invoices_${DateTime.now().millisecondsSinceEpoch}.pdf',
      Uint8List.fromList(await doc.save()));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('تم تنزيل ملف فواتير المخزن بصيغة PDF')));
  }

  Future<void> _pickInvoiceFilterDate(bool start) async {
    final picked = await showDatePicker(
      context: context,
      initialDate:
          (start ? _invoiceFilterStartDate : _invoiceFilterEndDate) ??
              DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      locale: const Locale('ar'),
    );
    if (picked == null || !mounted) return;
    setState(() {
      if (start) {
        _invoiceFilterStartDate = picked;
      } else {
        _invoiceFilterEndDate = picked;
      }
    });
  }

  void _clearInvoiceFilters() {
    setState(() {
      _invoiceFilterStartDate = null;
      _invoiceFilterEndDate = null;
      _invoiceSearchController.clear();
    });
  }

  Widget _invoiceFilterDateButton(String label, DateTime? value, bool start) {
    return OutlinedButton.icon(
      onPressed: () => _pickInvoiceFilterDate(start),
      icon: const Icon(Icons.calendar_today, size: 18),
      label: Text(value == null
          ? label
          : '$label: ${_formatDisplayDate(value.toIso8601String())}'),
    );
  }

  List<Map<String, dynamic>> _filteredInvoiceRecords() {
    final query = _invoiceSearchController.text.trim().toLowerCase();
    return _invoiceRecords.where((invoice) {
      final invoiceNumber =
          (invoice['invoice_number']?.toString() ?? '').toLowerCase();
      final invoiceDate = DateTime.tryParse(
          invoice['created_at']?.toString() ?? '');
      final dateMatches = invoiceDate == null ||
          ((_invoiceFilterStartDate == null ||
                  !invoiceDate.isBefore(_invoiceFilterStartDate!)) &&
              (_invoiceFilterEndDate == null ||
                  !invoiceDate.isAfter(_invoiceFilterEndDate!)));
      return dateMatches &&
          (query.isEmpty || invoiceNumber.contains(query));
    }).toList();
  }

  String _formatDisplayDate(String? value) {
    if (value == null || value.isEmpty) {
      return '';
    }
    final parsed = DateTime.tryParse(value);
    if (parsed == null) {
      return value;
    }
    return '${parsed.year.toString().padLeft(4, '0')}-${parsed.month.toString().padLeft(2, '0')}-${parsed.day.toString().padLeft(2, '0')}';
  }

  Future<void> _handleRefuelSaved(
      Refuel savedRefuel, Vehicle selectedVehicle) async {
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    if (token == null) {
      return;
    }
    final payload = {
      'refuel_id': savedRefuel.id,
      'vehicle_id': savedRefuel.vehicleId,
      'fuel_type': selectedVehicle.fuelType,
      'current_odometer': savedRefuel.currentOdometer,
      'liters': savedRefuel.liters,
      'actual_percentage': savedRefuel.actualPercentage,
      'created_at': savedRefuel.createdAt,
      'is_excess': savedRefuel.isExcess,
      'is_illogical': savedRefuel.isIllogical,
      'station': savedRefuel.station,
    };
    try {
      await ApiService.createInventoryDiscount(token, payload);
      if (!mounted) return;
      await _loadStoreBalances();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('فشل تسجيل خصم المخزن')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const ScaAppBar(title: 'المخزن'),
      drawer: ScaDrawer(
        currentRoute: 'store',
        onDashboard: () {
          Navigator.of(context).pop();
          Navigator.of(context)
              .push(MaterialPageRoute(builder: (_) => const DashboardScreen()));
        },
        onVehicleSearch: () {
          Navigator.of(context).pop();
          Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const VehicleSearchScreen()));
        },
        onStore: () {},
        onStoreTab: (index) => _tabController.animateTo(index),
        onGasTab: (index) {
          Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => GasScreen(initialTab: index)));
        },
        onVehicleData: () {
          Navigator.of(context).pop();
          Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const VehicleDataScreen()));
        },
        onReports: () {
          Navigator.of(context).pop();
          Navigator.of(context)
              .push(MaterialPageRoute(builder: (_) => const ReportsScreen()));
        },
        onReportTab: (index) {
          Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => ReportsScreen(initialTab: index)));
        },
        onSettings: () {
          Navigator.of(context).pop();
          Navigator.of(context)
              .push(MaterialPageRoute(builder: (_) => const SettingsScreen()));
        },
        onArchive: () {
          Navigator.of(context).pop();
          Navigator.of(context)
              .push(MaterialPageRoute(builder: (_) => const ArchiveScreen()));
        },
        onLogout: () async {
          final authProvider =
              Provider.of<AuthProvider>(context, listen: false);
          await authProvider.logout();
          if (!mounted) return;
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const LoginScreen()),
            (route) => false,
          );
        },
      ),
      body: Scrollbar(
          thumbVisibility: true,
          child: NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) => [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Text(
                      'رصيد المخزن',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: _showAddInvoiceDialog,
                    icon: const Icon(Icons.add),
                    label: const Text('إضافة فاتورة'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (_isLoadingBalances)
                const LinearProgressIndicator()
              else if (_balancesError != null)
                Text(_balancesError!, style: const TextStyle(color: Colors.red))
              else
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.grey.shade300),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withOpacity(0.03),
                          blurRadius: 8,
                          offset: const Offset(0, 3))
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Align(
                        alignment: Alignment.centerRight,
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _isStoreBalanceExpanded =
                                  !_isStoreBalanceExpanded;
                            });
                          },
                          child: Icon(
                            _isStoreBalanceExpanded
                                ? Icons.keyboard_arrow_up
                                : Icons.keyboard_arrow_down,
                            size: 22,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ),
                      if (_isStoreBalanceExpanded) ...[
                        const SizedBox(height: 10),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                                child: _buildBalanceCard(
                                    'سولار', _solarBalanceDisplay.toDouble())),
                            const SizedBox(width: 10),
                            Expanded(
                                child: _buildBalanceCard('بنزين 92',
                                    _gasoline92BalanceDisplay.toDouble())),
                            const SizedBox(width: 10),
                            Expanded(
                                child: _buildBalanceCard('بنزين 95',
                                    _gasoline95BalanceDisplay.toDouble())),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              const SizedBox(height: 12),
              Builder(
                builder: (context) => ScaKeyboardTabBar(
                  controller: _tabController,
                  tabs: const [
                  Tab(text: 'المتابعة'),
                  Tab(text: 'الفواتير'),
                  Tab(text: 'تقرير التسوية'),
                  Tab(text: 'تغيير السعر'),
                  Tab(text: 'المأموريّات'),
                  Tab(text: 'جرد'),
                  ],
                ),
              ),
                    ],
                  ),
                ),
              ),
            ],
            body: TabBarView(
              controller: _tabController,
              physics: (defaultTargetPlatform == TargetPlatform.android ||
                      defaultTargetPlatform == TargetPlatform.iOS)
                  ? const NeverScrollableScrollPhysics()
                  : null,
              children: [
                    VehicleSearchScreen(
                      showScaffold: false,
                      showBack: false,
                      onRefuelSaved: _handleRefuelSaved,
                    ),
                    _buildInvoiceTab(),
                    _buildSettlementReportTab(),
                    _buildPriceChangeTab(),
                    MissionsTab(
                      vehicles: _vehicles,
                      onBalanceChanged: _loadStoreBalances,
                    ),
                const InventoryTab(),
              ],
            ),
          ),
      ),
    );
  }

  Widget _buildInvoiceTab() {
    final filteredInvoices = _filteredInvoiceRecords();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
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
              SizedBox(
                width: 220,
                child: TextField(
                  controller: _invoiceSearchController,
                  decoration: const InputDecoration(
                    labelText: 'رقم الفاتورة',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.receipt_long),
                    isDense: true,
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              _invoiceFilterDateButton(
                  'من تاريخ', _invoiceFilterStartDate, true),
              _invoiceFilterDateButton('إلى تاريخ', _invoiceFilterEndDate, false),
              IconButton.filledTonal(
                tooltip: 'مسح الفلاتر',
                onPressed: _clearInvoiceFilters,
                icon: const Icon(Icons.cleaning_services),
              ),
              IconButton.filledTonal(
                tooltip: 'تصدير Excel',
                onPressed: _isLoadingInvoiceRecords
                    ? null
                    : _exportInvoiceRecordsToExcel,
                style: IconButton.styleFrom(
                    foregroundColor: Colors.green.shade700),
                icon: const Icon(Icons.table_view),
              ),
              IconButton.filledTonal(
                tooltip: 'تصدير PDF',
                onPressed: _isLoadingInvoiceRecords
                    ? null
                    : _exportInvoiceRecordsToPdf,
                style: IconButton.styleFrom(
                    foregroundColor: Colors.red.shade700),
                icon: const Icon(Icons.picture_as_pdf),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (_isLoadingInvoiceRecords)
          const LinearProgressIndicator()
        else if (_invoiceRecordsError != null)
          Text(_invoiceRecordsError!, style: const TextStyle(color: Colors.red))
        else if (filteredInvoices.isEmpty)
          const Expanded(child: Center(child: Text('لا توجد فواتير')))
        else
          Expanded(
            child: LayoutBuilder(
              builder: (context, tableConstraints) {
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minWidth: tableConstraints.maxWidth,
                      ),
                      child: Focus(
                        focusNode: _invoiceTableFocus,
                        autofocus: true,
                        onKeyEvent: (node, event) {
                          if (event is! KeyDownEvent || filteredInvoices.isEmpty) {
                            return KeyEventResult.ignored;
                          }
                          if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
                            setState(() => _selectedInvoiceIndex =
                                ((_selectedInvoiceIndex ?? -1) + 1)
                                    .clamp(0, filteredInvoices.length - 1));
                            return KeyEventResult.handled;
                          }
                          if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
                            setState(() => _selectedInvoiceIndex =
                                ((_selectedInvoiceIndex ?? filteredInvoices.length) - 1)
                                    .clamp(0, filteredInvoices.length - 1));
                            return KeyEventResult.handled;
                          }
                          if (event.logicalKey == LogicalKeyboardKey.enter &&
                              _selectedInvoiceIndex != null) {
                            _showInvoiceDetailsDialog(
                                filteredInvoices[_selectedInvoiceIndex!]);
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
                  dividerThickness: 1,
                  horizontalMargin: 16,
                  columnSpacing: 28,
                  headingTextStyle: const TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.black87),
                  columns: const [
                    DataColumn(label: Text('رقم الفاتورة')),
                    DataColumn(label: Text('تاريخ الفاتورة')),
                    DataColumn(label: Text('إجمالي القيمة')),
                    DataColumn(label: Text('الإجراءات')),
                  ],
                    rows: filteredInvoices.asMap().entries.map((entry) {
                    final invoice = entry.value;
                    return DataRow(
                      selected: _selectedInvoiceIndex == entry.key,
                      onSelectChanged: (selected) => setState(() {
                        _selectedInvoiceIndex = selected == true ? entry.key : null;
                      }),
                      cells: [
                      DataCell(
                          Text(invoice['invoice_number']?.toString() ?? '')),
                      DataCell(Text(_formatDisplayDate(
                          invoice['created_at']?.toString()))),
                      DataCell(Text((double.tryParse(
                                  invoice['total_amount']?.toString() ?? '') ??
                              0.0)
                          .toStringAsFixed(2))),
                      DataCell(
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              tooltip: 'معلومات',
                              icon: const Icon(Icons.info_outline),
                              onPressed: () =>
                                  _showInvoiceDetailsDialog(invoice),
                            ),
                            IconButton(
                              tooltip: 'تعديل',
                              icon: const Icon(Icons.edit),
                              onPressed: () =>
                                  _showInvoiceFormDialog(invoice: invoice),
                            ),
                            IconButton(
                              tooltip: 'حذف',
                              icon: const Icon(Icons.delete_outline),
                              onPressed: () => _deleteInvoiceRecord(invoice),
                            ),
                          ],
                        ),
                      ),
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
      ],
    );
  }

  Widget _buildPriceChangeTab() {
    final fuelEntries = [
      {
        'fuel_type': 'سولار',
        'balance': _solarBalance,
        'current_price': _solarPrice
      },
      {
        'fuel_type': 'بنزين 92',
        'balance': _gasoline92Balance,
        'current_price': _gasoline92Price
      },
      {
        'fuel_type': 'بنزين 95',
        'balance': _gasoline95Balance,
        'current_price': _gasoline95Price
      },
    ];
    final fuelOrder = ['سولار', 'بنزين 92', 'بنزين 95'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _priceChangeDateController,
          readOnly: true,
          decoration: InputDecoration(
            labelText: 'تاريخ التغيير',
            border: const OutlineInputBorder(),
            suffixIcon: IconButton(
                icon: const Icon(Icons.calendar_month),
                onPressed: _pickPriceChangeDate),
          ),
          onTap: _pickPriceChangeDate,
        ),
        const SizedBox(height: 12),
        ElevatedButton.icon(
          onPressed: _savePriceChange,
          icon: const Icon(Icons.save_alt),
          label: const Text('حفظ التغيير'),
        ),
        const SizedBox(height: 16),
        if (_priceChangeError != null)
          Text(_priceChangeError!, style: const TextStyle(color: Colors.red))
        else if (_isLoadingPriceChangeLogs)
          const LinearProgressIndicator()
        else
          Expanded(
            child: ListView(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text('تعديل الأسعار',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 18)),
                      const SizedBox(height: 12),
                      ...fuelEntries.map((entry) {
                        final fuelType = entry['fuel_type'] as String;
                        final balance = entry['balance'] as double;
                        final currentPrice = entry['current_price'] as double;
                        final newPriceController =
                            _priceChangeControllers[fuelType]!;
                        final focusNode = _priceChangeFocusNodes[fuelType]!;
                        final index = fuelOrder.indexOf(fuelType);
                        final nextFocus = index < fuelOrder.length - 1
                            ? _priceChangeFocusNodes[fuelOrder[index + 1]]
                            : null;
                        final previousFocus = index > 0
                            ? _priceChangeFocusNodes[fuelOrder[index - 1]]
                            : null;
                        final parsedNewPrice =
                            double.tryParse(newPriceController.text.trim());
                        final newQuantity =
                            newPriceController.text.trim().isEmpty ||
                                    parsedNewPrice == null ||
                                    parsedNewPrice <= 0
                                ? balance
                                : (balance * currentPrice) / parsedNewPrice;

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 94,
                                child: Text(fuelType,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14)),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Focus(
                                  onKeyEvent: (node, event) {
                                    if (event is! KeyDownEvent)
                                      return KeyEventResult.ignored;
                                    final key = event.logicalKey;
                                    if (key == LogicalKeyboardKey.arrowDown ||
                                        key == LogicalKeyboardKey.arrowRight) {
                                      if (nextFocus != null) {
                                        FocusScope.of(context)
                                            .requestFocus(nextFocus);
                                      }
                                      return KeyEventResult.handled;
                                    }
                                    if (key == LogicalKeyboardKey.arrowUp ||
                                        key == LogicalKeyboardKey.arrowLeft) {
                                      if (previousFocus != null) {
                                        FocusScope.of(context)
                                            .requestFocus(previousFocus);
                                      }
                                      return KeyEventResult.handled;
                                    }
                                    return KeyEventResult.ignored;
                                  },
                                  child: TextField(
                                    controller: newPriceController,
                                    focusNode: focusNode,
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                            decimal: true),
                                    textInputAction: nextFocus == null
                                        ? TextInputAction.done
                                        : TextInputAction.next,
                                    onChanged: (_) => setState(() {}),
                                    onSubmitted: (_) {
                                      if (nextFocus != null) {
                                        FocusScope.of(context)
                                            .requestFocus(nextFocus);
                                      } else {
                                        _savePriceChange();
                                      }
                                    },
                                    decoration: const InputDecoration(
                                      labelText: 'السعر الجديد',
                                      border: OutlineInputBorder(),
                                      isDense: true,
                                      contentPadding: EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 12),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              SizedBox(
                                width: 110,
                                child: InputDecorator(
                                  decoration: const InputDecoration(
                                    labelText: 'السعر الحالي',
                                    border: OutlineInputBorder(),
                                    isDense: true,
                                    contentPadding: EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 12),
                                  ),
                                  child: Text(currentPrice.toStringAsFixed(2),
                                      style: const TextStyle(fontSize: 14)),
                                ),
                              ),
                              const SizedBox(width: 8),
                              SizedBox(
                                width: 130,
                                child: InputDecorator(
                                  decoration: const InputDecoration(
                                    labelText: 'الكمية الجديدة',
                                    border: OutlineInputBorder(),
                                    isDense: true,
                                    contentPadding: EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 12),
                                  ),
                                  child: Text(
                                      '${newQuantity.toStringAsFixed(2)} لتر',
                                      style: const TextStyle(fontSize: 14)),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const Text('تفاصيل تغيير السعر',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                const SizedBox(height: 8),
                if (_priceChangeLogs.isEmpty)
                  const Text('لا توجد سجلات بعد')
                else
                  LayoutBuilder(
                    builder: (context, tableConstraints) {
                      return SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: SingleChildScrollView(
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                minWidth: tableConstraints.maxWidth,
                              ),
                              child: DataTable(
                                headingRowColor: WidgetStatePropertyAll(
                                    Theme.of(context)
                                        .colorScheme
                                        .primaryContainer),
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
                                border: TableBorder.all(
                                    color: Colors.grey.shade300),
                                horizontalMargin: 16,
                                columnSpacing: 24,
                                headingTextStyle: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87),
                      columns: const [
                        DataColumn(label: Text('م')),
                        DataColumn(label: Text('تاريخ التغيير')),
                        DataColumn(label: Text('الأنواع')),
                        DataColumn(label: Text('المعلومات')),
                        DataColumn(label: Text('تصدير')),
                        DataColumn(label: Text('')),
                      ],
                      rows: _priceChangeLogs.asMap().entries.map((entry) {
                        final log = entry.value;
                        final types = _priceChangeDetails(log)
                            .map((detail) => detail['fuel_type']?.toString())
                            .whereType<String>()
                            .join('، ');
                        return DataRow(cells: [
                          DataCell(Text('${entry.key + 1}')),
                          DataCell(Text(_formatDisplayDate(
                              log['changed_at']?.toString()))),
                          DataCell(Text(types.isEmpty ? '-' : types)),
                          DataCell(IconButton(
                            tooltip: 'عرض التفاصيل',
                            icon: const Icon(Icons.info_outline),
                            onPressed: () => _showPriceChangeDetails(log),
                          )),
                          DataCell(IconButton(
                            tooltip: 'تصدير التفاصيل',
                            icon: const Icon(Icons.file_download_outlined),
                            onPressed: () => _exportPriceChangeDetails(log),
                          )),
                          DataCell(IconButton(
                            tooltip: 'حذف السجل',
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () => _deletePriceChangeLog(
                                (log['id'] as int?) ?? 0),
                          )),
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
      ],
    );
  }

  Widget _buildSettlementReportTab() {
    final fuelTotals =
        _settlementSummary['fuel_totals'] as Map<String, dynamic>? ?? {};
    final totalVehicles = _settlementSummary['total_vehicles'] ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _settlementStartDateController,
                readOnly: true,
                decoration: InputDecoration(
                  labelText: 'تاريخ من',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                      icon: const Icon(Icons.calendar_month),
                      onPressed: _pickSettlementStartDate),
                ),
                onTap: _pickSettlementStartDate,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _settlementEndDateController,
                readOnly: true,
                decoration: InputDecoration(
                  labelText: 'تاريخ إلى',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                      icon: const Icon(Icons.calendar_month),
                      onPressed: _pickSettlementEndDate),
                ),
                onTap: _pickSettlementEndDate,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: DropdownButtonFormField<String?>(
                value: _settlementFuelType,
                decoration: const InputDecoration(
                    labelText: 'نوع الوقود', border: OutlineInputBorder()),
                items: [
                  DropdownMenuItem<String?>(value: null, child: Text('الكل')),
                  DropdownMenuItem<String?>(
                      value: 'سولار', child: Text('سولار')),
                  DropdownMenuItem<String?>(
                      value: 'بنزين 92', child: Text('بنزين 92')),
                  DropdownMenuItem<String?>(
                      value: 'بنزين 95', child: Text('بنزين 95')),
                ],
                onChanged: (value) =>
                    setState(() => _settlementFuelType = value),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _settlementVehicleNumberController,
                textInputAction: TextInputAction.search,
                onSubmitted: (_) => _loadSettlementReport(),
                decoration: const InputDecoration(
                    labelText: 'رقم السيارة', border: OutlineInputBorder()),
              ),
            ),
            const SizedBox(width: 12),
            IconButton(
              tooltip: 'عرض التقرير',
              onPressed:
                  _isLoadingSettlementReport ? null : _loadSettlementReport,
              icon: const Icon(Icons.search, color: Colors.blue),
            ),
            const SizedBox(width: 8),
            IconButton(
              tooltip: 'تصدير Excel',
              onPressed: _settlementRows.isEmpty
                  ? null
                  : _exportSettlementReportToExcel,
              icon: const Icon(Icons.table_view, color: Colors.green),
            ),
            const SizedBox(width: 8),
            IconButton(
              tooltip: 'تصدير PDF',
              onPressed:
                  _settlementRows.isEmpty ? null : _exportSettlementReportToPdf,
              icon: const Icon(Icons.picture_as_pdf, color: Colors.red),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_isLoadingSettlementReport)
          const LinearProgressIndicator()
        else if (_settlementReportError != null)
          Text(_settlementReportError!,
              style: const TextStyle(color: Colors.red))
        else
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Wrap(
                    spacing: 16,
                    runSpacing: 8,
                    children: [
                      Text('إجمالي عدد السيارات: $totalVehicles',
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      ...fuelTotals.entries
                          .map((entry) => Text(
                              '${entry.key}: ${entry.value.toStringAsFixed(2)}'))
                          .toList(),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: _settlementRows.isEmpty
                      ? const Center(child: Text('لا توجد بيانات للعرض'))
                      : LayoutBuilder(
                          builder: (context, tableConstraints) {
                            return SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: SingleChildScrollView(
                                child: ConstrainedBox(
                                  constraints: BoxConstraints(
                                    minWidth: tableConstraints.maxWidth,
                                  ),
                                  child: Focus(
                                    focusNode: _settlementTableFocus,
                                    autofocus: true,
                                    onKeyEvent: (node, event) {
                                      if (event is! KeyDownEvent ||
                                          _settlementRows.isEmpty) {
                                        return KeyEventResult.ignored;
                                      }
                                      if (event.logicalKey ==
                                          LogicalKeyboardKey.arrowDown) {
                                        setState(() => _selectedSettlementIndex =
                                            ((_selectedSettlementIndex ?? -1) + 1)
                                                .clamp(0, _settlementRows.length - 1));
                                        return KeyEventResult.handled;
                                      }
                                      if (event.logicalKey ==
                                          LogicalKeyboardKey.arrowUp) {
                                        setState(() => _selectedSettlementIndex =
                                            ((_selectedSettlementIndex ?? _settlementRows.length) - 1)
                                                .clamp(0, _settlementRows.length - 1));
                                        return KeyEventResult.handled;
                                      }
                                      return KeyEventResult.ignored;
                                    },
                                    child: DataTable(
                                    headingRowColor: WidgetStatePropertyAll(
                                        Theme.of(context)
                                            .colorScheme
                                            .primaryContainer),
                                    dataRowColor:
                                        WidgetStateProperty.resolveWith(
                                            (states) {
                                      if (states
                                          .contains(WidgetState.hovered)) {
                                        return Theme.of(context)
                                            .colorScheme
                                            .primary
                                            .withValues(alpha: 0.08);
                                      }
                                      return null;
                                    }),
                                    border: TableBorder.all(
                                        color: Colors.grey.shade300),
                                    horizontalMargin: 16,
                                    columnSpacing: 24,
                                    headingTextStyle: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87),
                              columns: const [
                                DataColumn(label: Text('م.')),
                                DataColumn(label: Text('رقم السيارة')),
                                DataColumn(label: Text('السجل')),
                                DataColumn(label: Text('الكود')),
                                DataColumn(label: Text('نوع الوقود')),
                                DataColumn(label: Text('الكمية المنصرفة')),
                                DataColumn(label: Text('نوع السيارة')),
                                DataColumn(label: Text('الماركة')),
                              ],
                                  rows: _settlementRows
                                    .asMap()
                                    .entries
                                    .map((entry) {
                                final index = entry.key;
                                final row = entry.value;
                                return DataRow(
                                  selected: _selectedSettlementIndex == index,
                                  onSelectChanged: (selected) => setState(() {
                                    _selectedSettlementIndex =
                                        selected == true ? index : null;
                                  }),
                                  cells: [
                                  DataCell(Text('${index + 1}')),
                                  DataCell(Text(
                                      row['vehicle_number']?.toString() ?? '')),
                                  DataCell(
                                      Text(row['registry']?.toString() ?? '')),
                                  DataCell(Text(row['code']?.toString() ?? '')),
                                  DataCell(
                                      Text(row['fuel_type']?.toString() ?? '')),
                                  DataCell(Text((double.tryParse(
                                              row['quantity']?.toString() ??
                                                  '') ??
                                          0.0)
                                      .toStringAsFixed(2))),
                                  DataCell(Text(
                                      row['vehicle_type']?.toString() ?? '')),
                                  DataCell(
                                      Text(row['brand']?.toString() ?? '')),
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
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildBalanceCard(String title, double value) {
    final displayValue =
        value % 1 == 0 ? value.toStringAsFixed(0) : value.toStringAsFixed(1);
    // Determine color based on fuel type in title
    Color bgColor = Colors.white;
    Color iconColor = Colors.blue;
    if (title.contains('سولار')) {
      bgColor = Colors.white;
      iconColor = const Color(0xFF1E88E5);
    } else if (title.contains('بنزين 92')) {
      iconColor = const Color(0xFFEF6C00);
    } else if (title.contains('بنزين 95')) {
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
                  Text(title.replaceAll('رصيد ', ''),
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

  Widget _buildCardBalanceIndicator(String fuelType, int liters) {
    final colors = {
      'سولار': const Color(0xFF1E88E5),
      'بنزين 92': const Color(0xFFEF6C00),
      'بنزين 95': const Color(0xFF2E7D32),
    };
    final color = colors[fuelType] ?? Colors.black;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.water_drop, size: 18, color: color),
          const SizedBox(width: 6),
          Text('$fuelType ${liters.toString()} لتر',
              style: TextStyle(color: color, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
