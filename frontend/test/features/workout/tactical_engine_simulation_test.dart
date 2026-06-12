import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lari_lari/features/workout/application/workout_controller.dart';
import 'package:lari_lari/core/domain/models/workout_session.dart';
import 'package:lari_lari/core/services/workout_storage_service.dart';
import 'package:lari_lari/core/services/sync_queue_service.dart';
import 'package:lari_lari/dev/dev_providers.dart';
import 'package:lari_lari/core/domain/models/position_sample.dart';
import 'package:lari_lari/core/domain/repositories/tracking_source.dart';

class MockWorkoutStorage extends Mock implements WorkoutStorageService {}
class MockSyncQueue extends Mock implements SyncQueueService {}
class MockTrackingSource extends Mock implements TrackingSource {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    registerFallbackValue(WorkoutSession(id: '1', userId: '1', startedAt: DateTime.now()));
  });

  late ProviderContainer container;
  late MockWorkoutStorage mockStorage;
  late MockSyncQueue mockSync;
  late MockTrackingSource mockTracking;
  late StreamController<PositionSample> locationController;

  setUp(() {
    mockStorage = MockWorkoutStorage();
    mockSync = MockSyncQueue();
    mockTracking = MockTrackingSource();
    locationController = StreamController<PositionSample>.broadcast();

    when(() => mockTracking.watchPosition()).thenAnswer((_) => locationController.stream);
    when(() => mockStorage.saveWorkout(any())).thenAnswer((_) async {});
    when(() => mockSync.enqueueWorkout(any())).thenAnswer((_) async {});
    when(() => mockSync.processQueue()).thenAnswer((_) async {});

    container = ProviderContainer(
      overrides: [
        workoutStorageServiceProvider.overrideWithValue(mockStorage),
        syncQueueServiceProvider.overrideWithValue(mockSync),
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
        lat: -6.225015, // within 20m
        lng: 106.827144,
        accuracyMeters: 5,
      ));
      await Future.delayed(Duration.zero);

      final state = container.read(workoutControllerProvider);
      expect(state.isLoopClosed, true, reason: 'Loop should be detected as closed');

      // 5. END MISSION
      await controller.end();
      expect(container.read(workoutControllerProvider).state, WorkoutState.ended);
      verify(() => mockStorage.saveWorkout(any())).called(greaterThan(0));

      // 6. SYNC UPLINK
      await controller.saveAndEnqueueSync();
      verify(() => mockSync.enqueueWorkout(any())).called(1);
      verify(() => mockSync.processQueue()).called(1);
    });
  });
}
