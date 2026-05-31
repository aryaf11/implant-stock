import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../providers/stock_provider.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/status_badge.dart';

class LogScreen extends StatelessWidget {
  const LogScreen({super.key});

  Color _opColor(String op) => switch (op) {
        'إضافة' => AppColors.success,
        'صرف' => AppColors.warning,
        'استخدام' => AppColors.danger,
        'استرجاع' => AppColors.info,
        'طلب' => AppColors.purple,
        _ => const Color(0xFF718096),
      };

  @override
  Widget build(BuildContext context) {
    final logs = context.watch<StockProvider>().state?.movementLog ?? [];
    if (logs.isEmpty) {
      return const EmptyState(
        message: 'لا توجد حركات مسجّلة',
        icon: Icons.history,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: logs.length,
      itemBuilder: (_, i) {
        final l = logs[i];
        final color = _opColor(l.op);
        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          child: ListTile(
            contentPadding: const EdgeInsets.all(14),
            leading: CircleAvatar(
              backgroundColor: color.withValues(alpha: 0.12),
              child: Icon(Icons.swap_horiz, color: color, size: 22),
            ),
            title: Text(l.type, style: const TextStyle(fontWeight: FontWeight.w700)),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l.detail, style: const TextStyle(fontSize: 12)),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      StatusBadge(label: l.op, color: color),
                      const SizedBox(width: 8),
                      Text('الكمية: ${l.qty}', style: const TextStyle(fontSize: 12)),
                    ],
                  ),
                ],
              ),
            ),
            trailing: Text(
              l.date,
              style: const TextStyle(fontSize: 11, color: Color(0xFF718096)),
            ),
          ),
        );
      },
    );
  }
}
