import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prm393_finance_project/main.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('System / E2E tests', () {
    testWidgets('App launches and shows main layout with navigation',
        (WidgetTester tester) async {
      runApp(const ProviderScope(child: FinanceApp()));
      await tester.pumpAndSettle(const Duration(seconds: 3));

      expect(find.text('Tổng quan'), findsOneWidget);
    });

    testWidgets('Tap Transactions tab and see transaction screen',
        (WidgetTester tester) async {
      runApp(const ProviderScope(child: FinanceApp()));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      await tester.tap(find.text('Giao dịch'));
      await tester.pumpAndSettle();

      expect(find.text('Ghi chú chi tiêu'), findsOneWidget);
    });

    testWidgets('Tap Settings tab and see settings screen',
        (WidgetTester tester) async {
      runApp(const ProviderScope(child: FinanceApp()));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      await tester.tap(find.text('Cài đặt'));
      await tester.pumpAndSettle();

      expect(find.text('Cài đặt'), findsWidgets);
      expect(find.text('Chế độ tối'), findsOneWidget);
    });

    testWidgets('Tap Báo cáo tab', (WidgetTester tester) async {
      runApp(const ProviderScope(child: FinanceApp()));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      await tester.tap(find.text('Báo cáo'));
      await tester.pumpAndSettle();

      expect(find.text('Báo cáo thống kê'), findsOneWidget);
    });
  });
}
