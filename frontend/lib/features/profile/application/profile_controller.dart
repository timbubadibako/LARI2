import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/config/api_config.dart';
import '../../../core/domain/models/user_profile.dart';
import '../../../core/services/supabase_logger.dart';
import '../../../dev/dev_providers.dart';
import '../../auth/application/auth_controller.dart';

final profileControllerProvider =
    AsyncNotifierProvider<ProfileController, UserProfile?>(() {
      return ProfileController();
    });

class ProfileController extends AsyncNotifier<UserProfile?> {
  bool get _logEnabled => ref.read(supabaseDevLogEnabledProvider);
  final String _baseUrl = ApiConfig.baseUrl;

  @override
  Future<UserProfile?> build() async {
    return _fetchProfile();
  }

  Future<UserProfile?> _fetchProfile() async {
    final userId = ref.read(currentUserSessionProvider);
    if (userId == null) return null;

    try {
      final response = await http.get(Uri.parse('$_baseUrl/profiles/$userId'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return UserProfile.fromJson(data);
      }
    } catch (e) {
      SupabaseLogger.log(_logEnabled, 'Fetch Profile Error', success: false, error: e.toString());
    }

    // Fallback if API fails
    return UserProfile(
      userId: userId,
      displayName: 'Agent $userId',
      level: 1,
      xp: 0,
      isFallback: true,
    );
  }

  Future<void> updateDisplayName(String newName) async {
    // TODO: Implement API call
  }

  Future<void> updateProfile({
    String? displayName,
    String? bio,
    String? avatarUrl,
    bool? publicProfile,
    bool? ghostMode,
  }) async {
    // TODO: Implement API call
  }
}
