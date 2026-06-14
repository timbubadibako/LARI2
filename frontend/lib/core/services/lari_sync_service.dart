import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../domain/models/workout_session.dart';
import 'lari_logger.dart';
import '../../../dev/dev_providers.dart';

class LariSyncService {
  final Box<dynamic> _box;
  final ProviderContainer _container;

  LariSyncService(this._box, this._container);

  String get _baseUrl => _container.read(baseUrlProvider);
  bool get _logEnabled => _container.read(lariDevLogEnabledProvider);

  Future<void> enqueueWorkout(WorkoutSession workout) async {
    final payload = {
      'id': workout.id,
      'user_id': workout.userId,
      'guild_id': workout.guildId, // Null-safe
      'distance_km': workout.distanceMeters / 1000.0,
      'duration_sec': workout.durationSeconds,
      'points': workout.points.map((p) => {
        'lat': p.lat,
        'lng': p.lng,
        'timestamp': p.ts.toIso8601String(),
        'accuracy': p.accuracyMeters,
      }).toList(),
      'status': workout.isLoopClosed ? 'captured' : 'finished',
      'created_at': workout.startedAt.toIso8601String(),
    };

    await _box.put(workout.id, {
      'id': workout.id,
      'status': 'PENDING',
      'payload': payload,
    });
    
    LariLogger.log(_logEnabled, 'SYNC_QUEUE: Run ${workout.id} enqueued.');
  }

  Future<bool> processQueue() async {
    final pending = _box.values.where((t) => t['status'] == 'PENDING').toList();
    if (pending.isEmpty) return true;

    bool allSuccess = true;
    for (var task in pending) {
      try {
        final id = task['id'];
        debugPrint('SYNC_ATTEMPT: Uploading $id to $_baseUrl/sync/run');
        
        final response = await http.post(
          Uri.parse('$_baseUrl/sync/run'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(task['payload']),
        ).timeout(const Duration(seconds: 15));

        if (response.statusCode == 200 || response.statusCode == 201) {
          final updated = Map<String, dynamic>.from(task);
          updated['status'] = 'SYNCED';
          await _box.put(id, updated);
          LariLogger.log(_logEnabled, 'SYNC_SUCCESS: $id');
        } else {
          allSuccess = false;
          debugPrint('SYNC_FAILED: HTTP ${response.statusCode} - ${response.body}');
        }
      } catch (e) {
        allSuccess = false;
        debugPrint('SYNC_ERROR: $e');
      }
    }
    return allSuccess;
  }
}

final lariSyncServiceProvider = Provider<LariSyncService>((ref) {
  throw UnimplementedError('Initialize in main.dart');
});
