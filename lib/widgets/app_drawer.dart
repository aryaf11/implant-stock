import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import 'app_logo.dart';

class NavDestination {
  const NavDestination({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    this.subtitle,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final String? subtitle;
}

class AppDrawer extends StatelessWidget {
  const AppDrawer({
    super.key,
    required this.title,
    required this.subtitle,
    required this.userName,
    required this.destinations,
    required this.selectedIndex,
    required this.onSelect,
    required this.onLogout,
    this.avatarIcon = Icons.warehouse_outlined,
  });

  final String title;
  final String subtitle;
  final String userName;
  final IconData avatarIcon;
  final List<NavDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onSelect;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 48, 20, 24),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: AppColors.headerGradient,
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const AppLogo(size: 72, showShadow: false),
                const SizedBox(height: 14),
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    userName,
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: destinations.length,
              itemBuilder: (_, i) {
                final d = destinations[i];
                final selected = i == selectedIndex;
                return ListTile(
                  leading: Icon(
                    selected ? d.selectedIcon : d.icon,
                    color: selected ? AppColors.primary : const Color(0xFF718096),
                  ),
                  title: Text(
                    d.label,
                    style: TextStyle(
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                      color: selected ? AppColors.primary : const Color(0xFF2D3748),
                    ),
                  ),
                  subtitle: d.subtitle != null
                      ? Text(d.subtitle!, style: const TextStyle(fontSize: 11))
                      : null,
                  selected: selected,
                  selectedTileColor: AppColors.primary.withValues(alpha: 0.08),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  onTap: () {
                    onSelect(i);
                    Navigator.pop(context);
                  },
                );
              },
            ),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.logout, color: AppColors.danger),
            title: const Text('تسجيل الخروج', style: TextStyle(color: AppColors.danger)),
            onTap: onLogout,
          ),
          const SizedBox(height: 4),
          Center(
            child: Text(
              'الإصدار 1.2.1 · مزامنة سحابية',
              style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 11,
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
