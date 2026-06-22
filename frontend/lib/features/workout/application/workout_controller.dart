import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:uuid/uuid.dart';
import '../../../core/domain/models/workout_session.dart';
import '../../../core/domain/models/position_sample.dart';
import '../../../core/services/lari_sync_service.dart';
import '../../../dev/dev_providers.dart';
import '../../auth/application/auth_controller.dart';
import '../../profile/application/profile_controller.dart';
import '../../history/application/history_controller.dart';
import '../../map/application/territory_controller.dart';

final workoutControllerProvider = NotifierProvider<WorkoutController, WorkoutSession>(() {
  return WorkoutController();
});

class WorkoutController extends Notifier<WorkoutSession> {
  static const _uuid = Uuid();
  StreamSubscription? _positionSub;
  Timer? _timer;

  @override
  WorkoutSession build() {
    ref.onDispose(() {
      _timer?.cancel();
      _positionSub?.cancel();
    });

    return _idleState();
  }

  WorkoutSession _idleState() => WorkoutSession(
    id: _uuid.v4(),
    userId: ref.read(currentUserSessionProvider) ?? '',
    startedAt: DateTime.now(),
    state: WorkoutState.idle,
    points: const [],
  );

  List<PositionSample> get route => state.points;

  void start() {
    final user = ref.read(currentUserSessionProvider);
    final profile = ref.read(profileControllerProvider).value;
    if (user == null) return;

    state = WorkoutSession(
      id: _uuid.v4(),
      userId: user,
      guildId: profile?.guildId,
      startedAt: DateTime.now(),
      state: WorkoutState.running,
      points: const [],
    );

    _startTracking();

    // 🔥 CAPTURE STARTING POINT IMMEDIATELY
    Geolocator.getCurrentPosition().then((pos) {
      if (state.state == WorkoutState.running && state.points.isEmpty) {
        final startSample = PositionSample(
          ts: DateTime.now(),
          lat: pos.latitude,
          lng: pos.longitude,
          accuracyMeters: pos.accuracy,
        );
        state = state.copyWith(points: [startSample]);
      }
    });
  }

  void pause() {
    _timer?.cancel();
    _positionSub?.cancel();
    state = state.copyWith(state: WorkoutState.paused);
  }

  void resume() {
    state = state.copyWith(state: WorkoutState.running);
    _startTracking();
  }

  Future<void> end() async {
    try {
      debugPrint('WorkoutController: Ending session ${state.id}');
      
      // Guard: discard sessions with insufficient GPS data — do not inject dummy coords.
      if (state.points.length < 2) {
        debugPrint('WorkoutController: Session discarded — insufficient GPS points (${state.points.length}). Minimum 2 required.');
        pause();
        state = _idleState();
        return;
      }

      pause();
      
      // Hand off to sync service
      final syncService = ref.read(lariSyncServiceProvider);
      debugPrint('WorkoutController: Enqueuing workout to Hive...');
      await syncService.enqueueWorkout(state);
      
      debugPrint('WorkoutController: Triggering background sync queue...');
      // Fire and forget background sync
      syncService.processQueue();
      
      // 🔥 UPDATE MAP & HISTORY UI immediately
      debugPrint('WorkoutController: Invalidating providers...');
      ref.invalidate(userHistoryProvider);
      ref.invalidate(allTerritoriesProvider);
      
      debugPrint('WorkoutController: Resetting to idle state.');
      state = _idleState();
    } catch (e, stack) {
      debugPrint('WorkoutController_ERROR: Failed to end session cleanly: $e\n$stack');
      rethrow; // Let the UI handle it
    }
  }

  void _startTracking() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (state.state == WorkoutState.running) {
        state = state.copyWith(durationSeconds: state.durationSeconds + 1);
      }
    });

    _positionSub?.cancel();
    _positionSub = ref.read(trackingSourceProvider).watchPosition().listen((sample) {
      if (state.state != WorkoutState.running) return;
      
      final points = List<PositionSample>.from(state.points);
      double dist = state.distanceMeters;

      if (points.isNotEmpty) {
        final last = points.last;
        final gap = Geolocator.distanceBetween(last.lat, last.lng, sample.lat, sample.lng);
        
        // DEV MODE: Speed limiter disabled (GEMINI.md)
        dist += gap;
      }
      
      points.add(sample);

      // Determine if loop is closed dynamically
      bool isClosed = false;
      if (points.length >= 3) {
        final first = points.first;
        final last = points.last;
        final gapToStart = Geolocator.distanceBetween(first.lat, first.lng, last.lat, last.lng);
        
        double maxDisplacement = 0.0;
        for (final p in points) {
          final d = Geolocator.distanceBetween(first.lat, first.lng, p.lat, p.lng);
          if (d > maxDisplacement) {
            maxDisplacement = d;
          }
        }

        // Must displace by more than 30 meters and return within 25 meters to close loop
        isClosed = maxDisplacement > 30.0 && gapToStart <= 25.0;
      }
      
      state = state.copyWith(
        points: points,
        distanceMeters: dist,
        isLoopClosed: isClosed,
      );
    });
  }
}
