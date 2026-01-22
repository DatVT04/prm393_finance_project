// lib/src/shared/utils/date_formatter.dart
import 'package:intl/intl.dart';

/// Utility class for formatting dates
class DateFormatter {
  /// Format date to Vietnamese format
  /// Example: DateTime(2024, 1, 15) -> "15/01/2024"
  static String format(DateTime date) {
    return "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}";
  }

  /// Format date with time
  /// Example: DateTime(2024, 1, 15, 14, 30) -> "15/01/2024 14:30"
  static String formatWithTime(DateTime date) {
    return "${format(date)} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}";
  }

  /// Format date using intl package for localization
  static String formatLocalized(
    DateTime date, {
    String pattern = 'dd/MM/yyyy',
  }) {
    return DateFormat(pattern, 'vi_VN').format(date);
  }
}
