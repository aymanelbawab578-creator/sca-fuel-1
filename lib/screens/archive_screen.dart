import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../utils/file_save_helper.dart';
import '../widgets/sca_layout.dart';
import 'dashboard_screen.dart';
import 'store_screen.dart';
import 'login_screen.dart';
import 'reports_screen.dart';
import 'gas_screen.dart';
import 'settings_screen.dart';
import 'vehicle_data_screen.dart';
import 'vehicle_search_screen.dart';

class ArchiveScreen extends StatefulWidget {
  const ArchiveScreen({super.key});

  @override
  State<ArchiveScreen> createState() => _ArchiveScreenState();
}

class _ArchiveScreenState extends State<ArchiveScreen> {
  final _archiveListFocus = FocusNode();
  int? _selectedArchiveIndex;
  bool _isLoading = true;
  bool _isCleaning = false;
  String? _error;
  List<Map<String, dynamic>> _archives = [];

  @override
  void dispose() {
    _archiveListFocus.dispose();
    super.dispose();
  }
  List<String> _temporaryArchives = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadArchivePageData();
      }
    });
  }

  Future<void> _loadArchivePageData() async {
    if (!mounted) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;
    if (token == null) {
      if (!mounted) return;
      setState(() {
        _error = 'لم يتم العثور على رمز المصادقة. يرجى تسجيل الدخول مرة أخرى.';
        _isLoading = false;
      });
      return;
    }

    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await ApiService.listArchives(token);
      final temporaryStatus = await ApiService.getTemporaryArchiveStatus(token);
      if (!mounted) return;
      setState(() {
        _archives = response;
        _temporaryArchives = (temporaryStatus['filenames'] as List<dynamic>? ?? []).cast<String>();
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

  Future<void> _createArchive() async {
    if (!mounted) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;
    if (token == null) return;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        DateTime? startDate;
        DateTime? endDate;
        bool isPreviewing = false;
        Map<String, dynamic>? previewSummary;
        String? previewError;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('اختيار الفترة للأرشفة'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('اختر الفترة الزمنية التي تريد أرشفتها، ثم اعرض الملخص قبل التنفيذ.'),
                    const SizedBox(height: 12),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('تاريخ البداية'),
                      subtitle: Text(_formatDate(startDate)),
                      trailing: const Icon(Icons.calendar_today_outlined),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: startDate ?? DateTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now(),
                        );
                        if (!context.mounted) return;
                        if (picked != null) {
                          setDialogState(() {
                            startDate = picked;
                            if (endDate != null && endDate!.isBefore(startDate!)) {
                              endDate = startDate;
                            }
                            previewSummary = null;
                            previewError = null;
                          });
                        }
                      },
                    ),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('تاريخ النهاية'),
                      subtitle: Text(_formatDate(endDate)),
                      trailing: const Icon(Icons.calendar_today_outlined),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: endDate ?? startDate ?? DateTime.now(),
                          firstDate: startDate ?? DateTime(2020),
                          lastDate: DateTime.now(),
                        );
                        if (!context.mounted) return;
                        if (picked != null) {
                          setDialogState(() {
                            endDate = picked;
                            previewSummary = null;
                            previewError = null;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    if (previewSummary != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Theme.of(dialogContext).colorScheme.surfaceContainerHighest.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('ملخص الأرشفة', style: TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            Text('الفترة: ${_formatDate(startDate)} → ${_formatDate(endDate)}'),
                            Text('عدد السجلات: ${previewSummary!['record_count'] ?? 0}'),
                            Text('سجلات الوقود: ${previewSummary!['refuel_record_count'] ?? 0}'),
                            Text('سجلات الفواتير: ${previewSummary!['invoice_record_count'] ?? 0}'),
                            Text('الحجم التقريبي: ${previewSummary!['approximate_size_bytes'] ?? 0} بايت'),
                          ],
                        ),
                      ),
                    ],
                    if (previewError != null) ...[
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(previewError!, style: const TextStyle(color: Colors.red)),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('إلغاء')),
                OutlinedButton(
                  onPressed: isPreviewing || startDate == null || endDate == null
                      ? null
                      : () async {
                          setDialogState(() {
                            isPreviewing = true;
                            previewError = null;
                          });
                          try {
                            final response = await ApiService.previewArchive(
                              token,
                              startDate: startDate!,
                              endDate: endDate!,
                            );
                            setDialogState(() {
                              previewSummary = response;
                            });
                          } catch (e) {
                            setDialogState(() {
                              previewError = e.toString();
                            });
                          } finally {
                            setDialogState(() {
                              isPreviewing = false;
                            });
                          }
                        },
                  child: isPreviewing ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('عرض الملخص'),
                ),
                ElevatedButton(
                  onPressed: previewSummary == null || startDate == null || endDate == null
                      ? null
                      : () async {
                          setDialogState(() {
                            isPreviewing = true;
                            previewError = null;
                          });
                          try {
                            await ApiService.createArchive(
                              token,
                              startDate: startDate!,
                              endDate: endDate!,
                            );
                            if (!mounted) return;
                            if (!dialogContext.mounted) return;
                            Navigator.pop(dialogContext);
                            _showSnackBar('تم إنشاء الأرشيف بنجاح.');
                            await _loadArchivePageData();
                          } catch (e) {
                            if (!mounted) return;
                            setDialogState(() {
                              previewError = e.toString();
                            });
                          } finally {
                            if (mounted) {
                              setDialogState(() {
                                isPreviewing = false;
                              });
                            }
                          }
                        },
                  child: const Text('إنشاء الأرشيف'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) {
      return 'غير محدد';
    }
    return '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _loadArchiveTemporarily(Map<String, dynamic> archive) async {
    if (!mounted) return;
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    if (token == null) return;

    try {
      await ApiService.loadArchiveTemporarily(token, archive['filename'] as String);
      if (!mounted) return;
      await _refreshTemporaryStatus(token);
      _showSnackBar('تم تحميل الأرشيف مؤقتًا. التقارير ستقرأه مع البيانات الحية.');
    } catch (e) {
      if (!mounted) return;
      _showSnackBar(e.toString());
    }
  }

  Future<void> _refreshTemporaryStatus(String token) async {
    final status = await ApiService.getTemporaryArchiveStatus(token);
    if (!mounted) return;
    setState(() {
      _temporaryArchives = (status['filenames'] as List<dynamic>? ?? []).cast<String>();
    });
  }

  Future<void> _removeTemporaryArchive(Map<String, dynamic> archive) async {
    if (!mounted) return;
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    if (token == null) return;
    try {
      await ApiService.removeTemporaryArchive(token, archive['filename'] as String);
      if (!mounted) return;
      await _refreshTemporaryStatus(token);
      _showSnackBar('تمت إزالة الأرشيف من الجلسة.');
    } catch (e) {
      if (!mounted) return;
      _showSnackBar(e.toString());
    }
  }

  Future<void> _clearTemporaryArchives() async {
    if (!mounted || _temporaryArchives.isEmpty) return;
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    if (token == null) return;
    try {
      await ApiService.clearTemporaryArchive(token);
      if (!mounted) return;
      setState(() {
        _temporaryArchives = [];
      });
      _showSnackBar('تم مسح جميع الأرشيفات المؤقتة من الجلسة.');
    } catch (e) {
      if (!mounted) return;
      _showSnackBar(e.toString());
    }
  }

  Future<void> _cleanupArchivedData() async {
    if (!mounted) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;
    if (token == null) return;

    setState(() {
      _isCleaning = true;
    });

    try {
      final status = await ApiService.getArchiveStatus(token);
      if (!mounted) return;

      final archived = status['archived'] == true;
      final archive = status['archive'] as Map<String, dynamic>?;
      if (!archived || archive == null) {
        if (!mounted) return;
        _showSnackBar('لا يمكن حذف البيانات لأنها لم تُؤرشف بعد.\nيرجى إنشاء أرشيف أولاً.');
        return;
      }

      await showDialog<void>(
        context: context,
        builder: (dialogContext) {
          DateTime? startDate;
          DateTime? endDate;
          bool isPreviewing = false;
          Map<String, dynamic>? previewSummary;
          String? previewError;

          return StatefulBuilder(
            builder: (context, setDialogState) {
              return AlertDialog(
                title: const Text('تنظيف قاعدة البيانات حسب الفترة'),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('اختر الفترة الزمنية التي تريد تنظيفها من قاعدة البيانات، ثم اعرض الملخص قبل التنفيذ.'),
                      const SizedBox(height: 12),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('تاريخ البداية'),
                        subtitle: Text(_formatDate(startDate)),
                        trailing: const Icon(Icons.calendar_today_outlined),
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: dialogContext,
                            initialDate: startDate ?? DateTime.now(),
                            firstDate: DateTime(2020),
                            lastDate: DateTime.now(),
                          );
                          if (picked != null) {
                            setDialogState(() {
                              startDate = picked;
                              if (endDate != null && endDate!.isBefore(startDate!)) {
                                endDate = startDate;
                              }
                              previewSummary = null;
                              previewError = null;
                            });
                          }
                        },
                      ),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('تاريخ النهاية'),
                        subtitle: Text(_formatDate(endDate)),
                        trailing: const Icon(Icons.calendar_today_outlined),
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: dialogContext,
                            initialDate: endDate ?? startDate ?? DateTime.now(),
                            firstDate: startDate ?? DateTime(2020),
                            lastDate: DateTime.now(),
                          );
                          if (picked != null) {
                            setDialogState(() {
                              endDate = picked;
                              previewSummary = null;
                              previewError = null;
                            });
                          }
                        },
                      ),
                      if (previewSummary != null) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Theme.of(dialogContext).colorScheme.surfaceContainerHighest.withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('ملخص التنظيف', style: TextStyle(fontWeight: FontWeight.bold)),
                              const SizedBox(height: 8),
                              Text('الفترة: ${_formatDate(startDate)} → ${_formatDate(endDate)}'),
                              Text('سجلات الوقود: ${previewSummary!['refuel_record_count'] ?? 0}'),
                              Text('سجلات الفواتير: ${previewSummary!['invoice_record_count'] ?? 0}'),
                            ],
                          ),
                        ),
                      ],
                      if (previewError != null) ...[
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(previewError!, style: const TextStyle(color: Colors.red)),
                        ),
                      ],
                    ],
                  ),
                ),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('إلغاء')),
                  OutlinedButton(
                    onPressed: isPreviewing || startDate == null || endDate == null
                        ? null
                        : () async {
                            setDialogState(() {
                              isPreviewing = true;
                              previewError = null;
                            });
                            try {
                              final response = await ApiService.cleanupArchivedData(
                                token,
                                startDate: startDate!,
                                endDate: endDate!,
                                confirm: false,
                              );
                              setDialogState(() {
                                previewSummary = response['summary'] as Map<String, dynamic>? ?? <String, dynamic>{};
                              });
                            } catch (e) {
                              setDialogState(() {
                                previewError = e.toString();
                              });
                            } finally {
                              setDialogState(() {
                                isPreviewing = false;
                              });
                            }
                          },
                    child: isPreviewing
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text('عرض الملخص'),
                  ),
                  ElevatedButton(
                    onPressed: previewSummary == null || startDate == null || endDate == null
                        ? null
                        : () async {
                            setDialogState(() {
                              isPreviewing = true;
                              previewError = null;
                            });
                            try {
                              await ApiService.cleanupArchivedData(
                                token,
                                startDate: startDate!,
                                endDate: endDate!,
                                confirm: true,
                              );
                              if (!mounted) return;
                              if (!context.mounted) return;
                              Navigator.pop(dialogContext);
                              _showSnackBar('تم تنظيف قاعدة البيانات بنجاح.');
                              await _loadArchivePageData();
                            } catch (e) {
                              if (!mounted) return;
                              setDialogState(() {
                                previewError = e.toString();
                              });
                            } finally {
                              if (mounted) {
                                setDialogState(() {
                                  isPreviewing = false;
                                });
                              }
                            }
                          },
                    child: const Text('تنظيف'),
                  ),
                ],
              );
            },
          );
        },
      );
    } catch (e) {
      if (!mounted) return;
      _showSnackBar(e.toString());
    } finally {
      if (mounted) {
        setState(() {
          _isCleaning = false;
        });
      }
    }
  }

  void _showArchiveDetails(Map<String, dynamic> archive) {
    final widgetContext = context;
    showDialog(
      context: widgetContext,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(archive['filename'] as String),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _detailRow('اسم الملف', archive['filename'] as String),
              _detailRow('تاريخ الإنشاء', archive['created_at']?.toString() ?? 'غير متوفر'),
              _detailRow('الحجم', archive['size']?.toString() ?? 'غير متوفر'),
              _detailRow('الفترة الزمنية', '${archive['period_start'] ?? 'n/a'} → ${archive['period_end'] ?? 'n/a'}'),
              _detailRow('عدد السجلات', archive['record_count']?.toString() ?? '0'),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('إغلاق')),
            ElevatedButton(onPressed: () {
              Navigator.pop(dialogContext);
              _loadArchiveTemporarily(archive);
            }, child: const Text('تحميل مؤقت')),
          ],
        );
      },
    );
  }

  Future<void> _downloadArchiveFile(Map<String, dynamic> archive) async {
    if (!mounted) return;
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;
    if (token == null) return;

    try {
      final content = await ApiService.downloadArchive(token, archive['filename'] as String);
      if (!mounted) return;
      final bytes = Uint8List.fromList(utf8.encode(content));
      final filename = archive['filename'] as String;
      await saveBytesAsFile(filename, bytes);
      if (!mounted) return;
      _showSnackBar('تم تنزيل ملف الأرشيف بنجاح.');
    } catch (e) {
      if (!mounted) return;
      _showSnackBar(e.toString());
    }
  }

  Future<void> _deleteArchiveFile(Map<String, dynamic> archive) async {
    if (!mounted) return;
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;
    if (token == null) return;

    final warningText = archive['missing_data_warning'] == true
        ? 'هذا الأرشيف يحتوي على بيانات غير موجودة حالياً داخل قاعدة البيانات.\n\nإذا تم حذفه فلن يمكن استعادة هذه البيانات مرة أخرى.'
        : 'هل تريد حذف ملف الأرشيف ${archive['filename']}؟';

    final requiresDeleteText = archive['missing_data_warning'] == true;
    final confirmationController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('حذف الأرشيف'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(warningText),
                if (requiresDeleteText) ...[
                  const SizedBox(height: 12),
                  const Text('اكتب كلمة "حذف" للتأكيد:'),
                  const SizedBox(height: 8),
                  TextField(
                    controller: confirmationController,
                    decoration: const InputDecoration(hintText: 'حذف'),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('إلغاء')),
            ElevatedButton(
              onPressed: () {
                if (requiresDeleteText && confirmationController.text.trim() != 'حذف') {
                  if (!dialogContext.mounted) return;
                  ScaffoldMessenger.of(dialogContext).showSnackBar(const SnackBar(content: Text('يرجى كتابة كلمة "حذف" للتأكيد.')));
                  return;
                }
                Navigator.pop(dialogContext, true);
              },
              child: const Text('حذف'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) return;

    try {
      await ApiService.deleteArchive(token, archive['filename'] as String);
      if (!mounted) return;
      _showSnackBar('تم حذف ملف الأرشيف بنجاح.');
      await _loadArchivePageData();
    } catch (e) {
      if (!mounted) return;
      _showSnackBar(e.toString());
    }
  }

  Widget _buildArchiveActions(Map<String, dynamic> archive) {
    return PopupMenuButton<String>(
      onSelected: (value) {
        if (value == 'temporary') {
          _loadArchiveTemporarily(archive);
        } else if (value == 'download') {
          _downloadArchiveFile(archive);
        } else if (value == 'delete') {
          _deleteArchiveFile(archive);
        } else if (value == 'remove-temporary') {
          _removeTemporaryArchive(archive);
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(value: 'temporary', child: Text('تحميل أرشيف مؤقت')),
        if (_temporaryArchives.contains(archive['filename']))
          const PopupMenuItem(value: 'remove-temporary', child: Text('إزالة من الجلسة')),
        const PopupMenuItem(value: 'download', child: Text('تنزيل الأرشيف')),
        const PopupMenuItem(value: 'delete', child: Text('حذف الأرشيف')),
      ],
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  void _navigateToDashboard() {
    final widgetContext = context;
    if (!mounted || !widgetContext.mounted) return;
    Navigator.of(widgetContext).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const DashboardScreen()),
      (route) => false,
    );
  }

  void _navigateToVehicleSearch() {
    final widgetContext = context;
    if (!mounted || !widgetContext.mounted) return;
    Navigator.of(widgetContext).push(MaterialPageRoute(builder: (_) => const VehicleSearchScreen()));
  }

  void _navigateToVehicleData() {
    final widgetContext = context;
    if (!mounted || !widgetContext.mounted) return;
    Navigator.of(widgetContext).push(MaterialPageRoute(builder: (_) => const VehicleDataScreen()));
  }

  void _navigateToReports() {
    final widgetContext = context;
    if (!mounted || !widgetContext.mounted) return;
    Navigator.of(widgetContext).push(MaterialPageRoute(builder: (_) => const ReportsScreen()));
  }

  void _navigateToSettings() {
    final widgetContext = context;
    if (!mounted || !widgetContext.mounted) return;
    Navigator.of(widgetContext).push(MaterialPageRoute(builder: (_) => const SettingsScreen()));
  }

  Future<void> _logout() async {
    final widgetContext = context;
    final authProvider = Provider.of<AuthProvider>(widgetContext, listen: false);
    await authProvider.logout();
    if (!mounted || !widgetContext.mounted) return;
    Navigator.of(widgetContext).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const ScaAppBar(title: 'الأرشيف'),
      drawer: ScaDrawer(
        currentRoute: 'archive',
        onDashboard: _navigateToDashboard,
        onVehicleSearch: _navigateToVehicleSearch,
        onStore: () {
          Navigator.of(context).push(MaterialPageRoute(builder: (_) => const StoreScreen()));
        },
        onStoreTab: (index) {
          Navigator.of(context).push(MaterialPageRoute(builder: (_) => StoreScreen(initialTab: index)));
        },
        onGasTab: (index) {
          Navigator.of(context).push(MaterialPageRoute(builder: (_) => GasScreen(initialTab: index)));
        },
        onVehicleData: _navigateToVehicleData,
        onReports: _navigateToReports,
        onReportTab: (index) {
          Navigator.of(context).push(MaterialPageRoute(builder: (_) => ReportsScreen(initialTab: index)));
        },
        onSettings: _navigateToSettings,
        onArchive: () {},
        onLogout: _logout,
      ),
      body: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _createArchive,
                        icon: const Icon(Icons.archive_outlined),
                        label: const Text('أرشف البيانات'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _temporaryArchives.isEmpty ? null : _clearTemporaryArchives,
                        icon: const Icon(Icons.layers_clear_outlined),
                        label: Text('مسح المؤقت (${_temporaryArchives.length})'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _isCleaning ? null : _cleanupArchivedData,
                        icon: const Icon(Icons.cleaning_services_outlined),
                        label: const Text('تنظيف قاعدة البيانات'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (_isLoading)
                  const Expanded(child: Center(child: CircularProgressIndicator()))
                else if (_error != null)
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(_error!, textAlign: TextAlign.center),
                          const SizedBox(height: 12),
                          ElevatedButton(onPressed: _loadArchivePageData, child: const Text('إعادة التحميل')),
                        ],
                      ),
                    ),
                  )
                else if (_archives.isEmpty)
                  const Expanded(
                    child: Center(
                      child: Text('لا يوجد أرشيف بعد.', style: TextStyle(fontSize: 16)),
                    ),
                  )
                else
                  Expanded(
                    child: Focus(
                      focusNode: _archiveListFocus,
                      autofocus: true,
                      onKeyEvent: (node, event) {
                        if (event is! KeyDownEvent || _archives.isEmpty) {
                          return KeyEventResult.ignored;
                        }
                        if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
                          setState(() => _selectedArchiveIndex =
                              ((_selectedArchiveIndex ?? -1) + 1)
                                  .clamp(0, _archives.length - 1));
                          return KeyEventResult.handled;
                        }
                        if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
                          setState(() => _selectedArchiveIndex =
                              ((_selectedArchiveIndex ?? _archives.length) - 1)
                                  .clamp(0, _archives.length - 1));
                          return KeyEventResult.handled;
                        }
                        if (event.logicalKey == LogicalKeyboardKey.enter &&
                            _selectedArchiveIndex != null) {
                          _showArchiveDetails(
                              _archives[_selectedArchiveIndex!]);
                          return KeyEventResult.handled;
                        }
                        return KeyEventResult.ignored;
                      },
                      child: ListView.separated(
                      itemCount: _archives.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final archive = _archives[index];
                        return ListTile(
                          selected: _selectedArchiveIndex == index,
                          title: Text(archive['filename'] as String),
                          subtitle: Text(
                            'إنشاء: ${archive['created_at'] ?? 'غير متوفر'}\nالحجم: ${archive['size'] ?? 0} بايت\nالسجلات: ${archive['record_count'] ?? 0}',
                          ),
                          trailing: _buildArchiveActions(archive),
                          onTap: () => _showArchiveDetails(archive),
                        );
                      },
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
