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
  StockCategory _category = kStockCategories.first;
  BrandCatalog? _brand;
  String? _type;
  String? _size;
  final _customCategory = TextEditingController();
  final _itemName = TextEditingController();
  final _itemSpec = TextEditingController();
  final _customSize = TextEditingController();
  final _qty = TextEditingController();
  final _lot = TextEditingController();
  final _threshold = TextEditingController(text: '3');
  DateTime? _expiry;

  @override
  void dispose() {
    _customCategory.dispose();
    _itemName.dispose();
    _itemSpec.dispose();
    _customSize.dispose();
    _qty.dispose();
    _lot.dispose();
    _threshold.dispose();
    super.dispose();
  }

  void _onCategoryChanged(StockCategory category) {
    setState(() {
      _category = category;
      _brand = null;
      _type = null;
      _size = null;
      _customCategory.clear();
      _itemName.clear();
      _itemSpec.clear();
      _customSize.clear();
    });
  }

  Future<void> _submit() async {
    late final String brand;
    late final String type;
    late final String size;

    if (_category.isImplants) {
      brand = _brand?.name ?? '';
      type = _type ?? '';
      size = _customSize.text.trim().isNotEmpty
          ? _customSize.text.trim()
          : (_size ?? '');
      if (brand.isEmpty || type.isEmpty || size.isEmpty) {
        _msg('يرجى اختيار الشركة والنوع والمقاس');
        return;
      }
    } else {
      if (_category.id == 'custom') {
        brand = _customCategory.text.trim();
        if (brand.isEmpty) {
          _msg('يرجى إدخال اسم الصنف');
          return;
        }
      } else {
        brand = _category.storageBrand!;
      }
      type = _itemName.text.trim();
      if (type.isEmpty) {
        _msg('يرجى إدخال اسم المادة');
        return;
      }
      size = _itemSpec.text.trim().isEmpty ? '—' : _itemSpec.text.trim();
    }

    final qty = int.tryParse(_qty.text);
    final thr = int.tryParse(_threshold.text) ?? 3;

    if (qty == null || qty < 1) {
      _msg('يرجى إدخال كمية صحيحة');
      return;
    }

    final repo = context.read<StockRepository>();
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
      if (!_category.isImplants) {
        _itemName.clear();
        _itemSpec.clear();
        if (_category.id == 'custom') _customCategory.clear();
      }
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

  Widget _categorySelector() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: kStockCategories.map((c) {
        final selected = _category.id == c.id;
        return ChoiceChip(
          label: Text(c.nameAr),
          selected: selected,
          selectedColor: AppColors.primary.withValues(alpha: 0.15),
          checkmarkColor: AppColors.primary,
          onSelected: (_) => _onCategoryChanged(c),
        );
      }).toList(),
    );
  }

  Widget _implantFields() {
    return Column(
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
          if (_type != null) ...[
            const SizedBox(height: 8),
            Text(
              'مقاسات $_type',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
            ),
            const SizedBox(height: 8),
            ..._brand!.sizesForType(_type!).map((s) {
              final sel = _size == s && _customSize.text.isEmpty;
              return Card(
                margin: const EdgeInsets.only(bottom: 6),
                elevation: 0,
                color: sel
                    ? AppColors.brandColor(_brand!.name).withValues(alpha: 0.12)
                    : const Color(0xFFF7FAFC),
                child: ListTile(
                  dense: true,
                  title: Text(s, style: const TextStyle(fontWeight: FontWeight.w600)),
                  trailing: sel
                      ? Icon(Icons.check_circle, color: AppColors.brandColor(_brand!.name))
                      : null,
                  onTap: () => setState(() {
                    _size = s;
                    _customSize.clear();
                  }),
                ),
              );
            }),
          ],
          const SizedBox(height: 8),
          TextField(
            controller: _customSize,
            decoration: const InputDecoration(
              labelText: 'مقاس مخصص (اختياري)',
            ),
            onChanged: (_) => setState(() => _size = null),
          ),
        ],
      ],
    );
  }

  Widget _generalItemFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_category.id == 'custom') ...[
          TextField(
            controller: _customCategory,
            decoration: const InputDecoration(
              labelText: 'اسم الصنف',
              hintText: 'مثال: مواد تعقيم، خيوط جراحية...',
            ),
          ),
          const SizedBox(height: 14),
        ] else ...[
          Align(
            alignment: Alignment.centerRight,
            child: BrandBadge(brand: _category.storageBrand!),
          ),
          const SizedBox(height: 14),
        ],
        TextField(
          controller: _itemName,
          decoration: InputDecoration(
            labelText: _category.id == 'custom' ? 'اسم المادة' : 'اسم ${_category.nameAr}',
            hintText: _category.id == 'accessories'
                ? 'مثال: Healing cap، Abutment...'
                : _category.id == 'tools'
                    ? 'مثال: مفك، قالب سيلikon...'
                    : 'مثال: قفازات، محلول تعقيم...',
          ),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _itemSpec,
          decoration: const InputDecoration(
            labelText: 'المواصفات (اختياري)',
            hintText: 'مقاس، لون، رقم الموديل...',
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: SectionCard(
        title: 'إضافة مخزون للمستودع',
        subtitle: _category.isImplants
            ? 'اختر الشركة ثم النوع والمقاس'
            : 'أدخل بيانات ${_category.nameAr}',
        icon: Icons.add_box_outlined,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'الصنف',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
            ),
            const SizedBox(height: 10),
            _categorySelector(),
            const SizedBox(height: 20),
            if (_category.isImplants) _implantFields() else _generalItemFields(),
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
