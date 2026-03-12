// lib/src/shared/utils/currency_formatter.dart
/// Utility class for formatting currency values
class CurrencyFormatter {
  /// Format number to Vietnamese currency format
  /// Example: 25000000 -> "25.000.000 đ"
  static String format(num amount) {
    return "${amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (match) => '.')} đ";
  }

  /// Parse currency string to number
  /// Example: "25.000.000 đ" -> 25000000
  static double? parse(String currencyString) {
    final cleaned = currencyString.replaceAll(RegExp(r'[^\d]'), '');
    return double.tryParse(cleaned);
  }
}
