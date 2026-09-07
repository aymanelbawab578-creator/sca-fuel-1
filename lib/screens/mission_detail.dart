import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../providers/auth_provider.dart';
import '../services/api_service.dart';

class MissionDetailScreen extends StatefulWidget {
  final int missionId;
  const MissionDetailScreen({super.key, required this.missionId});

  @override
  State<MissionDetailScreen> createState() => _MissionDetailScreenState();
}

class _MissionDetailScreenState extends State<MissionDetailScreen> {
  Map<String, dynamic>? _mission;
  List<dynamic> _expenses = [];
  bool _loading = false;
  final _expensesFocusNode = FocusNode();
  int? _selectedExpenseIndex;

  // === الجزء الأول: بيانات المأمورية ===
  late TextEditingController _chargedLitersController;
  late TextEditingController _driverNameController;
  late TextEditingController _driverJobNumberController;
  late TextEditingController _directionController;
  late TextEditingController _orderNumberController;
  late TextEditingController _orderDateController;
  late TextEditingController _startOdometerController;
  late TextEditingController _endOdometerController;
  late TextEditingController _notesController;

  late DateTime _selectedDate;
  String _selectedFuelType = 'سولار';
  final List<String> _fuelTypes = ['سولار', 'بنزين 92', 'بنزين 95'];

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _loadMission();
  }

  void _initializeControllers() {
    _chargedLitersController = TextEditingController();
    _driverNameController = TextEditingController();
    _driverJobNumberController = TextEditingController();
    _directionController = TextEditingController();
    _orderNumberController = TextEditingController();
    _orderDateController = TextEditingController();
    _startOdometerController = TextEditingController();
    _endOdometerController = TextEditingController();
    _notesController = TextEditingController();
    _selectedDate = DateTime.now();
  }

  Future<void> _loadMission() async {
    if (!mounted) return;
    setState(() => _loading = true);
    final token = Provider.of<AuthProvider>(context, listen: false).token!;
    try {
      final m = await ApiService.getMission(token, widget.missionId);
      if (!mounted) return;
      setState(() {
        _mission = m;
        _loading = false;
      });
      // تعبئة الحقول من بيانات المأمورية
      _chargedLitersController.text =
          (_mission?['charged_liters'] ?? 0.0).toString();
      _driverNameController.text = (_mission?['driver_name'] ?? '') as String;
      _driverJobNumberController.text =
          (_mission?['driver_job_number'] ?? '') as String;
      _directionController.text = (_mission?['direction'] ?? '') as String;
      _orderNumberController.text = (_mission?['order_number'] ?? '') as String;
      _orderDateController.text = (_mission?['order_date'] ?? '') as String;
      _startOdometerController.text =
          (_mission?['start_odometer'] ?? '').toString();
      _endOdometerController.text =
          (_mission?['end_odometer'] ?? '').toString();
      _notesController.text = (_mission?['notes'] ?? '') as String;
      _selectedFuelType = (_mission?['fuel_type'] ?? 'سولار') as String;
      if (_mission?['created_at'] != null) {
        _selectedDate = DateTime.parse(_mission!['created_at']);
      }
      if (!mounted) return;
      setState(() {
        _expenses = m['expenses'] ?? [];
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('فشل جلب المأمورية: ${e.toString()}')));
    }
  }

  Future<void> _addExpenseDialog() async {
    final dateController = TextEditingController(
        text: DateFormat('yyyy-MM-dd').format(DateTime.now()));
    final odometerController = TextEditingController();
    final litersController = TextEditingController();
    final receiptController = TextEditingController();
    final expenseNotesController = TextEditingController();
    final dateFocus = FocusNode();
    final odometerFocus = FocusNode();
    final litersFocus = FocusNode();
    final receiptFocus = FocusNode();
    final notesFocus = FocusNode();

    void moveFocus(BuildContext ctx, FocusNode focusNode) {
      FocusScope.of(ctx).requestFocus(focusNode);
    }

    KeyEventResult handleNavigation(
      BuildContext ctx,
      KeyEvent event,
      FocusNode previousFocus,
      FocusNode nextFocus,
    ) {
      if (event is! KeyDownEvent) return KeyEventResult.ignored;
      final key = event.logicalKey;
      if (key == LogicalKeyboardKey.arrowDown ||
          key == LogicalKeyboardKey.arrowRight) {
        moveFocus(ctx, nextFocus);
        return KeyEventResult.handled;
      }
      if (key == LogicalKeyboardKey.arrowUp ||
          key == LogicalKeyboardKey.arrowLeft) {
        moveFocus(ctx, previousFocus);
        return KeyEventResult.handled;
      }
      return KeyEventResult.ignored;
    }

    final res = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('أضف تفويلة جديدة'),
        content: SingleChildScrollView(
          child: Column(
            children: [
              Focus(
                onKeyEvent: (node, event) =>
                    handleNavigation(ctx, event, notesFocus, odometerFocus),
                child: TextField(
                  controller: dateController,
                  focusNode: dateFocus,
                  autofocus: true,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                      labelText: 'تاريخ الصرف (YYYY-MM-DD)'),
                  readOnly: true,
                  onSubmitted: (_) => moveFocus(ctx, odometerFocus),
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
              Focus(
                onKeyEvent: (node, event) =>
                    handleNavigation(ctx, event, dateFocus, litersFocus),
                child: TextField(
                  controller: odometerController,
                  focusNode: odometerFocus,
                  textInputAction: TextInputAction.next,
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  onSubmitted: (_) => moveFocus(ctx, litersFocus),
                  decoration: const InputDecoration(labelText: 'عداد الصرف'),
                ),
              ),
              Focus(
                onKeyEvent: (node, event) =>
                    handleNavigation(ctx, event, odometerFocus, receiptFocus),
                child: TextField(
                  controller: litersController,
                  focusNode: litersFocus,
                  textInputAction: TextInputAction.next,
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  onSubmitted: (_) => moveFocus(ctx, receiptFocus),
                  decoration:
                      const InputDecoration(labelText: 'الكمية المنصرفة (لتر)'),
                ),
              ),
              Focus(
                onKeyEvent: (node, event) =>
                    handleNavigation(ctx, event, litersFocus, notesFocus),
                child: TextField(
                  controller: receiptController,
                  focusNode: receiptFocus,
                  textInputAction: TextInputAction.next,
                  onSubmitted: (_) => moveFocus(ctx, notesFocus),
                  decoration: const InputDecoration(
                      labelText: 'رقم الوصلة/بيانات الوصلة'),
                ),
              ),
              Focus(
                onKeyEvent: (node, event) =>
                    handleNavigation(ctx, event, receiptFocus, dateFocus),
                child: TextField(
                  controller: expenseNotesController,
                  focusNode: notesFocus,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => Navigator.of(ctx).pop(true),
                  decoration: const InputDecoration(labelText: 'ملاحظات'),
                  maxLines: 3,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('إلغاء')),
          ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('حفظ')),
        ],
      ),
    );
    dateFocus.dispose();
    odometerFocus.dispose();
    litersFocus.dispose();
    receiptFocus.dispose();
    notesFocus.dispose();
    if (res != true) return;
    final token = Provider.of<AuthProvider>(context, listen: false).token!;
    final payload = {
      'date': dateController.text,
      'odometer': double.tryParse(odometerController.text) ?? 0.0,
      'liters': double.tryParse(litersController.text) ?? 0.0,
      'receipt_data': receiptController.text,
    };
    try {
      final createdExpense =
          await ApiService.addMissionExpense(token, widget.missionId, payload);
      if (!mounted) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() {
          _expenses = [..._expenses, createdExpense];
        });
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تم إضافة التفويلة بنجاح')));
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('فشل إضافة التفويلة: ${e.toString()}')));
    }
  }

  Future<void> _completeMission() async {
    if (widget.missionId <= 0) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'رقم المأمورية غير صحيح. أعد فتح المأمورية من القائمة ثم حاول مرة أخرى.')),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تأكيد الترحيل'),
        content: const Text(
            'هل تريد حفظ وترحيل المأمورية كـ مكتملة؟\nستُنشأ سجلات التفويل والخصم والاستهلاك.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('إلغاء')),
          ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('نعم، ترحيل')),
        ],
      ),
    );
    if (confirm != true) return;
    if (!mounted) return;

    final token = Provider.of<AuthProvider>(context, listen: false).token!;
    try {
      await ApiService.getMission(token, widget.missionId);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'المأمورية غير موجودة في قاعدة البيانات، أعد فتحها من القائمة ثم حاول مرة أخرى.')),
      );
      Navigator.of(context).pop(false);
      return;
    }

    try {
      await ApiService.completeMission(token, widget.missionId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم ترحيل المأمورية كـ مكتملة')));
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      if (e.toString().contains('عداد')) {
  final continueAnyway = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Row(
        children: [
          Icon(
            Icons.warning_amber_rounded,
            color: Colors.orange,
          ),
          SizedBox(width: 8),
          Text('تنبيه العداد'),
        ],
      ),
      content: Text(
  (() {
    final errorText = e.toString();
    final match = RegExp(
      r'message:\s*(.*?),\s*code:',
    ).firstMatch(errorText);

    final message = match?.group(1) ?? errorText;

    return '$message\n\n'
        'هل تريد حفظ المأمورية رغم اختلاف العداد؟';
  })(),
),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: const Text('إلغاء'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          child: const Text('حفظ رغم التحذير'),
        ),
      ],
    ),
  );
        if (continueAnyway == true) {
          try {
            await ApiService.completeMission(token, widget.missionId,
                force: true);
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text('تم ترحيل المأمورية رغم تحذير العداد')));
            Navigator.of(context).pop(true);
          } catch (forceError) {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text('فشل الترحيل: ${forceError.toString()}')));
          }
        }
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('فشل الترحيل: ${e.toString()}')));
    }
  }

  Future<void> _editExpenseDialog(Map<String, dynamic> expense) async {
    final dateController = TextEditingController(text: expense['date']?.toString() ?? '');
    final odometerController = TextEditingController(text: expense['odometer']?.toString() ?? '');
    final litersController = TextEditingController(text: expense['liters']?.toString() ?? '');
    final receiptController = TextEditingController(text: expense['receipt_data']?.toString() ?? '');
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تعديل التفويلة'),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: dateController,
                readOnly: true,
                decoration: const InputDecoration(labelText: 'تاريخ التفويلة'),
                onTap: () async {
                  final initialDate = DateTime.tryParse(dateController.text) ?? DateTime.now();
                  final picked = await showDatePicker(
                    context: ctx,
                    initialDate: initialDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) {
                    dateController.text = DateFormat('yyyy-MM-dd').format(picked);
                  }
                },
              ),
              TextField(
                controller: odometerController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'عداد التفويلة'),
              ),
              TextField(
                controller: litersController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'كمية التفويلة'),
              ),
              TextField(
                controller: receiptController,
                decoration: const InputDecoration(labelText: 'بيانات الإيصال'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('إلغاء')),
          ElevatedButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('حفظ')),
        ],
      ),
    );
    if (result != true) return;
    final expenseId = expense['id'];
    if (expenseId == null) return;
    final token = Provider.of<AuthProvider>(context, listen: false).token!;
    try {
      await ApiService.updateMissionExpense(token, widget.missionId, expenseId, {
        'date': dateController.text,
        'odometer': double.tryParse(odometerController.text) ?? 0.0,
        'liters': double.tryParse(litersController.text) ?? 0.0,
        'receipt_data': receiptController.text,
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم تعديل التفويلة بنجاح')));
      await _loadMission();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('فشل تعديل التفويلة: ${e.toString()}')));
    }
    dateController.dispose();
    odometerController.dispose();
    litersController.dispose();
    receiptController.dispose();
  }

  Future<void> _saveMissionEdits() async {
    final token = Provider.of<AuthProvider>(context, listen: false).token!;
    final payload = <String, dynamic>{
      'charged_liters': double.tryParse(_chargedLitersController.text) ?? 0.0,
      'fuel_type': _selectedFuelType,
      'created_at': DateFormat('yyyy-MM-dd').format(_selectedDate),
      'driver_name': _driverNameController.text,
      'driver_job_number': _driverJobNumberController.text,
      'direction': _directionController.text,
      'order_number': _orderNumberController.text,
      'order_date': _orderDateController.text,
      'start_odometer': double.tryParse(_startOdometerController.text),
      'end_odometer': double.tryParse(_endOdometerController.text),
      'notes': _notesController.text,
    };
    try {
      await ApiService.updateMission(token, widget.missionId, payload);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم حفظ التغييرات بنجاح')));
      await _loadMission();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('فشل حفظ التغييرات: ${e.toString()}')));
    }
  }

  double _getRemainingBalance() {
    final charged = double.tryParse(_chargedLitersController.text) ?? 0.0;
    double totalExpended = 0.0;
    for (final expense in _expenses) {
      totalExpended += (expense['liters'] ?? 0.0) as double;
    }
    return charged - totalExpended;
  }

  Widget _buildResponsiveRow(bool isMobile, Widget first, Widget second) {
    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [first, const SizedBox(height: 12), second],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: first),
        const SizedBox(width: 12),
        Expanded(child: second),
      ],
    );
  }

  Widget _buildFieldLabel(String label, Widget child) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 13, color: Colors.black87)),
        const SizedBox(height: 6),
        child,
      ],
    );
  }

  Widget _buildBalanceBlock(String title, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: const TextStyle(fontSize: 13, color: Colors.black54)),
        const SizedBox(height: 6),
        Text(value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      ],
    );
  }

  Future<void> _deleteExpense(Map<String, dynamic> expense) async {
    if (!mounted) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: const Text(
            'هل تريد حذف هذه التفويلة؟\nسيتم إرجاع القيمة إلى رصيد الكارت'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('إلغاء')),
          ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('حذف')),
        ],
      ),
    );
    if (confirm != true) return;
    final token = Provider.of<AuthProvider>(context, listen: false).token!;
    try {
      final expenseId = expense['id'];
      if (expenseId == null) throw Exception('لا يوجد معرف للتفويلة');
      await ApiService.deleteMissionExpense(token, widget.missionId, expenseId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('تم حذف التفويلة وإرجاع الرصيد للكارت')));
      await _loadMission();
      // Notify parent tab to refresh balances immediately after deletion
      if (context.mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('فشل حذف التفويلة: ${e.toString()}')));
    }
  }

  @override
  void dispose() {
    _chargedLitersController.dispose();
    _driverNameController.dispose();
    _driverJobNumberController.dispose();
    _directionController.dispose();
    _orderNumberController.dispose();
    _orderDateController.dispose();
    _startOdometerController.dispose();
    _endOdometerController.dispose();
    _notesController.dispose();
    _expensesFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vehicleNumber = _mission?['vehicle_number']?.toString().trim();
    final appTitle = (vehicleNumber != null && vehicleNumber.isNotEmpty)
        ? 'سيارة $vehicleNumber'
        : 'المأمورية';

    return Scaffold(
      appBar: AppBar(
        title: Text(appTitle),
        centerTitle: true,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_mission != null) ...[
                      // ==========================================
                      // الجزء الأول: بيانات المأمورية
                      // ==========================================
                      Card(
                        elevation: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('بيانات المأمورية',
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold)),
                              const SizedBox(height: 16),
                              LayoutBuilder(
                                builder: (context, constraints) {
                                  final isMobile = constraints.maxWidth < 700;
                                  return Column(
                                    children: [
                                      _buildResponsiveRow(
                                        isMobile,
                                        _buildFieldLabel(
                                            'رقم السيارة',
                                            InputDecorator(
                                              decoration: const InputDecoration(
                                                  border: OutlineInputBorder()),
                                              child: Text(
                                                  _mission!['vehicle_number']
                                                          ?.toString() ??
                                                      '---'),
                                            )),
                                        _buildFieldLabel(
                                            'نوع الوقود',
                                            DropdownButtonFormField<String>(
                                              value: _selectedFuelType,
                                              decoration: const InputDecoration(
                                                  border: OutlineInputBorder()),
                                              items: _fuelTypes
                                                  .map((f) => DropdownMenuItem(
                                                      value: f, child: Text(f)))
                                                  .toList(),
                                              onChanged: (v) {
                                                if (v != null)
                                                  setState(() =>
                                                      _selectedFuelType = v);
                                              },
                                            )),
                                      ),
                                      const SizedBox(height: 12),
                                      _buildResponsiveRow(
                                        isMobile,
                                        _buildFieldLabel(
                                            'تاريخ الشحن',
                                            GestureDetector(
                                              onTap: () async {
                                                final picked =
                                                    await showDatePicker(
                                                  context: context,
                                                  firstDate: DateTime(2020),
                                                  lastDate: DateTime.now(),
                                                );
                                                if (picked != null) {
                                                  setState(() =>
                                                      _selectedDate = picked);
                                                }
                                              },
                                              child: InputDecorator(
                                                decoration:
                                                    const InputDecoration(
                                                  border: OutlineInputBorder(),
                                                  suffixIcon: Icon(
                                                      Icons.calendar_today),
                                                ),
                                                child: Text(
                                                    DateFormat('yyyy-MM-dd')
                                                        .format(_selectedDate)),
                                              ),
                                            )),
                                        _buildFieldLabel(
                                            'عداد المأمورية',
                                            TextField(
                                              controller:
                                                  _startOdometerController,
                                              keyboardType: TextInputType
                                                  .numberWithOptions(
                                                      decimal: true),
                                              decoration: const InputDecoration(
                                                  border: OutlineInputBorder()),
                                            )),
                                      ),
                                      const SizedBox(height: 12),
                                      _buildResponsiveRow(
                                        isMobile,
                                        _buildFieldLabel(
                                            'اسم السائق',
                                            TextField(
                                              controller: _driverNameController,
                                              decoration: const InputDecoration(
                                                  border: OutlineInputBorder()),
                                            )),
                                        _buildFieldLabel(
                                            'رقم عمل السائق',
                                            TextField(
                                              controller:
                                                  _driverJobNumberController,
                                              decoration: const InputDecoration(
                                                  border: OutlineInputBorder()),
                                            )),
                                      ),
                                      const SizedBox(height: 12),
                                      _buildResponsiveRow(
                                        isMobile,
                                        _buildFieldLabel(
                                            'اتجاه المأمورية',
                                            TextField(
                                              controller: _directionController,
                                              decoration: const InputDecoration(
                                                  border: OutlineInputBorder()),
                                            )),
                                        _buildFieldLabel(
                                            'رقم أمر التشغيل',
                                            TextField(
                                              controller:
                                                  _orderNumberController,
                                              decoration: const InputDecoration(
                                                  border: OutlineInputBorder()),
                                            )),
                                      ),
                                      const SizedBox(height: 12),
                                      _buildResponsiveRow(
                                        isMobile,
                                        _buildFieldLabel(
                                            'تاريخ أمر التشغيل',
                                            TextField(
                                              controller: _orderDateController,
                                              decoration: const InputDecoration(
                                                border: OutlineInputBorder(),
                                                suffixIcon: Icon(Icons.calendar_today),
                                              ),
                                              readOnly: true,
                                              onTap: () async {
                                                final picked =
                                                    await showDatePicker(
                                                  context: context,
                                                  initialDate: DateTime.now(),
                                                  firstDate: DateTime(2020),
                                                  lastDate: DateTime(2100),
                                                );
                                                if (picked != null) {
                                                  _orderDateController.text =
                                                      DateFormat('yyyy-MM-dd')
                                                          .format(picked);
                                                }
                                              },
                                            )),
                                        _buildFieldLabel(
                                            'عداد نهاية التشغيل',
                                            TextField(
                                              controller:
                                                  _endOdometerController,
                                              keyboardType: TextInputType
                                                  .numberWithOptions(
                                                      decimal: true),
                                              decoration: const InputDecoration(
                                                  border: OutlineInputBorder()),
                                            )),
                                      ),
                                      const SizedBox(height: 12),
                                      _buildResponsiveRow(
                                        isMobile,
                                        _buildFieldLabel(
                                            'كمية الشحن (لتر)',
                                            TextField(
                                              controller:
                                                  _chargedLitersController,
                                              keyboardType: TextInputType
                                                  .numberWithOptions(
                                                      decimal: true),
                                              decoration: const InputDecoration(
                                                  border: OutlineInputBorder()),
                                              onChanged: (_) => setState(() {}),
                                            )),
                                        _buildFieldLabel(
                                            'ملاحظات',
                                            TextField(
                                              controller: _notesController,
                                              maxLines: 3,
                                              decoration: const InputDecoration(
                                                  border: OutlineInputBorder()),
                                            )),
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // ==========================================
                      // الجزء الثاني: تفويلات المأمورية
                      // ==========================================
                      Card(
                        elevation: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                      'ثانياً: تمويلات المأمورية (التفويلات)',
                                      style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold)),
                                  ElevatedButton.icon(
                                    onPressed: _addExpenseDialog,
                                    icon: const Icon(Icons.add),
                                    label: const Text('إضافة تفويلة'),
                                    style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              _expenses.isEmpty
                                  ? const Padding(
                                      padding:
                                          EdgeInsets.symmetric(vertical: 20),
                                      child: Center(
                                          child: Text('لم تُضف تفويلات بعد')),
                                    )
                                  : Focus(
                                      focusNode: _expensesFocusNode,
                                      autofocus: true,
                                      onKeyEvent: (node, event) {
                                        if (event is! KeyDownEvent ||
                                            _expenses.isEmpty) {
                                          return KeyEventResult.ignored;
                                        }
                                        if (event.logicalKey ==
                                            LogicalKeyboardKey.arrowDown) {
                                          setState(() => _selectedExpenseIndex =
                                              ((_selectedExpenseIndex ?? -1) + 1)
                                                  .clamp(0, _expenses.length - 1));
                                          return KeyEventResult.handled;
                                        }
                                        if (event.logicalKey ==
                                            LogicalKeyboardKey.arrowUp) {
                                          setState(() => _selectedExpenseIndex =
                                              ((_selectedExpenseIndex ?? _expenses.length) - 1)
                                                  .clamp(0, _expenses.length - 1));
                                          return KeyEventResult.handled;
                                        }
                                        if (event.logicalKey ==
                                                LogicalKeyboardKey.enter &&
                                            _selectedExpenseIndex != null) {
                                          _deleteExpense(_expenses[
                                              _selectedExpenseIndex!]);
                                          return KeyEventResult.handled;
                                        }
                                        return KeyEventResult.ignored;
                                      },
                                      child: SingleChildScrollView(
                                      scrollDirection: Axis.horizontal,
                                      child: ConstrainedBox(
                                        constraints:
                                            const BoxConstraints(minWidth: 700),
                                        child: DataTable(
                                          columnSpacing: 18,
                                          headingRowHeight: 48,
                                          dataRowHeight: 54,
                                          columns: const [
                                            DataColumn(label: Text('م')),
                                            DataColumn(
                                                label: Text('تاريخ التفويلة')),
                                            DataColumn(label: Text('المحطة')),
                                            DataColumn(
                                                label: Text('كمية التفويلة')),
                                            DataColumn(
                                                label: Text('رقم العداد')),
                                            DataColumn(label: Text('إجراء')),
                                          ],
                                          rows: _expenses
                                              .asMap()
                                              .entries
                                              .map((e) {
                                            final idx = e.key + 1;
                                            final exp = e.value;
                                            return DataRow(
                                              selected: _selectedExpenseIndex == e.key,
                                              onSelectChanged: (selected) => setState(() {
                                                _selectedExpenseIndex =
                                                    selected == true ? e.key : null;
                                              }),
                                              cells: [
                                              DataCell(Text('$idx')),
                                              DataCell(Text(
                                                  exp['date']?.toString() ??
                                                      '---')),
                                              DataCell(Text(
                                                  exp['station']?.toString() ??
                                                      exp['receipt_data']
                                                          ?.toString() ??
                                                      '---')),
                                              DataCell(Text(
                                                  '${exp['liters'] ?? '---'} لتر')),
                                              DataCell(Text(
                                                  exp['odometer']?.toString() ??
                                                      '---')),
                                              DataCell(Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  IconButton(
                                                    icon: const Icon(Icons.edit, color: Colors.blue),
                                                    tooltip: 'تعديل التفويلة',
                                                    onPressed: () => _editExpenseDialog(exp),
                                                  ),
                                                  IconButton(
                                                    icon: const Icon(Icons.delete, color: Colors.red),
                                                    onPressed: () => _deleteExpense(exp),
                                                  ),
                                                ],
                                              )),
                                            ]);
                                          }).toList(),
                                        ),
                                      ),
                                    ),
                                    ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // ==========================================
                      // الجزء الثالث: رصيد الكارت بعد العودة
                      // ==========================================
                      Card(
                        elevation: 2,
                        color: Colors.blue[50],
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('ثالثاً: رصيد الكارت بعد العودة',
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold)),
                              const SizedBox(height: 16),
                              LayoutBuilder(
                                builder: (context, constraints) {
                                  final isMobile = constraints.maxWidth < 620;
                                  return Flex(
                                    direction: isMobile
                                        ? Axis.vertical
                                        : Axis.horizontal,
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      _buildBalanceBlock('كمية الشحن',
                                          '${double.tryParse(_chargedLitersController.text) ?? 0.0} لتر'),
                                      if (!isMobile)
                                        const Padding(
                                            padding: EdgeInsets.symmetric(
                                                horizontal: 8.0),
                                            child: Icon(Icons.remove,
                                                size: 28, color: Colors.grey)),
                                      _buildBalanceBlock(
                                          'إجمالي الكمية المصروفة',
                                          '${_expenses.fold<double>(0, (sum, e) => sum + ((e['liters'] ?? 0.0) as double))} لتر'),
                                      if (!isMobile)
                                        const Padding(
                                            padding: EdgeInsets.symmetric(
                                                horizontal: 8.0),
                                            child: Text('=',
                                                style: TextStyle(
                                                    fontSize: 32,
                                                    color: Colors.grey))),
                                      Container(
                                        margin: EdgeInsets.only(
                                            top: isMobile ? 12 : 0),
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 14, horizontal: 16),
                                        decoration: BoxDecoration(
                                          color: Colors.green[100],
                                          border: Border.all(
                                              color: Colors.green, width: 2),
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.center,
                                          children: [
                                            const Text('الرصيد المتبقي',
                                                style: TextStyle(
                                                    fontSize: 13,
                                                    color: Colors.black54)),
                                            const SizedBox(height: 6),
                                            Text(
                                              '${_getRemainingBalance().toStringAsFixed(2)} لتر',
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 18,
                                                  color: Colors.green),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // ==========================================
                      // الأزرار
                      // ==========================================
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final isMobile = constraints.maxWidth < 620;
                          return Flex(
                            direction:
                                isMobile ? Axis.vertical : Axis.horizontal,
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: _saveMissionEdits,
                                  icon: const Icon(Icons.save),
                                  label: const Text('حفظ المأمورية'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 14),
                                  ),
                                ),
                              ),
                              SizedBox(
                                  width: isMobile ? 0 : 12,
                                  height: isMobile ? 12 : 0),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: _completeMission,
                                  icon: const Icon(Icons.check_circle),
                                  label: const Text('حفظ كمأمورية جديدة'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 14),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 20),
                    ],
                  ],
                ),
              ),
            ),
    );
  }
}
