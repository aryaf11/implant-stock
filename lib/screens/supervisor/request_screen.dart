import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/models/implant_item.dart';
import '../../core/services/stock_repository.dart';
import '../../providers/stock_provider.dart';
import '../../widgets/request_status_badge.dart';

class RequestScreen extends StatefulWidget {
  const RequestScreen({super.key, required this.centerId});

  final String centerId;

  @override
  State<RequestScreen> createState() => _RequestScreenState();
}

class _RequestScreenState extends State<RequestScreen> {
  ImplantItem? _item;
  final _qty = TextEditingController();
  final _note = TextEditingController();

  @override
  void dispose() {
    _qty.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (_item == null) return;
    final q = int.tryParse(_qty.text);
    if (q == null || q < 1) {
      _snack('أدخل كمية صحيحة');
      return;
    }
    final repo = context.read<StockRepository>();
    final err = await context.read<StockProvider>().run(
          (s) => repo.sendRequest(
            s,
            centerId: widget.centerId,
            warehouseItemId: _item!.id,
            qty: q,
            note: _note.text.trim(),
          ),
        );
    if (err != null) {
      _snack(err);
    } else {
      _snack('تم إرسال الطلب للأدمن', ok: true);
      _qty.clear();
      _note.clear();
    }
  }

  void _snack(String m, {bool ok = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(m), backgroundColor: ok ? Colors.green : null),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<StockProvider>().state;
    if (s == null) return const Center(child: CircularProgressIndicator());

    final available = s.warehouse.where((i) => i.qty > 0).toList();
    final myReqs =
        s.requests.where((r) => r.centerId == widget.centerId).toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('طلب زرعة من المستودع',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                if (available.isEmpty)
                  const Text('لا يوجد مخزون متاح في المستودع حالياً')
                else ...[
                  DropdownButtonFormField<ImplantItem>(
                    value: _item,
                    decoration: const InputDecoration(labelText: 'الزرعة المتاحة'),
                    items: available
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
                    controller: _note,
                    decoration: const InputDecoration(labelText: 'ملاحظات'),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(onPressed: _send, child: const Text('إرسال الطلب')),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Text('طلباتي السابقة', style: TextStyle(fontWeight: FontWeight.bold)),
        ...myReqs.map(
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
