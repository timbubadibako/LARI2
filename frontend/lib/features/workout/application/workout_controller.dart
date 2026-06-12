import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart'; // For distance calculation
import '../../../core/domain/models/workout_session.dart';
import '../../../core/domain/models/position_sample.dart';
import '../../../core/domain/repositories/tracking_source.dart';
import '../../../core/services/workout_storage_service.dart';
import '../../../core/services/sync_queue_service.dart';
import '../../../dev/dev_providers.dart';

final workoutControllerProvider =
    NotifierProvider<WorkoutController, WorkoutSession>(() {
      return WorkoutController();
    });

class WorkoutController extends Notifier<WorkoutSession> {
  StreamSubscription<PositionSample>? _positionSub;
  Timer? _timer;
  bool _skipNextDistance = false;
  DateTime _lastMovementTime = DateTime.now();
  static const Duration autoPauseThreshold = Duration(seconds: 15);

  @override
  WorkoutSession build() {
    return WorkoutSession(
      id: 'workout_${DateTime.now().millisecondsSinceEpoch}',
      userId: 'local_user', // dummy
      startedAt: DateTime.now(),
    );
  }

  TrackingSource get _trackingSource => ref.read(trackingSourceProvider);

  List<PositionSample> get route => state.points;

  void start() {
    // Reset state for a fresh workout
    state = WorkoutSession(
      id: 'workout_${DateTime.now().millisecondsSinceEpoch}',
      userId: 'local_user', // dummy
      startedAt: DateTime.now(),
      state: WorkoutState.running,
      points: const [],
      avgPaceSecondsPerKm: null,
    );

    _skipNextDistance = false;
    _lastMovementTime = DateTime.now();
    _startTimer();
    _startPositionSubscription();
  }

  void pause({bool isAuto = false}) {
    _timer?.cancel();
    _positionSub?.cancel();
    state = state.copyWith(state: WorkoutState.paused);
  }

  void resume() {
    state = state.copyWith(state: WorkoutState.running);
    _skipNextDistance = state.points.isNotEmpty;
    _lastMovementTime = DateTime.now();
    _startTimer();
    _startPositionSubscription(skipNextDistance: _skipNextDistance);
  }

  void refreshTrackingSource() {
    if (state.state != WorkoutState.running) return;
    _startPositionSubscription(skipNextDistance: true);
  }

  Future<void> end() async {
    _timer?.cancel();
    _positionSub?.cancel();
    state = state.copyWith(state: WorkoutState.ended, endedAt: DateTime.now());
    await ref.read(workoutStorageServiceProvider).saveWorkout(state);
  }

  void toggleGhostMode() {
    state = state.copyWith(ghostMode: !state.ghostMode);
  }

  void updateTitleAndNotes(String title, String notes) {
    state = state.copyWith(title: title, notes: notes);
  }

  Future<void> saveAndEnqueueSync() async {
    // Atomic: write to local DB then enqueue upload
    await ref.read(workoutStorageServiceProvider).saveWorkout(state);
    await ref.read(syncQueueServiceProvider).enqueueWorkout(state);
    
    // Attempt to process queue immediately if we have connection
    ref.read(syncQueueServiceProvider).processQueue();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state.state == WorkoutState.running) {
        state = state.copyWith(durationSeconds: state.durationSeconds + 1);
        _updateDerivedMetrics();

        // Auto-pause logic
        if (DateTime.now().difference(_lastMovementTime) > autoPauseThreshold) {
          pause();
        }

        // Periodic local save (e.g., every 30 seconds)
        if (state.durationSeconds % 30 == 0) {
          ref.read(workoutStorageServiceProvider).saveWorkout(state);
        }
      }
    });
  }

  void _startPositionSubscription({bool skipNextDistance = false}) {
    _positionSub?.cancel();
    _skipNextDistance = skipNextDistance;

    _positionSub = _trackingSource.watchPosition().listen((sample) {
      if (state.state == WorkoutState.running) {
        _processNewPosition(sample);
      }
    });
  }

  void _processNewPosition(PositionSample sample) {
    if (state.state != WorkoutState.running) return;

    final currentPoints = List<PositionSample>.from(state.points);
    double newDistance = state.distanceMeters;
    bool loopClosed = false;

    if (currentPoints.isNotEmpty) {
      if (_skipNextDistance) {
        _skipNextDistance = false;
      } else {
        final last = currentPoints.last;
        final distance = Geolocator.distanceBetween(
          last.lat,
          last.lng,
          sample.lat,
          sample.lng,
        );
        newDistance += distance;
        
        // Update last movement if we moved a reasonable distance
        if (distance > 1.0) {
          _lastMovementTime = DateTime.now();
        }
      }

      // Loop detection: Current point vs Start point
      // Only check if we've moved at least 100m to avoid instant detection
      if (newDistance > 100) {
        final first = currentPoints.first;
        final distToStart = Geolocator.distanceBetween(
          sample.lat,
          sample.lng,
          first.lat,
          first.lng,
        );
        if (distToStart < 20) {
          loopClosed = true;
        }
      }
    } else {
      _lastMovementTime = DateTime.now();
    }

    // Fallback movement check via speed
    if (sample.speedMps != null && sample.speedMps! > 0.5) {
      _lastMovementTime = DateTime.now();
    }

    currentPoints.add(sample);

    state = state.copyWith(
      points: currentPoints,
      distanceMeters: newDistance,
      isLoopClosed: loopClosed,
    );

    _updateDerivedMetrics();
  }

  void claimTerritory() {
    if (!state.isLoopClosed) return;
    
    // In a real app, this would send the polygon to Supabase
    // For now, we'll just reset loop state or trigger some UI feedback
    state = state.copyWith(isLoopClosed: false);
    
    // Trigger haptic feedback
    HapticFeedback.mediumImpact();
  }

  void _updateDerivedMetrics() {
    double? pace;
    if (state.distanceMeters > 0) {
      pace = state.durationSeconds / (state.distanceMeters / 1000.0);
    }

    // Very dummy calorie estimate: ~1 kcal per kg per km. Assuming 70kg.
    double calories = 70.0 * (state.distanceMeters / 1000.0);

    state = state.copyWith(
      avgPaceSecondsPerKm: pace,
      caloriesEstimate: calories,
    );
  }
}
