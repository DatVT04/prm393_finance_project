import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';
import 'package:easy_localization/easy_localization.dart';

/// Utility class for formatting currency values
class CurrencyFormatter {
  /// Format number based on current locale
  static String format(BuildContext context, num amount) {
    final locale = context.locale.toString();
    
    // For Vietnamese, we use specific formatting to match "đ" symbol if preferred by user
    // Otherwise simpleCurrency handles most cases
    if (locale.startsWith('vi')) {
      return NumberFormat.currency(
        locale: 'vi_VN',
        symbol: 'đ',
        decimalDigits: 0,
      ).format(amount);
    }
    
    // Default to simple currency formatting for other locales
    // This will pick $ for en, ¥ for ja, etc.
    final formatter = NumberFormat.simpleCurrency(
      locale: locale,
    );
    
    return formatter.format(amount);
  }

  /// Parse currency string to number
  /// This is still useful for input fields
  static double? parse(String currencyString) {
    final cleaned = currencyString.replaceAll(RegExp(r'[^\d]'), '');
    return double.tryParse(cleaned);
  }

  /// Get a generic number formatter for the current locale
  static NumberFormat getNumberFormatter(BuildContext context) {
    return NumberFormat('#,###', context.locale.toString());
  }

  /// Get currency symbol based on current locale
  static String getSymbol(BuildContext context) {
    final locale = context.locale.toString();
    if (locale.startsWith('vi')) return 'đ';
    
    final formatter = NumberFormat.simpleCurrency(locale: locale);
    return formatter.currencySymbol;
  }
}
