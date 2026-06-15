import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/models/implant_item.dart';
import '../../core/services/stock_repository.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/stock_provider.dart';
import '../../widgets/section_card.dart';

class NurseUseScreen extends StatefulWidget {
  const NurseUseScreen({super.key, required this.centerId});

  final String centerId;

  @override
  State<NurseUseScreen> createState() => _NurseUseScreenState();
}

class _NurseUseScreenState extends State<NurseUseScreen> {
  ImplantItem? _item;
  final _qty = TextEditingController(text: '1');
  final _patient = TextEditingController();
  final _fileNo = TextEditingController();

  @override
  void dispose() {
    _qty.dispose();
    _patient.dispose();
    _fileNo.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_item == null) {
      _msg('اختر الزرعة');
      return;
    }
    final q = int.tryParse(_qty.text);
    if (q == null || q < 1) {
      _msg('أدخل كمية صحيحة');
      return;
    }
    if (_patient.text.trim().isEmpty) {
      _msg('اسم المريض مطلوب');
      return;
    }

    final auth = context.read<AuthProvider>().user!;
    final repo = context.read<StockRepository>();
    final err = await context.read<StockProvider>().run(
          (s) => repo.submitNurseUsage(
            s,
            centerId: widget.centerId,
            nurseUsername: auth.username,
            nurseName: auth.displayName,
            itemId: _item!.id,
            qty: q,
            patientName: _patient.text.trim(),
            patientFileNo: _fileNo.text.trim(),
          ),
        );
    if (!mounted) return;
    if (err != null) {
      _msg(err);
    } else {
      _msg('تم الإرسال للأدمن', ok: true);
      _qty.text = '1';
      _patient.clear();
      _fileNo.clear();
      setState(() => _item = null);
    }
  }

  void _msg(String t, {bool ok = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(t),
        backgroundColor: ok ? AppColors.success : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final items =
        context.watch<StockProvider>().state?.centers[widget.centerId] ?? [];
    final available = items.where((i) => i.qty > 0).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: SectionCard(
        title: 'تسجيل استخدام زرعة',
        subtitle: 'يُخصم من مخزون الفرع ويُرسل للأدمن',
        icon: Icons.medical_services_outlined,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DropdownButtonFormField<ImplantItem>(
              value: available.contains(_item) ? _item : null,
              decoration: const InputDecoration(labelText: 'الزرعة'),
              items: available
                  .map(
                    (i) => DropdownMenuItem(
                      value: i,
                      child: Text('${i.fullName} (${i.qty})'),
                    ),
                  )
                  .toList(),
              onChanged: (v) => setState(() => _item = v),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _qty,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'الكمية'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _patient,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'اسم المريض',
                hintText: 'مطلوب',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _fileNo,
              decoration: const InputDecoration(
                labelText: 'رقم ملف المريض (اختياري)',
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _submit,
              icon: const Icon(Icons.send_rounded),
              label: const Text('إرسال للأدمن'),
            ),
          ],
        ),
      ),
    );
  }
}
