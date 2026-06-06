import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/models/app_user.dart';
import '../../core/models/stored_user.dart';
import '../../core/services/user_repository.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/section_card.dart';

class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  List<StoredUser> _users = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final repo = context.read<UserRepository>();
    await repo.ensureDefaults();
    final list = await repo.loadAll();
    if (mounted) {
      setState(() {
        _users = list;
        _loading = false;
      });
    }
  }

  Future<void> _showUserDialog({StoredUser? existing}) async {
    final isEdit = existing != null;
    final usernameCtrl =
        TextEditingController(text: existing?.username ?? '');
    final passCtrl = TextEditingController();
    final nameCtrl =
        TextEditingController(text: existing?.displayName ?? '');
    var role = existing?.role ?? UserRole.supervisor;
    var centerId = existing?.centerId ?? kCenters.first.id;
    var obscure = true;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlg) => AlertDialog(
          title: Text(isEdit ? 'تعديل مستخدم' : 'إضافة مستخدم'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: usernameCtrl,
                  enabled: !isEdit,
                  decoration: const InputDecoration(
                    labelText: 'اسم المستخدم',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: passCtrl,
                  obscureText: obscure,
                  decoration: InputDecoration(
                    labelText: isEdit
                        ? 'كلمة مرور جديدة (اتركها فارغة بدون تغيير)'
                        : 'كلمة المرور',
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscure
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                      onPressed: () => setDlg(() => obscure = !obscure),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'الاسم المعروض'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<UserRole>(
                  value: role,
                  decoration: const InputDecoration(labelText: 'الصلاحية'),
                  items: const [
                    DropdownMenuItem(
                      value: UserRole.admin,
                      child: Text('أدمن المستودع'),
                    ),
                    DropdownMenuItem(
                      value: UserRole.supervisor,
                      child: Text('مشرف فرع'),
                    ),
                  ],
                  onChanged: (v) => setDlg(() => role = v ?? role),
                ),
                if (role == UserRole.supervisor) ...[
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: centerId,
                    decoration: const InputDecoration(labelText: 'الفرع'),
                    items: kCenters
                        .map(
                          (c) => DropdownMenuItem(
                            value: c.id,
                            child: Text(c.nameAr),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setDlg(() => centerId = v ?? centerId),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('إلغاء'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(isEdit ? 'حفظ' : 'إضافة'),
            ),
          ],
        ),
      ),
    );

    if (ok != true || !mounted) return;

    final repo = context.read<UserRepository>();
    try {
      if (isEdit) {
        await repo.updateUser(
          existing.username,
          password: passCtrl.text.trim().isEmpty ? null : passCtrl.text,
          displayName: nameCtrl.text.trim(),
          role: role,
          centerId: role == UserRole.supervisor ? centerId : null,
          clearCenterId: role == UserRole.admin,
        );
      } else {
        await repo.addUser(
          StoredUser(
            username: usernameCtrl.text.trim(),
            password: passCtrl.text,
            displayName: nameCtrl.text.trim().isEmpty
                ? usernameCtrl.text.trim()
                : nameCtrl.text.trim(),
            role: role,
            centerId: role == UserRole.supervisor ? centerId : null,
          ),
        );
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم الحفظ'),
            backgroundColor: AppColors.success,
          ),
        );
        await _load();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  Future<void> _deleteUser(StoredUser user) async {
    final me = context.read<AuthProvider>().user?.username;
    if (user.username == me) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لا يمكن حذف حسابك الحالي')),
      );
      return;
    }
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف المستخدم؟'),
        content: Text('حذف "${user.username}" نهائياً؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      await context.read<UserRepository>().deleteUser(user.username);
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم الحذف')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          FilledButton.icon(
            onPressed: () => _showUserDialog(),
            icon: const Icon(Icons.person_add),
            label: const Text('إضافة مستخدم جديد'),
          ),
          const SizedBox(height: 16),
          const SectionHeader(title: 'إدارة المستخدمين'),
          Text(
            'إضافة وتعديل أسماء الدخول وكلمات المرور',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: const Color(0xFF718096),
                ),
          ),
          const SizedBox(height: 12),
          ..._users.map(
            (u) => Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: u.isAdmin
                      ? AppColors.primary.withValues(alpha: 0.15)
                      : AppColors.info.withValues(alpha: 0.15),
                  child: Icon(
                    u.isAdmin ? Icons.admin_panel_settings : Icons.person,
                    color: u.isAdmin ? AppColors.primary : AppColors.info,
                  ),
                ),
                title: Text(
                  u.displayName,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: Text(
                  '${u.username} · ${u.isAdmin ? "أدمن" : centerNameAr(u.centerId ?? "")}',
                ),
                trailing: PopupMenuButton<String>(
                  onSelected: (v) {
                    if (v == 'edit') {
                      _showUserDialog(existing: u);
                    } else if (v == 'delete') {
                      _deleteUser(u);
                    }
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(value: 'edit', child: Text('تعديل')),
                    const PopupMenuItem(value: 'delete', child: Text('حذف')),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
