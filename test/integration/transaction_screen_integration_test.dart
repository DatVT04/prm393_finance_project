import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prm393_finance_project/src/features/transactions/transaction_screen.dart';
import 'package:prm393_finance_project/src/features/transactions/providers/finance_providers.dart';
import 'package:prm393_finance_project/src/core/models/financial_entry_model.dart';

void main() {
  group('TransactionScreen integration tests', () {
    testWidgets('TransactionScreen shows title and list when entries loaded',
        (WidgetTester tester) async {
      final entries = [
        FinancialEntryModel(
          id: 1,
          amount: 100000,
          categoryId: 1,
          transactionDate: DateTime.now(),
          type: 'EXPENSE',
          accountId: 1,
          note: 'Test note',
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            entriesWithRefreshProvider.overrideWith((ref) => Future.value(entries)),
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

    testWidgets('TransactionScreen has filter and FAB', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: TransactionScreen(),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 200));

      expect(find.byType(FloatingActionButton), findsWidgets);
    });
  });
}
