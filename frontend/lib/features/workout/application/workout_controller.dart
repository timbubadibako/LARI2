import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:uuid/uuid.dart';
import '../../../core/domain/models/workout_session.dart';
import '../../../core/domain/models/position_sample.dart';
import '../../../core/services/lari_sync_service.dart';
import '../../../dev/dev_providers.dart';
import '../../auth/application/auth_controller.dart';
import '../../profile/application/profile_controller.dart';

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
    pause();
    // Hand off to sync service
    await ref.read(lariSyncServiceProvider).enqueueWorkout(state);
    ref.read(lariSyncServiceProvider).processQueue();
    
    state = _idleState();
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
      state = state.copyWith(points: points, distanceMeters: dist);
    });
  }
}
