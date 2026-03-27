/// Parse Vietnamese quick entry: "Ăn phở 50k", "Đổ xăng 100k sáng nay" -> amount + suggested category.
class ParsedQuickEntry {
  final double amount;
  final String? suggestedCategoryName;
  final String? note;

  ParsedQuickEntry({required this.amount, this.suggestedCategoryName, this.note});
}

class NaturalLanguageParser {
  /// Keywords map to category name (must match backend categories).
  static const Map<String, String> _categoryKeywords = {};

  /**
   * Phân tích một câu đơn (ví dụ: "Ăn phở 50k", "Xăng 100k").
   * Trả về đối tượng ParsedQuickEntry chứa số tiền và hạng mục gợi ý.
   */
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

  /**
   * Phân tích nhiều giao dịch trong một câu (ví dụ: "Cơm 30k, nước 20k").
   * Hỗ trợ tách bằng dấu phẩy, chấm phẩy hoặc dòng mới.
   */
  static List<ParsedQuickEntry> parseMultiple(String text) {
    if (text.trim().isEmpty) return const [];
    // 1) Prefer splitting by common delimiters/punctuation.
    final parts = text
        .split(RegExp(r'[,\n;]+'))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    final result = <ParsedQuickEntry>[];
    for (final p in parts) {
      final parsed = parse(p);
      if (parsed != null) result.add(parsed);
    }
    if (result.length >= 2) return result;

    // 2) Speech-to-text sometimes removes punctuation. Fallback: split by amount occurrences.
    // We slice each segment from previous amount end to current amount end,
    // which usually yields: "<note words> <amount>" per transaction.
    final amountMatches = RegExp(
      r'(\d+(?:[.,]\d+)?)\s*(?:k\b|tr(?:iệu)?\b)|(\d{1,3}(?:[.,]\d{3})*(?:[.,]\d+)?)\s*(?:đ|vnđ)?',
      caseSensitive: false,
    ).allMatches(text).toList();

    if (amountMatches.length < 2) return result; // keep whatever we got (0 or 1)

    final fallback = <ParsedQuickEntry>[];
    for (var i = 0; i < amountMatches.length; i++) {
      final start = i == 0 ? 0 : amountMatches[i - 1].end;
      final end = amountMatches[i].end;
      final segment = text.substring(start, end).trim();
      final parsed = parse(segment);
      if (parsed != null) fallback.add(parsed);
    }
    return fallback.isNotEmpty ? fallback : result;
  }

  /**
   * Hàm trích xuất con số từ văn bản thô.
   * Xử lý các định dạng "k" (nghìn), "tr" (triệu), hoặc con số thuần túy.
   * Có thuật toán thông minh để tự động nhân 1000 cho các số nhỏ (vd: "50" -> 50.000).
   */
  static double? _extractAmount(String text) {
    // Khớp định dạng 50k, 100k
    final kMatch = RegExp(r'(\d+(?:[.,]\d+)?)\s*k\b', caseSensitive: false).firstMatch(text);
    if (kMatch != null) {
      final num = double.tryParse(kMatch.group(1)!.replaceAll(',', '.'));
      return num != null ? num * 1000 : null;
    }
    // Khớp định dạng 1.5tr, 1tr
    final trMatch = RegExp(r'(\d+(?:[.,]\d+)?)\s*tr(?:iệu)?\b', caseSensitive: false).firstMatch(text);
    if (trMatch != null) {
      final num = double.tryParse(trMatch.group(1)!.replaceAll(',', '.'));
      return num != null ? num * 1000000 : null;
    }
    // Khớp số thông thường và đơn vị đ/vnđ
    final numMatch = RegExp(r'(\d{1,3}(?:[.,]\d{3})*(?:[.,]\d+)?)\s*(?:đ|vnđ)?', caseSensitive: false).firstMatch(text);
    if (numMatch != null) {
      final raw = numMatch.group(1)!.replaceAll(',', '').replaceAll('.', '');
      final value = double.tryParse(raw);
      if (value != null) {
        // Nếu nói "một trăm" thì hiểu là 100.000đ
        if (value < 1000) {
          return value * 1000;
        }
        return value;
      }
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
