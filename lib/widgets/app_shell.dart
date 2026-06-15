import 'package:flutter/material.dart';

import '../core/models/implant_item.dart';
import '../core/theme/app_colors.dart';

class AppNavItem {
  const AppNavItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
}

/// هيكل موحّد: شريط علوي أخضر + عنوان + محتوى + شريط سفلي.
class AppShell extends StatelessWidget {
  const AppShell({
    super.key,
    required this.title,
    required this.body,
    required this.navItems,
    required this.selectedIndex,
    required this.onNavSelect,
    this.drawer,
    this.actions,
    this.showPageTitle = true,
  });

  final String title;
  final Widget body;
  final List<AppNavItem> navItems;
  final int selectedIndex;
  final ValueChanged<int> onNavSelect;
  final Widget? drawer;
  final List<Widget>? actions;
  final bool showPageTitle;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.pageBg,
        drawer: drawer,
        appBar: AppBar(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          title: Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 18,
            ),
          ),
          leading: drawer != null
              ? Builder(
                  builder: (ctx) => IconButton(
                    icon: const Icon(Icons.menu_rounded),
                    onPressed: () => Scaffold.of(ctx).openDrawer(),
                  ),
                )
              : null,
          actions: actions,
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (showPageTitle)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFF1A202C),
                      ),
                ),
              ),
            Expanded(child: body),
          ],
        ),
        bottomNavigationBar: _AppBottomNav(
          items: navItems,
          selectedIndex: selectedIndex,
          onSelect: onNavSelect,
        ),
      ),
    );
  }
}

class _AppBottomNav extends StatelessWidget {
  const _AppBottomNav({
    required this.items,
    required this.selectedIndex,
    required this.onSelect,
  });

  final List<AppNavItem> items;
  final int selectedIndex;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, -2),
          ),
        ],
      ),
        child: SafeArea(
        top: false,
        child: SizedBox(
          height: 72,
          child: Row(
            children: [
              for (var i = 0; i < items.length; i++) ...[
                if (i > 0) const SizedBox(width: 2),
                Expanded(
                  child: InkWell(
                    onTap: () => onSelect(i),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          i == selectedIndex
                              ? items[i].selectedIcon
                              : items[i].icon,
                          size: 26,
                          color: i == selectedIndex && selectedIndex >= 0
                              ? AppColors.primary
                              : const Color(0xFF9CA3AF),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          items[i].label,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight:
                                i == selectedIndex && selectedIndex >= 0
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                            color: i == selectedIndex && selectedIndex >= 0
                                ? AppColors.primary
                                : const Color(0xFF9CA3AF),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// بطاقة بيضاء بنفس أسلوب التقارير.
class AppContentCard extends StatelessWidget {
  const AppContentCard({
    super.key,
    required this.title,
    required this.child,
    this.padding = const EdgeInsets.all(18),
  });

  final String title;
  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
            ),
            const SizedBox(height: 14),
            child,
          ],
        ),
      ),
    );
  }
}

/// صف: اسم الصنف + شارة عدد خضراء.
class AppCountRow extends StatelessWidget {
  const AppCountRow({
    super.key,
    required this.label,
    required this.count,
    this.showDivider = true,
  });

  final String label;
  final int count;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: Color(0xFF2D3748),
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$count',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (showDivider) const Divider(height: 1, color: Color(0xFFE8EDF2)),
      ],
    );
  }
}

/// ملخص ثلاثي: معلق / موافق / مرفوض.
class AppTriMetricCard extends StatelessWidget {
  const AppTriMetricCard({
    super.key,
    required this.title,
    required this.pending,
    required this.approved,
    required this.rejected,
    this.pendingLabel = 'معلق',
    this.approvedLabel = 'موافق عليه',
    this.rejectedLabel = 'مرفوض',
  });

  final String title;
  final int pending;
  final int approved;
  final int rejected;
  final String pendingLabel;
  final String approvedLabel;
  final String rejectedLabel;

  @override
  Widget build(BuildContext context) {
    return AppContentCard(
      title: title,
      child: Row(
        children: [
          _metric(pending, pendingLabel, AppColors.warning),
          _metric(approved, approvedLabel, AppColors.success),
          _metric(rejected, rejectedLabel, AppColors.danger),
        ],
      ),
    );
  }

  Widget _metric(int value, String label, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(
            '$value',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: color,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF718096),
            ),
          ),
        ],
      ),
    );
  }
}

/// تجميع المخزون حسب الشركة/الصنف.
Map<String, int> inventoryByCategory(Iterable<ImplantItem> items) {
  final map = <String, int>{};
  for (final item in items) {
    map[item.brand] = (map[item.brand] ?? 0) + item.qty;
  }
  final sorted = map.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  return Map.fromEntries(sorted);
}
