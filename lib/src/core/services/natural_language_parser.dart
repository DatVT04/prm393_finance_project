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

  /// Parse multiple entries in one sentence, e.g.
  /// "Ăn cơm 100k, uống sữa 50k; đi mua sắm 500k"
  /// -> 3 ParsedQuickEntry.
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
      final raw = numMatch.group(1)!.replaceAll(',', '').replaceAll('.', '');
      final value = double.tryParse(raw);
      if (value != null) {
        // Heuristic for Vietnamese speech: nếu không có đơn vị k/tr mà chỉ nói
        // "100", "200", "500" thì thường là "100k", "200k", "500k".
        // Nếu số < 1000 và không có dấu phân cách nghìn -> coi như "nghìn".
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
