import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import 'package:lari_lari/features/workout/application/workout_controller.dart';
import 'package:lari_lari/core/domain/models/workout_session.dart';
import 'package:lari_lari/core/services/workout_storage_service.dart';
import 'package:lari_lari/core/services/lari_sync_service.dart';
import 'package:lari_lari/dev/dev_providers.dart';
import 'package:lari_lari/core/domain/models/position_sample.dart';
import 'package:lari_lari/core/domain/repositories/tracking_source.dart';
import 'package:lari_lari/core/services/shared_preferences_provider.dart';

class MockWorkoutStorage extends Mock implements WorkoutStorageService {}
class MockSyncQueue extends Mock implements LariSyncService {}
class MockTrackingSource extends Mock implements TrackingSource {}

class FakeGeolocatorPlatform extends GeolocatorPlatform {
  @override
  Future<Position> getCurrentPosition({
    LocationSettings? locationSettings,
  }) async {
    return Position(
      longitude: 106.827143,
      latitude: -6.225014,
      timestamp: DateTime.now(),
      accuracy: 5,
      altitude: 0,
      altitudeAccuracy: 0,
      heading: 0,
      headingAccuracy: 0,
      speed: 0,
      speedAccuracy: 0,
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    GeolocatorPlatform.instance = FakeGeolocatorPlatform();
    registerFallbackValue(WorkoutSession(id: '1', userId: '1', startedAt: DateTime.now()));
  });

  late ProviderContainer container;
  late MockWorkoutStorage mockStorage;
  late MockSyncQueue mockSync;
  late MockTrackingSource mockTracking;
  late StreamController<PositionSample> locationController;

  setUp(() async {
    SharedPreferences.setMockInitialValues({'auth.session_id': 'user_123'});
    final prefs = await SharedPreferences.getInstance();
    
    mockStorage = MockWorkoutStorage();
    mockSync = MockSyncQueue();
    mockTracking = MockTrackingSource();
    locationController = StreamController<PositionSample>.broadcast();

    when(() => mockTracking.watchPosition()).thenAnswer((_) => locationController.stream);
    when(() => mockStorage.saveWorkout(any())).thenAnswer((_) async {});
    when(() => mockSync.enqueueWorkout(any())).thenAnswer((_) async {});
    when(() => mockSync.processQueue()).thenAnswer((_) async => true);

    container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        workoutStorageServiceProvider.overrideWithValue(mockStorage),
        lariSyncServiceProvider.overrideWithValue(mockSync),
        trackingSourceProvider.overrideWithValue(mockTracking),
      ],
    );
  });

  tearDown(() {
    locationController.close();
    container.dispose();
  });

  group('Tactical Engine Headless Simulation', () {
    test('FULL_CYCLE: Start -> Move -> Loop -> End -> Sync', () async {
      final controller = container.read(workoutControllerProvider.notifier);

      // 1. START MISSION
      controller.start();
      expect(container.read(workoutControllerProvider).state, WorkoutState.running);

      // 2. EMIT START POINT (Point A)
      locationController.add(PositionSample(
        ts: DateTime.now(),
        lat: -6.225014,
        lng: 106.827143,
        accuracyMeters: 5,
      ));
      await Future.delayed(Duration.zero);

      // 3. EMIT MID POINT (Point B - >100m away)
      locationController.add(PositionSample(
        ts: DateTime.now().add(const Duration(seconds: 30)),
        lat: -6.226500, // Roughly 160m away
        lng: 106.828500,
        accuracyMeters: 5,
      ));
      await Future.delayed(Duration.zero);
      
      expect(container.read(workoutControllerProvider).distanceMeters > 100, true);
      expect(container.read(workoutControllerProvider).isLoopClosed, false);

      // 4. EMIT END POINT (Back to Point A)
      locationController.add(PositionSample(
        ts: DateTime.now().add(const Duration(seconds: 60)),
        lat: -6.225015, // within 20m (close to start point)
        lng: 106.827144,
        accuracyMeters: 5,
      ));
      await Future.delayed(Duration.zero);

      final state = container.read(workoutControllerProvider);
      expect(state.isLoopClosed, true, reason: 'Loop should be detected as closed');

      // 5. END MISSION (which enqueues and syncs automatically)
      await controller.end();
      expect(container.read(workoutControllerProvider).state, WorkoutState.idle);

      // 6. SYNC VERIFICATION
      verify(() => mockSync.enqueueWorkout(any())).called(1);
      verify(() => mockSync.processQueue()).called(1);
    });
  });
}
