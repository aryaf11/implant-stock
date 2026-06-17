import 'package:flutter/material.dart';

import '../constants/app_constants.dart';
import '../models/movement_log.dart';
import '../services/stock_repository.dart';
import '../utils/date_utils.dart';

enum ReportPeriod { week, month, all, custom }

class ReportLine {
  const ReportLine({
    required this.date,
    required this.centerId,
    required this.op,
    required this.type,
    required this.qty,
    required this.detail,
    required this.note,
  });

  final DateTime date;
  final String centerId;
  final String op;
  final String type;
  final int qty;
  final String detail;
  final String note;

  bool get isReturn => op == 'استرجاع';
}

class BranchReportSummary {
  const BranchReportSummary({
    required this.centerId,
    required this.dispatchQty,
    required this.returnQty,
    required this.lineCount,
    required this.byDate,
  });

  final String centerId;
  final int dispatchQty;
  final int returnQty;
  final int lineCount;
  final Map<DateTime, List<ReportLine>> byDate;

  int get totalQty => dispatchQty + returnQty;
}

class ReportService {
  static const reportOps = {'صرف', 'استرجاع'};

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
      case ReportPeriod.all:
        return DateTimeRange(
          start: DateTime(2020, 1, 1),
          end: today,
        );
      case ReportPeriod.custom:
        return custom ?? DateTimeRange(start: today, end: today);
    }
  }

  static List<ReportLine> extractMovements(
    StockState state, {
    required DateTimeRange range,
    String? centerId,
    bool includeAllDates = false,
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

    final lines = <ReportLine>[];
    for (final log in state.movementLog) {
      if (!reportOps.contains(log.op)) continue;
      var d = parseDateAr(log.date);
      if (d == null) {
        if (!includeAllDates) continue;
        d = from;
      }
      final day = DateTime(d.year, d.month, d.day);
      if (!includeAllDates && (day.isBefore(from) || day.isAfter(to))) continue;

      final cid = _resolveCenterId(log);
      if (centerId != null && centerId.isNotEmpty && cid != centerId) {
        continue;
      }

      lines.add(ReportLine(
        date: day,
        centerId: cid,
        op: log.op,
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
      final id = resolveCenterId(log.center);
      if (kCenters.any((c) => c.id == id)) return id;
    }
    for (final c in kCenters) {
      if (log.detail.contains(c.nameAr)) return c.id;
    }
    if (log.detail.contains('د. صالح') || log.detail.contains('dr.saleh')) {
      return 'drsaleh';
    }
    return log.center.isEmpty ? 'unknown' : resolveCenterId(log.center);
  }

  static List<BranchReportSummary> summarizeByBranch(List<ReportLine> lines) {
    final map = <String, List<ReportLine>>{};
    for (final l in lines) {
      map.putIfAbsent(l.centerId, () => []).add(l);
    }

    final summaries = <BranchReportSummary>[];
    for (final c in kCenters) {
      final branchLines = map[c.id] ?? [];
      if (branchLines.isEmpty) continue;

      final byDate = <DateTime, List<ReportLine>>{};
      var dispatchQty = 0;
      var returnQty = 0;
      for (final l in branchLines) {
        if (l.isReturn) {
          returnQty += l.qty;
        } else {
          dispatchQty += l.qty;
        }
        byDate.putIfAbsent(l.date, () => []).add(l);
      }
      final sortedDates = byDate.keys.toList()..sort((a, b) => b.compareTo(a));
      final sortedByDate = {
        for (final d in sortedDates) d: byDate[d]!,
      };

      summaries.add(BranchReportSummary(
        centerId: c.id,
        dispatchQty: dispatchQty,
        returnQty: returnQty,
        lineCount: branchLines.length,
        byDate: sortedByDate,
      ));
    }

    final unknown = map['unknown'];
    if (unknown != null && unknown.isNotEmpty) {
      final byDate = <DateTime, List<ReportLine>>{};
      var dispatchQty = 0;
      var returnQty = 0;
      for (final l in unknown) {
        if (l.isReturn) {
          returnQty += l.qty;
        } else {
          dispatchQty += l.qty;
        }
        byDate.putIfAbsent(l.date, () => []).add(l);
      }
      summaries.add(BranchReportSummary(
        centerId: 'unknown',
        dispatchQty: dispatchQty,
        returnQty: returnQty,
        lineCount: unknown.length,
        byDate: byDate,
      ));
    }

    return summaries;
  }
}
