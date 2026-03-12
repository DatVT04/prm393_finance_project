/// Parse clipboard text from bank/SMS (e.g. "GD -200.000 VND ...") to suggest amount and category.
class ClipboardSuggestion {
  final double amount;
  final String? suggestedCategoryName;
  final String rawText;

  ClipboardSuggestion({
    required this.amount,
    this.suggestedCategoryName,
    required this.rawText,
  });
}

class ClipboardParser {
  /// Detect amount from patterns like "-200.000", "200.000 VND", "So du: -50000"
  static ClipboardSuggestion? parse(String text) {
    if (text.trim().isEmpty) return null;

    final normalized = text.replaceAll(RegExp(r'\s+'), ' ');
    double? amount = _extractAmount(normalized);
    if (amount == null || amount <= 0) return null;

    // Often clipboard is debit (negative)
    if (!normalized.contains('-') && !normalized.toLowerCase().contains('trừ')) {
      amount = -amount;
    }
    amount = amount.abs();

    String? category;
    if (normalized.toLowerCase().contains('gửi xe') || normalized.toLowerCase().contains('parking')) {
      category = 'Gửi xe';
    } else if (normalized.toLowerCase().contains('xăng') || normalized.toLowerCase().contains('gas')) {
      category = 'Xăng xe';
    } else if (normalized.toLowerCase().contains('ăn') || normalized.toLowerCase().contains('food')) {
      category = 'Ăn uống';
    } else if (normalized.toLowerCase().contains('mua') || normalized.toLowerCase().contains('siêu thị')) {
      category = 'Mua sắm';
    }

    return ClipboardSuggestion(
      amount: amount,
      suggestedCategoryName: category,
      rawText: text.trim().length > 150 ? '${text.trim().substring(0, 147)}...' : text.trim(),
    );
  }

  static double? _extractAmount(String text) {
    // -200.000 or 200.000 VND or 50,000
    final m = RegExp(r'[-]?\s*(\d{1,3}(?:[.,]\d{3})*(?:[.,]\d+)?)\s*(?:đ|vnd|vnđ)?', caseSensitive: false).firstMatch(text);
    if (m != null) {
      final raw = m.group(1)!.replaceAll(',', '').replaceAll('.', '');
      return double.tryParse(raw);
    }
    return null;
  }
}
