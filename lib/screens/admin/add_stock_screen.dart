import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/services/stock_repository.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/stock_provider.dart';
import '../../widgets/brand_badge.dart';
import '../../widgets/section_card.dart';

class AddStockScreen extends StatefulWidget {
  const AddStockScreen({super.key});

  @override
  State<AddStockScreen> createState() => _AddStockScreenState();
}

class _AddStockScreenState extends State<AddStockScreen> {
  BrandCatalog? _brand;
  String? _type;
  String? _size;
  final _customSize = TextEditingController();
  final _qty = TextEditingController();
  final _lot = TextEditingController();
  final _threshold = TextEditingController(text: '3');
  DateTime? _expiry;

  @override
  void dispose() {
    _customSize.dispose();
    _qty.dispose();
    _lot.dispose();
    _threshold.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final brand = _brand?.name;
    final type = _type;
    final size = _customSize.text.trim().isNotEmpty ? _customSize.text.trim() : _size;
    final qty = int.tryParse(_qty.text);
    final thr = int.tryParse(_threshold.text) ?? 3;

    if (brand == null || type == null || size == null || size.isEmpty) {
      _msg('يرجى اختيار الشركة والنوع والمقاس');
      return;
    }
    if (qty == null || qty < 1) {
      _msg('يرجى إدخال كمية صحيحة');
      return;
    }

    final repo = StockRepository();
    final err = await context.read<StockProvider>().run(
          (s) => repo.addToWarehouse(
            s,
            brand: brand,
            type: type,
            size: size,
            qty: qty,
            lot: _lot.text.trim(),
            expiry: _expiry != null
                ? '${_expiry!.year}-${_expiry!.month.toString().padLeft(2, '0')}-${_expiry!.day.toString().padLeft(2, '0')}'
                : '',
            threshold: thr,
          ),
        );
    if (err != null) {
      _msg(err);
    } else {
      _msg('تمت الإضافة', ok: true);
      _qty.clear();
      _lot.clear();
    }
  }

  void _msg(String t, {bool ok = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(t), backgroundColor: ok ? Colors.green : null),
    );
  }

  static const _brandMeta = {
    'Straumann': ('🔵', 'سويسرية'),
    'BioHorizons': ('🟢', 'أمريكية'),
    'Ora': ('🟡', 'أورا'),
  };

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: SectionCard(
        title: 'إضافة مخزون للمستودع',
        subtitle: 'اختر الشركة ثم النوع والمقاس',
        icon: Icons.add_box_outlined,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                for (final b in kBrands) ...[
                  BrandSelectCard(
                    name: b.name,
                    subtitle: _brandMeta[b.name]?.$2 ?? '',
                    emoji: _brandMeta[b.name]?.$1 ?? '⚪',
                    selected: _brand?.name == b.name,
                    onTap: () => setState(() {
                      _brand = b;
                      _type = null;
                      _size = null;
                    }),
                  ),
                  if (b != kBrands.last) const SizedBox(width: 8),
                ],
              ],
            ),
            if (_brand != null) ...[
              const SizedBox(height: 20),
              DropdownButtonFormField<String>(
                initialValue: _type,
                decoration: const InputDecoration(labelText: 'نوع الزرعة'),
                items: _brand!.types
                    .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                    .toList(),
                onChanged: (v) => setState(() {
                  _type = v;
                  _size = null;
                }),
              ),
              const SizedBox(height: 14),
              Align(
                alignment: Alignment.centerRight,
                child: BrandBadge(brand: _brand!.name),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _brand!.sizes.map((s) {
                  final sel = _size == s;
                  return FilterChip(
                    label: Text(s),
                    selected: sel,
                    selectedColor: AppColors.brandColor(_brand!.name)
                        .withValues(alpha: 0.2),
                    checkmarkColor: AppColors.brandColor(_brand!.name),
                    onSelected: (_) => setState(() {
                      _size = s;
                      _customSize.clear();
                    }),
                  );
                }).toList(),
              ),
              TextField(
                controller: _customSize,
                decoration: const InputDecoration(
                  labelText: 'مقاس مخصص (اختياري)',
                ),
                onChanged: (_) => setState(() => _size = null),
              ),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _qty,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'الكمية'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _lot,
                    decoration: const InputDecoration(labelText: 'رقم اللوت'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      final d = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate:
                            DateTime.now().add(const Duration(days: 3650)),
                      );
                      if (d != null) setState(() => _expiry = d);
                    },
                    borderRadius: BorderRadius.circular(14),
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'تاريخ الانتهاء',
                        suffixIcon: Icon(Icons.calendar_today_outlined),
                      ),
                      child: Text(
                        _expiry == null
                            ? 'اختر التاريخ'
                            : '${_expiry!.year}/${_expiry!.month}/${_expiry!.day}',
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _threshold,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'حد التنبيه'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _submit,
              icon: const Icon(Icons.check_rounded),
              label: const Text('إضافة للمستودع'),
            ),
          ],
        ),
      ),
    );
  }
}
