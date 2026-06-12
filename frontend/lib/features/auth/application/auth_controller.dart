import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/config/api_config.dart';
import '../../../core/services/supabase_logger.dart';
import '../../../dev/dev_providers.dart';

class CurrentUserSessionNotifier extends Notifier<String?> {
  static const String _sessionKey = 'lari_session_user_id';

  @override
  String? build() {
    // We can't do async load here directly, but we can return null and let AuthController load it.
    // Or we can use a FutureProvider for the Initial load.
    // Let's stick to a simpler approach: AuthController handles the SharedPreferences.
    return null;
  }

  void setSession(String? userId) {
    state = userId;
    _persistSession(userId);
  }

  Future<void> _persistSession(String? userId) async {
    final prefs = await SharedPreferences.getInstance();
    if (userId == null) {
      await prefs.remove(_sessionKey);
    } else {
      await prefs.setString(_sessionKey, userId);
    }
  }

  Future<void> loadSession() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getString(_sessionKey);
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
  final String _baseUrl = ApiConfig.baseUrl;

  AuthController(this._ref);

  String? get currentUserId => _ref.read(currentUserSessionProvider);
  
  // Backward compatibility getter
  String? get currentUser => currentUserId;

  bool get _logEnabled => _ref.read(supabaseDevLogEnabledProvider);

  Future<void> initSession() async {
    await _ref.read(currentUserSessionProvider.notifier).loadSession();
  }

  Future<void> resetPasswordForEmail(String email) async {
    // TODO: Implement API call
    SupabaseLogger.log(_logEnabled, 'API Auth ResetPassword (Not Implemented)');
  }

  Future<bool> signInWithEmailPassword(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _ref.read(currentUserSessionProvider.notifier).setSession(data['id']);
        SupabaseLogger.log(_logEnabled, 'API Auth SignIn Success');
        return true;
      }
      
      SupabaseLogger.log(_logEnabled, 'API Auth SignIn Failed', success: false, error: response.body);
      return false;
    } catch (e) {
      SupabaseLogger.log(_logEnabled, 'API Auth SignIn Error', success: false, error: e.toString());
      rethrow;
    }
  }

  Future<bool> signUpWithEmailPassword(String email, String password, String displayName) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
          'display_name': displayName,
        }),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        _ref.read(currentUserSessionProvider.notifier).setSession(data['id']);
        SupabaseLogger.log(_logEnabled, 'API Auth SignUp Success');
        return true;
      }

      SupabaseLogger.log(_logEnabled, 'API Auth SignUp Failed', success: false, error: response.body);
      return false;
    } catch (e) {
      SupabaseLogger.log(_logEnabled, 'API Auth SignUp Error', success: false, error: e.toString());
      rethrow;
    }
  }

  Future<void> signOut() async {
    _ref.read(currentUserSessionProvider.notifier).setSession(null);
    SupabaseLogger.log(_logEnabled, 'API Auth SignOut');
  }
}
