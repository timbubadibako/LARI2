import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/shared_preferences_provider.dart';
import 'package:latlong2/latlong.dart';

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
    // TODO: Implement presence sync with Go backend
    state = newValue;
  }
}

final presenceOptInProvider = NotifierProvider<PresenceOptInNotifier, bool>(
  PresenceOptInNotifier.new,
);

class PresenceData {
  final String userId;
  final List<LatLng> route;

  PresenceData({required this.userId, required this.route});
}

class PresenceLinesNotifier extends Notifier<List<PresenceData>> {
  @override
  List<PresenceData> build() {
    final optedIn = ref.watch(presenceOptInProvider);
    if (!optedIn) return [];

    // Mock data for other users' presence lines
    return [
      PresenceData(
        userId: 'user_123',
        route: [
          const LatLng(-6.224014, 106.826143),
          const LatLng(-6.223014, 106.827143),
          const LatLng(-6.222014, 106.828143),
        ],
      ),
      PresenceData(
        userId: 'user_456',
        route: [
          const LatLng(-6.226014, 106.825143),
          const LatLng(-6.227014, 106.824143),
        ],
      ),
    ];
  }
}

final presenceLinesProvider =
    NotifierProvider<PresenceLinesNotifier, List<PresenceData>>(
      PresenceLinesNotifier.new,
    );
