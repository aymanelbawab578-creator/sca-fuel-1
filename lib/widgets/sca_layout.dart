import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../screens/gas_screen.dart';

class ScaColors {
  static const Color navy = Color(0xFF0D2D4F);
  static const Color turquoise = Color(0xFF1E88E5);
  static const Color lightGray = Color(0xFFF5F7F9);
  static const Color background = Color(0xFFFAFAFB);
  static const Color surface = Colors.white;
  static const Color onSurface = Color(0xFF0F1F33);
}

class ScaKeyboardTabBar extends StatelessWidget
    implements PreferredSizeWidget {
  final TabController controller;
  final List<Widget> tabs;

  const ScaKeyboardTabBar({
    super.key,
    required this.controller,
    required this.tabs,
  });

  @override
  Widget build(BuildContext context) {
    return Focus(
      autofocus: true,
      onKeyEvent: (node, event) {
        if (event is! KeyDownEvent) {
          return KeyEventResult.ignored;
        }

        var nextIndex = controller.index;

        if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
          nextIndex = (nextIndex + 1).clamp(0, tabs.length - 1);
        } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
          nextIndex = (nextIndex - 1).clamp(0, tabs.length - 1);
        } else if (event.logicalKey == LogicalKeyboardKey.enter) {
          controller.animateTo(controller.index);
          return KeyEventResult.handled;
        } else {
          return KeyEventResult.ignored;
        }

        controller.animateTo(nextIndex);
        return KeyEventResult.handled;
      },
      child: TabBar(
        controller: controller,
        tabs: tabs,
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kTextTabBarHeight);
}

class ScaAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool showBack;
  final bool showMenu;
  final VoidCallback? onBack;

  const ScaAppBar({
    super.key,
    required this.title,
    this.showBack = false,
    this.showMenu = true,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: const Color(0xFFF2F2F2),
      elevation: 0,
      leadingWidth: showBack && showMenu ? 112 : 56,
      automaticallyImplyLeading: !showBack,
      leading: showBack
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  color: ScaColors.onSurface,
                  onPressed: onBack,
                ),
                if (showMenu)
                  Builder(
                    builder: (context) {
                      return IconButton(
                        icon: const Icon(Icons.menu),
                        color: ScaColors.onSurface,
                        onPressed: () =>
                            Scaffold.of(context).openDrawer(),
                      );
                    },
                  ),
              ],
            )
          : null,
      title: Row(
        children: [
          Image.asset('assets/sca.png', height: 30),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: ScaColors.onSurface,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      iconTheme: const IconThemeData(
        color: ScaColors.onSurface,
      ),
      titleTextStyle: const TextStyle(
        color: ScaColors.onSurface,
        fontWeight: FontWeight.bold,
        fontSize: 20,
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class ScaDrawer extends StatelessWidget {
  final VoidCallback onDashboard;
  final VoidCallback onVehicleSearch;
  final VoidCallback onStore;
  final VoidCallback onVehicleData;
  final VoidCallback onReports;
  final VoidCallback onSettings;
  final VoidCallback onArchive;
  final VoidCallback onLogout;
  final VoidCallback? onGas;
  final void Function(int)? onReportTab;
  final void Function(int)? onGasTab;
  final void Function(int)? onStoreTab;
  final String currentRoute;

  const ScaDrawer({
    super.key,
    required this.onDashboard,
    required this.onVehicleSearch,
    required this.onStore,
    required this.onVehicleData,
    required this.onReports,
    required this.onSettings,
    required this.onArchive,
    required this.onLogout,
    this.onGas,
    this.onReportTab,
    this.onGasTab,
    this.onStoreTab,
    required this.currentRoute,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      width: 292,
      child: Container(
        color: Colors.white,
        child: ListView(
          padding: EdgeInsets.zero,
          physics: const ClampingScrollPhysics(),
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(
                color: Colors.white,
              ),
              child: SizedBox(
                width: double.infinity,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      'assets/sca.png',
                      width: 72,
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'SCA Fuel',
                      style: TextStyle(
                        color: Color(0xFF333333),
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            _buildDrawerItem(
              context,
              icon: Icons.dashboard,
              label: 'Dashboard',
              selected: currentRoute == 'dashboard',
              onTap: onDashboard,
            ),
            _divider(),

            _buildDrawerItem(
              context,
              icon: Icons.directions_car,
              label: 'متابعة المركبات',
              selected: currentRoute == 'vehicle_search',
              onTap: onVehicleSearch,
            ),
            _divider(),

            _buildStoreItem(context),
            _divider(),

            _buildGasItem(context),
            _divider(),

            _buildDrawerItem(
              context,
              icon: Icons.list_alt,
              label: 'بيانات المركبات',
              selected: currentRoute == 'vehicle_data',
              onTap: onVehicleData,
            ),
            _divider(),

            _buildReportsItem(context),
            _divider(),

            _buildDrawerItem(
              context,
              icon: Icons.settings_applications,
              label: 'الإعدادات',
              selected: currentRoute == 'settings',
              onTap: onSettings,
            ),

            _divider(),

            _buildDrawerItem(
              context,
              icon: Icons.archive_outlined,
              label: 'الأرشيف',
              selected: currentRoute == 'archive',
              onTap: onArchive,
            ),

            _divider(),

            // تسجيل الخروج
            _buildDrawerItem(
              context,
              icon: Icons.logout,
              label: 'تسجيل الخروج',
              selected: false,
              isLogout: true,
              onTap: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('تأكيد تسجيل الخروج'),
                    content: const Text('هل تريد تسجيل الخروج؟'),
                    actions: [
                      TextButton(
                        onPressed: () =>
                            Navigator.pop(context, false),
                        child: const Text('إلغاء'),
                      ),
                      TextButton(
                        onPressed: () =>
                            Navigator.pop(context, true),
                        child: const Text(
                          'نعم',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                );

                if (confirmed == true) {
                  onLogout();
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _divider() {
    return const Divider(
      height: 1,
      thickness: 0.6,
      indent: 16,
      endIndent: 16,
      color: Color(0xFFE5E9EE),
    );
  }

  Widget _buildDrawerItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required bool selected,
    required VoidCallback onTap,
    bool isLogout = false,
  }) {
    final itemColor = isLogout
        ? const Color(0xFFB3261E)
        : (selected
            ? ScaColors.navy
            : const Color(0xFF333333));

    return ListTile(
      dense: true,
      minVerticalPadding: 0,
      visualDensity: const VisualDensity(
        vertical: -2,
      ),
      leading: Icon(
        icon,
        color: itemColor,
      ),
      title: Text(
        label,
        style: TextStyle(
          color: itemColor,
          fontWeight: selected || isLogout
              ? FontWeight.bold
              : FontWeight.normal,
        ),
      ),
      selected: selected,
      selectedTileColor: const Color(0xFFE8F2FF),
      tileColor: Colors.white,
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
    );
  }

  Widget _buildReportsItem(BuildContext context) {
    final selected = currentRoute == 'reports';
    final itemColor = selected
        ? ScaColors.navy
        : const Color(0xFF333333);

    return Theme(
      data: Theme.of(context).copyWith(
        dividerColor: Colors.transparent,
      ),
      child: ExpansionTile(
        initiallyExpanded: selected,
        tilePadding: const EdgeInsets.symmetric(
          horizontal: 16,
        ),
        childrenPadding: EdgeInsets.zero,
        visualDensity: const VisualDensity(
          vertical: -2,
        ),
        iconColor: ScaColors.navy,
        collapsedIconColor: const Color(0xFF333333),
        leading: Icon(
          Icons.receipt_long,
          color: itemColor,
        ),
        title: Text(
          'التقارير',
          style: TextStyle(
            color: itemColor,
            fontWeight: selected
                ? FontWeight.bold
                : FontWeight.normal,
          ),
        ),
        children: [
          _buildSubItem(
            context,
            'التقرير اليومي',
            0,
            onReportTab,
            onReports,
          ),
          _buildSubItem(
            context,
            'تقرير النسبة',
            1,
            onReportTab,
            onReports,
          ),
          _buildSubItem(
            context,
            'تقرير الفترة',
            2,
            onReportTab,
            onReports,
          ),
          _buildSubItem(
            context,
            'كميات الوقود',
            3,
            onReportTab,
            onReports,
          ),
          _buildSubItem(
            context,
            'حاسبة الفواتير',
            4,
            onReportTab,
            onReports,
          ),
          _buildSubItem(
            context,
            'تسليم كارت',
            5,
            onReportTab,
            onReports,
          ),
        ],
      ),
    );
  }

  Widget _buildStoreItem(BuildContext context) {
    final selected = currentRoute == 'store';
    final itemColor = selected
        ? ScaColors.navy
        : const Color(0xFF333333);

    return Theme(
      data: Theme.of(context).copyWith(
        dividerColor: Colors.transparent,
      ),
      child: ExpansionTile(
        initiallyExpanded: selected,
        tilePadding: const EdgeInsets.symmetric(
          horizontal: 16,
        ),
        childrenPadding: EdgeInsets.zero,
        visualDensity: const VisualDensity(
          vertical: -2,
        ),
        iconColor: ScaColors.navy,
        collapsedIconColor: const Color(0xFF333333),
        leading: Icon(
          Icons.store,
          color: itemColor,
        ),
        title: Text(
          'المخزن',
          style: TextStyle(
            color: itemColor,
            fontWeight: selected
                ? FontWeight.bold
                : FontWeight.normal,
          ),
        ),
        children: [
          _buildSubItem(
            context,
            'المتابعة',
            0,
            onStoreTab,
            onStore,
          ),
          _buildSubItem(
            context,
            'الفواتير',
            1,
            onStoreTab,
            onStore,
          ),
          _buildSubItem(
            context,
            'تقرير التسوية',
            2,
            onStoreTab,
            onStore,
          ),
          _buildSubItem(
            context,
            'تغيير السعر',
            3,
            onStoreTab,
            onStore,
          ),
          _buildSubItem(
            context,
            'المأموريات',
            4,
            onStoreTab,
            onStore,
          ),
          _buildSubItem(
            context,
            'جرد',
            5,
            onStoreTab,
            onStore,
          ),
        ],
      ),
    );
  }

  Widget _buildGasItem(BuildContext context) {
    final selected = currentRoute == 'gas';
    final itemColor = selected
        ? ScaColors.navy
        : const Color(0xFF333333);

    return Theme(
      data: Theme.of(context).copyWith(
        dividerColor: Colors.transparent,
      ),
      child: ExpansionTile(
        initiallyExpanded: selected,
        tilePadding: const EdgeInsets.symmetric(
          horizontal: 16,
        ),
        childrenPadding: EdgeInsets.zero,
        visualDensity: const VisualDensity(
          vertical: -2,
        ),
        iconColor: ScaColors.navy,
        collapsedIconColor: const Color(0xFF333333),
        leading: Icon(
          Icons.local_gas_station,
          color: itemColor,
        ),
        title: Text(
          'الغاز',
          style: TextStyle(
            color: itemColor,
            fontWeight: selected
                ? FontWeight.bold
                : FontWeight.normal,
          ),
        ),
        children: [
          _buildSubItem(
            context,
            'تسجيل الغاز',
            0,
            onGasTab,
            onGas ??
                () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const GasScreen(),
                      ),
                    ),
          ),
          _buildSubItem(
            context,
            'تقرير الغاز',
            1,
            onGasTab,
            onGas ??
                () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const GasScreen(),
                      ),
                    ),
          ),
          _buildSubItem(
            context,
            'سجل الفترات',
            2,
            onGasTab,
            onGas ??
                () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const GasScreen(),
                      ),
                    ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubItem(
    BuildContext context,
    String label,
    int index,
    void Function(int)? onTab,
    VoidCallback onMainPage,
  ) {
    return ListTile(
      dense: true,
      minVerticalPadding: 0,
      visualDensity: const VisualDensity(
        vertical: -4,
      ),
      contentPadding: const EdgeInsetsDirectional.only(
        start: 72,
        end: 16,
      ),
      title: Text(
        label,
        style: const TextStyle(
          fontSize: 14,
          color: Color(0xFF333333),
        ),
      ),
      onTap: () {
        // نفس منطق الاستدعاء القديم
        Navigator.pop(context);

        if (onTab != null) {
          onTab(index);
        } else {
          onMainPage();
        }
      },
    );
  }
}
