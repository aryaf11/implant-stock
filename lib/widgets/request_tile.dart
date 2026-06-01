import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';

class RequestTile extends StatelessWidget {
  const RequestTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.onApprove,
    required this.onReject,
    this.isReturn = false,
    this.isBusy = false,
  });

  final String title;
  final String subtitle;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;
  final bool isReturn;
  final bool isBusy;

  @override
  Widget build(BuildContext context) {
    final accent = isReturn ? AppColors.info : AppColors.purple;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border(right: BorderSide(color: accent, width: 4)),
        ),
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                isReturn ? Icons.replay : Icons.send,
                color: accent,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF718096),
                    ),
                  ),
                ],
              ),
            ),
            if (isBusy)
              const Padding(
                padding: EdgeInsets.all(12),
                child: SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(strokeWidth: 2.5),
                ),
              )
            else
              Column(
                children: [
                  _ActionBtn(
                    icon: Icons.check_rounded,
                    color: AppColors.success,
                    onTap: onApprove,
                  ),
                  const SizedBox(height: 6),
                  _ActionBtn(
                    icon: Icons.close_rounded,
                    color: AppColors.danger,
                    onTap: onReject,
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  const _ActionBtn({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(icon, color: color, size: 22),
        ),
      ),
    );
  }
}
