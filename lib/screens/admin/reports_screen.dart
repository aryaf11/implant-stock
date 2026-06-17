import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import '../../core/services/report_service.dart';
import '../../core/services/stock_repository.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/date_utils.dart';
import '../../widgets/app_shell.dart';
import '../../widgets/brand_inventory_view.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/stock_data_gate.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  ReportPeriod _period = ReportPeriod.month;
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

  int _countInRange(
    StockState state,
    DateTimeRange range,
    bool Function(String op) match,
  ) {
    final from = DateTime(range.start.year, range.start.month, range.start.day);
    final to = DateTime(
      range.end.year,
      range.end.month,
      range.end.day,
      23,
      59,
      59,
    );
    return state.movementLog.where((l) {
      if (!match(l.op)) return false;
      final d = parseDateAr(l.date);
      if (d == null) return _period == ReportPeriod.all;
      final day = DateTime(d.year, d.month, d.day);
      return !day.isBefore(from) && !day.isAfter(to);
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
          includeAllDates: _period == ReportPeriod.all,
        );
        final summaries = ReportService.summarizeByBranch(lines);
        final pending = state.pendingRequests.length +
            state.pendingReturnRequests.length;
        final approved = _countInRange(
          state,
          range,
          (op) => op.contains('صرف') || op.contains('موافقة'),
        );
        final rejected = _countInRange(state, range, (op) => op.contains('رفض'));

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          children: [
            SegmentedButton<ReportPeriod>(
              segments: const [
                ButtonSegment(value: ReportPeriod.week, label: Text('أسبوع')),
                ButtonSegment(value: ReportPeriod.month, label: Text('شهر')),
                ButtonSegment(value: ReportPeriod.all, label: Text('الكل')),
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
            const Text(
              'مخزون المستودع حسب الشركة',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 15,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 8),
            BrandInventoryView(
              items: state.warehouse,
              emptyMessage: 'لا يوجد مخزون في المستودع',
            ),
            AppTriMetricCard(
              title: 'ملخص الطلبات · ${formatRangeAr(range)}',
              pending: pending,
              approved: approved,
              rejected: rejected,
            ),
            if (state.pendingNurseReports.isNotEmpty)
              AppContentCard(
                title: 'تقارير الممرضة (${state.pendingNurseReports.length})',
                child: Column(
                  children: state.pendingNurseReports.map((r) {
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(
                        r.isFailure
                            ? Icons.report_problem
                            : Icons.medical_services,
                        color:
                            r.isFailure ? AppColors.danger : AppColors.info,
                      ),
                      title: Text(r.title,
                          style: const TextStyle(fontWeight: FontWeight.w700)),
                      subtitle: Text(
                        '${centerNameAr(r.centerId)} · ${r.nurseName}\n${r.subtitle}',
                      ),
                      isThreeLine: true,
                    );
                  }).toList(),
                ),
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
                message: 'لا توجد عمليات صرف أو استرجاع في هذه الفترة',
                subtitle: 'جرّب «الكل» أو «شهر» لعرض سجل أوسع',
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
      trailing: Text(
        '${summary.lineCount} عملية',
        style: const TextStyle(
          fontWeight: FontWeight.w700,
          color: Color(0xFF718096),
          fontSize: 12,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'صرف ${summary.dispatchQty} · استرجاع ${summary.returnQty}',
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
