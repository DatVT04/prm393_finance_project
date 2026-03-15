// Full Dashboard uses HomeAppBar with NetworkImage (avatar); in test env
// HTTP returns 400. We test TotalBalanceCard with overridden providers instead.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prm393_finance_project/src/features/dashboard/widgets/total_balance_card.dart';
import 'package:prm393_finance_project/src/features/transactions/providers/finance_providers.dart';
import 'package:prm393_finance_project/src/core/models/account_model.dart';
import 'package:prm393_finance_project/src/core/models/financial_entry_model.dart';

void main() {
  group('Dashboard integration tests', () {
    testWidgets('TotalBalanceCard builds with mock providers',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            entriesWithRefreshProvider.overrideWith((ref) => Future.value(<FinancialEntryModel>[])),
            accountsProvider.overrideWith((ref) => Future.value([AccountModel(id: 1, name: 'Ví', balance: 0)])),
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
