import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../providers/stock_provider.dart';

class CentersInventoryScreen extends StatefulWidget {
  const CentersInventoryScreen({super.key});

  @override
  State<CentersInventoryScreen> createState() => _CentersInventoryScreenState();
}

class _CentersInventoryScreenState extends State<CentersInventoryScreen> {
  String _filter = 'all';

  @override
  Widget build(BuildContext context) {
    final centers = context.watch<StockProvider>().state?.centers ?? {};
    final rows = <Widget>[];

    for (final c in kCenters) {
      if (_filter != 'all' && _filter != c.id) continue;
      final items = centers[c.id] ?? [];
      for (final item in items) {
        rows.add(
          Card(
            child: ListTile(
              leading: Chip(label: Text(c.nameAr)),
              title: Text(item.fullName),
              trailing: Text('${item.qty}',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
          ),
        );
      }
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: DropdownButtonFormField<String>(
            value: _filter,
            decoration: const InputDecoration(labelText: 'تصفية الفرع'),
            items: [
              const DropdownMenuItem(value: 'all', child: Text('جميع الفروع')),
              ...kCenters.map(
                (c) => DropdownMenuItem(value: c.id, child: Text(c.nameAr)),
              ),
            ],
            onChanged: (v) => setState(() => _filter = v!),
          ),
        ),
        Expanded(
          child: rows.isEmpty
              ? const Center(child: Text('لا يوجد مخزون في الفروع'))
              : ListView(children: rows),
        ),
      ],
    );
  }
}
