import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/stock_provider.dart';
import '../../widgets/app_shell.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/stock_data_gate.dart';
import '../../widgets/implant_tile.dart';
import '../../widgets/request_tile.dart';

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
        final byCategory = inventoryByCategory(s.warehouse);
        final pending = s.pendingRequests.length +
            s.pendingReturnRequests.length +
            s.pendingNurseReports.length;

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          children: [
            Text(
              'مرحباً، ${context.read<AuthProvider>().user?.displayName ?? "الأدمن"}',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: const Color(0xFF718096),
                  ),
            ),
            const SizedBox(height: 12),
            AppContentCard(
              title: 'المخزون حسب التصنيف',
              child: byCategory.isEmpty
                  ? const Text('لا يوجد مخزون',
                      style: TextStyle(color: Color(0xFF718096)))
                  : Column(
                      children: [
                        for (final e in byCategory.entries)
                          AppCountRow(
                            label: e.key,
                            count: e.value,
                            showDivider: e.key != byCategory.keys.last,
                          ),
                      ],
                    ),
            ),
            AppTriMetricCard(
              title: 'ملخص الطلبات',
              pending: pending,
              approved: s.movementLog
                  .where((l) => l.op.contains('صرف'))
                  .length,
              rejected: s.movementLog
                  .where((l) => l.op.contains('رفض'))
                  .length,
            ),
            if (s.pendingNurseReports.isNotEmpty) ...[
              AppContentCard(
                title: 'تقارير الممرضة (${s.pendingNurseReports.length})',
                child: Column(
                  children: s.pendingNurseReports.map((r) {
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      elevation: 0,
                      color: const Color(0xFFF7FAFC),
                      child: ListTile(
                        leading: Icon(
                          r.isFailure
                              ? Icons.report_problem
                              : Icons.medical_services,
                          color: r.isFailure
                              ? AppColors.danger
                              : AppColors.info,
                        ),
                        title: Text(r.title,
                            style: const TextStyle(fontWeight: FontWeight.w700)),
                        subtitle: Text(
                          '${centerNameAr(r.centerId)} · ${r.nurseName}\n${r.subtitle}',
                        ),
                        isThreeLine: true,
                        trailing: stock.isBusy('nurse_${r.id}')
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : IconButton(
                                icon: const Icon(Icons.check_circle_outline),
                                color: AppColors.success,
                                onPressed: () =>
                                    _onDismissNurse(context, r.id),
                              ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
            if (low.isNotEmpty) ...[
              AppContentCard(
                title: 'مخزون منخفض',
                child: Column(
                  children: low.map((i) => ImplantTile(item: i)).toList(),
                ),
              ),
            ],
            AppContentCard(
              title: 'طلبات الصرف المعلقة',
              child: s.pendingRequests.isEmpty
                  ? const EmptyState(
                      message: 'لا توجد طلبات معلقة',
                      icon: Icons.inbox_outlined,
                    )
                  : Column(
                      children: s.pendingRequests
                          .map(
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
                          )
                          .toList(),
                    ),
            ),
            AppContentCard(
              title: 'طلبات الاسترجاع المعلقة',
              child: s.pendingReturnRequests.isEmpty
                  ? const EmptyState(
                      message: 'لا توجد طلبات استرجاع',
                      icon: Icons.replay_outlined,
                    )
                  : Column(
                      children: s.pendingReturnRequests
                          .map(
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
                          )
                          .toList(),
                    ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _onDismissNurse(BuildContext context, String id) async {
    final stock = context.read<StockProvider>();
    final err = await stock.dismissNurseReport(id);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(err ?? 'تم الاطلاع على التقرير'),
        backgroundColor: err != null ? AppColors.danger : AppColors.success,
      ),
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
