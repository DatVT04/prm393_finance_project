import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'package:prm393_finance_project/src/core/network/finance_api_client.dart';
import 'package:prm393_finance_project/src/features/transactions/providers/finance_providers.dart';

const String _keyUserId = 'user_id';
const String _keyDisplayName = 'display_name';
const String _keyAvatarUrl = 'avatar_url';

final GoogleSignIn _googleSignIn = GoogleSignIn(
  clientId: kIsWeb ? '954893711733-v3bv8152vpscgj3oacpcoefgqmsg0l9u.apps.googleusercontent.com' : null,
  scopes: <String>['email', 'profile'],
);

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

  Future<void> signInWithGoogle() async {
    state = const AsyncValue.loading();
    try {
      debugPrint('Starting Google Sign-In...');

      // On Web, signIn() might hang if not initialized properly or due to cookies.
      // We use a single instance to avoid "multiple calls" warning.
      final googleUser = await _googleSignIn.signIn().timeout(
        const Duration(seconds: 30),
        onTimeout: () => throw Exception('Hết thời gian đăng nhập Google. Vui lòng thử lại.'),
      );

      if (googleUser == null) {
        debugPrint('Google Sign-In cancelled by user.');
        state = const AsyncValue.data(null);
        return;
      }

      debugPrint('Google Sign-In success: ${googleUser.email}');

      // Call our backend
      final client = ref.read(apiClientProvider);
      final response = await client.googleLogin(
        googleUser.email,
        googleUser.displayName,
      );

      debugPrint('Backend Google Login success: $response');

      final id = (response['userId'] as num).toInt();
      final name = response['displayName'] as String?;
      final avatar = response['avatarUrl'] as String?;

      await setUserId(id, name: name, avatar: avatar);
      debugPrint('User ID set: $id');
    } catch (e, stack) {
      debugPrint('Google Sign-In Error: $e');
      // If it fails on web, suggest testing on Android
      String msg = e.toString();
      if (kIsWeb) {
        msg += '\n(Lưu ý: Google Sign-In trên Web có thể bị chặn bởi trình duyệt. Hãy thử trên Android để ổn định nhất.)';
      }
      state = AsyncValue.error(msg, stack);
      rethrow;
    }
  }

  Future<void> updateAvatar(String avatar) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyAvatarUrl, avatar);
    
    final current = ref.read(userProfileProvider);
    ref.read(userProfileProvider.notifier).state = 
        UserProfileData(displayName: current.displayName, avatarUrl: avatar);
  }

  Future<void> updateDisplayName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyDisplayName, name);

    final current = ref.read(userProfileProvider);
    ref.read(userProfileProvider.notifier).state =
        UserProfileData(displayName: name, avatarUrl: current.avatarUrl);
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
