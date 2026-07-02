import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/domain/models/user_profile.dart';
import '../../../core/services/shared_preferences_provider.dart';
import '../../../core/services/http_client_provider.dart';
import '../../../core/config/api_config.dart';
import '../../../core/services/lari_logger.dart';
import '../../../dev/dev_providers.dart';
import '../../auth/application/auth_controller.dart';

final profileControllerProvider =
    AsyncNotifierProvider<ProfileController, UserProfile?>(() {
      return ProfileController();
    });

class ProfileController extends AsyncNotifier<UserProfile?> {
  static const String _profileCacheKey = 'lari_profile_cache';
  
  bool get _logEnabled => ref.read(lariDevLogEnabledProvider);

  @override
  Future<UserProfile?> build() async {
    final userId = ref.watch(currentUserSessionProvider);
    debugPrint('ProfileController: Build triggered. UserID: $userId');
    
    if (userId == null) {
      return null;
    }

    // Try to load cache first to show something immediately
    final cached = await _getCache(userId);
    if (cached != null) {
      debugPrint('ProfileController: Initializing with cache: ${cached.displayName}');
    }

    return _fetchProfile(userId);
  }

  Future<UserProfile?> _getCache(String currentUserId) async {
    try {
      final prefs = ref.read(sharedPreferencesProvider);
      final cachedJson = prefs.getString(_profileCacheKey);
      if (cachedJson != null) {
        final profile = UserProfile.fromJson(jsonDecode(cachedJson));
        // 🔥 VALIDASI: Hanya kembalikan cache jika ID-nya sama
        if (profile.userId == currentUserId) {
          return profile;
        } else {
          debugPrint('ProfileController: Stale cache detected for different user. Ignoring.');
          await clearCache();
        }
      }
    } catch (e) {
      debugPrint('ProfileController: Cache read error: $e');
    }
    return null;
  }

  Future<void> clearCache() async {
    try {
      final prefs = ref.read(sharedPreferencesProvider);
      await prefs.remove(_profileCacheKey);
      debugPrint('ProfileController: Cache cleared.');
    } catch (e) {
      debugPrint('ProfileController: Cache clear error: $e');
    }
  }

  Future<void> _saveToCache(UserProfile profile) async {
    try {
      final prefs = ref.read(sharedPreferencesProvider);
      await prefs.setString(_profileCacheKey, jsonEncode(profile.toJson()));
    } catch (e) {
      debugPrint('ProfileController: Cache save error: $e');
    }
  }

  Future<UserProfile?> _fetchProfile(String userId) async {
    debugPrint('ProfileController: Fetching from Go backend for $userId');
    try {
      final client = ref.read(httpClientProvider);
      final baseUrl = ApiConfig.getBaseUrl(ref);
      
      final response = await client.get(
        Uri.parse('$baseUrl/profiles/$userId'),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final profile = UserProfile.fromJson(data);
        debugPrint('ProfileController: Parse success: ${profile.displayName}');
        _saveToCache(profile);
        return profile;
      } else {
        debugPrint('ProfileController: Backend error ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      debugPrint('ProfileController: Fetch error: $e');
      LariLogger.log(_logEnabled, 'Fetch Profile Error', success: false, error: e.toString());
    }

    // Check if we have a valid cached value to return instead of fallback
    final cached = await _getCache(userId);
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
      final client = ref.read(httpClientProvider);
      final baseUrl = ApiConfig.getBaseUrl(ref);

      final body = <String, dynamic>{};
      if (displayName != null) body['display_name'] = displayName;
      if (bio != null) body['bio'] = bio;
      if (publicProfile != null) body['public_profile'] = publicProfile;
      if (ghostMode != null) body['ghost_mode'] = ghostMode;
      if (signatureData != null) body['signature_data'] = signatureData;

      final response = await client.put(
        Uri.parse('$baseUrl/profiles/$userId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        LariLogger.log(_logEnabled, 'Update Profile Success');
        ref.invalidateSelf();
        return true;
      }
      return false;
    } catch (e) {
      LariLogger.log(_logEnabled, 'Update Profile Error', success: false, error: e.toString());
      return false;
    } finally {
      // Re-fetch profile to restore state if update failed or to confirm success
      if (!state.hasValue) {
        state = await AsyncValue.guard(() => _fetchProfile(userId));
      }
    }
  }
}

typedef ProfileOverviewData = ({String displayName, int level, String? bio});
typedef ProfileTotalsData = ({double distanceKm, int sectors, int rank, int level});

final profileOverviewProvider = Provider<ProfileOverviewData?>((ref) {
  final profile = ref.watch(profileControllerProvider).asData?.value;
  if (profile == null) return null;
  return (
    displayName: profile.displayNameOrFallback,
    level: profile.level,
    bio: profile.bio,
  );
});

final profileTotalsProvider = Provider<ProfileTotalsData?>((ref) {
  final profile = ref.watch(profileControllerProvider).asData?.value;
  if (profile == null) return null;
  return (
    distanceKm: profile.totalDistanceKm,
    sectors: profile.totalSectorsHeld,
    rank: profile.globalRank,
    level: profile.level,
  );
});
