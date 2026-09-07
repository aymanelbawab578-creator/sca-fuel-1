/// نسخة محسّنة من PeriodReportTab لتحسين الأداء
/// تستخدم تخزين البيانات المحسوبة وتجنب الحسابات المتكررة

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:pdf/pdf.dart' as pdf;
import 'package:pdf/widgets.dart' as pw;

import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../models/vehicle.dart';
import '../models/refuel.dart';
import '../helpers/reports_calculations.dart';

class OptimizedPeriodReportTab extends StatefulWidget {
  final List<Vehicle> vehicles;
  final List<Refuel> allRefuels;
  final String? vehicleQuery;
  final String? globalFuelType;

  const OptimizedPeriodReportTab({
    required this.vehicles,
    required this.allRefuels,
    this.vehicleQuery,
    this.globalFuelType,
    super.key,
  });

  @override
  State<OptimizedPeriodReportTab> createState() => _OptimizedPeriodReportTabState();
}

class _OptimizedPeriodReportTabState extends State<OptimizedPeriodReportTab> {
  DateTime? _startDate;
  DateTime? _endDate;
  Map<String, dynamic>? _apiResult;
  Map<String, dynamic>? _cachedReportData; // تخزين البيانات المحسوبة
  bool _isLoading = false;
  int? _filterVehicleId;
  final Map<int, FocusNode> _vehicleTableFocusNodes = {};
  final Map<int, int?> _highlightedRefuelIndexes = {};

  void _handleVehicleTableKey(KeyEvent event, int vehicleId, int rowCount) {
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

  Future<void> _selectDate(BuildContext context, bool isStart) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      locale: const Locale('ar'),
    );
    if (picked != null) {
      setState(() => isStart ? _startDate = picked : _endDate = picked);
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
          await ApiService.getRangeReport(token, _startDate!, _endDate!);
      
      if (!mounted) return;
      
      // استخدام الدالة المحسّنة لحساب البيانات مرة واحدة فقط
      final cachedData = ReportsCalculations.optimizePeriodReportData(
        apiResult,
        vehicleQuery: widget.vehicleQuery,
        globalFuelType: widget.globalFuelType,
      );
      
      setState(() {
        _apiResult = apiResult;
        _cachedReportData = cachedData;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('خطأ: ${e.toString()}')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
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
                                  label: Text(_startDate != null
                                      ? DateFormat('dd/MM/yyyy').format(_startDate!)
                                      : 'من تاريخ'),
                                  onPressed: () => _selectDate(context, true),
                                ),
                                const SizedBox(height: 8),
                                TextButton.icon(
                                  icon: const Icon(Icons.calendar_today),
                                  label: Text(_endDate != null
                                      ? DateFormat('dd/MM/yyyy').format(_endDate!)
                                      : 'إلى تاريخ'),
                                  onPressed: () => _selectDate(context, false),
                                ),
                              ],
                            )
                          : Row(
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
                                const SizedBox(width: 8),
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
                            );
                    },
                  ),
                  const SizedBox(height: 12),
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
          const SizedBox(height: 12),
          if (_isLoading)
            const CircularProgressIndicator()
          else if (_cachedReportData != null)
            _buildReportContent()
        ],
      ),
    );
  }

  Widget _buildReportContent() {
    final vehicleMap = (_cachedReportData!['vehicleMap'] as Map<int, Map<String, dynamic>>?) ?? {};
    final totalVehicles = _cachedReportData!['totalVehicles'] as int? ?? 0;
    final totalRefuels = _cachedReportData!['totalRefuels'] as int? ?? 0;
    final totalLiters = _cachedReportData!['totalLiters'] as double? ?? 0.0;

    if (vehicleMap.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Text(
          'لا توجد بيانات للفترة المختارة',
          style: TextStyle(fontSize: 14, color: Colors.grey),
        ),
      );
    }

    return Column(
      children: [
        // ملخص التقرير
        Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'ملخص التقرير',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade200),
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
                            'إجمالي اللترات: ${totalLiters.toStringAsFixed(1)} لتر',
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
        ),
        const SizedBox(height: 12),
        // جداول السيارات
        ...vehicleMap.entries.map((entry) {
          final vehicleId = entry.key;
          final vehicle = entry.value;
          final refuels = (vehicle['refuels'] as List<Map<String, dynamic>>?) ?? [];
          final vehicleTotalLiters = vehicle['totalLiters'] as double? ?? 0.0;

          return _buildVehicleCard(
            vehicleId,
            vehicle,
            refuels,
            vehicleTotalLiters,
          );
        }).toList(),
      ],
    );
  }

  Widget _buildVehicleCard(
    int vehicleId,
    Map<String, dynamic> vehicle,
    List<Map<String, dynamic>> refuels,
    double vehicleTotalLiters,
  ) {
    final focusNode = _vehicleTableFocusNodes.putIfAbsent(
      vehicleId,
      () => FocusNode(debugLabel: 'period-vehicle-$vehicleId'),
    );
    final highlightedIndex = _highlightedRefuelIndexes[vehicleId];

    return Column(
      children: [
        Card(
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
                if (refuels.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('لا توجد تفويلات لهذه السيارة'),
                  )
                else
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
                                  top: BorderSide(color: Colors.grey.shade300, width: 0.5),
                                  bottom: BorderSide(color: Colors.grey.shade300, width: 0.5),
                                ),
                                columns: [
                                  DataColumn(
                                    label: Text('م', style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: Colors.grey.shade700,
                                    )),
                                  ),
                                  DataColumn(
                                    label: Text('التاريخ', style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: Colors.grey.shade700,
                                    )),
                                  ),
                                  DataColumn(
                                    label: Text('العداد', style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: Colors.grey.shade700,
                                    )),
                                    numeric: true,
                                  ),
                                  DataColumn(
                                    label: Text('اللترات', style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: Colors.grey.shade700,
                                    )),
                                    numeric: true,
                                  ),
                                  DataColumn(
                                    label: Text('النسبة', style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: Colors.grey.shade700,
                                    )),
                                    numeric: true,
                                  ),
                                  DataColumn(
                                    label: Text('المحطة', style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: Colors.grey.shade700,
                                    )),
                                  ),
                                ],
                                rows: refuels.asMap().entries.map((entry) {
                                  final index = entry.key;
                                  final refuel = entry.value;
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
                                      DataCell(Text('${index + 1}')),
                                      DataCell(Text(refuel['date'].toString())),
                                      DataCell(Text(refuel['odometer'].toString())),
                                      DataCell(Text((refuel['liters'] as num).toStringAsFixed(1))),
                                      DataCell(Text(
                                        (refuel['ratio'] as num) == 0
                                            ? '-'
                                            : (refuel['ratio'] as num).toStringAsFixed(2),
                                      )),
                                      DataCell(Text(
                                        ReportsCalculations.shortStationName(
                                          refuel['station'].toString(),
                                        ),
                                      )),
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
        const SizedBox(height: 12),
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
