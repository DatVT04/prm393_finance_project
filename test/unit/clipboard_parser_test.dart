import 'package:flutter_test/flutter_test.dart';
import 'package:prm393_finance_project/src/core/services/clipboard_parser.dart';

void main() {
  group('ClipboardParser.parse', () {
    test('returns null for empty, whitespace, or text without number', () {
      expect(ClipboardParser.parse(''), isNull);
      expect(ClipboardParser.parse('   '), isNull);
      expect(ClipboardParser.parse('Tin nhắn không có số'), isNull);
    });

    test('extracts amount from common SMS bank formats', () {
      expect(ClipboardParser.parse('GD -200.000 VND')!.amount, 200000.0);
      expect(ClipboardParser.parse('Thanh toan 50.000d')!.amount, 50000.0);
      expect(ClipboardParser.parse('So du: 50,000')!.amount, 50000.0);
    });

    test('handles large Vietnamese amount "1.500.000"', () {
      expect(ClipboardParser.parse('GD -1.500.000 VND')!.amount, 1500000.0);
    });

    test('amount is always positive regardless of sign in SMS', () {
      expect(ClipboardParser.parse('GD -150.000 VND')!.amount, greaterThan(0));
    });

    test('rawText is preserved; truncated to 150 chars when too long', () {
      const text = 'GD -200.000 VND Ăn phở';
      expect(ClipboardParser.parse(text)!.rawText, text);

      final longText = 'GD -200.000 VND ' + 'x' * 200;
      final r = ClipboardParser.parse(longText)!;
      expect(r.rawText.length, lessThanOrEqualTo(150));
      expect(r.rawText.endsWith('...'), isTrue);
    });

    test('suggests correct category from SMS text keywords', () {
      expect(
        ClipboardParser.parse('GD -10.000 VND phi gửi xe')!.suggestedCategoryName,
        'Gửi xe',
      );
      expect(
        ClipboardParser.parse('GD -100.000 VND do xăng')!.suggestedCategoryName,
        'Xăng xe',
      );
      expect(
        ClipboardParser.parse('GD -50.000 VND ăn phở')!.suggestedCategoryName,
        'Ăn uống',
      );
      expect(
        ClipboardParser.parse('GD -200.000 VND mua đồ')!.suggestedCategoryName,
        'Mua sắm',
      );
    });

    test('returns null category for unrecognized merchant', () {
      expect(ClipboardParser.parse('GD -200.000 VND')!.suggestedCategoryName, isNull);
    });
  });
}
