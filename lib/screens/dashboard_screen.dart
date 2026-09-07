import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../widgets/sca_layout.dart';
import 'vehicle_search_screen.dart';
import 'vehicle_data_screen.dart';
import 'reports_screen.dart';
import 'gas_screen.dart';
import 'settings_screen.dart';
import 'archive_screen.dart';
import 'store_screen.dart';
import 'login_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _isLoading = true;
  String? _error;
  int _vehicleCount = 0;
  int _refuelCount = 0;
  double _totalLiters = 0;
  int _excessCount = 0;
  List<dynamic> _excessVehicles = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadDashboardSummary();
      }
    });
  }

  Future<void> _loadDashboardSummary() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    // Wait a short while for AuthProvider to load token (avoid calling API before token is ready)
    int waitAttempts = 0;
    while (authProvider.token == null && waitAttempts < 6) {
      // small delay to allow AuthProvider._loadToken() to complete
      await Future.delayed(const Duration(milliseconds: 250));
      waitAttempts++;
    }

    if (authProvider.token == null) {
      if (mounted) {
        setState(() {
          _error = 'لم يتم العثور على رمز المصادقة. يرجى تسجيل الدخول مرة أخرى.';
          _isLoading = false;
        });
      }
      return;
    }

    if (mounted) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }

    try {
      // زيادة مهلة استجابة الـ API لصفحة الداشبورد بسبب احتمال بطء استعلام البيانات.
      final summary = await ApiService.fetchDashboardSummary(authProvider.token!)
          .timeout(const Duration(seconds: 30), onTimeout: () => throw Exception('انتهت المهلة الزمنية لتحميل البيانات'));
      
      if (!mounted) return;
      
      setState(() {
        _vehicleCount = summary['vehicle_count'] as int? ?? 0;
        _refuelCount = summary['refuel_count'] as int? ?? 0;
        _totalLiters = (summary['total_liters'] as num?)?.toDouble() ?? 0.0;
        _excessCount = summary['excess_count'] as int? ?? 0;
        _excessVehicles = summary['excess_vehicles'] as List<dynamic>? ?? [];
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'فشل تحميل لوحة التحكم. ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  void _showExcessDetails() {
    if (_excessVehicles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لا توجد تجاوزات اليوم.')),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Center(
                child: Text(
                  'تفاصيل التجاوزات اليوم',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 12),
              if (_excessVehicles.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Text('لا توجد تجاوزات لعرضها اليوم.'),
                )
              else
                SizedBox(
                  height: 360,
                  child: ListView.separated(
                    itemCount: _excessVehicles.length,
                    separatorBuilder: (_, __) => const Divider(),
                    itemBuilder: (context, index) {
                      final vehicle = _excessVehicles[index] as Map<String, dynamic>;
                      final letters = vehicle['letters'] as String?;
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        title: Text('${vehicle['number']}${letters != null && letters.isNotEmpty ? ' $letters' : ''}'),
                        subtitle: Text('${vehicle['vehicle_type']} • ${vehicle['liters']} لتر • عداد ${vehicle['current_odometer']}'),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.red.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${(vehicle['actual_percentage'] as num).toDouble().toStringAsFixed(1)} لتر/100كم',
                            style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('إغلاق'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _navigateToVehicleData() {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const VehicleDataScreen()));
  }

  void _navigateToVehicleSearch() {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const VehicleSearchScreen()));
  }

  void _navigateToReports() {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ReportsScreen()));
  }

  void _navigateToSettings() {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SettingsScreen()));
  }

  Future<void> _logout() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.logout();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const ScaAppBar(title: 'SCA Fuel'),
      drawer: ScaDrawer(
        currentRoute: 'dashboard',
        onDashboard: () {},
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
        onArchive: () {
          Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ArchiveScreen()));
        },
        onLogout: _logout,
      ),
      body: Container(
        decoration: BoxDecoration(
          image: const DecorationImage(
            image: AssetImage('assets/bus.jpg'),
            fit: BoxFit.cover,
            opacity: 0.85,
          ),
          gradient: LinearGradient(
            colors: [Color(0xFF0D47A1).withOpacity(0.35), Color(0xFF1976D2).withOpacity(0.35)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 8),
                const Center(
                  child: Text(
                    'SCA Fuel',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 6),
                const Center(
                  child: Text(
                    'لوحة تحكم ذكية لإدارة الوقود والمركبات',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: Colors.white70),
                  ),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(28),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context).scaffoldBackgroundColor.withOpacity(0.6),
                        ),
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('إحصائيات اليوم', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
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
                                      const SizedBox(height: 16),
                                      ElevatedButton(
                                        onPressed: _loadDashboardSummary,
                                        child: const Text('إعادة تحميل'),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            else
                              Expanded(
                                child: GridView.count(
                                  crossAxisCount: MediaQuery.of(context).size.width > 700 ? 4 : 2,
                                  crossAxisSpacing: 12,
                                  mainAxisSpacing: 12,
                                  children: [
                                    _StatCard(
                                      title: 'عدد التفويلات',
                                      value: '$_refuelCount',
                                      color: Colors.indigo,
                                      icon: Icons.local_gas_station,
                                    ),
                                    _StatCard(
                                      title: 'عدد السيارات',
                                      value: '$_vehicleCount',
                                      color: Colors.teal,
                                      icon: Icons.directions_car,
                                    ),
                                    _StatCard(
                                      title: 'إجمالي اللترات',
                                      value: '${_totalLiters.toStringAsFixed(1)} لتر',
                                      color: Colors.green.shade700,
                                      icon: Icons.water_drop,
                                    ),
                                    _StatCard(
                                      title: 'التجاوزات',
                                      value: '$_excessCount',
                                      color: Colors.red,
                                      icon: Icons.warning_rounded,
                                      onTap: _showExcessDetails,
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
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

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final Color color;
  final IconData? icon;
  final VoidCallback? onTap;

  const _StatCard({
    required this.title,
    required this.value,
    required this.color,
    this.icon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 5,
        shadowColor: color.withOpacity(0.3),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              colors: [color.withOpacity(0.18), color.withOpacity(0.05)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (icon != null)
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(icon, size: 24, color: color),
                    )
                  else
                    const SizedBox(width: 40),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87)),
                  ),
                ],
              ),
              const Spacer(),
              Text(value, style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: Colors.black87)),
              if (onTap != null)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Text('اضغط للمزيد', style: TextStyle(fontSize: 12, color: Colors.black54)),
                ),
            ],
          ),
        ),
      ),
    );
  }
}