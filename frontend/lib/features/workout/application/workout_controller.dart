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
  static const double _autoPauseSpeedThresholdMps = 0.45;
  static const int _autoPauseDelaySeconds = 15;
  static const double _loopClosureToleranceMeters = 25.0;
  static const double _minLoopDisplacementMeters = 30.0;
  StreamSubscription? _positionSub;
  Timer? _timer;
  PositionSample? _lastObservedSample;
  PositionSample? _resumeBaselineSample;
  int _stationarySeconds = 0;
  int _movingSeconds = 0;

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
    _stationarySeconds = 0;
    _movingSeconds = 0;
    _resumeBaselineSample = null;
    _lastObservedSample = null;

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
        _lastObservedSample = startSample;
      }
    });
  }

  void pause() {
    _timer?.cancel();
    _positionSub?.cancel();
    _resumeBaselineSample = null;
    _stationarySeconds = 0;
    _movingSeconds = 0;
    state = state.copyWith(state: WorkoutState.paused, isAutoPaused: false);
  }

  void resume() {
    _resumeBaselineSample = null;
    _stationarySeconds = 0;
    _movingSeconds = 0;
    state = state.copyWith(state: WorkoutState.running, isAutoPaused: false);
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
      final lastObserved = _lastObservedSample;
      _lastObservedSample = sample;

      if (state.state == WorkoutState.paused && state.isAutoPaused) {
        _handleAutoPausedSample(lastObserved, sample);
        return;
      }

      if (state.state != WorkoutState.running) return;

      final points = List<PositionSample>.from(state.points);
      double dist = state.distanceMeters;
      final lastPoint = points.isNotEmpty ? points.last : null;
      final motion = _estimateMotion(lastObserved, sample);

      if (motion != null && motion.speedMps < _autoPauseSpeedThresholdMps) {
        _stationarySeconds += motion.elapsedSeconds;
        _movingSeconds = 0;
      } else if (motion != null) {
        _stationarySeconds = 0;
        _movingSeconds += motion.elapsedSeconds;
      }

      if (_stationarySeconds >= _autoPauseDelaySeconds) {
        _resumeBaselineSample = sample;
        _movingSeconds = 0;
        state = state.copyWith(state: WorkoutState.paused, isAutoPaused: true);
        return;
      }

      double gapFromPrevious = 0.0;
      if (_resumeBaselineSample != null) {
        // TODO(production): model segmented routes so resume does not visually connect long gaps.
        gapFromPrevious = 0.0;
        _resumeBaselineSample = null;
      } else if (lastPoint != null) {
        gapFromPrevious = Geolocator.distanceBetween(lastPoint.lat, lastPoint.lng, sample.lat, sample.lng);
      }

      if (lastPoint != null) {
        // TODO(production): restore frontend speed limiter before release.
        // final elapsedSeconds = motion?.elapsedSeconds ?? 0;
        // final speedMps = elapsedSeconds > 0 ? gapFromPrevious / elapsedSeconds : 0.0;
        // if (speedMps > 11.11) return; // ~40 km/h
        dist += gapFromPrevious;
      }

      points.add(sample);

      final isClosed = _findLatestClosedLoopStartIndex(points) != null;
      
      state = state.copyWith(
        points: points,
        distanceMeters: dist,
        isLoopClosed: isClosed,
        isAutoPaused: false,
      );
    });
  }

  int? _findLatestClosedLoopStartIndex(List<PositionSample> points) {
    if (points.length < 3) return null;

    final last = points.last;
    for (int i = points.length - 3; i >= 0; i--) {
      final anchor = points[i];
      final gapMeters = Geolocator.distanceBetween(
        anchor.lat,
        anchor.lng,
        last.lat,
        last.lng,
      );
      if (gapMeters > _loopClosureToleranceMeters) {
        continue;
      }

      double maxDisplacement = 0.0;
      for (int j = i + 1; j < points.length; j++) {
        final displacement = Geolocator.distanceBetween(
          anchor.lat,
          anchor.lng,
          points[j].lat,
          points[j].lng,
        );
        if (displacement > maxDisplacement) {
          maxDisplacement = displacement;
        }
      }

      if (maxDisplacement > _minLoopDisplacementMeters) {
        return i;
      }
    }
    return null;
  }

  void _handleAutoPausedSample(PositionSample? lastObserved, PositionSample sample) {
    final motion = _estimateMotion(lastObserved, sample);
    if (motion != null && motion.speedMps >= _autoPauseSpeedThresholdMps) {
      _movingSeconds += motion.elapsedSeconds;
      _stationarySeconds = 0;
    } else if (motion != null) {
      _movingSeconds = 0;
      _stationarySeconds += motion.elapsedSeconds;
    }

    if (_movingSeconds >= _autoPauseDelaySeconds) {
      _resumeBaselineSample = sample;
      _movingSeconds = 0;
      _stationarySeconds = 0;
      state = state.copyWith(state: WorkoutState.running, isAutoPaused: false);
    }
  }

  ({int elapsedSeconds, double speedMps})? _estimateMotion(
    PositionSample? previous,
    PositionSample current,
  ) {
    if (previous == null) return null;

    final elapsedSeconds = current.ts.difference(previous.ts).inSeconds;
    if (elapsedSeconds <= 0) return null;

    final gapMeters = Geolocator.distanceBetween(
      previous.lat,
      previous.lng,
      current.lat,
      current.lng,
    );
    return (elapsedSeconds: elapsedSeconds, speedMps: gapMeters / elapsedSeconds);
  }
}
