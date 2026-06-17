import 'package:flutter/material.dart';

Future<int?> showEditQtyDialog(
  BuildContext context, {
  required String title,
  required int currentQty,
}) async {
  final addCtrl = TextEditingController();
  final setCtrl = TextEditingController(text: '$currentQty');
  var mode = 0; // 0=إضافة, 1=تعيين

  final result = await showDialog<int>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setDlg) => AlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('الكمية الحالية: $currentQty',
                style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            SegmentedButton<int>(
              segments: const [
                ButtonSegment(value: 0, label: Text('إضافة')),
                ButtonSegment(value: 1, label: Text('تعيين')),
              ],
              selected: {mode},
              onSelectionChanged: (s) => setDlg(() => mode = s.first),
            ),
            const SizedBox(height: 12),
            if (mode == 0)
              TextField(
                controller: addCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'كمية تُضاف',
                  hintText: 'مثال: 10',
                ),
              )
            else
              TextField(
                controller: setCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'الكمية الجديدة',
                ),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () {
              if (mode == 0) {
                final add = int.tryParse(addCtrl.text.trim());
                if (add == null || add < 1) return;
                Navigator.pop(ctx, currentQty + add);
              } else {
                final set = int.tryParse(setCtrl.text.trim());
                if (set == null || set < 0) return;
                Navigator.pop(ctx, set);
              }
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    ),
  );

  addCtrl.dispose();
  setCtrl.dispose();
  return result;
}
