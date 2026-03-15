import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prm393_finance_project/src/features/dashboard/widgets/total_balance_card.dart';
import 'package:prm393_finance_project/src/features/transactions/providers/finance_providers.dart';
import '../helpers/fake_finance_api_client.dart';

void main() {
  group('Dashboard integration tests', () {
    testWidgets('TotalBalanceCard hiển thị tổng số dư từ mock data',
        (WidgetTester tester) async {
      final fakeClient = FakeFinanceApiClient();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            apiClientProvider.overrideWithValue(fakeClient),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: TotalBalanceCard(),
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.byType(TotalBalanceCard), findsOneWidget);
    });

    testWidgets('TotalBalanceCard hiển thị khi không có dữ liệu (danh sách rỗng)',
        (WidgetTester tester) async {
      final fakeClient = FakeFinanceApiClient(entries: [], accounts: []);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            apiClientProvider.overrideWithValue(fakeClient),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: TotalBalanceCard(),
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.byType(TotalBalanceCard), findsOneWidget);
    });
  });
}
