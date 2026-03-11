/// From OCR raw text, extract total amount, store name, date for receipt.
class ReceiptOcrResult {
  final double? totalAmount;
  final String? storeName;
  final DateTime? date;
  final String rawText;

  ReceiptOcrResult({
    this.totalAmount,
    this.storeName,
    this.date,
    required this.rawText,
  });
}

class ReceiptOcrParser {
  /// Heuristics: total often appears as "Tổng", "TOTAL", "Thanh toán", amount with VND/đ.
  static ReceiptOcrResult parse(String rawText) {
    if (rawText.trim().isEmpty) return ReceiptOcrResult(rawText: rawText);

    final lines = rawText.split(RegExp(r'\n')).map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
    double? total;
    String? store;
    DateTime? date;

    // Store: often first non-empty line or line with "Cửa hàng", "Shop"
    for (final line in lines) {
      if (line.length > 2 && line.length < 80 && !_looksLikeAmount(line) && store == null) {
        if (!RegExp(r'^\d+').hasMatch(line)) store = line;
        break;
      }
    }

    // Total: line containing "tổng", "total", "thanh toán", "cộng" then number
    for (var i = 0; i < lines.length; i++) {
      final lower = lines[i].toLowerCase();
      if (lower.contains('tổng') || lower.contains('total') || lower.contains('thanh toán') ||
          lower.contains('cộng') || lower.contains('grand')) {
        total = _extractAmountFromLine(lines[i]);
        if (total == null && i + 1 < lines.length) total = _extractAmountFromLine(lines[i + 1]);
        if (total != null) break;
      }
    }
    if (total == null) {
      for (final line in lines.reversed) {
        total = _extractAmountFromLine(line);
        if (total != null && total > 0) break;
      }
    }

    // Date: dd/mm/yyyy or dd-mm-yyyy
    final dateReg = RegExp(r'(\d{1,2})[/\-](\d{1,2})[/\-](\d{2,4})');
    for (final line in lines) {
      final m = dateReg.firstMatch(line);
      if (m != null) {
        final d = int.tryParse(m.group(1)!);
        final mo = int.tryParse(m.group(2)!);
        var y = int.tryParse(m.group(3)!);
        if (y != null && y < 100) y += 2000;
        if (d != null && mo != null && y != null && d >= 1 && d <= 31 && mo >= 1 && mo <= 12) {
          date = DateTime(y, mo, d);
          break;
        }
      }
    }

    return ReceiptOcrResult(
      totalAmount: total,
      storeName: store,
      date: date,
      rawText: rawText,
    );
  }

  static bool _looksLikeAmount(String s) {
    return RegExp(r'\d{3,}').hasMatch(s) && (s.contains('đ') || s.contains('vnd') || s.contains('.'));
  }

  static double? _extractAmountFromLine(String line) {
    // Remove spaces between digits: "1 500 000" -> 1500000
    final normalized = line.replaceAll(RegExp(r'\s'), '');
    final match = RegExp(r'(\d{1,3}(?:\.\d{3})*(?:,\d+)?)\s*[đvnd]?', caseSensitive: false).firstMatch(normalized);
    if (match != null) {
      final numStr = match.group(1)!.replaceAll('.', '').replaceAll(',', '.');
      return double.tryParse(numStr);
    }
    final simple = RegExp(r'(\d+)').allMatches(line);
    if (simple.isNotEmpty) {
      final last = simple.last.group(1);
      return double.tryParse(last ?? '');
    }
    return null;
  }
}
