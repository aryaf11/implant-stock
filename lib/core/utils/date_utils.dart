import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// تاريخ للتخزين — أرقام إنجليزية لضمان قراءة التقارير لاحقاً.
String todayAr() => DateFormat('yyyy/MM/dd').format(DateTime.now());

String nowTimeAr() => DateFormat('HH:mm').format(DateTime.now());

String formatDateAr(DateTime d) => DateFormat('yyyy/MM/dd').format(d);

String formatDateLongAr(DateTime d) =>
    DateFormat('EEEE d MMMM yyyy', 'ar').format(d);

String _normalizeDigits(String s) {
  const arabic = '٠١٢٣٤٥٦٧٨٩';
  const persian = '۰۱۲۳۴۵۶۷۸۹';
  final buf = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    final c = s[i];
    final ai = arabic.indexOf(c);
    if (ai >= 0) {
      buf.write(ai);
      continue;
    }
    final pi = persian.indexOf(c);
    if (pi >= 0) {
      buf.write(pi);
      continue;
    }
    buf.write(c);
  }
  return buf.toString();
}

DateTime? parseDateAr(String s) {
  final raw = _normalizeDigits(s.trim());
  if (raw.isEmpty) return null;

  const patterns = ['yyyy/MM/dd', 'yyyy-MM-dd', 'dd/MM/yyyy', 'dd-MM-yyyy'];
  for (final p in patterns) {
    try {
      return DateFormat(p).parse(raw);
    } catch (_) {}
  }
  return null;
}

String formatRangeAr(DateTimeRange range) =>
    '${formatDateAr(range.start)} — ${formatDateAr(range.end)}';
