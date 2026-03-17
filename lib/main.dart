// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' hide ChangeNotifierProvider;
import 'package:flutter_localizations/flutter_localizations.dart';

import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'src/core/state/app_state.dart';
import 'src/core/theme/app_theme.dart';
import 'src/core/theme/locale_provider.dart';
import 'src/core/constants/app_constants.dart';
import 'src/features/auth/auth_provider.dart';
import 'src/features/auth/login_screen.dart';
import 'src/layout/main_layout.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (!kIsWeb) {
    await Firebase.initializeApp();
  } else {
    debugPrint('Firebase is not initialized on Web. Run on Android for full features.');
  }
  runApp(
    ProviderScope(
      child: ChangeNotifierProvider(
        create: (_) => AppState(),
        child: const FinanceApp(),
      ),
    ),
  );
}

class FinanceApp extends ConsumerWidget {
  const FinanceApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appState = context.watch<AppState>();
    final locale = ref.watch(localeProvider);
    final userIdAsync = ref.watch(currentUserIdProvider);

    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,

      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: appState.themeMode,

      locale: locale,
      home: userIdAsync.when(
        loading: () => const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
        error: (_, __) => const LoginScreen(),
        data: (userId) => userId != null ? const MainLayout() : const LoginScreen(),
      ),

      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('vi', 'VN'), Locale('en', 'US')],
    );
  }
}
