import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/stock_provider.dart';
import '../../widgets/app_shell.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/implant_tile.dart';
import '../../widgets/section_card.dart';

class MyInventoryScreen extends StatelessWidget {
  const MyInventoryScreen({super.key, required this.centerId});

  final String centerId;

  @override
  Widget build(BuildContext context) {
    final items =
        context.watch<StockProvider>().state?.centers[centerId] ?? [];

    if (items.isEmpty) {
      return const EmptyState(
        message: 'لا يوجد مخزون في فرعك',
        subtitle: 'اطلب من المستودع عبر تبويب «طلب»',
        icon: Icons.inventory_2_outlined,
      );
    }

    final low = items.where((i) => i.qty <= 2).length;

    final byCategory = inventoryByCategory(items);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      children: [
        if (low > 0)
          SectionCard(
            title: 'تنبيه',
            icon: Icons.warning_amber_rounded,
            child: Text(
              '$low صنف بكمية منخفضة (2 أو أقل)',
              style: const TextStyle(
                  color: Color(0xFFC05621), fontWeight: FontWeight.w600),
            ),
          ),
        if (low > 0) const SizedBox(height: 4),
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
          title: 'أصناف الفرع (${items.length})',
          child: Column(
            children:
                items.map((i) => ImplantTile(item: i, lowThreshold: 2)).toList(),
          ),
        ),
      ],
    );
  }
}
