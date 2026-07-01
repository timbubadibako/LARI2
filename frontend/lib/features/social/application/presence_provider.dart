import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../../../core/config/api_config.dart';
import '../../../core/services/shared_preferences_provider.dart';
import '../../auth/application/auth_controller.dart';
import '../../profile/application/profile_controller.dart';
import '../../workout/application/workout_controller.dart';
import '../../map/application/current_location_provider.dart';
import '../../../core/domain/models/workout_session.dart';
import '../../../core/domain/models/position_sample.dart';

const String kPresenceOptInKey = 'social.presenceOptIn';

class PresenceOptInNotifier extends Notifier<bool> {
  @override
  bool build() {
    return ref.read(sharedPreferencesProvider).getBool(kPresenceOptInKey) ??
        false;
  }

  Future<void> toggle() async {
    final newValue = !state;
    await ref
        .read(sharedPreferencesProvider)
        .setBool(kPresenceOptInKey, newValue);
    // Sync option to local state
    state = newValue;
  }
}

final presenceOptInProvider = NotifierProvider<PresenceOptInNotifier, bool>(
  PresenceOptInNotifier.new,
);

final presenceWebSocketProvider = Provider.autoDispose<WebSocketChannel?>((ref) {
  final optedIn = ref.watch(presenceOptInProvider);
  final userId = ref.watch(currentUserSessionProvider);
  if (!optedIn || userId == null) return null;

  final baseUrl = ref.watch(baseUrlProvider);
  final wsUrl = _getWsUrl(baseUrl);
  
  debugPrint('WS: Connecting to $wsUrl for user $userId');
  try {
    final channel = WebSocketChannel.connect(Uri.parse(wsUrl));
    ref.onDispose(() {
      debugPrint('WS: Closing connection');
      channel.sink.close();
    });
    return channel;
  } catch (e) {
    debugPrint('WS Connect Error: $e');
    return null;
  }
});

String _getWsUrl(String baseUrl) {
  final uri = Uri.parse(baseUrl);
  final wsScheme = uri.scheme == 'https' ? 'wss' : 'ws';
  return uri.replace(scheme: wsScheme, path: '/ws').toString();
}

class PresenceData {
  final String userId;
  final List<LatLng> route;
  final String color;
  final DateTime lastSeenAt;

  PresenceData({
    required this.userId,
    required this.route,
    required this.color,
    required this.lastSeenAt,
  });
}

class ContestedZone {
  final LatLng center;
  final double radiusMeters;
  final int runnerCount;
  final String colorHex;
  final String severity;

  const ContestedZone({
    required this.center,
    required this.radiusMeters,
    required this.runnerCount,
    required this.colorHex,
    required this.severity,
  });
}

class PresenceLinesNotifier extends Notifier<List<PresenceData>> {
  static const Duration _presenceStaleAfter = Duration(seconds: 25);
  StreamSubscription? _wsSubscription;
  Timer? _reconnectTimer;
  Timer? _pruneTimer;

  @override
  List<PresenceData> build() {
    final optedIn = ref.watch(presenceOptInProvider);
    final userId = ref.watch(currentUserSessionProvider);
    
    if (!optedIn || userId == null) {
      _wsSubscription?.cancel();
      _reconnectTimer?.cancel();
      _pruneTimer?.cancel();
      return [];
    }

    final channel = ref.watch(presenceWebSocketProvider);
    if (channel != null) {
      _wsSubscription?.cancel();
      _wsSubscription = channel.stream.listen(
        _handleIncomingMessage,
        onError: (err) {
          debugPrint('WS Stream Error: $err');
          _scheduleReconnect();
        },
        onDone: () {
          debugPrint('WS Stream Closed');
          _scheduleReconnect();
        },
      );
    }

    _pruneTimer ??= Timer.periodic(const Duration(seconds: 5), (_) {
      _pruneStalePresence();
    });

    // Set up a listener for workoutControllerProvider to send user's own location updates
    ref.listen<WorkoutSession>(workoutControllerProvider, (previous, next) {
      if (next.state == WorkoutState.running && next.points.isNotEmpty) {
        final lastPoint = next.points.last;
        final prevPoint = previous?.points.isNotEmpty == true ? previous?.points.last : null;
        
        // Only send if the coordinate actually changed to avoid duplicate network traffic
        if (prevPoint == null || prevPoint.lat != lastPoint.lat || prevPoint.lng != lastPoint.lng) {
          _sendOwnLocation(channel, userId, lastPoint);
        }
      }
    });

    ref.onDispose(() {
      _wsSubscription?.cancel();
      _reconnectTimer?.cancel();
      _pruneTimer?.cancel();
    });

    return [];
  }

  void _scheduleReconnect() {
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 5), () {
      if (ref.read(presenceOptInProvider)) {
        debugPrint('WS: Attempting to reconnect...');
        ref.invalidate(presenceWebSocketProvider);
      }
    });
  }

  void _sendOwnLocation(WebSocketChannel? channel, String userId, PositionSample sample) {
    if (channel == null) return;
    
    final profile = ref.read(profileControllerProvider).value;
    final color = profile?.territoryColor ?? '#FF00FF';

    final payload = {
      'type': 'PRESENCE_UPDATE',
      'user_id': userId,
      'lat': sample.lat,
      'lng': sample.lng,
      'color': color,
    };
    
    try {
      channel.sink.add(jsonEncode(payload));
      debugPrint('WS: Sent presence update: $payload');
    } catch (e) {
      debugPrint('WS Error sending location: $e');
    }
  }

  void _handleIncomingMessage(dynamic rawMsg) {
    try {
      final data = jsonDecode(rawMsg.toString());
      if (data['type'] == 'PRESENCE_UPDATE') {
        final userId = data['user_id'] as String;
        final lat = (data['lat'] as num).toDouble();
        final lng = (data['lng'] as num).toDouble();
        final color = data['color'] as String? ?? '#FFA500';
        final seenAt = DateTime.now().toUtc();
        
        final newPoint = LatLng(lat, lng);
        
        // Update the list of presence lines
        final existingIndex = state.indexWhere((item) => item.userId == userId);
        if (existingIndex != -1) {
          final existing = state[existingIndex];
          final updatedRoute = [...existing.route, newPoint];
          
          // Cap the presence trail length to e.g. 100 points to save memory
          if (updatedRoute.length > 100) {
            updatedRoute.removeAt(0);
          }

          state = [
            for (int i = 0; i < state.length; i++)
              if (i == existingIndex)
                PresenceData(
                  userId: userId,
                  route: updatedRoute,
                  color: color,
                  lastSeenAt: seenAt,
                )
              else
                state[i]
          ];
        } else {
          state = [
            ...state,
            PresenceData(
              userId: userId,
              route: [newPoint],
              color: color,
              lastSeenAt: seenAt,
            ),
          ];
        }
      }
    } catch (e) {
      debugPrint('Error parsing incoming WS message: $e');
    }
  }

  void _pruneStalePresence() {
    final cutoff = DateTime.now().toUtc().subtract(_presenceStaleAfter);
    final filtered = state.where((entry) => entry.lastSeenAt.isAfter(cutoff)).toList();
    if (filtered.length != state.length) {
      state = filtered;
    }
  }
}

final presenceLinesProvider =
    NotifierProvider<PresenceLinesNotifier, List<PresenceData>>(
      PresenceLinesNotifier.new,
    );

final contestedZonesProvider = Provider<List<ContestedZone>>((ref) {
  final presenceLines = ref.watch(presenceLinesProvider);
  final workout = ref.watch(workoutControllerProvider);
  final initialPosition = ref.watch(userInitialPositionProvider).asData?.value;
  final currentUserId = ref.watch(currentUserSessionProvider);

  final runnerPoints = <String, LatLng>{};
  for (final entry in presenceLines) {
    if (entry.route.isNotEmpty) {
      runnerPoints[entry.userId] = entry.route.last;
    }
  }

  if (workout.state == WorkoutState.running && workout.points.isNotEmpty) {
    final own = workout.points.last;
    runnerPoints[currentUserId ?? '__self__'] = LatLng(own.lat, own.lng);
  }

  if (runnerPoints.isEmpty || initialPosition == null) {
    return const [];
  }

  final viewer = LatLng(initialPosition.latitude, initialPosition.longitude);
  final nearPoints = runnerPoints.values.where((point) {
    final distance = Geolocator.distanceBetween(
      viewer.latitude,
      viewer.longitude,
      point.latitude,
      point.longitude,
    );
    return distance <= 20000;
  }).toList();

  if (nearPoints.isEmpty) {
    return const [];
  }

  final clusters = <List<LatLng>>[];
  for (final point in nearPoints) {
    List<LatLng>? matchedCluster;
    for (final cluster in clusters) {
      final clusterCenter = _averageLatLng(cluster);
      final distance = Geolocator.distanceBetween(
        clusterCenter.latitude,
        clusterCenter.longitude,
        point.latitude,
        point.longitude,
      );
      if (distance <= 1000) {
        matchedCluster = cluster;
        break;
      }
    }
    if (matchedCluster != null) {
      matchedCluster.add(point);
    } else {
      clusters.add([point]);
    }
  }

  return clusters.map((cluster) {
    final count = cluster.length;
    final center = _averageLatLng(cluster);
    final severity = count >= 5 ? 'HIGH' : count >= 3 ? 'MEDIUM' : 'LOW';
    final colorHex = count >= 5
        ? '#FF3B30'
        : count >= 3
            ? '#FF9500'
            : '#FFD60A';
    final radiusMeters = count >= 5 ? 2000.0 : 500.0;
    return ContestedZone(
      center: center,
      radiusMeters: radiusMeters,
      runnerCount: count,
      colorHex: colorHex,
      severity: severity,
    );
  }).toList();
});

LatLng _averageLatLng(List<LatLng> points) {
  var lat = 0.0;
  var lng = 0.0;
  for (final point in points) {
    lat += point.latitude;
    lng += point.longitude;
  }
  return LatLng(lat / points.length, lng / points.length);
}
