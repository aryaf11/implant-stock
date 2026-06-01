import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/models/implant_item.dart';
import '../../core/services/stock_repository.dart' show StockRepository, StockState;
import '../../providers/stock_provider.dart';

class ReturnWhScreen extends StatefulWidget {
  const ReturnWhScreen({super.key});

  @override
  State<ReturnWhScreen> createState() => _ReturnWhScreenState();
}

class _ReturnWhScreenState extends State<ReturnWhScreen> {
  String _centerId = kCenters.first.id;
  ImplantItem? _item;
  final _qty = TextEditingController();
  final _reason = TextEditingController();

  @override
  void dispose() {
    _qty.dispose();
    _reason.dispose();
    super.dispose();
  }

  List<ImplantItem> _centerItems(StockState? s) {
    if (s == null) return [];
    return s.centers[_centerId] ?? [];
  }

  Future<void> _submit() async {
    if (_item == null) return;
    final q = int.tryParse(_qty.text);
    if (q == null || q < 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('أدخل كمية صحيحة')),
      );
      return;
    }
    final repo = context.read<StockRepository>();
    final err = await context.read<StockProvider>().run(
          (s) => repo.returnFromCenter(
            s,
            centerId: _centerId,
            itemId: _item!.id,
            qty: q,
            reason: _reason.text.trim(),
          ),
        );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(err ?? 'تم الاسترجاع للمستودع')),
    );
    if (err == null) {
      _qty.clear();
      _reason.clear();
      setState(() => _item = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<StockProvider>().state;
    final items = _centerItems(s);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('استرجاع مباشر من فرع للمستودع',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _centerId,
            decoration: const InputDecoration(labelText: 'الفرع'),
            items: kCenters
                .map((c) =>
                    DropdownMenuItem(value: c.id, child: Text(c.nameAr)))
                .toList(),
            onChanged: (v) => setState(() {
              _centerId = v!;
              _item = null;
            }),
          ),
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
            decoration: const InputDecoration(labelText: 'سبب الاسترجاع'),
          ),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: _submit, child: const Text('استرجاع للمستودع')),
        ],
      ),
    );
  }
}
