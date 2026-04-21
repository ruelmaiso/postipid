import 'package:intl/intl.dart';

final NumberFormat _pesoFormat = NumberFormat.currency(
  locale: 'en_PH',
  symbol: 'PHP ',
  decimalDigits: 2,
);

String toPeso(num value) => _pesoFormat.format(value);

String toDateLabel(int value) => DateFormat('MMM dd, yyyy').format(
      DateTime.fromMillisecondsSinceEpoch(value),
    );

String toMonthDayLabel(int value) => DateFormat('MMM d').format(
      DateTime.fromMillisecondsSinceEpoch(value),
    );

String toShortDayLabel(int value) => DateFormat('EEE').format(
      DateTime.fromMillisecondsSinceEpoch(value),
    );

String toMonthYearLabel(int value) => DateFormat('MMMM yyyy').format(
      DateTime.fromMillisecondsSinceEpoch(value),
    );

String toDateTimeLabel(int value) => DateFormat('MMM dd, yyyy hh:mm a').format(
      DateTime.fromMillisecondsSinceEpoch(value),
    );

String toEnglishDayDateLabel(int value) =>
    DateFormat('EEEE, MMMM dd, yyyy').format(DateTime.fromMillisecondsSinceEpoch(value));

int startOfDay(int value) {
  final date = DateTime.fromMillisecondsSinceEpoch(value);
  return DateTime(date.year, date.month, date.day).millisecondsSinceEpoch;
}

int plusDays(int value, int days) {
  final date = DateTime.fromMillisecondsSinceEpoch(value);
  return DateTime(date.year, date.month, date.day + days).millisecondsSinceEpoch;
}
