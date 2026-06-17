import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/services/stock_repository.dart';
import '../../providers/stock_provider.dart';
import '../../widgets/app_shell.dart';
import '../../widgets/edit_qty_dialog.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/implant_tile.dart';

class WarehouseInventoryScreen extends StatelessWidget {
  const WarehouseInventoryScreen({super.key});

  Future<void> _editQty(BuildContext context, String itemId, int current) async {
    final newQty = await showEditQtyDialog(
      context,
      title: 'تعديل كمية المستودع',
      currentQty: current,
    );
    if (newQty == null || !context.mounted) return;
    final err = await context.read<StockProvider>().run(
          (s) => context.read<StockRepository>().updateWarehouseQty(
                s,
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
            children: items
                .map(
                  (i) => ImplantTile(
                    item: i,
                    onEditQty: () => _editQty(context, i.id, i.qty),
                  ),
                )
                .toList(),
          ),
        ),
      ],
    );
  }
}
