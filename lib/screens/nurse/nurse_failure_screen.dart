import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/models/implant_item.dart';
import '../../core/services/stock_repository.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/stock_provider.dart';
import '../../widgets/section_card.dart';

class NurseFailureScreen extends StatefulWidget {
  const NurseFailureScreen({super.key, required this.centerId});

  final String centerId;

  @override
  State<NurseFailureScreen> createState() => _NurseFailureScreenState();
}

class _NurseFailureScreenState extends State<NurseFailureScreen> {
  ImplantItem? _item;
  final _patient = TextEditingController();
  final _fileNo = TextEditingController();
  final _note = TextEditingController();

  @override
  void dispose() {
    _patient.dispose();
    _fileNo.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_patient.text.trim().isEmpty) {
      _msg('اسم المريض مطلوب');
      return;
    }
    if (_fileNo.text.trim().isEmpty) {
      _msg('رقم ملف المريض مطلوب');
      return;
    }

    final auth = context.read<AuthProvider>().user!;
    final repo = context.read<StockRepository>();
    final err = await context.read<StockProvider>().run(
          (s) => repo.submitImplantFailure(
            s,
            centerId: widget.centerId,
            nurseUsername: auth.username,
            nurseName: auth.displayName,
            patientName: _patient.text.trim(),
            patientFileNo: _fileNo.text.trim(),
            implantInfo: _item?.fullName ?? '',
            note: _note.text.trim(),
          ),
        );
    if (!mounted) return;
    if (err != null) {
      _msg(err);
    } else {
      _msg('تم إبلاغ الأدمن بفشل الزرعة', ok: true);
      _patient.clear();
      _fileNo.clear();
      _note.clear();
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

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: SectionCard(
        title: 'فشل الزرعة',
        subtitle: 'إبلاغ الأدمن باسم المريض ورقم ملفه',
        icon: Icons.report_problem_outlined,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
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
                labelText: 'رقم ملف المريض',
                hintText: 'مطلوب',
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<ImplantItem?>(
              value: items.contains(_item) ? _item : null,
              decoration: const InputDecoration(
                labelText: 'الزرعة (اختياري)',
              ),
              items: [
                const DropdownMenuItem<ImplantItem?>(
                  value: null,
                  child: Text('غير محدد'),
                ),
                ...items.map(
                  (i) => DropdownMenuItem(
                    value: i,
                    child: Text(i.fullName),
                  ),
                ),
              ],
              onChanged: (v) => setState(() => _item = v),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _note,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'ملاحظات (اختياري)',
                hintText: 'تفاصيل إضافية عن حالة الفشل...',
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
              onPressed: _submit,
              icon: const Icon(Icons.warning_amber_rounded),
              label: const Text('إرسال بلاغ للأدمن'),
            ),
          ],
        ),
      ),
    );
  }
}
