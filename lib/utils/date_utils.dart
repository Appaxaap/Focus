import 'package:intl/intl.dart';

String formatDate(DateTime date) {
  return DateFormat.yMd().add_jm().format(date);
}

bool isSameDay(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}

bool isSameWeek(DateTime a, DateTime b) {
  final weekA = (a.day / 7).ceil();
  final weekB = (b.day / 7).ceil();
  return a.year == b.year && a.month == b.month && weekA == weekB;
}

bool isSameMonth(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month;
}