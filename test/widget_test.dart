import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:provider/provider.dart' as p;

import 'package:prm393_finance_project/main.dart';
import 'package:prm393_finance_project/src/core/state/app_state.dart';
import 'package:prm393_finance_project/src/features/transactions/providers/finance_providers.dart';
import 'package:prm393_finance_project/src/features/auth/auth_provider.dart';
import 'helpers/fake_finance_api_client.dart';
import 'helpers/test_helper.dart';

class _FakeUserIdNotifier extends CurrentUserIdNotifier {
  @override
  Future<int?> build() async => 1;
}

void main() {
  setUpAll(() async {
    await initTestLocalization();
  });

  testWidgets('App starts and shows main layout', (WidgetTester tester) async {
    final fakeAuthOverride = currentUserIdProvider.overrideWith(() {
      return _FakeUserIdNotifier();
    });

    // Build our app and trigger a frame.
    await tester.pumpWidget(
      EasyLocalization(
        supportedLocales: const [Locale('vi'), Locale('en')],
        path: 'assets/translations',
        fallbackLocale: const Locale('vi'),
        useOnlyLangCode: true,
        child: ProviderScope(
          overrides: [
            apiClientProvider.overrideWithValue(FakeFinanceApiClient()),
            fakeAuthOverride,
          ],
          child: p.ChangeNotifierProvider(
            create: (_) => AppState(),
            child: const FinanceApp(),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify that the app starts without errors
    expect(find.byType(MaterialApp), findsWidgets);
  });
}
