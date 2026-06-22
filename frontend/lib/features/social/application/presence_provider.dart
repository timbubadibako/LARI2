import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../../../core/config/api_config.dart';
import '../../../core/services/shared_preferences_provider.dart';
import '../../auth/application/auth_controller.dart';
import '../../profile/application/profile_controller.dart';
import '../../workout/application/workout_controller.dart';
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

  PresenceData({
    required this.userId,
    required this.route,
    required this.color,
  });
}

class PresenceLinesNotifier extends Notifier<List<PresenceData>> {
  StreamSubscription? _wsSubscription;
  Timer? _reconnectTimer;

  @override
  List<PresenceData> build() {
    final optedIn = ref.watch(presenceOptInProvider);
    final userId = ref.watch(currentUserSessionProvider);
    
    if (!optedIn || userId == null) {
      _wsSubscription?.cancel();
      _reconnectTimer?.cancel();
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
            ),
          ];
        }
      }
    } catch (e) {
      debugPrint('Error parsing incoming WS message: $e');
    }
  }
}

final presenceLinesProvider =
    NotifierProvider<PresenceLinesNotifier, List<PresenceData>>(
      PresenceLinesNotifier.new,
    );
