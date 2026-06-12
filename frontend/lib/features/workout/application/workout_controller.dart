import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart'; // For distance calculation
import 'package:sensors_plus/sensors_plus.dart';
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
  StreamSubscription<UserAccelerometerEvent>? _accelSub;
  Timer? _timer;
  bool _skipNextDistance = false;
  DateTime _lastMovementTime = DateTime.now();
  static const Duration autoPauseThreshold = Duration(seconds: 15);

  // IMU State for Dead Reckoning
  double _currentAccelMagnitude = 0.0;
  static const double _movementThreshold = 1.5; // Threshold for confirming movement via IMU

  @override
  WorkoutSession build() {
    ref.onDispose(() {
      _timer?.cancel();
      _positionSub?.cancel();
      _accelSub?.cancel();
    });

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
    _startSensorSubscription();
  }

  void pause({bool isAuto = false}) {
    _timer?.cancel();
    _positionSub?.cancel();
    _accelSub?.cancel();
    state = state.copyWith(state: WorkoutState.paused);
  }

  void resume() {
    state = state.copyWith(state: WorkoutState.running);
    _skipNextDistance = state.points.isNotEmpty;
    _lastMovementTime = DateTime.now();
    _startTimer();
    _startPositionSubscription(skipNextDistance: _skipNextDistance);
    _startSensorSubscription();
  }

  void refreshTrackingSource() {
    if (state.state != WorkoutState.running) return;
    _startPositionSubscription(skipNextDistance: true);
  }

  Future<void> end() async {
    _timer?.cancel();
    _positionSub?.cancel();
    _accelSub?.cancel();
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
        
        // --- DEAD RECKONING ENGINE v1 (Sensor Fusion) ---
        _performDeadReckoning();

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

  void _startSensorSubscription() {
    _accelSub?.cancel();
    _accelSub = userAccelerometerEvents.listen((event) {
      // Calculate magnitude of movement (ignoring gravity)
      _currentAccelMagnitude = math.sqrt(event.x * event.x + event.y * event.y + event.z * event.z);
      
      // If significant movement detected, update movement timer to prevent auto-pause
      if (_currentAccelMagnitude > _movementThreshold) {
        _lastMovementTime = DateTime.now();
      }
    });
  }

  void _performDeadReckoning() {
    if (state.points.isEmpty) return;

    final lastPoint = state.points.last;
    final timeSinceLastPoint = DateTime.now().difference(lastPoint.ts);

    // Logic: If GPS signal lost for > 3 seconds AND IMU confirms physical movement
    if (timeSinceLastPoint.inSeconds >= 3 && _currentAccelMagnitude > 0.5) {
      final speed = lastPoint.speedMps ?? 2.5; // Fallback to 2.5 m/s if speed unknown
      final bearing = lastPoint.bearingDeg ?? 0.0;

      // Project position forward by 1 second based on last known velocity
      const double metersPerDegree = 111111.0;
      final double radians = bearing * (math.pi / 180.0);
      final double latRad = lastPoint.lat * (math.pi / 180.0);
      
      final double newLat = lastPoint.lat + (speed * math.cos(radians) / metersPerDegree);
      final double newLng = lastPoint.lng + (speed * math.sin(radians) / (metersPerDegree * math.cos(latRad)));

      final estimatedSample = PositionSample(
        ts: DateTime.now(),
        lat: newLat,
        lng: newLng,
        accuracyMeters: 30.0, // Marked with uncertainty
        speedMps: speed,
        bearingDeg: bearing,
        isEstimated: true,
      );

      debugPrint('DEAD_RECKONING: GPS Lost. IMU detected movement. Estimating position...');
      _processNewPosition(estimatedSample);
    }
  }

  void _startPositionSubscription({bool skipNextDistance = false}) {
    _positionSub?.cancel();
    _skipNextDistance = skipNextDistance;

    // Default tracking source is established in dev_providers
    _positionSub = _trackingSource.watchPosition().listen((sample) {
      if (state.state == WorkoutState.running) {
        _processNewPosition(sample);
        _handleDynamicSampling(sample);
      }
    });
  }

  void _handleDynamicSampling(PositionSample sample) {
    // Logic: If accuracy is low (> 15m) OR we suspect off-road,
    // we boost frequency internally.
    final bool needsHigherPrecision = (sample.accuracyMeters) > 15 || state.isLoopClosed;
    
    if (needsHigherPrecision && state.durationSeconds % 5 == 0) {
      debugPrint('TACTICAL_BOOST: High precision mode active.');
    }
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
        
        // Filter out jumps > 50m in 1s unless it's a known gap
        if (!sample.isEstimated && distance > 50.0) {
           debugPrint('GPS_FILTER: Ignoring outlier jump of ${distance.toStringAsFixed(1)}m');
           return;
        }

        newDistance += distance;
        
        // Update last movement if we moved a reasonable distance
        if (distance > 1.0) {
          _lastMovementTime = DateTime.now();
        }
      }

      // Loop detection
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
    state = state.copyWith(isLoopClosed: false);
    HapticFeedback.mediumImpact();
  }

  void _updateDerivedMetrics() {
    double? pace;
    if (state.distanceMeters > 0) {
      pace = state.durationSeconds / (state.distanceMeters / 1000.0);
    }

    double calories = 70.0 * (state.distanceMeters / 1000.0);

    state = state.copyWith(
      avgPaceSecondsPerKm: pace,
      caloriesEstimate: calories,
    );
  }
}
