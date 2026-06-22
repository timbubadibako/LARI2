import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';

import '../core/domain/models/position_sample.dart';
import '../core/domain/repositories/tracking_source.dart';
import '../core/services/location_service.dart';
import 'fake_location_service.dart';
import '../core/services/shared_preferences_provider.dart';

enum AppMode { dev, prod }

const String kUseFakeLocationPrefKey = 'dev.useFakeLocation';
const String kFakeLocationConfigPrefKey = 'dev.fakeLocationConfig';

const bool kAllowDevMenuInRelease = bool.fromEnvironment(
  'LARI-LARI_ALLOW_DEV_MENU',
  defaultValue: false,
);
const bool kAllowFakeGpsInRelease = bool.fromEnvironment(
  'LARI-LARI_ALLOW_FAKE_GPS',
  defaultValue: false,
);

final appModeProvider = Provider<AppMode>((ref) {
  if (kReleaseMode && !kAllowDevMenuInRelease && !kAllowFakeGpsInRelease) {
    return AppMode.prod;
  }

  if (kDebugMode || kAllowDevMenuInRelease || kAllowFakeGpsInRelease) {
    return AppMode.dev;
  }

  return AppMode.prod;
});

final devMenuVisibleProvider = Provider<bool>((ref) {
  return ref.watch(appModeProvider) == AppMode.dev;
});

class LariDevLogEnabledNotifier extends Notifier<bool> {
  @override
  bool build() => false;
  void toggle(bool value) => state = value;
}

final lariDevLogEnabledProvider = NotifierProvider<LariDevLogEnabledNotifier, bool>(() {
  return LariDevLogEnabledNotifier();
});

class UseFakeLocationPrefNotifier extends Notifier<bool> {
  @override
  bool build() {
    return ref
            .read(sharedPreferencesProvider)
            .getBool(kUseFakeLocationPrefKey) ??
        false;
  }

  Future<void> setEnabled(bool enabled) async {
    await ref
        .read(sharedPreferencesProvider)
        .setBool(kUseFakeLocationPrefKey, enabled);
    state = enabled;
  }
}

final useFakeLocationPrefProvider =
    NotifierProvider<UseFakeLocationPrefNotifier, bool>(
      UseFakeLocationPrefNotifier.new,
    );

class DevFakeLocationConfigNotifier extends Notifier<FakeLocationConfig> {
  @override
  FakeLocationConfig build() {
    final prefs = ref.read(sharedPreferencesProvider);
    // Since I updated the model, let's just default to fresh if it fails
    return const FakeLocationConfig.defaults();
  }

  Future<void> update(FakeLocationConfig config) async {
    // We skip saving to prefs for now to avoid json mismatch errors until dev cycle stabilizes
    state = config;
  }

  Future<void> applyPreset(FakeLocationConfig config) async {
    await update(config);
  }

  Future<bool> syncWithRealPosition() async {
    try {
      final enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) return false;

      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        return false;
      }

      final position = await Geolocator.getCurrentPosition();
      await update(
        state.copyWith(
          centerLat: position.latitude,
          centerLng: position.longitude,
        ),
      );
      return true;
    } catch (e) {
      debugPrint('SYNC_REAL_POS_ERROR: $e');
      return false;
    }
  }

  Future<void> setField({
    double? centerLat,
    double? centerLng,
    double? loopDistanceMeters,
    int? durationSeconds,
    Duration? sampleInterval,
    double? accuracyMeanMeters,
    double? accuracyStdMeters,
    bool? includeJitter,
    bool? loopForever,
    double? startAngleDeg,
    bool? variablePace,
    bool? simulateDropouts,
    double? dropoutProbability,
    bool? showRawPoints,
    bool? showDisplayPoints,
    bool? showSampleRate,
    bool? showLastAccuracy,
    bool? showCumulativeDistance,
    FakeScenario? scenario,
  }) async {
    await update(
      state.copyWith(
        centerLat: centerLat,
        centerLng: centerLng,
        loopDistanceMeters: loopDistanceMeters,
        durationSeconds: durationSeconds,
        sampleInterval: sampleInterval,
        accuracyMeanMeters: accuracyMeanMeters,
        accuracyStdMeters: accuracyStdMeters,
        includeJitter: includeJitter,
        loopForever: loopForever,
        startAngleDeg: startAngleDeg,
        variablePace: variablePace,
        simulateDropouts: simulateDropouts,
        dropoutProbability: dropoutProbability,
        scenario: scenario,
      ),
    );
  }
}

final devFakeLocationConfigProvider =
    NotifierProvider<DevFakeLocationConfigNotifier, FakeLocationConfig>(
      DevFakeLocationConfigNotifier.new,
    );

final fakeLocationActiveProvider = Provider<bool>((ref) {
  return ref.watch(appModeProvider) == AppMode.dev &&
      ref.watch(useFakeLocationPrefProvider);
});

const String kUseMockBackendPrefKey = 'dev.useMockBackend';
const String kUseLocalBackendPrefKey = 'dev.useLocalBackend';

class UseMockBackendPrefNotifier extends Notifier<bool> {
  @override
  bool build() {
    return ref
            .read(sharedPreferencesProvider)
            .getBool(kUseMockBackendPrefKey) ??
        false;
  }

  Future<void> setEnabled(bool enabled) async {
    await ref
        .read(sharedPreferencesProvider)
        .setBool(kUseMockBackendPrefKey, enabled);
    state = enabled;
  }
}

class UseLocalBackendPrefNotifier extends Notifier<bool> {
  @override
  bool build() {
    return ref
            .read(sharedPreferencesProvider)
            .getBool(kUseLocalBackendPrefKey) ??
        true; // Default to Local (untuk tes Supabase)
  }

  Future<void> setEnabled(bool enabled) async {
    await ref
        .read(sharedPreferencesProvider)
        .setBool(kUseLocalBackendPrefKey, enabled);
    state = enabled;
  }
}

final useMockBackendPrefProvider =
    NotifierProvider<UseMockBackendPrefNotifier, bool>(
      UseMockBackendPrefNotifier.new,
    );

final useLocalBackendPrefProvider =
    NotifierProvider<UseLocalBackendPrefNotifier, bool>(
      UseLocalBackendPrefNotifier.new,
    );

final mockBackendActiveProvider = Provider<bool>((ref) {
  return ref.watch(appModeProvider) == AppMode.dev &&
      ref.watch(useMockBackendPrefProvider);
});

final localBackendActiveProvider = Provider<bool>((ref) {
  return ref.watch(appModeProvider) == AppMode.dev &&
      ref.watch(useLocalBackendPrefProvider);
});

final trackingSourceProvider = Provider<TrackingSource>((ref) {
  final appMode = ref.watch(appModeProvider);
  final useFake = ref.watch(useFakeLocationPrefProvider);

  if (appMode == AppMode.dev && useFake) {
    final fake = FakeLocationService(
      config: ref.watch(devFakeLocationConfigProvider),
    );
    ref.onDispose(fake.stop);
    return fake;
  }

  return LocationService();
});

final locationStreamProvider = StreamProvider.autoDispose<PositionSample>((
  ref,
) {
  return ref.watch(trackingSourceProvider).watchPosition();
});
