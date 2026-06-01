import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

String todayAr() => DateFormat('yyyy/MM/dd', 'ar').format(DateTime.now());

String nowTimeAr() => DateFormat('HH:mm', 'ar').format(DateTime.now());

String formatDateAr(DateTime d) => DateFormat('yyyy/MM/dd', 'ar').format(d);

String formatDateLongAr(DateTime d) =>
    DateFormat('EEEE d MMMM yyyy', 'ar').format(d);

DateTime? parseDateAr(String s) {
  if (s.trim().isEmpty) return null;
  try {
    return DateFormat('yyyy/MM/dd').parse(s);
  } catch (_) {
    return null;
  }
}

String formatRangeAr(DateTimeRange range) =>
    '${formatDateAr(range.start)} — ${formatDateAr(range.end)}';
