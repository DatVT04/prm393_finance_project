import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:prm393_finance_project/src/core/models/account_model.dart';
import 'package:prm393_finance_project/src/core/models/category_model.dart';
import 'package:prm393_finance_project/src/core/models/financial_entry_model.dart';
import 'package:prm393_finance_project/src/core/network/finance_api_client.dart';

final apiClientProvider = Provider<FinanceApiClient>((ref) => FinanceApiClient());
final localeProvider = StateProvider<String>((ref) => 'vi');

final categoriesRefreshProvider = StateProvider<int>((ref) => 0);

final categoriesProvider = FutureProvider<List<CategoryModel>>((ref) async {
  ref.watch(categoriesRefreshProvider);
  ref.watch(localeProvider); // Watch locale to refetch when it changes
  final client = ref.watch(apiClientProvider);
  return client.getCategories();
});

final categoriesWithRefreshProvider = categoriesProvider;

void refreshCategories(dynamic ref) {
  ref.read(categoriesRefreshProvider.notifier).update((int v) => v + 1);
}

final accountsProvider = FutureProvider<List<AccountModel>>((ref) async {
  final client = ref.watch(apiClientProvider);
  return client.getAccounts(includeDeleted: false);
});

final allAccountsProvider = FutureProvider<List<AccountModel>>((ref) async {
  final client = ref.watch(apiClientProvider);
  return client.getAccounts(includeDeleted: true);
});

/// Invalidate accounts để refetch số dư (sau khi nạp tiền / chi tiêu).
void refreshAccounts(dynamic ref) {
  ref.invalidate(accountsProvider);
  ref.invalidate(allAccountsProvider);
}

final entriesRefreshProvider = StateProvider<int>((ref) => 0);

final entriesProvider = FutureProvider<List<FinancialEntryModel>>((ref) async {
  ref.watch(entriesRefreshProvider);
  final client = ref.watch(apiClientProvider);
  return client.getEntries();
});

final entriesWithRefreshProvider = entriesProvider;

/// Use this to refetch entries (e.g. after add/delete). Increment to trigger refresh.
void refreshEntries(dynamic ref) {
  ref.read(entriesRefreshProvider.notifier).update((int v) => v + 1);
}
