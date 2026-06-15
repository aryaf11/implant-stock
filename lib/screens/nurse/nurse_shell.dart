import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../providers/auth_provider.dart';
import '../../providers/stock_provider.dart';
import '../../widgets/app_shell.dart';
import 'nurse_failure_screen.dart';
import 'nurse_use_screen.dart';

class NurseShell extends StatefulWidget {
  const NurseShell({super.key});

  @override
  State<NurseShell> createState() => _NurseShellState();
}

class _NurseShellState extends State<NurseShell> {
  int _index = 0;

  static const _nav = [
    AppNavItem(
      icon: Icons.medical_services_outlined,
      selectedIcon: Icons.medical_services,
      label: 'استخدام',
    ),
    AppNavItem(
      icon: Icons.report_problem_outlined,
      selectedIcon: Icons.report_problem,
      label: 'فشل زرعة',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final centerId = auth.user?.centerId ?? kCenters.first.id;

    final pages = [
      NurseUseScreen(centerId: centerId),
      NurseFailureScreen(centerId: centerId),
    ];

    return AppShell(
      title:
          '${auth.user?.displayName ?? "ممرضة"} · ${centerNameAr(centerId)}',
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
