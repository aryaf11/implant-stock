import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';

class BrandBadge extends StatelessWidget {
  const BrandBadge({super.key, required this.brand, this.compact = false});

  final String brand;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final color = AppColors.brandColor(brand);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 12,
        vertical: compact ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        brand.isEmpty ? '—' : brand,
        style: TextStyle(
          color: color,
          fontSize: compact ? 11 : 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class BrandSelectCard extends StatelessWidget {
  const BrandSelectCard({
    super.key,
    required this.name,
    required this.subtitle,
    required this.emoji,
    required this.selected,
    required this.onTap,
  });

  final String name;
  final String subtitle;
  final String emoji;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.brandGradients[name] ??
        [AppColors.primary, AppColors.primaryLight];

    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
            decoration: BoxDecoration(
              gradient: selected
                  ? LinearGradient(colors: colors)
                  : null,
              color: selected ? null : const Color(0xFFF7FAFC),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: selected ? colors.first : const Color(0xFFE2E8F0),
                width: selected ? 2 : 1,
              ),
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: colors.first.withValues(alpha: 0.35),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            child: Column(
              children: [
                Text(emoji, style: const TextStyle(fontSize: 28)),
                const SizedBox(height: 6),
                Text(
                  name,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                    color: selected ? Colors.white : const Color(0xFF1A202C),
                  ),
                  textAlign: TextAlign.center,
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 10,
                    color: selected
                        ? Colors.white.withValues(alpha: 0.85)
                        : const Color(0xFF718096),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
