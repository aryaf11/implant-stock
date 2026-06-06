import 'package:flutter/material.dart';

import '../core/models/implant_item.dart';
import '../core/theme/app_colors.dart';
import 'brand_badge.dart';
import 'status_badge.dart';

class ImplantTile extends StatelessWidget {
  const ImplantTile({
    super.key,
    required this.item,
    this.trailing,
    this.subtitle,
    this.lowThreshold,
  });

  final ImplantItem item;
  final Widget? trailing;
  final String? subtitle;
  final int? lowThreshold;

  @override
  Widget build(BuildContext context) {
    final thr = lowThreshold ?? item.threshold;
    final isOut = item.qty == 0;
    final isLow = !isOut && item.qty <= thr;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border(
            right: BorderSide(
              color: isOut
                  ? AppColors.danger
                  : isLow
                      ? AppColors.warning
                      : AppColors.success,
              width: 4,
            ),
          ),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          title: Row(
            children: [
              BrandBadge(brand: item.brand, compact: true),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  item.size == '—' || item.size.isEmpty
                      ? item.type
                      : '${item.type} · ${item.size}',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          subtitle: subtitle != null
              ? Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    subtitle!,
                    style: const TextStyle(fontSize: 12, color: Color(0xFF718096)),
                  ),
                )
              : (item.lot.isNotEmpty || item.expiry.isNotEmpty)
                  ? Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        [
                          if (item.lot.isNotEmpty) 'لوت: ${item.lot}',
                          if (item.expiry.isNotEmpty) 'انتهاء: ${item.expiry}',
                        ].join(' · '),
                        style: const TextStyle(fontSize: 12),
                      ),
                    )
                  : null,
          trailing: trailing ??
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${item.qty}',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: AppColors.primary,
                    ),
                  ),
                  stockStatusBadge(item.qty, thr),
                ],
              ),
        ),
      ),
    );
  }
}
