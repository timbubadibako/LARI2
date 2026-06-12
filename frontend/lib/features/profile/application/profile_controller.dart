import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/config/api_config.dart';
import '../../../core/domain/models/user_profile.dart';
import '../../../core/services/http_client_provider.dart';
import '../../../core/services/supabase_logger.dart';
import '../../../dev/dev_providers.dart';
import '../../auth/application/auth_controller.dart';

final profileControllerProvider =
    AsyncNotifierProvider<ProfileController, UserProfile?>(() {
      return ProfileController();
    });

class ProfileController extends AsyncNotifier<UserProfile?> {
  static const String _profileCacheKey = 'lari_profile_cache';
  
  bool get _logEnabled => ref.read(supabaseDevLogEnabledProvider);
  final String _baseUrl = ApiConfig.baseUrl;

  http.Client get _client => ref.read(httpClientProvider);

  @override
  Future<UserProfile?> build() async {
    final userId = ref.watch(currentUserSessionProvider);
    debugPrint('ProfileController: Build triggered. UserID: $userId');
    
    if (userId == null) {
      return null;
    }

    // Try to load cache first to show something immediately
    final cached = await _getCache();
    if (cached != null) {
      debugPrint('ProfileController: Initializing with cache: ${cached.displayName}');
    }

    return _fetchProfile(userId);
  }

  Future<UserProfile?> _getCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedJson = prefs.getString(_profileCacheKey);
      if (cachedJson != null) {
        return UserProfile.fromJson(jsonDecode(cachedJson));
      }
    } catch (e) {
      debugPrint('ProfileController: Cache read error: $e');
    }
    return null;
  }

  Future<void> _saveToCache(UserProfile profile) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_profileCacheKey, jsonEncode(profile.toJson()));
    } catch (e) {
      debugPrint('ProfileController: Cache save error: $e');
    }
  }

  Future<UserProfile?> _fetchProfile(String userId) async {
    debugPrint('ProfileController: Fetching from $_baseUrl/profiles/$userId');
    try {
      final response = await _client.get(Uri.parse('$_baseUrl/profiles/$userId')).timeout(const Duration(seconds: 10));
      debugPrint('ProfileController: Server Response: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final profile = UserProfile.fromJson(data);
        debugPrint('ProfileController: Parse success: ${profile.displayName}');
        _saveToCache(profile);
        return profile;
      }
    } catch (e) {
      debugPrint('ProfileController: Fetch error: $e');
      SupabaseLogger.log(_logEnabled, 'Fetch Profile Error', success: false, error: e.toString());
    }

    // Check if we have a valid cached value to return instead of fallback
    final cached = await _getCache();
    if (cached != null) {
      debugPrint('ProfileController: Returning cached data after network failure');
      return cached;
    }

    debugPrint('ProfileController: Returning fallback profile');
    return UserProfile(
      userId: userId,
      displayName: 'Agent $userId',
      level: 1,
      xp: 0,
      isFallback: true,
    );
  }

  Future<void> updateDisplayName(String newName) async {
    await updateProfile(displayName: newName);
  }

  Future<bool> updateProfile({
    String? displayName,
    String? bio,
    String? avatarUrl,
    bool? publicProfile,
    bool? ghostMode,
    String? signatureData,
  }) async {
    final userId = ref.read(currentUserSessionProvider);
    if (userId == null) return false;

    state = const AsyncValue.loading();

    try {
      final body = <String, dynamic>{};
      if (displayName != null) body['display_name'] = displayName;
      if (bio != null) body['bio'] = bio;
      if (publicProfile != null) body['public_profile'] = publicProfile;
      if (ghostMode != null) body['ghost_mode'] = ghostMode;
      if (signatureData != null) body['signature_data'] = signatureData;

      final response = await _client.put(
        Uri.parse('$_baseUrl/profiles/$userId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        SupabaseLogger.log(_logEnabled, 'Update Profile Success');
        ref.invalidateSelf();
        return true;
      }
      
      SupabaseLogger.log(_logEnabled, 'Update Profile Failed', success: false, error: response.body);
      return false;
    } catch (e) {
      SupabaseLogger.log(_logEnabled, 'Update Profile Error', success: false, error: e.toString());
      return false;
    } finally {
      // Re-fetch profile to restore state if update failed or to confirm success
      if (!state.hasValue) {
        state = await AsyncValue.guard(() => _fetchProfile(userId));
      }
    }
  }
}
