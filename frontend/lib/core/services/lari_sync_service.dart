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
  final Ref _ref;

  LariSyncService(this._box, this._ref);

  String get _baseUrl => _ref.read(baseUrlProvider);
  bool get _logEnabled => _ref.read(lariDevLogEnabledProvider);

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
        'timestamp': p.ts.toUtc().toIso8601String(),
        'accuracy': p.accuracyMeters,
      }).toList(),
      'status': workout.isLoopClosed ? 'captured' : 'finished',
      'created_at': workout.startedAt.toUtc().toIso8601String(),
    };

    await _box.put(workout.id, {
      'id': workout.id,
      'status': 'pending',
      'payload': payload,
    });
    
    LariLogger.log(_logEnabled, 'SYNC_QUEUE: Run ${workout.id} enqueued.');
  }

  Future<bool> processQueue() async {
    final pending = _box.values.where((t) => t['status'] == 'pending').toList();
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
          updated['status'] = 'synced';
          await _box.put(id, updated);
          LariLogger.log(_logEnabled, 'SYNC_SUCCESS: $id');
        } else if (response.statusCode == 400) {
          // 🔥 AUTO-CLEANUP: If data is invalid (400), delete it so it stops failing
          await _box.delete(id);
          debugPrint('SYNC_CLEANUP: Removed invalid task $id from queue.');
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

  Future<void> clearQueue() async {
    await _box.clear();
    LariLogger.log(_logEnabled, 'SYNC_QUEUE: Entire queue cleared.');
  }

  List<Map<String, dynamic>> getAllMissions() {
    return _box.values
        .map((e) => Map<String, dynamic>.from(e))
        .toList()
        .reversed
        .toList();
  }
}

final syncBoxProvider = Provider<Box<dynamic>>((ref) {
  throw UnimplementedError('Initialize syncBoxProvider in main.dart');
});

final lariSyncServiceProvider = Provider<LariSyncService>((ref) {
  final box = ref.watch(syncBoxProvider);
  return LariSyncService(box, ref);
});
