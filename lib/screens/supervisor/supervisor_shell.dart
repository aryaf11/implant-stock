import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../providers/auth_provider.dart';
import '../../providers/stock_provider.dart';
import '../../widgets/app_shell.dart';
import 'my_inventory_screen.dart';
import 'my_log_screen.dart';
import 'request_screen.dart';
import 'return_screen.dart';
import 'use_screen.dart';

class SupervisorShell extends StatefulWidget {
  const SupervisorShell({super.key});

  @override
  State<SupervisorShell> createState() => _SupervisorShellState();
}

class _SupervisorShellState extends State<SupervisorShell> {
  int _index = 0;

  static const _nav = [
    AppNavItem(
      icon: Icons.home_outlined,
      selectedIcon: Icons.home_rounded,
      label: 'الرئيسية',
    ),
    AppNavItem(
      icon: Icons.send_outlined,
      selectedIcon: Icons.send_rounded,
      label: 'طلب',
    ),
    AppNavItem(
      icon: Icons.medical_services_outlined,
      selectedIcon: Icons.medical_services,
      label: 'استخدام',
    ),
    AppNavItem(
      icon: Icons.replay_outlined,
      selectedIcon: Icons.replay,
      label: 'إرجاع',
    ),
    AppNavItem(
      icon: Icons.bar_chart_outlined,
      selectedIcon: Icons.bar_chart_rounded,
      label: 'سجلي',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final centerId = auth.user?.centerId ?? kCenters.first.id;

    final pages = [
      MyInventoryScreen(centerId: centerId),
      RequestScreen(centerId: centerId),
      UseScreen(centerId: centerId),
      ReturnScreen(centerId: centerId),
      MyLogScreen(centerId: centerId),
    ];

    return AppShell(
      title: '${centerNameAr(centerId)} · ${_nav[_index].label}',
      showPageTitle: false,
      selectedIndex: _index,
      navItems: _nav,
      onNavSelect: (i) => setState(() => _index = i),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh_rounded),
          onPressed: () => context.read<StockProvider>().refresh(),
        ),
        IconButton(
          icon: const Icon(Icons.logout_rounded),
          onPressed: () async {
            context.read<StockProvider>().stopListening();
            await auth.logout();
          },
        ),
      ],
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        child: KeyedSubtree(
          key: ValueKey(_index),
          child: pages[_index],
        ),
      ),
    );
  }
}
