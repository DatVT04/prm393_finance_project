import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:prm393_finance_project/src/core/network/finance_api_client.dart';

const String _keyUserId = 'user_id';

/// Provider that loads and holds current user id; persists to SharedPreferences.
/// After login/register call [setUserId]; on logout call [clearUserId].
final currentUserIdProvider =
    AsyncNotifierProvider<CurrentUserIdNotifier, int?>(CurrentUserIdNotifier.new);

class CurrentUserIdNotifier extends AsyncNotifier<int?> {
  @override
  Future<int?> build() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getInt(_keyUserId);
    FinanceApiClient.setUserId(id);
    return id;
  }

  Future<void> setUserId(int id) async {
    state = const AsyncValue.loading();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyUserId, id);
    FinanceApiClient.setUserId(id);
    state = AsyncValue.data(id);
  }

  Future<void> clearUserId() async {
    state = const AsyncValue.loading();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyUserId);
    FinanceApiClient.setUserId(null);
    state = const AsyncValue.data(null);
  }
}
