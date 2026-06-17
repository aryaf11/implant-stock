import 'package:flutter/material.dart';

import '../core/models/implant_item.dart';
import '../core/theme/app_colors.dart';
import '../core/utils/inventory_grouping.dart';
import 'app_shell.dart';
import 'brand_badge.dart';

/// مخزون مرتب: كل شركة في بطاقة مع أنواعها ومقاساتها.
class BrandInventoryView extends StatelessWidget {
  const BrandInventoryView({
    super.key,
    required this.items,
    this.onEditQty,
    this.emptyMessage = 'لا يوجد مخزون',
  });

  final Iterable<ImplantItem> items;
  final void Function(ImplantItem item)? onEditQty;
  final String emptyMessage;

  @override
  Widget build(BuildContext context) {
    final groups = groupInventoryByBrand(items);
    if (groups.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Text(
          emptyMessage,
          style: const TextStyle(color: Color(0xFF718096)),
        ),
      );
    }

    return Column(
      children: groups
          .map(
            (g) => AppContentCard(
              title: g.brand,
              trailing: Text(
                '${g.totalQty} قطعة',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: AppColors.brandColor(g.brand),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  BrandBadge(brand: g.brand),
                  const SizedBox(height: 12),
                  for (var ti = 0; ti < g.types.length; ti++) ...[
                    if (ti > 0) const Divider(height: 20),
                    _TypeSection(
                      group: g.types[ti],
                      onEditQty: onEditQty,
                      brandColor: AppColors.brandColor(g.brand),
                    ),
                  ],
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}

class _TypeSection extends StatelessWidget {
  const _TypeSection({
    required this.group,
    required this.brandColor,
    this.onEditQty,
  });

  final TypeInventoryGroup group;
  final Color brandColor;
  final void Function(ImplantItem item)? onEditQty;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                group.type,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
            ),
            Text(
              '${group.totalQty}',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: brandColor,
                fontSize: 13,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        for (final item in group.items) _SizeRow(
          item: item,
          brandColor: brandColor,
          onEditQty: onEditQty,
        ),
      ],
    );
  }
}

class _SizeRow extends StatelessWidget {
  const _SizeRow({
    required this.item,
    required this.brandColor,
    this.onEditQty,
  });

  final ImplantItem item;
  final Color brandColor;
  final void Function(ImplantItem item)? onEditQty;

  @override
  Widget build(BuildContext context) {
    final sizeLabel =
        item.size.trim().isEmpty || item.size == '—' ? 'بدون مقاس' : item.size;
    final lotInfo = [
      if (item.lot.isNotEmpty) 'لوت ${item.lot}',
      if (item.expiry.isNotEmpty) 'انتهاء ${item.expiry}',
    ].join(' · ');

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF7FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border(
          right: BorderSide(color: brandColor, width: 3),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  sizeLabel,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                if (lotInfo.isNotEmpty)
                  Text(
                    lotInfo,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF718096),
                    ),
                  ),
              ],
            ),
          ),
          if (onEditQty != null)
            IconButton(
              tooltip: 'تعديل الكمية',
              icon: const Icon(Icons.edit_outlined, size: 18),
              onPressed: () => onEditQty!(item),
              visualDensity: VisualDensity.compact,
            ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: brandColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${item.qty}',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 16,
                color: brandColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
