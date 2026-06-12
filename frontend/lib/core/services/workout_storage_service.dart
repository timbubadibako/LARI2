import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../domain/models/workout_session.dart';

final workoutStorageServiceProvider = Provider<WorkoutStorageService>((ref) {
  // This will be overridden in main.dart
  throw UnimplementedError('WorkoutStorageService must be initialized');
});

class WorkoutStorageService {
  final Box<dynamic> _box;

  WorkoutStorageService(this._box);

  Future<void> saveWorkout(WorkoutSession workout) async {
    await _box.put(workout.id, {
      'id': workout.id,
      'startedAt': workout.startedAt.toIso8601String(),
      'endedAt': workout.endedAt?.toIso8601String(),
      'state': workout.state.name,
      'durationSeconds': workout.durationSeconds,
      'distanceMeters': workout.distanceMeters,
      'avgPaceSecondsPerKm': workout.avgPaceSecondsPerKm,
      'caloriesEstimate': workout.caloriesEstimate,
      'ghostMode': workout.ghostMode,
      'source': workout.source,
      'title': workout.title,
      'notes': workout.notes,
      'points': workout.points.map((point) => point.toJson()).toList(),
    });
  }

  List<Map<String, dynamic>> getAllWorkouts() {
    return _box.values
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  Future<void> clearAllWorkouts() async {
    await _box.clear();
  }
}
