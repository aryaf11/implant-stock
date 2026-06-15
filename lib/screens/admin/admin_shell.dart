import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/stock_provider.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/app_shell.dart';
import 'add_stock_screen.dart';
import 'admin_home_screen.dart';
import 'centers_inventory_screen.dart';
import 'dispatch_screen.dart';
import 'log_screen.dart';
import 'reports_screen.dart';
import 'return_wh_screen.dart';
import 'users_screen.dart';
import 'warehouse_inventory_screen.dart';

class AdminShell extends StatefulWidget {
  const AdminShell({super.key});

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int _tab = 0;
  int? _menuPage;

  static const _bottomNav = [
    AppNavItem(
      icon: Icons.home_outlined,
      selectedIcon: Icons.home_rounded,
      label: 'الرئيسية',
    ),
    AppNavItem(
      icon: Icons.add_circle_outline,
      selectedIcon: Icons.add_circle,
      label: 'إضافة',
    ),
    AppNavItem(
      icon: Icons.send_outlined,
      selectedIcon: Icons.send_rounded,
      label: 'صرف',
    ),
    AppNavItem(
      icon: Icons.inventory_2_outlined,
      selectedIcon: Icons.inventory_2,
      label: 'المخزون',
    ),
    AppNavItem(
      icon: Icons.bar_chart_outlined,
      selectedIcon: Icons.bar_chart_rounded,
      label: 'تقارير',
    ),
  ];

  static const _drawerDestinations = [
    NavDestination(
      icon: Icons.replay_outlined,
      selectedIcon: Icons.replay,
      label: 'استرجاع',
    ),
    NavDestination(
      icon: Icons.local_hospital_outlined,
      selectedIcon: Icons.local_hospital,
      label: 'مخزون الفروع',
    ),
    NavDestination(
      icon: Icons.history_outlined,
      selectedIcon: Icons.history,
      label: 'السجل',
    ),
    NavDestination(
      icon: Icons.manage_accounts_outlined,
      selectedIcon: Icons.manage_accounts,
      label: 'المستخدمين',
    ),
  ];

  static const _tabPages = [
    AdminHomeScreen(),
    AddStockScreen(),
    DispatchScreen(),
    WarehouseInventoryScreen(),
    ReportsScreen(),
  ];

  static const _menuPages = [
    ReturnWhScreen(),
    CentersInventoryScreen(),
    LogScreen(),
    UsersScreen(),
  ];

  String get _title {
    if (_menuPage != null) return _drawerDestinations[_menuPage!].label;
    return _bottomNav[_tab].label;
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final pending =
        context.watch<StockProvider>().state?.pendingRequests.length ?? 0;

    return AppShell(
      title: _title,
      selectedIndex: _menuPage != null ? -1 : _tab,
      navItems: _bottomNav,
      onNavSelect: (i) => setState(() {
        _tab = i;
        _menuPage = null;
      }),
      actions: [
        if (pending > 0 && _tab == 0 && _menuPage == null)
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text('$pending طلب',
                    style: const TextStyle(fontSize: 12)),
              ),
            ),
          ),
        IconButton(
          tooltip: 'تحديث',
          icon: const Icon(Icons.refresh_rounded),
          onPressed: () => context.read<StockProvider>().refresh(),
        ),
      ],
      drawer: AppDrawer(
        title: 'مخزون الزرعات',
        subtitle: 'لوحة المستودع',
        userName: auth.user?.displayName ?? 'الأدمن',
        avatarIcon: Icons.warehouse_outlined,
        destinations: _drawerDestinations,
        selectedIndex: _menuPage ?? -1,
        onSelect: (i) => setState(() => _menuPage = i),
        onLogout: () async {
          context.read<StockProvider>().stopListening();
          await auth.logout();
        },
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        child: KeyedSubtree(
          key: ValueKey(_menuPage ?? 'tab_$_tab'),
          child: _menuPage != null ? _menuPages[_menuPage!] : _tabPages[_tab],
        ),
      ),
    );
  }
}
