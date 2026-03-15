import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prm393_finance_project/main.dart';
import 'package:prm393_finance_project/src/features/auth/auth_provider.dart';
import 'package:prm393_finance_project/src/features/transactions/providers/finance_providers.dart';
import '../test/helpers/fake_finance_api_client.dart';

/// Hàm dùng để tạm dừng giữa các thao tác (giúp người xem dễ theo dõi UI)
Future<void> _slowDown() async {
  await Future.delayed(const Duration(seconds: 2));
}

final _fakeAuthOverride = currentUserIdProvider.overrideWith(() {
  return _FakeUserIdNotifier();
});

class _FakeUserIdNotifier extends CurrentUserIdNotifier {
  @override
  Future<int?> build() async => 1;
}

Widget _buildTestApp() {
  final fakeClient = FakeFinanceApiClient();
  return ProviderScope(
    overrides: [
      _fakeAuthOverride,
      apiClientProvider.overrideWithValue(fakeClient),
    ],
    child: const FinanceApp(),
  );
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('System / E2E tests:', () {
    testWidgets('App khởi động và hiển thị layout chính (Dashboard)',
        (WidgetTester tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();
      
      // Dừng 2 giây cho người dùng xem giao diện mở lên
      await _slowDown();

      expect(find.text('Tổng quan'), findsWidgets);
    });

    testWidgets('Nhấn vào tab Giao dịch',
        (WidgetTester tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();
      await _slowDown();

      final giaoDichFinder = find.text('Giao dịch');
      expect(giaoDichFinder, findsWidgets);
      
      // Nhấn
      await tester.tap(giaoDichFinder.first);
      await tester.pumpAndSettle();

      // Dừng thêm 2 giây sau khi UI chuyển cảnh
      await _slowDown();
      expect(find.text('Ghi chú chi tiêu'), findsOneWidget);
    });

    testWidgets('Nhấn vào tab Cài đặt',
        (WidgetTester tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();

      final caiDatFinder = find.text('Cài đặt');
      await tester.tap(caiDatFinder.first);
      await tester.pumpAndSettle();

      await _slowDown();
      expect(find.text('Chế độ tối'), findsOneWidget);
    });

    testWidgets('Nhấn vào tab Báo cáo',
        (WidgetTester tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();

      final baoCaoFinder = find.text('Báo cáo');
      await tester.tap(baoCaoFinder.first);
      await tester.pumpAndSettle();

      await _slowDown();
      expect(find.text('Báo cáo thống kê'), findsOneWidget);
    });

    testWidgets('Nhấn vào tab Trợ lý AI',
        (WidgetTester tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();

      final aiFinder = find.text('Trợ lý AI');
      await tester.tap(aiFinder.first);
      await tester.pumpAndSettle();

      await _slowDown();
      expect(find.byType(TextField).last, findsOneWidget);
    });
  });
}
