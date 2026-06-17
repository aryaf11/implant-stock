import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/services/stock_repository.dart';
import '../../providers/stock_provider.dart';
import '../../widgets/app_shell.dart';
import '../../widgets/brand_inventory_view.dart';
import '../../widgets/edit_qty_dialog.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/section_card.dart';

class MyInventoryScreen extends StatelessWidget {
  const MyInventoryScreen({super.key, required this.centerId});

  final String centerId;

  Future<void> _editQty(
    BuildContext context,
    String itemId,
    int current,
  ) async {
    final newQty = await showEditQtyDialog(
      context,
      title: 'تعديل كمية ${centerNameAr(centerId)}',
      currentQty: current,
    );
    if (newQty == null || !context.mounted) return;
    final err = await context.read<StockProvider>().run(
          (s) => context.read<StockRepository>().updateCenterQty(
                s,
                centerId: centerId,
                itemId: itemId,
                newQty: newQty,
              ),
        );
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(err ?? 'تم تحديث الكمية')),
    );
  }

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
          title: 'ملخص سريع',
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
        const Padding(
          padding: EdgeInsets.only(bottom: 8),
          child: Text(
            'المخزون حسب الشركة والمقاس',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 15,
              color: Color(0xFF1A202C),
            ),
          ),
        ),
        BrandInventoryView(
          items: items,
          onEditQty: (item) => _editQty(context, item.id, item.qty),
        ),
      ],
    );
  }
}
