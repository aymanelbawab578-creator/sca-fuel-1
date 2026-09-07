import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../services/api_service.dart';
import '../helpers/settings_helper.dart';
import '../widgets/sca_layout.dart';
import 'dashboard_screen.dart';
import 'vehicle_search_screen.dart';
import 'vehicle_data_screen.dart';
import 'archive_screen.dart';
import 'store_screen.dart';
import 'login_screen.dart';
import 'reports_screen.dart';
import 'gas_screen.dart';
import 'about_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  UserData? _userData;
  bool _isLoading = true;
  String? _error;
  bool _isCloudConnected = true;
  DateTime? _lastSyncTime;
  final String _appVersion = '1.3';

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadSystemInfo();
  }

  Future<void> _loadSystemInfo() async {
    // محاكاة تحميل بيانات النظام مع timeout
    try {
      final lastSync = await _getLastSyncTime().timeout(
        const Duration(seconds: 5),
        onTimeout: () => null,
      );
      
      if (mounted) {
        setState(() {
          _lastSyncTime = lastSync;
          _isCloudConnected = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isCloudConnected = false;
        });
      }
    }
  }

  Future<void> _manualSync() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.token == null) throw Exception('غير مسجل الدخول');
      await ApiService.manualSync(authProvider.token!);
      if (!mounted) return;
      setState(() {
        _lastSyncTime = DateTime.now();
        _isCloudConnected = true;
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تمت المزامنة بنجاح')));
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isCloudConnected = false;
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('فشل المزامنة: ${e.toString()}')));
    }
  }

  Future<DateTime?> _getLastSyncTime() async {
    // هذه دالة مساعدة لمحاكاة الحصول على آخر وقت مزامنة
    // يمكن تحديثها لاحقاً للحصول على البيانات الفعلية من SharedPreferences
    await Future.delayed(const Duration(milliseconds: 100));
    return DateTime.now().subtract(const Duration(hours: 2));
  }

  Future<void> _showChangeUsernameDialog() async {
    final controller = TextEditingController(text: _userData?.username ?? '');
    String? dialogError;
    bool isSaving = false;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(builder: (context, setState) {
          return AlertDialog(
            title: const Text('تغيير اسم المستخدم'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: controller,
                  decoration: const InputDecoration(
                    labelText: 'اسم المستخدم الجديد',
                    border: OutlineInputBorder(),
                  ),
                ),
                if (dialogError != null) ...[
                  const SizedBox(height: 12),
                  Text(dialogError!, style: const TextStyle(color: Colors.red)),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: isSaving ? null : () => Navigator.of(context).pop(),
                child: const Text('إلغاء'),
              ),
              ElevatedButton(
                onPressed: isSaving
                    ? null
                    : () async {
                        final newUsername = controller.text.trim();
                        final error = SettingsValidation.validateUsername(newUsername);
                        if (error != null) {
                          setState(() => dialogError = error);
                          return;
                        }
                        if (_userData != null && newUsername == _userData!.username) {
                          setState(() => dialogError = 'اسم المستخدم الجديد يجب أن يختلف عن الحالي');
                          return;
                        }

                        setState(() => isSaving = true);
                        try {
                          final authProvider = Provider.of<AuthProvider>(context, listen: false);
                          await ApiService.updateUsername(authProvider.token!, newUsername);
                          if (!mounted) return;
                          Navigator.of(context).pop();
                          _loadUserData();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('تم تحديث اسم المستخدم بنجاح')),
                          );
                        } catch (e) {
                          setState(() => dialogError = e.toString());
                        } finally {
                          if (mounted) setState(() => isSaving = false);
                        }
                      },
                child: isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('حفظ'),
              ),
            ],
          );
        });
      },
    );
  }

  Future<void> _showChangePasswordDialog() async {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    String? dialogError;
    bool isSaving = false;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(builder: (context, setState) {
          return AlertDialog(
            title: const Text('تغيير كلمة المرور'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: currentPasswordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'كلمة المرور الحالية',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: newPasswordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'كلمة المرور الجديدة',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: confirmPasswordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'تأكيد كلمة المرور الجديدة',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  if (dialogError != null) ...[
                    const SizedBox(height: 12),
                    Text(dialogError!, style: const TextStyle(color: Colors.red)),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: isSaving ? null : () => Navigator.of(context).pop(),
                child: const Text('إلغاء'),
              ),
              ElevatedButton(
                onPressed: isSaving
                    ? null
                    : () async {
                        final currentPassword = currentPasswordController.text;
                        final newPassword = newPasswordController.text;
                        final confirmPassword = confirmPasswordController.text;

                        if (currentPassword.isEmpty) {
                          setState(() => dialogError = 'كلمة المرور الحالية مطلوبة');
                          return;
                        }

                        final passwordError = SettingsValidation.validatePassword(newPassword);
                        if (passwordError != null) {
                          setState(() => dialogError = passwordError);
                          return;
                        }

                        final matchError = SettingsValidation.validatePasswordMatch(newPassword, confirmPassword);
                        if (matchError != null) {
                          setState(() => dialogError = matchError);
                          return;
                        }

                        final differentError = SettingsValidation.validateNewPasswordDifferent(currentPassword, newPassword);
                        if (differentError != null) {
                          setState(() => dialogError = differentError);
                          return;
                        }

                        setState(() => isSaving = true);
                        try {
                          final authProvider = Provider.of<AuthProvider>(context, listen: false);
                          await ApiService.changePassword(authProvider.token!, currentPassword, newPassword);
                          if (!mounted) return;
                          Navigator.of(context).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('تم تغيير كلمة المرور بنجاح')),
                          );
                        } catch (e) {
                          setState(() => dialogError = e.toString());
                        } finally {
                          if (mounted) setState(() => isSaving = false);
                        }
                      },
                child: isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('حفظ'),
              ),
            ],
          );
        });
      },
    );
  }

  Future<void> _loadUserData() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (!mounted) return;

    try {
      // إضافة timeout للـ API call
      final data = await ApiService.getCurrentUser(authProvider.token!)
          .timeout(const Duration(seconds: 10), onTimeout: () => throw Exception('انتهت المهلة الزمنية لتحميل بيانات المستخدم'));

      if (!mounted) return;

      setState(() {
        _userData = UserData.fromJson(data);
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

  void _goToDashboard() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const DashboardScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: ScaAppBar(title: 'الإعدادات', showBack: true, onBack: _goToDashboard),
      drawer: ScaDrawer(
        currentRoute: 'settings',
        onDashboard: _goToDashboard,
        onVehicleSearch: () {
          Navigator.of(context).push(MaterialPageRoute(builder: (_) => const VehicleSearchScreen()));
        },
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
        onSettings: () {},
        onLogout: () async {
          final confirmed = await _showConfirmDialog(
            context,
            'تسجيل الخروج',
            'هل تريد تسجيل الخروج من البرنامج؟',
          );
          if (!confirmed) return;
          if (!context.mounted) return;
          final authProvider = Provider.of<AuthProvider>(context, listen: false);
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
                        onPressed: _loadUserData,
                        child: const Text('إعادة محاولة'),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      if (_userData != null) ...[
                        _UserInfoSection(
                          userData: _userData!,
                          onChangeUsername: _showChangeUsernameDialog,
                          onChangePassword: _showChangePasswordDialog,
                        ),
                        const SizedBox(height: 20),
                        _ThemeModeSection(),
                        const SizedBox(height: 20),
                        const Card(
                          elevation: 2,
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: Text(
                              'تم تصميم وتطوير البرنامج بواسطة ayman elbawab',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                                          _SystemInfoSection(
                          appVersion: _appVersion,
                          isCloudConnected: _isCloudConnected,
                          lastSyncTime: _lastSyncTime,
                          onManualSync: _manualSync,
                        ),
                        const SizedBox(height: 20),
                      ],
                                        Card(
                                          elevation: 2,
                                          child: ListTile(
                                            leading: Icon(Icons.info_outline,
                                                color: Theme.of(context).primaryColor),
                                            title: const Text('حول البرنامج'),
                                            subtitle: const Text('معلومات البرنامج والإصدار'),
                                            trailing: const Icon(Icons.chevron_left),
                                            onTap: () => Navigator.of(context).push(
                                              MaterialPageRoute(
                                                  builder: (_) => const AboutScreen()),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 20),
                      _LogoutSection(),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
    );
  }
}

// ============ قسم بيانات المستخدم ============
class _UserInfoSection extends StatelessWidget {
  final UserData userData;
  final VoidCallback onChangeUsername;
  final VoidCallback onChangePassword;

  const _UserInfoSection({
    required this.userData,
    required this.onChangeUsername,
    required this.onChangePassword,
  });

  String _getRoleInArabic(String role) {
    final roles = {
      'Admin': 'مسؤول',
      'Data Entry': 'إدخال البيانات',
      'Viewer': 'مشاهد',
    };
    return roles[role] ?? role;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.account_circle, color: Theme.of(context).primaryColor, size: 24),
                const SizedBox(width: 12),
                const Text(
                  'الحساب',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _AccountInfoRow(
              label: 'اسم المستخدم',
              value: userData.username,
              icon: Icons.person,
            ),
            const SizedBox(height: 12),
            _AccountInfoRow(
              label: 'الاسم الكامل',
              value: userData.fullName,
              icon: Icons.badge,
            ),
            const SizedBox(height: 12),
            _AccountInfoRow(
              label: 'نوع الصلاحية',
              value: _getRoleInArabic(userData.role),
              icon: Icons.security,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.person_outline),
                      label: const Text('تغيير اسم المستخدم'),
                      onPressed: onChangeUsername,
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.lock_outline),
                      label: const Text('تغيير كلمة المرور'),
                      onPressed: onChangePassword,
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
}

class _AccountInfoRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _AccountInfoRow({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.grey),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(color: Colors.grey, fontSize: 13),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ============ قسم المظهر ============
class _ThemeModeSection extends StatelessWidget {
  const _ThemeModeSection();

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.palette, color: Theme.of(context).primaryColor, size: 24),
                const SizedBox(width: 12),
                const Text(
                  'المظهر',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Consumer<ThemeProvider>(
              builder: (context, themeProvider, child) {
                return Column(
                  children: [
                    RadioListTile<bool>(
                      title: const Text('الوضع الفاتح'),
                      value: false,
                      groupValue: themeProvider.isDarkMode,
                      onChanged: (value) {
                        if (value != null) {
                          themeProvider.setDarkMode(value);
                        }
                      },
                    ),
                    RadioListTile<bool>(
                      title: const Text('الوضع الداكن'),
                      value: true,
                      groupValue: themeProvider.isDarkMode,
                      onChanged: (value) {
                        if (value != null) {
                          themeProvider.setDarkMode(value);
                        }
                      },
                    ),
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

// ============ قسم معلومات النظام ============
class _SystemInfoSection extends StatelessWidget {
  final String appVersion;
  final bool isCloudConnected;
  final DateTime? lastSyncTime;
  final VoidCallback? onManualSync;

  const _SystemInfoSection({
    required this.appVersion,
    required this.isCloudConnected,
    required this.lastSyncTime,
    this.onManualSync,
  });

  String _formatSyncTime(DateTime? time) {
    if (time == null) {
      return 'لم تتم مزامنة بعد';
    }
    final formatter = DateFormat('dd/MM/yyyy HH:mm', 'ar');
    return formatter.format(time);
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.settings_suggest, color: Theme.of(context).primaryColor, size: 24),
                const SizedBox(width: 12),
                const Text(
                  'النظام',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _SystemInfoRow(
              label: 'إصدار البرنامج',
              value: appVersion,
              icon: Icons.info_outline,
            ),
            const SizedBox(height: 12),
            _SystemInfoRow(
              label: 'حالة الاتصال بالسحابة',
              value: isCloudConnected ? 'متصل' : 'غير متصل',
              icon: Icons.cloud,
              valueColor: isCloudConnected ? Colors.green : Colors.red,
            ),
            const SizedBox(height: 12),
            _SystemInfoRow(
              label: 'آخر تاريخ مزامنة',
              value: _formatSyncTime(lastSyncTime),
              icon: Icons.sync,
              isMultiLine: true,
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.sync),
                label: const Text('مزامنة الآن'),
                onPressed: onManualSync,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SystemInfoRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color? valueColor;
  final bool isMultiLine;

  const _SystemInfoRow({
    required this.label,
    required this.value,
    required this.icon,
    this.valueColor,
    this.isMultiLine = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: isMultiLine ? CrossAxisAlignment.start : CrossAxisAlignment.center,
      children: [
        Icon(icon, size: 20, color: Colors.grey),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(color: Colors.grey, fontSize: 13),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: valueColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ============ قسم تسجيل الخروج ============
class _LogoutSection extends StatelessWidget {
  const _LogoutSection();

  Future<void> _logout(BuildContext context) async {
    final confirmed = await _showConfirmDialog(
      context,
      'تسجيل الخروج',
      'هل تريد تسجيل الخروج من البرنامج؟',
    );

    if (!confirmed) return;

    if (!context.mounted) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.logout();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        icon: const Icon(Icons.logout),
        label: const Text('تسجيل الخروج'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
        onPressed: () => _logout(context),
      ),
    );
  }
}

// ============ دالة مساعدة لنافذة التأكيد ============
Future<bool> _showConfirmDialog(
  BuildContext context,
  String title,
  String message,
) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('إلغاء'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('تأكيد'),
        ),
      ],
    ),
  );

  return result ?? false;
}