import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/stock_provider.dart';
import 'nurse_failure_screen.dart';
import 'nurse_use_screen.dart';

class NurseShell extends StatefulWidget {
  const NurseShell({super.key});

  @override
  State<NurseShell> createState() => _NurseShellState();
}

class _NurseShellState extends State<NurseShell> {
  int _index = 0;

  static const _destinations = [
    (Icons.medical_services_outlined, Icons.medical_services, 'استخدام'),
    (Icons.report_problem_outlined, Icons.report_problem, 'فشل زرعة'),
  ];

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final centerId = auth.user?.centerId ?? kCenters.first.id;
    final centerName = centerNameAr(centerId);
    final d = _destinations[_index];

    final pages = [
      NurseUseScreen(centerId: centerId),
      NurseFailureScreen(centerId: centerId),
    ];

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: AppColors.headerGradient,
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
              ),
            ),
          ),
          title: Column(
            children: [
              Text('${auth.user?.displayName ?? "ممرضة"} · $centerName',
                  style: const TextStyle(fontSize: 15)),
              Text(
                d.$3,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withValues(alpha: 0.85),
                  fontWeight: FontWeight.normal,
                ),
              ),
            ],
          ),
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
        ),
        body: AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: KeyedSubtree(
            key: ValueKey(_index),
            child: pages[_index],
          ),
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: (i) => setState(() => _index = i),
          destinations: [
            for (final item in _destinations)
              NavigationDestination(
                icon: Icon(item.$1),
                selectedIcon: Icon(item.$2),
                label: item.$3,
              ),
          ],
        ),
      ),
    );
  }
}
