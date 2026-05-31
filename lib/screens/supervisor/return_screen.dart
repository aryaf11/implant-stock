import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/models/implant_item.dart';
import '../../core/services/stock_repository.dart';
import '../../providers/stock_provider.dart';
import '../../widgets/request_status_badge.dart';

class ReturnScreen extends StatefulWidget {
  const ReturnScreen({super.key, required this.centerId});

  final String centerId;

  @override
  State<ReturnScreen> createState() => _ReturnScreenState();
}

class _ReturnScreenState extends State<ReturnScreen> {
  ImplantItem? _item;
  final _qty = TextEditingController();
  final _reason = TextEditingController();

  @override
  void dispose() {
    _qty.dispose();
    _reason.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_item == null) return;
    final q = int.tryParse(_qty.text);
    if (q == null || q < 1) return;
    final repo = StockRepository();
    final err = await context.read<StockProvider>().run(
          (s) => repo.submitReturnRequest(
            s,
            centerId: widget.centerId,
            itemId: _item!.id,
            qty: q,
            reason: _reason.text.trim(),
          ),
        );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(err ?? 'تم إرسال طلب الإرجاع للأدمن')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<StockProvider>().state;
    final items = s?.centers[widget.centerId] ?? [];
    final myReturns = s?.returnRequests
            .where((r) => r.centerId == widget.centerId)
            .toList() ??
        [];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('طلب إرجاع للمستودع (يتطلب موافقة الأدمن)',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                DropdownButtonFormField<ImplantItem>(
                  value: items.contains(_item) ? _item : null,
                  decoration: const InputDecoration(labelText: 'الزرعة'),
                  items: items
                      .map((i) => DropdownMenuItem(
                            value: i,
                            child: Text('${i.fullName} (${i.qty})'),
                          ))
                      .toList(),
                  onChanged: (v) => setState(() => _item = v),
                ),
                TextField(
                  controller: _qty,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'الكمية'),
                ),
                TextField(
                  controller: _reason,
                  decoration: const InputDecoration(labelText: 'سبب الإرجاع'),
                ),
                const SizedBox(height: 12),
                ElevatedButton(onPressed: _submit, child: const Text('إرسال طلب الإرجاع')),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Text('طلبات الإرجاع السابقة',
            style: TextStyle(fontWeight: FontWeight.bold)),
        ...myReturns.map(
          (r) => ListTile(
            title: Text(r.fullName),
            subtitle: Text('${r.qty} | ${r.date}'),
            trailing: requestStatusBadge(r.status),
          ),
        ),
      ],
    );
  }
}
