import 'package:flutter/material.dart';

import '../constants/app_constants.dart';
import '../models/movement_log.dart';
import '../services/stock_repository.dart';
import '../utils/date_utils.dart';

enum ReportPeriod { week, month, custom }

class DispatchLine {
  const DispatchLine({
    required this.date,
    required this.centerId,
    required this.type,
    required this.qty,
    required this.detail,
    required this.note,
  });

  final DateTime date;
  final String centerId;
  final String type;
  final int qty;
  final String detail;
  final String note;
}

class BranchDispatchSummary {
  const BranchDispatchSummary({
    required this.centerId,
    required this.totalQty,
    required this.lineCount,
    required this.byDate,
  });

  final String centerId;
  final int totalQty;
  final int lineCount;
  final Map<DateTime, List<DispatchLine>> byDate;
}

class ReportService {
  static const dispatchOps = {'صرف'};

  static DateTimeRange periodRange(ReportPeriod period, {DateTimeRange? custom}) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    switch (period) {
      case ReportPeriod.week:
        return DateTimeRange(
          start: today.subtract(const Duration(days: 6)),
          end: today,
        );
      case ReportPeriod.month:
        final start = DateTime(today.year, today.month, 1);
        return DateTimeRange(start: start, end: today);
      case ReportPeriod.custom:
        return custom ?? DateTimeRange(start: today, end: today);
    }
  }

  static List<DispatchLine> extractDispatches(
    StockState state, {
    required DateTimeRange range,
    String? centerId,
  }) {
    final from = DateTime(range.start.year, range.start.month, range.start.day);
    final to = DateTime(
      range.end.year,
      range.end.month,
      range.end.day,
      23,
      59,
      59,
    );

    final lines = <DispatchLine>[];
    for (final log in state.movementLog) {
      if (!dispatchOps.contains(log.op)) continue;
      final d = parseDateAr(log.date);
      if (d == null) continue;
      final day = DateTime(d.year, d.month, d.day);
      if (day.isBefore(from) || day.isAfter(to)) continue;

      final cid = _resolveCenterId(log);
      if (centerId != null && centerId.isNotEmpty && cid != centerId) {
        continue;
      }

      lines.add(DispatchLine(
        date: day,
        centerId: cid,
        type: log.type,
        qty: log.qty,
        detail: log.detail,
        note: log.note,
      ));
    }
    lines.sort((a, b) => b.date.compareTo(a.date));
    return lines;
  }

  static String _resolveCenterId(MovementLog log) {
    if (log.center.isNotEmpty && log.center != 'المستودع') {
      if (kCenters.any((c) => c.id == log.center)) return log.center;
    }
    for (final c in kCenters) {
      if (log.detail.contains(c.nameAr)) return c.id;
    }
    return log.center.isEmpty ? 'unknown' : log.center;
  }

  static List<BranchDispatchSummary> summarizeByBranch(List<DispatchLine> lines) {
    final map = <String, List<DispatchLine>>{};
    for (final l in lines) {
      map.putIfAbsent(l.centerId, () => []).add(l);
    }

    final summaries = <BranchDispatchSummary>[];
    for (final c in kCenters) {
      final branchLines = map[c.id] ?? [];
      if (branchLines.isEmpty) continue;

      final byDate = <DateTime, List<DispatchLine>>{};
      var total = 0;
      for (final l in branchLines) {
        total += l.qty;
        byDate.putIfAbsent(l.date, () => []).add(l);
      }
      final sortedDates = byDate.keys.toList()..sort((a, b) => b.compareTo(a));
      final sortedByDate = {
        for (final d in sortedDates) d: byDate[d]!,
      };

      summaries.add(BranchDispatchSummary(
        centerId: c.id,
        totalQty: total,
        lineCount: branchLines.length,
        byDate: sortedByDate,
      ));
    }

    final unknown = map['unknown'];
    if (unknown != null && unknown.isNotEmpty) {
      final byDate = <DateTime, List<DispatchLine>>{};
      var total = 0;
      for (final l in unknown) {
        total += l.qty;
        byDate.putIfAbsent(l.date, () => []).add(l);
      }
      summaries.add(BranchDispatchSummary(
        centerId: 'unknown',
        totalQty: total,
        lineCount: unknown.length,
        byDate: byDate,
      ));
    }

    return summaries;
  }
}
