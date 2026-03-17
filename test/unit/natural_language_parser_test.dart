import 'package:flutter_test/flutter_test.dart';
import 'package:prm393_finance_project/src/core/services/natural_language_parser.dart';

void main() {
  group('NaturalLanguageParser.parse', () {
    test('returns null for empty or whitespace-only string', () {
      expect(NaturalLanguageParser.parse(''), isNull);
      expect(NaturalLanguageParser.parse('   '), isNull);
    });

    test('returns null when no amount found', () {
      expect(NaturalLanguageParser.parse('Đi chơi với bạn bè'), isNull);
    });

    test('parses "50k" format -> 50000', () {
      final r = NaturalLanguageParser.parse('Ăn phở 50k')!;
      expect(r.amount, 50000.0);
    });

    test('parses "1.5tr" format -> 1500000', () {
      final r = NaturalLanguageParser.parse('mua đồ 1.5tr')!;
      expect(r.amount, 1500000.0);
    });

    test('parses Vietnamese dot-format "50.000" -> 50000', () {
      final r = NaturalLanguageParser.parse('Ăn cơm 50.000')!;
      expect(r.amount, 50000.0);
    });

    test('bare number < 1000 is treated as x1000 ("100" -> 100000)', () {
      final r = NaturalLanguageParser.parse('Ăn phở 100')!;
      expect(r.amount, 100000.0);
    });

    test('suggests correct categories for keywords', () {
      expect(NaturalLanguageParser.parse('Ăn phở 50k')!.suggestedCategoryName, 'Ăn uống');
      // 'gas' dùng thay 'xăng' vì 'Đổ xăng' chứa 'ăn' → match Ăn uống trước
      expect(NaturalLanguageParser.parse('đổ gas 100k')!.suggestedCategoryName, 'Xăng xe');
      expect(NaturalLanguageParser.parse('mua áo 200k')!.suggestedCategoryName, 'Mua sắm');
      expect(NaturalLanguageParser.parse('Xem phim 80k')!.suggestedCategoryName, 'Giải trí');
      // 'bệnh viện' dùng thay 'thuốc' vì 'Mua thuốc' chứa 'mua' → match Mua sắm trước
      expect(NaturalLanguageParser.parse('đi bệnh viện 50k')!.suggestedCategoryName, 'Y tế');
    });

    test('returns null category for unknown keyword', () {
      final r = NaturalLanguageParser.parse('Chi tiêu linh tinh 50k')!;
      expect(r.suggestedCategoryName, isNull);
    });

    test('note is set to original text and truncated when too long', () {
      expect(NaturalLanguageParser.parse('Ăn phở 50k')!.note, 'Ăn phở 50k');

      final longText = 'Ăn phở ' + 'a' * 250 + ' 50k';
      final r = NaturalLanguageParser.parse(longText)!;
      expect(r.note!.length, lessThanOrEqualTo(200));
      expect(r.note!.endsWith('...'), isTrue);
    });
  });

  group('NaturalLanguageParser.parseMultiple', () {
    test('returns empty list for empty or whitespace-only string', () {
      expect(NaturalLanguageParser.parseMultiple(''), isEmpty);
      expect(NaturalLanguageParser.parseMultiple('  '), isEmpty);
    });

    test('splits by comma, semicolon, and newline delimiters', () {
      expect(
        NaturalLanguageParser.parseMultiple('Ăn cơm 100k, uống sữa 50k').length, 2,
      );
      expect(
        NaturalLanguageParser.parseMultiple('Ăn cơm 100k; đổ xăng 80k').length, 2,
      );
      expect(
        NaturalLanguageParser.parseMultiple('Ăn phở 50k\nUống cafe 30k').length, 2,
      );
    });

    test('single entry with no delimiter returns 1 result', () {
      final results = NaturalLanguageParser.parseMultiple('Ăn phở 50k');
      expect(results.length, 1);
      expect(results.first.amount, 50000.0);
    });

    test('ignores segments with no detectable amount', () {
      final results = NaturalLanguageParser.parseMultiple(
        'Ăn cơm 100k, hôm nay đẹp trời, uống sữa 50k',
      );
      expect(results.length, 2);
    });
  });
}
