import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/stock_provider.dart';
import '../../widgets/app_shell.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/implant_tile.dart';

class WarehouseInventoryScreen extends StatelessWidget {
  const WarehouseInventoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final items = context.watch<StockProvider>().state?.warehouse ?? [];
    final byCategory = inventoryByCategory(items);

    if (items.isEmpty) {
      return const EmptyState(
        message: 'المستودع فارغ',
        subtitle: 'انتقل إلى «إضافة» لإدخال أول دفعة',
        icon: Icons.warehouse_outlined,
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      children: [
        AppContentCard(
          title: 'المخزون حسب التصنيف',
          child: Column(
            children: [
              for (final e in byCategory.entries)
                AppCountRow(
                  label: e.key,
                  count: e.value,
                  showDivider: e.key != byCategory.keys.last,
                ),
            ],
          ),
        ),
        AppContentCard(
          title: 'كل الأصناف (${items.length})',
          child: Column(
            children: items.map((i) => ImplantTile(item: i)).toList(),
          ),
        ),
      ],
    );
  }
}
