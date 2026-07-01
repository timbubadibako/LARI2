import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../config/api_config.dart';
import '../domain/models/workout_session.dart';
import 'lari_logger.dart';
import 'http_client_provider.dart';
import '../../../dev/dev_providers.dart';

class LariSyncService {
  final Box<dynamic> _box;
  final Ref _ref;

  LariSyncService(this._box, this._ref) {
    cleanOldSynced();
  }

  Future<void> cleanOldSynced() async {
    try {
      final syncedKeys = _box.keys.where((key) {
        final val = _box.get(key);
        return val is Map && val['status'] == 'synced';
      }).toList();

      for (final key in syncedKeys) {
        await _box.delete(key);
      }
      if (syncedKeys.isNotEmpty) {
        LariLogger.log(_logEnabled, 'CLEANUP: Removed ${syncedKeys.length} legacy synced items from local database.');
      }
    } catch (e) {
      debugPrint('CLEANUP_ERROR: Failed to remove legacy synced items: $e');
    }
  }

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

    final client = _ref.read(httpClientProvider);
    const int maxRetries = 5;
    bool allSuccess = true;
    for (var task in pending) {
      try {
        final id = task['id'];
        final retryCount = (task['retry_count'] as int?) ?? 0;

        // Skip tasks that have exhausted retries
        if (retryCount >= maxRetries) {
          final quarantined = Map<String, dynamic>.from(task);
          quarantined['status'] = 'quarantined';
          quarantined['quarantine_reason'] = 'max_retries_exceeded';
          await _box.put(id, quarantined);
          LariLogger.log(_logEnabled, 'SYNC_QUARANTINE: $id exceeded max retries ($maxRetries).');
          continue;
        }

        debugPrint('SYNC_ATTEMPT: Uploading $id to $_baseUrl/sync/run (attempt ${retryCount + 1}/$maxRetries)');

        final response = await client.post(
          Uri.parse('$_baseUrl/sync/run'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(task['payload']),
        ).timeout(const Duration(seconds: 15));

        if (response.statusCode == 200 || response.statusCode == 201) {
          await _box.delete(id);
          LariLogger.log(_logEnabled, 'SYNC_SUCCESS: Run $id uploaded successfully. Deleted from local queue.');
        } else if (response.statusCode == 400) {
          // 400 = server rejected data as invalid. Quarantine (don't delete) for debugging.
          final quarantined = Map<String, dynamic>.from(task);
          quarantined['status'] = 'quarantined';
          quarantined['quarantine_reason'] = 'server_rejected_400: ${response.body}';
          quarantined['last_error'] = 'Server rejected run data';
          await _box.put(id, quarantined);
          LariLogger.log(_logEnabled, 'SYNC_QUARANTINE: $id rejected by server (400). Data preserved for review.');
        } else if (response.statusCode == 401) {
          allSuccess = false;
          final updated = Map<String, dynamic>.from(task);
          updated['retry_count'] = retryCount + 1;
          updated['last_error'] = 'Unauthorized. Session expired or token missing.';
          await _box.put(id, updated);
          LariLogger.log(
            _logEnabled,
            'SYNC_AUTH_FAILED: $id unauthorized on /sync/run',
            success: false,
            error: 'HTTP 401',
          );
        } else {
          // Transient error — increment retry count
          allSuccess = false;
          final updated = Map<String, dynamic>.from(task);
          updated['retry_count'] = retryCount + 1;
          updated['last_error'] = 'HTTP ${response.statusCode}: ${response.body}';
          await _box.put(id, updated);
          debugPrint('SYNC_FAILED: HTTP ${response.statusCode} for $id. Retry count: ${retryCount + 1}/$maxRetries.');
        }
      } catch (e) {
        allSuccess = false;
        final id = task['id'];
        final retryCount = (task['retry_count'] as int?) ?? 0;
        final updated = Map<String, dynamic>.from(task);
        updated['retry_count'] = retryCount + 1;
        updated['last_error'] = e.toString();
        await _box.put(id, updated);
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
