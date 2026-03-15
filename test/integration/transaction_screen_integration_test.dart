import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prm393_finance_project/src/features/transactions/transaction_screen.dart';
import 'package:prm393_finance_project/src/features/transactions/providers/finance_providers.dart';
import '../helpers/fake_finance_api_client.dart';

void main() {
  group('TransactionScreen integration tests', () {
    testWidgets('TransactionScreen hiển thị title và danh sách entries từ mock data',
        (WidgetTester tester) async {
      final fakeClient = FakeFinanceApiClient();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            apiClientProvider.overrideWithValue(fakeClient),
          ],
          child: const MaterialApp(
            home: TransactionScreen(),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('Ghi chú chi tiêu'), findsOneWidget);
    });

    testWidgets('TransactionScreen có FAB khi dùng mock data',
        (WidgetTester tester) async {
      final fakeClient = FakeFinanceApiClient();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            apiClientProvider.overrideWithValue(fakeClient),
          ],
          child: const MaterialApp(
            home: TransactionScreen(),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 200));

      expect(find.byType(FloatingActionButton), findsWidgets);
    });

    testWidgets('TransactionScreen hiển thị entries khi có mock data',
        (WidgetTester tester) async {
      final fakeClient = FakeFinanceApiClient();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            apiClientProvider.overrideWithValue(fakeClient),
          ],
          child: const MaterialApp(
            home: TransactionScreen(),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      // Kiểm tra có entries hiển thị (note của fake data)
      expect(find.text('Bữa trưa'), findsOneWidget);
    });
  });
}
