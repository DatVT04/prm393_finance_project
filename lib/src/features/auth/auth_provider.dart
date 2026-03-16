import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:prm393_finance_project/src/core/network/finance_api_client.dart';

const String _keyUserId = 'user_id';
const String _keyDisplayName = 'display_name';
const String _keyAvatarUrl = 'avatar_url';

class UserProfileData {
  final String? displayName;
  final String? avatarUrl;
  UserProfileData({this.displayName, this.avatarUrl});
}

/// Provider that loads and holds current user id; persists to SharedPreferences.
/// After login/register call [setUserId]; on logout call [clearUserId].
final currentUserIdProvider =
    AsyncNotifierProvider<CurrentUserIdNotifier, int?>(CurrentUserIdNotifier.new);

final userProfileProvider = StateProvider<UserProfileData>((ref) {
  return UserProfileData();
});

class CurrentUserIdNotifier extends AsyncNotifier<int?> {
  @override
  Future<int?> build() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getInt(_keyUserId);
    final name = prefs.getString(_keyDisplayName);
    final avatar = prefs.getString(_keyAvatarUrl);
    
    // Update profile provider immediately
    Future.microtask(() {
      ref.read(userProfileProvider.notifier).state = 
          UserProfileData(displayName: name, avatarUrl: avatar);
    });

    FinanceApiClient.setUserId(id);
    return id;
  }

  Future<void> setUserId(int id, {String? name, String? avatar}) async {
    state = const AsyncValue.loading();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyUserId, id);
    if (name != null) {
      await prefs.setString(_keyDisplayName, name);
    }
    if (avatar != null) {
      await prefs.setString(_keyAvatarUrl, avatar);
    }
    
    ref.read(userProfileProvider.notifier).state = 
        UserProfileData(displayName: name, avatarUrl: avatar);

    FinanceApiClient.setUserId(id);
    state = AsyncValue.data(id);
  }

  Future<void> updateAvatar(String avatar) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyAvatarUrl, avatar);
    
    final current = ref.read(userProfileProvider);
    ref.read(userProfileProvider.notifier).state = 
        UserProfileData(displayName: current.displayName, avatarUrl: avatar);
  }

  Future<void> clearUserId() async {
    state = const AsyncValue.loading();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyUserId);
    await prefs.remove(_keyDisplayName);
    await prefs.remove(_keyAvatarUrl);
    
    ref.read(userProfileProvider.notifier).state = UserProfileData();
    
    FinanceApiClient.setUserId(null);
    state = const AsyncValue.data(null);
  }
}
