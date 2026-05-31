import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/stock_provider.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/implant_tile.dart';
import '../../widgets/section_card.dart';

class WarehouseInventoryScreen extends StatelessWidget {
  const WarehouseInventoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final items = context.watch<StockProvider>().state?.warehouse ?? [];

    if (items.isEmpty) {
      return const EmptyState(
        message: 'المستودع فارغ',
        subtitle: 'انتقل إلى «إضافة مخزون» لإدخال أول دفعة',
        icon: Icons.warehouse_outlined,
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        SectionHeader(
          title: 'مخزون المستودع (${items.length} صنف)',
        ),
        ...items.map((i) => ImplantTile(item: i)),
      ],
    );
  }
}
