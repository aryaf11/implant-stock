import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/stock_provider.dart';
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

  static const _destinations = [
    (Icons.inventory_2_outlined, Icons.inventory_2, 'مخزوني'),
    (Icons.send_outlined, Icons.send, 'طلب'),
    (Icons.medical_services_outlined, Icons.medical_services, 'استخدام'),
    (Icons.replay_outlined, Icons.replay, 'إرجاع'),
    (Icons.history_outlined, Icons.history, 'سجلي'),
  ];

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final centerId = auth.user?.centerId ?? kCenters.first.id;
    final centerName = centerNameAr(centerId);

    final pages = [
      MyInventoryScreen(centerId: centerId),
      RequestScreen(centerId: centerId),
      UseScreen(centerId: centerId),
      ReturnScreen(centerId: centerId),
      MyLogScreen(centerId: centerId),
    ];

    final d = _destinations[_index];

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: const LinearGradient(
                colors: AppColors.headerGradient,
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
              ),
            ),
          ),
          title: Column(
            children: [
              Text(centerName, style: const TextStyle(fontSize: 16)),
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
