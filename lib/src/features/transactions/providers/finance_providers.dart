import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:prm393_finance_project/src/core/models/account_model.dart';
import 'package:prm393_finance_project/src/core/models/category_model.dart';
import 'package:prm393_finance_project/src/core/models/financial_entry_model.dart';
import 'package:prm393_finance_project/src/core/network/finance_api_client.dart';

final apiClientProvider = Provider<FinanceApiClient>((ref) => FinanceApiClient());

final categoriesProvider = FutureProvider<List<CategoryModel>>((ref) async {
  final client = ref.watch(apiClientProvider);
  return client.getCategories();
});

final categoriesRefreshProvider = StateProvider<int>((ref) => 0);

final categoriesWithRefreshProvider = FutureProvider<List<CategoryModel>>((ref) async {
  ref.watch(categoriesRefreshProvider);
  final client = ref.watch(apiClientProvider);
  return client.getCategories();
});

void refreshCategories(WidgetRef ref) {
  ref.read(categoriesRefreshProvider.notifier).update((v) => v + 1);
}

final accountsProvider = FutureProvider<List<AccountModel>>((ref) async {
  final client = ref.watch(apiClientProvider);
  return client.getAccounts();
});

/// Invalidate accounts để refetch số dư (sau khi nạp tiền / chi tiêu).
void refreshAccounts(WidgetRef ref) {
  ref.invalidate(accountsProvider);
}

final entriesProvider = FutureProvider<List<FinancialEntryModel>>((ref) async {
  final client = ref.watch(apiClientProvider);
  return client.getEntries();
});

final entriesRefreshProvider = StateProvider<int>((ref) => 0);

/// Use this to refetch entries (e.g. after add/delete). Increment to trigger refresh.
void refreshEntries(WidgetRef ref) {
  ref.read(entriesRefreshProvider.notifier).update((v) => v + 1);
}

final entriesWithRefreshProvider = FutureProvider<List<FinancialEntryModel>>((ref) async {
  ref.watch(entriesRefreshProvider);
  final client = ref.watch(apiClientProvider);
  return client.getEntries();
});
