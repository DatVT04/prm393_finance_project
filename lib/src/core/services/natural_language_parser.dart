/// Parse Vietnamese quick entry: "Ăn phở 50k", "Đổ xăng 100k sáng nay" -> amount + suggested category.
class ParsedQuickEntry {
  final double amount;
  final String? suggestedCategoryName;
  final String? note;

  ParsedQuickEntry({required this.amount, this.suggestedCategoryName, this.note});
}

class NaturalLanguageParser {
  /// Keywords map to category name (must match backend categories).
  static const Map<String, String> _categoryKeywords = {
    'ăn': 'Ăn uống',
    'phở': 'Ăn uống',
    'cơm': 'Ăn uống',
    'bún': 'Ăn uống',
    'trà sữa': 'Ăn uống',
    'cafe': 'Ăn uống',
    'cà phê': 'Ăn uống',
    'uống': 'Ăn uống',
    'xăng': 'Xăng xe',
    'đổ xăng': 'Xăng xe',
    'gas': 'Xăng xe',
    'mua': 'Mua sắm',
    'sắm': 'Mua sắm',
    'siêu thị': 'Mua sắm',
    'giải trí': 'Giải trí',
    'phim': 'Giải trí',
    'game': 'Giải trí',
    'y tế': 'Y tế',
    'thuốc': 'Y tế',
    'bệnh viện': 'Y tế',
    'học': 'Giáo dục',
    'sách': 'Giáo dục',
    'gửi xe': 'Gửi xe',
    'parking': 'Gửi xe',
  };

  /// Parse text like "Ăn phở 50k" or "Đổ xăng 100k sáng nay". Returns null if no amount found.
  static ParsedQuickEntry? parse(String text) {
    if (text.trim().isEmpty) return null;

    final normalized = text.toLowerCase().trim();
    double? amount = _extractAmount(normalized);
    if (amount == null || amount <= 0) return null;

    String? category = _suggestCategory(normalized);
    String note = text.trim();
    if (note.length > 200) note = '${note.substring(0, 197)}...';

    return ParsedQuickEntry(
      amount: amount,
      suggestedCategoryName: category,
      note: note,
    );
  }

  static double? _extractAmount(String text) {
    // Match 50k, 50.000, 50000, 1.5tr, 1tr, 100k, 100.000đ
    final kMatch = RegExp(r'(\d+(?:[.,]\d+)?)\s*k\b', caseSensitive: false).firstMatch(text);
    if (kMatch != null) {
      final num = double.tryParse(kMatch.group(1)!.replaceAll(',', '.'));
      return num != null ? num * 1000 : null;
    }
    final trMatch = RegExp(r'(\d+(?:[.,]\d+)?)\s*tr(?:iệu)?\b', caseSensitive: false).firstMatch(text);
    if (trMatch != null) {
      final num = double.tryParse(trMatch.group(1)!.replaceAll(',', '.'));
      return num != null ? num * 1000000 : null;
    }
    final numMatch = RegExp(r'(\d{1,3}(?:[.,]\d{3})*(?:[.,]\d+)?)\s*(?:đ|vnđ)?', caseSensitive: false).firstMatch(text);
    if (numMatch != null) {
      final raw = numMatch.group(1)!.replaceAll(',', '');
      return double.tryParse(raw);
    }
    return null;
  }

  static String? _suggestCategory(String text) {
    for (final entry in _categoryKeywords.entries) {
      if (text.contains(entry.key)) return entry.value;
    }
    return null;
  }
}
