import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../../../core/services/http_client_provider.dart';
import '../../../core/config/api_config.dart';
import '../../map/application/current_location_provider.dart';
import '../domain/models/social_models.dart';

final socialControllerProvider = Provider<SocialController>((ref) {
  return SocialController(ref);
});

class SocialController {
  final Ref _ref;

  SocialController(this._ref);

  /// Note: WebSocket would be better for real-time,
  /// for now we stub or use polling if needed.
  Stream<List<Map<String, dynamic>>> watchGlobalActivityStream() {
    return const Stream.empty();
  }

  Future<List<LeaderboardEntry>> fetchLeaderboard(String district) async {
    try {
      final client = _ref.read(httpClientProvider);
      final baseUrl = ApiConfig.getBaseUrl(_ref);

      final response = await client.get(
        Uri.parse('$baseUrl/leaderboard/$district'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => LeaderboardEntry.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<List<DominionEntry>> fetchGuildDominion() async {
    try {
      final client = _ref.read(httpClientProvider);
      final baseUrl = ApiConfig.getBaseUrl(_ref);

      final response = await client.get(Uri.parse('$baseUrl/guilds/dominion'));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((e) => DominionEntry.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<List<GlobalActivity>> fetchGlobalActivity() async {
    try {
      final client = _ref.read(httpClientProvider);
      final baseUrl = ApiConfig.getBaseUrl(_ref);

      final response = await client.get(Uri.parse('$baseUrl/runs/global'));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((e) => GlobalActivity.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<List<Graffiti>> fetchRecentGraffiti() async {
    try {
      final client = _ref.read(httpClientProvider);
      final baseUrl = ApiConfig.getBaseUrl(_ref);

      final response = await client.get(Uri.parse('$baseUrl/graffiti'));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((e) => Graffiti.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<bool> postGraffiti(
    String userId,
    List<List<Map<String, double>>> data,
  ) async {
    try {
      final client = _ref.read(httpClientProvider);
      final baseUrl = ApiConfig.getBaseUrl(_ref);

      final response = await client.post(
        Uri.parse('$baseUrl/graffiti'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'user_id': userId, 'data': data}),
      );

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }
}

typedef SocialActiveNowSummary = ({
  int activeRunners,
  int capturedRuns,
  int hotZones,
});

class HotZonePreview {
  final Color intensity;
  final String displayName;
  final double distanceKm;
  final String? pathWkt;
  final DateTime createdAt;

  HotZonePreview({
    required this.intensity,
    required this.displayName,
    required this.distanceKm,
    required this.pathWkt,
    required this.createdAt,
  });
}

final leaderboardProvider =
    FutureProvider.family<List<LeaderboardEntry>, String>((
      ref,
      district,
    ) async {
      return ref.read(socialControllerProvider).fetchLeaderboard(district);
    });

final guildDominionProvider = FutureProvider<List<DominionEntry>>((ref) async {
  return ref.read(socialControllerProvider).fetchGuildDominion();
});

final globalActivityProvider = FutureProvider<List<GlobalActivity>>((
  ref,
) async {
  return ref.read(socialControllerProvider).fetchGlobalActivity();
});

final recentGraffitiProvider = FutureProvider<List<Graffiti>>((ref) async {
  return ref.read(socialControllerProvider).fetchRecentGraffiti();
});

final globalActivityStreamProvider = StreamProvider<List<Map<String, dynamic>>>(
  (ref) {
    return ref.read(socialControllerProvider).watchGlobalActivityStream();
  },
);

final socialActiveNowSummaryProvider = Provider<SocialActiveNowSummary>((ref) {
  final activities =
      ref.watch(globalActivityProvider).asData?.value ??
      const <GlobalActivity>[];
  final activeRunners = activities.length;
  final capturedRuns = activities.where((a) => a.status == 'captured').length;
  final hotZones = activeRunners == 0
      ? 0
      : ((activeRunners / 2).ceil()).clamp(1, 9);

  return (
    activeRunners: activeRunners,
    capturedRuns: capturedRuns,
    hotZones: hotZones,
  );
});

final hotZonePreviewProvider = Provider<List<HotZonePreview>>((ref) {
  final activities =
      ref.watch(globalActivityProvider).asData?.value ??
      const <GlobalActivity>[];
  final currentPosition = ref.watch(userInitialPositionProvider).asData?.value;
  final now = DateTime.now();

  double? distanceToUserKm(GlobalActivity activity) {
    if (currentPosition == null || activity.pathWkt == null) return null;
    final points = _parseWkt(activity.pathWkt!);
    if (points.isEmpty) return null;

    double nearestMeters = double.infinity;
    for (final point in points) {
      final distanceMeters = Geolocator.distanceBetween(
        currentPosition.latitude,
        currentPosition.longitude,
        point.latitude,
        point.longitude,
      );
      if (distanceMeters < nearestMeters) {
        nearestMeters = distanceMeters;
      }
    }
    return nearestMeters.isFinite ? nearestMeters / 1000.0 : null;
  }

  final filtered =
      activities
          .where((activity) => activity.status == 'captured')
          .where(
            (activity) =>
                now.difference(activity.createdAt) <= const Duration(days: 7),
          )
          .map(
            (activity) => (
              activity: activity,
              nearbyDistanceKm: distanceToUserKm(activity),
            ),
          )
          .where(
            (entry) =>
                entry.nearbyDistanceKm != null &&
                entry.nearbyDistanceKm! <= 1.0,
          )
          .toList()
        ..sort((a, b) {
          final distanceCompare = a.nearbyDistanceKm!.compareTo(
            b.nearbyDistanceKm!,
          );
          if (distanceCompare != 0) return distanceCompare;
          return b.activity.createdAt.compareTo(a.activity.createdAt);
        });

  return filtered.take(5).toList().asMap().entries.map((entry) {
    final index = entry.key;
    final zone = entry.value.activity;
    final intensity = index == 0
        ? zone.color
        : zone.color.withValues(alpha: (0.9 - (index * 0.12)).clamp(0.45, 0.9));

    return HotZonePreview(
      intensity: intensity,
      displayName: zone.displayName,
      distanceKm: entry.value.nearbyDistanceKm!,
      pathWkt: zone.pathWkt,
      createdAt: zone.createdAt,
    );
  }).toList();
});

final topWeeklyLeadersProvider = Provider<List<LeaderboardEntry>>((ref) {
  final entries =
      ref.watch(leaderboardProvider('KEC-GLOBAL')).asData?.value ??
      const <LeaderboardEntry>[];
  return entries.take(5).toList();
});

List<({double latitude, double longitude})> _parseWkt(String wkt) {
  if (!wkt.startsWith('LINESTRING')) return const [];
  try {
    final content = wkt.replaceAll('LINESTRING(', '').replaceAll(')', '');
    return content.split(',').map((pair) {
      final parts = pair.trim().split(' ');
      return (
        latitude: double.parse(parts[1]),
        longitude: double.parse(parts[0]),
      );
    }).toList();
  } catch (_) {
    return const [];
  }
}
