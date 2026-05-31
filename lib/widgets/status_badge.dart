import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';

class StatusBadge extends StatelessWidget {
  const StatusBadge({
    super.key,
    required this.label,
    required this.color,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

Widget stockStatusBadge(int qty, int threshold) {
  if (qty == 0) {
    return const StatusBadge(label: 'نفذ', color: AppColors.danger);
  }
  if (qty <= threshold) {
    return const StatusBadge(label: 'منخفض', color: AppColors.warning);
  }
  return const StatusBadge(label: 'متاح', color: AppColors.success);
}

Widget requestStatusBadge(String status) {
  switch (status) {
    case 'approved':
      return const StatusBadge(label: 'موافقة', color: AppColors.success);
    case 'rejected':
      return const StatusBadge(label: 'مرفوض', color: AppColors.danger);
    default:
      return const StatusBadge(label: 'معلق', color: AppColors.warning);
  }
}
