import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prm393_finance_project/src/features/settings/settings_screen.dart';
import '../helpers/test_helper.dart';

void main() {
  setUpAll(() async {
    await initTestLocalization();
  });

  group('SettingsScreen integration tests', () {
    testWidgets('SettingsScreen renders without error', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestableWidget(const SettingsScreen()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(SettingsScreen), findsOneWidget);
    });

    testWidgets('SettingsScreen has SwitchListTile for dark mode', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestableWidget(const SettingsScreen()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(SwitchListTile), findsOneWidget);
    });
  });
}
