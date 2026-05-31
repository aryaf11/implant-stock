import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/services/stock_repository.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/stock_provider.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/section_card.dart';
import '../../widgets/implant_tile.dart';
import '../../widgets/request_tile.dart';
import '../../widgets/stat_card.dart';

class AdminHomeScreen extends StatelessWidget {
  const AdminHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final stock = context.watch<StockProvider>();
    final s = stock.state;
    if (stock.isLoading || s == null) {
      return const LoadingView(message: 'جاري تحميل البيانات...');
    }

    final low = s.warehouse
        .where((i) => i.qty > 0 && i.qty <= i.threshold)
        .toList();

    return RefreshIndicator(
      onRefresh: stock.refresh,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'مرحباً، ${context.read<AuthProvider>().user?.displayName ?? "الأدمن"}',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          Text(
            'نظرة سريعة على المخزون والطلبات',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF718096),
                ),
          ),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.55,
            children: [
              StatCard(
                value: '${s.totalWarehouseQty}',
                label: 'المستودع',
                icon: Icons.warehouse_outlined,
              ),
              StatCard(
                value: '${s.totalCentersQty()}',
                label: 'الفروع',
                icon: Icons.local_hospital_outlined,
                colors: const [AppColors.info, Color(0xFF4299E1)],
              ),
              StatCard(
                value: '${low.length}',
                label: 'تنبيه منخفض',
                icon: Icons.warning_amber_rounded,
                colors: const [AppColors.warning, Color(0xFFED8936)],
              ),
              StatCard(
                value: '${s.pendingRequests.length}',
                label: 'طلبات صرف',
                icon: Icons.mark_email_unread_outlined,
                colors: const [AppColors.purple, Color(0xFF9F7AEA)],
              ),
            ],
          ),
          if (s.pendingReturnRequests.isNotEmpty) ...[
            const SizedBox(height: 12),
            StatCard(
              value: '${s.pendingReturnRequests.length}',
              label: 'طلبات إرجاع معلقة',
              icon: Icons.replay,
              colors: const [AppColors.info, Color(0xFF63B3ED)],
            ),
          ],
          if (low.isNotEmpty) ...[
            const SizedBox(height: 20),
            const SectionHeader(title: 'مخزون منخفض'),
            ...low.map((i) => ImplantTile(item: i)),
          ],
          const SizedBox(height: 20),
          const SectionHeader(title: 'طلبات الصرف المعلقة'),
          if (s.pendingRequests.isEmpty)
            const EmptyState(
              message: 'لا توجد طلبات معلقة',
              icon: Icons.inbox_outlined,
            )
          else
            ...s.pendingRequests.map(
              (r) => RequestTile(
                title: r.fullName,
                subtitle:
                    '${centerNameAr(r.centerId)} · ${r.qty} قطعة · ${r.date}',
                onApprove: () => _act(
                  context,
                  (repo, st) => repo.approveRequest(st, r.id),
                ),
                onReject: () => _act(
                  context,
                  (repo, st) => repo.rejectRequest(st, r.id),
                ),
              ),
            ),
          const SizedBox(height: 20),
          const SectionHeader(title: 'طلبات الاسترجاع المعلقة'),
          if (s.pendingReturnRequests.isEmpty)
            const EmptyState(
              message: 'لا توجد طلبات استرجاع',
              icon: Icons.replay_outlined,
            )
          else
            ...s.pendingReturnRequests.map(
              (r) => RequestTile(
                title: r.fullName,
                subtitle:
                    '${centerNameAr(r.centerId)} · ${r.qty} · ${r.reason}',
                isReturn: true,
                onApprove: () => _act(
                  context,
                  (repo, st) => repo.approveReturn(st, r.id),
                ),
                onReject: () => _act(
                  context,
                  (repo, st) => repo.rejectReturn(st, r.id),
                ),
              ),
            ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Future<void> _act(
    BuildContext context,
    Future<void> Function(StockRepository, StockState) fn,
  ) async {
    final provider = context.read<StockProvider>();
    final repo = StockRepository();
    final err = await provider.run((st) => fn(repo, st));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(err ?? 'تمت العملية بنجاح'),
        backgroundColor: err != null ? AppColors.danger : AppColors.success,
      ),
    );
  }
}
