import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/shared_preferences_provider.dart';

const String kIntegrationConnectionPrefix = 'profile.integration.';

class IntegrationConnectionNotifier extends Notifier<Map<String, bool>> {
  @override
  Map<String, bool> build() {
    final prefs = ref.read(sharedPreferencesProvider);
    return {
      'health': prefs.getBool('${kIntegrationConnectionPrefix}health') ?? false,
      'strava': prefs.getBool('${kIntegrationConnectionPrefix}strava') ?? false,
      'garmin': prefs.getBool('${kIntegrationConnectionPrefix}garmin') ?? false,
      'other': prefs.getBool('${kIntegrationConnectionPrefix}other') ?? false,
    };
  }

  Future<void> setConnected(String serviceId, bool connected) async {
    await ref
        .read(sharedPreferencesProvider)
        .setBool('$kIntegrationConnectionPrefix$serviceId', connected);

    state = {...state, serviceId: connected};
  }

  Future<void> toggle(String serviceId) async {
    await setConnected(serviceId, !(state[serviceId] ?? false));
  }
}

final integrationConnectionsProvider =
    NotifierProvider<IntegrationConnectionNotifier, Map<String, bool>>(
      IntegrationConnectionNotifier.new,
    );
