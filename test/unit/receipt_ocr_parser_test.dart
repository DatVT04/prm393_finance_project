import 'package:flutter_test/flutter_test.dart';
import 'package:prm393_finance_project/src/core/services/receipt_ocr_parser.dart';

void main() {
  group('ReceiptOcrParser', () {
    test('returns empty result for empty or whitespace-only text', () {
      expect(ReceiptOcrParser.parse('').rawText, '');
      expect(ReceiptOcrParser.parse('   \n  ').rawText, '   \n  ');
      expect(ReceiptOcrParser.parse('').totalAmount, isNull);
      expect(ReceiptOcrParser.parse('').storeName, isNull);
      expect(ReceiptOcrParser.parse('').date, isNull);
    });

    test('extracts total from line containing "Tổng" or "total"', () {
      final r = ReceiptOcrParser.parse('Cửa hàng A\nTổng: 150.000 đ\nCảm ơn');
      expect(r.totalAmount, 150000);
      expect(r.storeName, isNotNull);
    });

    test('extracts total from "Thanh toán" line (dot as thousand sep)', () {
      final r = ReceiptOcrParser.parse('Thanh toán: 50.000 đ');
      expect(r.totalAmount, 50000);
    });

    test('extracts amount with Vietnamese format (1.500.000 đ)', () {
      final r = ReceiptOcrParser.parse('Tổng cộng: 1.500.000 đ');
      expect(r.totalAmount, 1500000);
    });

    test('extracts date dd/mm/yyyy', () {
      final r = ReceiptOcrParser.parse('Ngày: 15/03/2025\nTổng: 100.000 đ');
      expect(r.date, DateTime(2025, 3, 15));
    });

    test('extracts date dd-mm-yyyy', () {
      final r = ReceiptOcrParser.parse('15-03-2025\nTotal 200000');
      expect(r.date, DateTime(2025, 3, 15));
    });

    test('extracts store name from first reasonable line', () {
      final r = ReceiptOcrParser.parse('Phở 24\nTổng: 45.000 đ');
      expect(r.storeName, 'Phở 24');
    });

    test('when no "tổng" line, takes last number as total', () {
      final r = ReceiptOcrParser.parse('Item 1\nItem 2\n50.000');
      expect(r.totalAmount, 50000);
    });
  });
}
