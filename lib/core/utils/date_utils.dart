import 'package:intl/intl.dart';

String todayAr() => DateFormat('yyyy/MM/dd', 'ar').format(DateTime.now());

String nowTimeAr() =>
    DateFormat('HH:mm', 'ar').format(DateTime.now());
