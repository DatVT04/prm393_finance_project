// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' hide ChangeNotifierProvider;
import 'package:provider/provider.dart';
import 'src/core/state/app_state.dart';
import 'src/core/theme/app_theme.dart';
import 'src/features/auth/auth_provider.dart';
import 'src/features/auth/login_screen.dart';
import 'src/layout/main_layout.dart';
import 'package:easy_localization/easy_localization.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();

  // Firebase removed for cross-platform reliability (Web/Windows/Android).
  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('en'), Locale('vi'), Locale('ja'), Locale('ko'), Locale('zh')],
      path: 'assets/translations',
      fallbackLocale: const Locale('vi'),
      useOnlyLangCode: true,
      child: ProviderScope(
        child: ChangeNotifierProvider(
          create: (_) => AppState(),
          child: const FinanceApp(),
        ),
      ),
    ),
  );
}

class FinanceApp extends ConsumerWidget {
  const FinanceApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Access context.locale to ensure this widget rebuilds on locale change
    final _ = context.locale;

    final appState = context.watch<AppState>();
    final userIdAsync = ref.watch(currentUserIdProvider);

    return MaterialApp(
      title: 'app_title'.tr(),
      debugShowCheckedModeBanner: false,

      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: appState.themeMode,

      locale: context.locale,
      home: userIdAsync.when(
        loading: () => const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
        error: (_, __) => const LoginScreen(),
        data: (userId) => userId != null ? MainLayout() : const LoginScreen(),
      ),

      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
    );
  }
}
