import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/budget_model.dart';
import '../../../core/network/finance_api_client.dart';
import '../../transactions/providers/finance_providers.dart';

final budgetsProvider = FutureProvider<List<BudgetModel>>((ref) async {
  final client = ref.watch(apiClientProvider);
  return client.getBudgets();
});

final budgetsRefreshProvider = StateProvider<int>((ref) => 0);

final budgetsWithRefreshProvider = FutureProvider<List<BudgetModel>>((ref) async {  //gọi api lấy hết budgets trong database
  ref.watch(budgetsRefreshProvider);
  final client = ref.watch(apiClientProvider);
  return client.getBudgets();
});

void refreshBudgets(WidgetRef ref) {
  ref.read(budgetsRefreshProvider.notifier).update((v) => v + 1);
}
