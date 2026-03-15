import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prm393_finance_project/src/features/settings/settings_screen.dart';

void main() {
  group('SettingsScreen integration tests', () {
    testWidgets('SettingsScreen shows Cài đặt and Chế độ tối', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: SettingsScreen(),
          ),
        ),
      );

      expect(find.text('Cài đặt'), findsOneWidget);
      expect(find.text('Chế độ tối'), findsOneWidget);
      expect(find.text('Thông tin nhóm'), findsOneWidget);
    });

    testWidgets('SettingsScreen has SwitchListTile for dark mode', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: SettingsScreen(),
          ),
        ),
      );

      expect(find.byType(SwitchListTile), findsOneWidget);
    });
  });
}
