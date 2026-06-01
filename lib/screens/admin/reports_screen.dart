import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import '../../core/services/report_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/date_utils.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/section_card.dart';
import '../../widgets/stat_card.dart';
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

  @override
  Widget build(BuildContext context) {
    return StockDataGate(
      builder: (context, state) {
        final range = ReportService.periodRange(
          _period,
          custom: _customRange,
        );
        final lines = ReportService.extractDispatches(
          state,
          range: range,
          centerId: _centerFilter,
        );
        final summaries = ReportService.summarizeByBranch(lines);
        final grandTotal = lines.fold<int>(0, (s, l) => s + l.qty);

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const SectionHeader(title: 'تقارير الصرف'),
            Text(
              formatRangeAr(range),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF718096),
                  ),
            ),
            const SizedBox(height: 16),
            SegmentedButton<ReportPeriod>(
              segments: const [
                ButtonSegment(
                  value: ReportPeriod.week,
                  label: Text('أسبوعي'),
                  icon: Icon(Icons.date_range, size: 18),
                ),
                ButtonSegment(
                  value: ReportPeriod.month,
                  label: Text('شهري'),
                  icon: Icon(Icons.calendar_month, size: 18),
                ),
                ButtonSegment(
                  value: ReportPeriod.custom,
                  label: Text('مخصص'),
                  icon: Icon(Icons.tune, size: 18),
                ),
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
            const SizedBox(height: 12),
            DropdownButtonFormField<String?>(
              value: _centerFilter,
              decoration: const InputDecoration(
                labelText: 'الفرع',
                prefixIcon: Icon(Icons.filter_list),
              ),
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
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.6,
              children: [
                StatCard(
                  value: '$grandTotal',
                  label: 'إجمالي القطع المصروفة',
                  icon: Icons.inventory_2_outlined,
                ),
                StatCard(
                  value: '${lines.length}',
                  label: 'عمليات صرف',
                  icon: Icons.receipt_long_outlined,
                  colors: const [AppColors.purple, Color(0xFF9F7AEA)],
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (summaries.isEmpty)
              const EmptyState(
                message: 'لا توجد عمليات صرف في هذه الفترة',
                icon: Icons.analytics_outlined,
              )
            else
              ...summaries.map((b) => _BranchReportCard(summary: b)),
            const SizedBox(height: 24),
          ],
        );
      },
    );
  }
}

class _BranchReportCard extends StatelessWidget {
  const _BranchReportCard({required this.summary});

  final BranchDispatchSummary summary;

  String get _branchTitle {
    if (summary.centerId == 'unknown') return 'غير محدد';
    return centerNameAr(summary.centerId);
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.primary.withValues(alpha: 0.12),
          child: const Icon(Icons.local_hospital, color: AppColors.primary),
        ),
        title: Text(
          _branchTitle,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        subtitle: Text(
          '${summary.lineCount} عملية · ${summary.totalQty} قطعة',
        ),
        children: [
          for (final entry in summary.byDate.entries) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Row(
                children: [
                  const Icon(Icons.event, size: 18, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Text(
                    formatDateLongAr(entry.key),
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${entry.value.fold<int>(0, (s, l) => s + l.qty)} قطعة',
                    style: const TextStyle(
                      color: Color(0xFF718096),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            ...entry.value.map(
              (l) => ListTile(
                dense: true,
                title: Text(l.type),
                subtitle: Text(
                  l.detail.isNotEmpty ? l.detail : l.note,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: Text(
                  '${l.qty}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
            const Divider(height: 1),
          ],
        ],
      ),
    );
  }
}
