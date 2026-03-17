import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart' as p;
import 'package:prm393_finance_project/src/core/state/app_state.dart';

/// Mock shared_preferences channel — cần thiết vì EasyLocalization.ensureInitialized()
/// dùng shared_preferences plugin không available trong flutter test (VM mode).
void mockSharedPreferences() {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
    const MethodChannel('plugins.flutter.io/shared_preferences'),
    (MethodCall call) async {
      if (call.method == 'getAll') return <String, dynamic>{};
      return null;
    },
  );
}

/// Wraps [child] với EasyLocalization + ProviderScope (Riverpod) + AppState
/// (provider package) — giống cấu trúc trong main.dart.
Widget buildTestableWidget(Widget child, {List<Override> overrides = const []}) {
  return EasyLocalization(
    supportedLocales: const [Locale('vi'), Locale('en')],
    path: 'assets/translations',
    fallbackLocale: const Locale('vi'),
    useOnlyLangCode: true,
    child: ProviderScope(
      overrides: overrides,
      child: p.ChangeNotifierProvider(
        create: (_) => AppState(),
        child: MaterialApp(
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('vi'), Locale('en')],
          home: child,
        ),
      ),
    ),
  );
}

/// Gọi trong setUpAll() trước khi bắt đầu integration tests.
Future<void> initTestLocalization() async {
  TestWidgetsFlutterBinding.ensureInitialized();
  mockSharedPreferences();
  await EasyLocalization.ensureInitialized();
}
