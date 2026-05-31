import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../providers/stock_provider.dart';

class MyLogScreen extends StatelessWidget {
  const MyLogScreen({super.key, required this.centerId});

  final String centerId;

  @override
  Widget build(BuildContext context) {
    final name = centerNameAr(centerId);
    final logs = context.watch<StockProvider>().state?.movementLog
            .where((l) => l.center == centerId || l.detail.contains(name))
            .toList() ??
        [];

    if (logs.isEmpty) {
      return const Center(child: Text('لا توجد حركات'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: logs.length,
      itemBuilder: (_, i) {
        final l = logs[i];
        return Card(
          child: ListTile(
            title: Text(l.type),
            subtitle: Text('${l.op} | ${l.qty} | ${l.detail}'),
            trailing: Text(l.date, style: const TextStyle(fontSize: 12)),
          ),
        );
      },
    );
  }
}
