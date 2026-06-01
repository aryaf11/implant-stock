import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/models/implant_item.dart';
import '../../core/services/stock_repository.dart';
import '../../providers/stock_provider.dart';
import '../../widgets/request_tile.dart';

class DispatchScreen extends StatefulWidget {
  const DispatchScreen({super.key});

  @override
  State<DispatchScreen> createState() => _DispatchScreenState();
}

class _DispatchScreenState extends State<DispatchScreen> {
  ImplantItem? _item;
  String _centerId = kCenters.first.id;
  final _qty = TextEditingController();
  final _note = TextEditingController();

  @override
  void dispose() {
    _qty.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _dispatch() async {
    if (_item == null) return;
    final q = int.tryParse(_qty.text);
    if (q == null || q < 1) {
      _snack('أدخل كمية صحيحة');
      return;
    }
    final repo = context.read<StockRepository>();
    final err = await context.read<StockProvider>().run(
          (s) => repo.dispatchToCenter(
            s,
            warehouseItemId: _item!.id,
            centerId: _centerId,
            qty: q,
            note: _note.text.trim(),
          ),
        );
    if (err != null) {
      _snack(err);
    } else {
      _snack('تم الصرف', ok: true);
      _qty.clear();
      _note.clear();
    }
  }

  void _snack(String m, {bool ok = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(m), backgroundColor: ok ? Colors.green : null),
    );
  }

  Future<void> _approve(String id, bool isReturn) async {
    final stock = context.read<StockProvider>();
    final err = isReturn
        ? await stock.approveReturn(id)
        : await stock.approveRequest(id);
    if (err != null) {
      _snack(err);
    } else {
      _snack('تمت الموافقة', ok: true);
    }
  }

  Future<void> _reject(String id, bool isReturn) async {
    final stock = context.read<StockProvider>();
    final err = isReturn
        ? await stock.rejectReturn(id)
        : await stock.rejectRequest(id);
    if (err != null) {
      _snack(err);
    } else {
      _snack('تم الرفض', ok: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final stock = context.watch<StockProvider>();
    final s = stock.state;
    if (s == null) return const Center(child: CircularProgressIndicator());

    final items = s.warehouse.where((i) => i.qty > 0).toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('صرف مباشر من المستودع',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 12),
                DropdownButtonFormField<ImplantItem>(
                  value: _item,
                  decoration: const InputDecoration(labelText: 'الزرعة'),
                  items: items
                      .map((i) => DropdownMenuItem(
                            value: i,
                            child: Text('${i.fullName} (${i.qty})'),
                          ))
                      .toList(),
                  onChanged: (v) => setState(() => _item = v),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _centerId,
                  decoration: const InputDecoration(labelText: 'الفرع'),
                  items: kCenters
                      .map((c) => DropdownMenuItem(
                            value: c.id,
                            child: Text(c.nameAr),
                          ))
                      .toList(),
                  onChanged: (v) => setState(() => _centerId = v!),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _qty,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'الكمية'),
                ),
                TextField(
                  controller: _note,
                  decoration: const InputDecoration(labelText: 'ملاحظات'),
                ),
                const SizedBox(height: 12),
                ElevatedButton(onPressed: _dispatch, child: const Text('صرف')),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        const Text('طلبات الصرف من المشرفين',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        ...s.pendingRequests.map(
          (r) => RequestTile(
            key: ValueKey('req_${r.id}'),
            title: r.fullName,
            subtitle: '${centerNameAr(r.centerId)} | ${r.qty}',
            isBusy: stock.isBusy(r.id),
            onApprove:
                stock.isBusy(r.id) ? null : () => _approve(r.id, false),
            onReject: stock.isBusy(r.id) ? null : () => _reject(r.id, false),
          ),
        ),
        const SizedBox(height: 16),
        const Text('طلبات الاسترجاع',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        ...s.pendingReturnRequests.map(
          (r) => RequestTile(
            key: ValueKey('ret_${r.id}'),
            title: r.fullName,
            subtitle: '${centerNameAr(r.centerId)} | ${r.qty}',
            isBusy: stock.isBusy('ret_${r.id}'),
            onApprove:
                stock.isBusy('ret_${r.id}') ? null : () => _approve(r.id, true),
            onReject:
                stock.isBusy('ret_${r.id}') ? null : () => _reject(r.id, true),
          ),
        ),
      ],
    );
  }
}
