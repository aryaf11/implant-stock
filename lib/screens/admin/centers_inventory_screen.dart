import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/services/stock_repository.dart';
import '../../providers/stock_provider.dart';
import '../../widgets/edit_qty_dialog.dart';
import '../../widgets/implant_tile.dart';

class CentersInventoryScreen extends StatefulWidget {
  const CentersInventoryScreen({super.key});

  @override
  State<CentersInventoryScreen> createState() => _CentersInventoryScreenState();
}

class _CentersInventoryScreenState extends State<CentersInventoryScreen> {
  String _filter = 'all';

  Future<void> _editQty(
    BuildContext context,
    String centerId,
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
    final centers = context.watch<StockProvider>().state?.centers ?? {};

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: DropdownButtonFormField<String>(
            initialValue: _filter,
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
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            children: [
              for (final c in kCenters)
                if (_filter == 'all' || _filter == c.id) ...[
                  Padding(
                    padding: const EdgeInsets.only(top: 8, bottom: 8),
                    child: Text(
                      c.nameAr,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  if ((centers[c.id] ?? []).isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(bottom: 12),
                      child: Text('لا يوجد مخزون',
                          style: TextStyle(color: Color(0xFF718096))),
                    )
                  else
                    ...(centers[c.id] ?? []).map(
                      (item) => ImplantTile(
                        item: item,
                        onEditQty: () =>
                            _editQty(context, c.id, item.id, item.qty),
                      ),
                    ),
                ],
            ],
          ),
        ),
      ],
    );
  }
}
