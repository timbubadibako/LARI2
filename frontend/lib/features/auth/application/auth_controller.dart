import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/shared_preferences_provider.dart';
import '../../../core/services/http_client_provider.dart';
import '../../../core/services/lari_sync_service.dart';
import '../../../core/config/api_config.dart';
import '../../../core/services/lari_logger.dart';
import '../../../dev/dev_providers.dart';
import '../../profile/application/profile_controller.dart';

const String kUserSessionIdKey = 'auth.session_id';
const String kUserTokenKey = 'auth.jwt_token';

class CurrentUserSessionNotifier extends Notifier<String?> {
  @override
  String? build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    return prefs.getString(kUserSessionIdKey);
  }

  Future<void> setSession(String? userId, {String? token}) async {
    final prefs = ref.read(sharedPreferencesProvider);
    if (userId == null) {
      await prefs.remove(kUserSessionIdKey);
      await prefs.remove(kUserTokenKey);
    } else {
      await prefs.setString(kUserSessionIdKey, userId);
      if (token != null) {
        await prefs.setString(kUserTokenKey, token);
      }
    }
    state = userId;
  }
}

final currentUserSessionProvider = NotifierProvider<CurrentUserSessionNotifier, String?>(
  CurrentUserSessionNotifier.new,
);

final authControllerProvider = Provider<AuthController>((ref) {
  return AuthController(ref);
});

class AuthController {
  final Ref _ref;

  AuthController(this._ref);

  String? get currentUserId => _ref.read(currentUserSessionProvider);
  
  String? get currentUser => currentUserId;

  bool get _logEnabled => _ref.read(lariDevLogEnabledProvider);

  Future<void> initSession() async {
    // Session is now handled via SharedPreferences in CurrentUserSessionNotifier build()
  }

  Future<void> resetPasswordForEmail(String email) async {
    // TODO: Implement backend reset password
    LariLogger.log(_logEnabled, 'Auth ResetPassword Not Implemented Locally', success: false);
  }

  Future<bool> signInWithEmailPassword(String email, String password) async {
    try {
      final client = _ref.read(httpClientProvider);
      final baseUrl = ApiConfig.getBaseUrl(_ref);
      
      final response = await client.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final String userId = data['id'];
        final String? token = data['token'];
        await _ref.read(currentUserSessionProvider.notifier).setSession(userId, token: token);
        LariLogger.log(_logEnabled, 'LARI2 Auth SignIn Success');
        return true;
      } else {
        LariLogger.log(_logEnabled, 'LARI2 Auth SignIn Failed: ${response.body}', success: false);
        return false;
      }
    } catch (e) {
      LariLogger.log(_logEnabled, 'LARI2 Auth SignIn Error', success: false, error: e.toString());
      return false;
    }
  }

  Future<bool> signUpWithEmailPassword(String email, String password, String displayName, String factionColor) async {
    try {
      final client = _ref.read(httpClientProvider);
      final baseUrl = ApiConfig.getBaseUrl(_ref);
      
      final response = await client.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
          'display_name': displayName,
          'faction_color': factionColor,
        }),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final String userId = data['id'];
        final String? token = data['token'];
        await _ref.read(currentUserSessionProvider.notifier).setSession(userId, token: token);
        LariLogger.log(_logEnabled, 'LARI2 Auth SignUp Success');
        return true;
      } else {
        LariLogger.log(_logEnabled, 'LARI2 Auth SignUp Failed: ${response.body}', success: false);
        return false;
      }
    } catch (e) {
      LariLogger.log(_logEnabled, 'LARI2 Auth SignUp Error', success: false, error: e.toString());
      return false;
    }
  }

  Future<void> signOut() async {
    // 1. Clear session ID
    await _ref.read(currentUserSessionProvider.notifier).setSession(null);
    
    // 2. Clear disk cache for profile
    await _ref.read(profileControllerProvider.notifier).clearCache();

    // 3. Clear sync queue (Avoid ghosting old invalid sync data)
    await _ref.read(lariSyncServiceProvider).clearQueue();
    
    LariLogger.log(_logEnabled, 'LARI2 Auth SignOut');
  }
}
