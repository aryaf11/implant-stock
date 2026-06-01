import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/stock_provider.dart';
import '../../widgets/app_drawer.dart';
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
  int _index = 0;
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  static const _destinations = [
    NavDestination(
      icon: Icons.dashboard_outlined,
      selectedIcon: Icons.dashboard,
      label: 'الرئيسية',
      subtitle: 'ملخص وطلبات معلقة',
    ),
    NavDestination(
      icon: Icons.add_box_outlined,
      selectedIcon: Icons.add_box,
      label: 'إضافة مخزون',
    ),
    NavDestination(
      icon: Icons.send_outlined,
      selectedIcon: Icons.send,
      label: 'صرف وطلبات',
    ),
    NavDestination(
      icon: Icons.replay_outlined,
      selectedIcon: Icons.replay,
      label: 'استرجاع',
    ),
    NavDestination(
      icon: Icons.warehouse_outlined,
      selectedIcon: Icons.warehouse,
      label: 'مخزون المستودع',
    ),
    NavDestination(
      icon: Icons.local_hospital_outlined,
      selectedIcon: Icons.local_hospital,
      label: 'مخزون الفروع',
    ),
    NavDestination(
      icon: Icons.analytics_outlined,
      selectedIcon: Icons.analytics,
      label: 'التقارير',
      subtitle: 'صرف أسبوعي وشهري',
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

  final _pages = const [
    AdminHomeScreen(),
    AddStockScreen(),
    DispatchScreen(),
    ReturnWhScreen(),
    WarehouseInventoryScreen(),
    CentersInventoryScreen(),
    ReportsScreen(),
    LogScreen(),
    UsersScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final pending = context.watch<StockProvider>().state?.pendingRequests.length ?? 0;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        key: _scaffoldKey,
        appBar: AppBar(
          title: Text(_destinations[_index].label),
          leading: IconButton(
            icon: const Icon(Icons.menu_rounded),
            onPressed: () => _scaffoldKey.currentState?.openDrawer(),
          ),
          actions: [
            if (pending > 0 && _index != 0)
              Padding(
                padding: const EdgeInsets.only(left: 4),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '$pending طلب',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ),
              ),
            IconButton(
              tooltip: 'تحديث',
              icon: const Icon(Icons.refresh_rounded),
              onPressed: () => context.read<StockProvider>().refresh(),
            ),
          ],
        ),
        drawer: AppDrawer(
          title: 'مخزون الزرعات',
          subtitle: 'لوحة المستودع',
          userName: auth.user?.displayName ?? 'الأدمن',
          avatarIcon: Icons.warehouse_outlined,
          destinations: _destinations,
          selectedIndex: _index,
          onSelect: (i) => setState(() => _index = i),
          onLogout: () async {
            context.read<StockProvider>().stopListening();
            await auth.logout();
          },
        ),
        body: AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: KeyedSubtree(
            key: ValueKey(_index),
            child: _pages[_index],
          ),
        ),
      ),
    );
  }
}
