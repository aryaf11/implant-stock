import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/models/implant_item.dart';
import '../../core/services/stock_repository.dart';
import '../../providers/stock_provider.dart';

class UseScreen extends StatefulWidget {
  const UseScreen({super.key, required this.centerId});

  final String centerId;

  @override
  State<UseScreen> createState() => _UseScreenState();
}

class _UseScreenState extends State<UseScreen> {
  ImplantItem? _item;
  final _qty = TextEditingController();
  final _patient = TextEditingController();

  @override
  void dispose() {
    _qty.dispose();
    _patient.dispose();
    super.dispose();
  }

  Future<void> _use() async {
    if (_item == null) return;
    final q = int.tryParse(_qty.text);
    if (q == null || q < 1) return;
    final repo = StockRepository();
    final err = await context.read<StockProvider>().run(
          (s) => repo.useImplant(
            s,
            centerId: widget.centerId,
            itemId: _item!.id,
            qty: q,
            patient: _patient.text.trim(),
          ),
        );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(err ?? 'تم تسجيل الاستخدام')),
    );
    if (err == null) {
      _qty.clear();
      _patient.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final items =
        context.watch<StockProvider>().state?.centers[widget.centerId] ?? [];

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('تسجيل استخدام زرعة',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),
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
            controller: _patient,
            decoration: const InputDecoration(labelText: 'اسم المريض (اختياري)'),
          ),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: _use, child: const Text('تسجيل الاستخدام')),
        ],
      ),
    );
  }
}
