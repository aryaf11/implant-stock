import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/stock_provider.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/stock_data_gate.dart';
import '../../widgets/section_card.dart';
import '../../widgets/implant_tile.dart';
import '../../widgets/request_tile.dart';
import '../../widgets/stat_card.dart';

class AdminHomeScreen extends StatelessWidget {
  const AdminHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return StockDataGate(
      builder: (context, s) {
        final stock = context.watch<StockProvider>();
        final low = s.warehouse
            .where((i) => i.qty > 0 && i.qty <= i.threshold)
            .toList();

        return ListView(
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
                  key: ValueKey('req_${r.id}'),
                  title: r.fullName,
                  subtitle:
                      '${centerNameAr(r.centerId)} · ${r.qty} قطعة · ${r.date}',
                  isBusy: stock.isBusy(r.id),
                  onApprove: stock.isBusy(r.id)
                      ? null
                      : () => _onApprove(context, r.id, false),
                  onReject: stock.isBusy(r.id)
                      ? null
                      : () => _onReject(context, r.id, false),
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
                  key: ValueKey('ret_${r.id}'),
                  title: r.fullName,
                  subtitle:
                      '${centerNameAr(r.centerId)} · ${r.qty} · ${r.reason}',
                  isReturn: true,
                  isBusy: stock.isBusy('ret_${r.id}'),
                  onApprove: stock.isBusy('ret_${r.id}')
                      ? null
                      : () => _onApprove(context, r.id, true),
                  onReject: stock.isBusy('ret_${r.id}')
                      ? null
                      : () => _onReject(context, r.id, true),
                ),
              ),
            const SizedBox(height: 24),
          ],
        );
      },
    );
  }

  Future<void> _onApprove(
    BuildContext context,
    String id,
    bool isReturn,
  ) async {
    final stock = context.read<StockProvider>();
    final err = isReturn
        ? await stock.approveReturn(id)
        : await stock.approveRequest(id);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(err ?? 'تمت الموافقة والصرف'),
        backgroundColor: err != null ? AppColors.danger : AppColors.success,
      ),
    );
  }

  Future<void> _onReject(
    BuildContext context,
    String id,
    bool isReturn,
  ) async {
    final stock = context.read<StockProvider>();
    final err = isReturn
        ? await stock.rejectReturn(id)
        : await stock.rejectRequest(id);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(err ?? 'تم الرفض'),
        backgroundColor: err != null ? AppColors.danger : null,
      ),
    );
  }
}
