import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import '../../core/services/report_service.dart';
import '../../core/services/stock_repository.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/date_utils.dart';
import '../../widgets/app_shell.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/stock_data_gate.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  ReportPeriod _period = ReportPeriod.week;
  String? _centerFilter;
  DateTimeRange? _customRange;

  Future<void> _pickCustomRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 2),
      lastDate: now,
      initialDateRange: _customRange ??
          DateTimeRange(
            start: now.subtract(const Duration(days: 30)),
            end: now,
          ),
      locale: const Locale('ar'),
    );
    if (picked != null) {
      setState(() {
        _customRange = picked;
        _period = ReportPeriod.custom;
      });
    }
  }

  int _approvedCount(StockState state, DateTimeRange range) {
    return state.movementLog.where((l) {
      if (!l.op.contains('صرف') && !l.op.contains('موافقة')) return false;
      final d = parseDateAr(l.date);
      if (d == null) return true;
      return !d.isBefore(range.start) && !d.isAfter(range.end);
    }).length;
  }

  @override
  Widget build(BuildContext context) {
    return StockDataGate(
      builder: (context, state) {
        final range = ReportService.periodRange(
          _period,
          custom: _customRange,
        );
        final lines = ReportService.extractMovements(
          state,
          range: range,
          centerId: _centerFilter,
        );
        final summaries = ReportService.summarizeByBranch(lines);
        final byCategory = inventoryByCategory(state.warehouse);
        final pending = state.pendingRequests.length +
            state.pendingReturnRequests.length;
        final approved = _approvedCount(state, range);
        final rejected = state.movementLog
            .where((l) => l.op.contains('رفض'))
            .length;

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          children: [
            SegmentedButton<ReportPeriod>(
              segments: const [
                ButtonSegment(value: ReportPeriod.week, label: Text('أسبوعي')),
                ButtonSegment(value: ReportPeriod.month, label: Text('شهري')),
                ButtonSegment(value: ReportPeriod.custom, label: Text('مخصص')),
              ],
              selected: {_period},
              onSelectionChanged: (s) {
                final p = s.first;
                setState(() => _period = p);
                if (p == ReportPeriod.custom) _pickCustomRange();
              },
            ),
            if (_period == ReportPeriod.custom) ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: _pickCustomRange,
                  icon: const Icon(Icons.edit_calendar),
                  label: Text(
                    _customRange != null
                        ? formatRangeAr(_customRange!)
                        : 'اختر الفترة',
                  ),
                ),
              ),
            ],
            const SizedBox(height: 8),
            DropdownButtonFormField<String?>(
              initialValue: _centerFilter,
              decoration: const InputDecoration(labelText: 'الفرع'),
              items: [
                const DropdownMenuItem(value: null, child: Text('كل الفروع')),
                ...kCenters.map(
                  (c) => DropdownMenuItem(
                    value: c.id,
                    child: Text(c.nameAr),
                  ),
                ),
              ],
              onChanged: (v) => setState(() => _centerFilter = v),
            ),
            const SizedBox(height: 16),
            AppContentCard(
              title: 'المخزون حسب التصنيف',
              child: byCategory.isEmpty
                  ? const Text(
                      'لا يوجد مخزون',
                      style: TextStyle(color: Color(0xFF718096)),
                    )
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
              approved: approved,
              rejected: rejected,
            ),
            Text(
              'تفاصيل الصرف والاسترجاع · ${formatRangeAr(range)}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF718096),
                  ),
            ),
            const SizedBox(height: 12),
            if (summaries.isEmpty)
              const EmptyState(
                message: 'لا توجد عمليات في هذه الفترة',
                icon: Icons.analytics_outlined,
              )
            else
              ...summaries.map((b) => _BranchReportCard(summary: b)),
          ],
        );
      },
    );
  }
}

class _BranchReportCard extends StatelessWidget {
  const _BranchReportCard({required this.summary});

  final BranchReportSummary summary;

  String get _branchTitle {
    if (summary.centerId == 'unknown') return 'غير محدد';
    return centerNameAr(summary.centerId);
  }

  @override
  Widget build(BuildContext context) {
    return AppContentCard(
      title: _branchTitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '${summary.lineCount} عملية · صرف ${summary.dispatchQty} · استرجاع ${summary.returnQty}',
            style: const TextStyle(color: Color(0xFF718096), fontSize: 13),
          ),
          const SizedBox(height: 8),
          for (final entry in summary.byDate.entries) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Text(
                formatDateLongAr(entry.key),
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ),
            for (final l in entry.value)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Icon(
                      l.isReturn ? Icons.replay : Icons.send,
                      size: 18,
                      color: l.isReturn ? AppColors.info : AppColors.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${l.type} · ${l.qty}',
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }
}
