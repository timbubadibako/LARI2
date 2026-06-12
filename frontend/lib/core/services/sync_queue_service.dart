import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../domain/models/workout_session.dart';

class SyncQueueService {
  final Box<dynamic> _box;
  final String _boxName = 'sync_queue';
  final String _baseUrl = ApiConfig.baseUrl;

  SyncQueueService(this._box);

  static Future<SyncQueueService> init() async {
    final box = await Hive.openBox('sync_queue');
    return SyncQueueService(box);
  }

  // Save locally first, then enqueue
  Future<void> enqueueWorkout(WorkoutSession workout) async {
    await _box.put(workout.id, {
      'id': workout.id,
      'status': 'pending', // 'pending' or 'synced'
      'createdAt': workout.startedAt.toIso8601String(),
      'payload': {
        'id': workout.id,
        'user_id': workout.userId,
        'points': workout.points.map((p) => {
          'lat': p.lat,
          'lng': p.lng,
          'timestamp': p.ts.toIso8601String(),
          'accuracy': p.accuracyMeters,
        }).toList(),
        'status': workout.isLoopClosed ? 'captured' : 'pending',
        'created_at': workout.startedAt.toIso8601String(),
      }
    });
  }

  // Background sync: push pending to Go Backend
  Future<void> processQueue() async {
    final pending = _box.values.where((t) => t['status'] == 'pending').toList();
    for (var task in pending) {
      try {
        final response = await http.post(
          Uri.parse('$_baseUrl/sync/run'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(task['payload']),
        );

        if (response.statusCode == 200) {
          final updated = Map<String, dynamic>.from(task);
          updated['status'] = 'synced';
          await _box.put(task['id'], updated);
        }
      } catch (e) {
        // Retry next time
      }
    }
  }

  // Delete from Local and Remote
  Future<void> deleteMission(String id, String userId) async {
    // 1. Delete from Local Hive
    await _box.delete(id);
    
    // 2. Delete from Go Backend (if synced)
    try {
      await http.delete(Uri.parse('$_baseUrl/runs?user_id=$userId&run_id=$id'));
    } catch (e) {
      // If remote delete fails, the server still has it, 
      // but UI won't show it locally anymore.
    }
  }

  // Reconcile local Hive with remote Go Backend
  Future<void> reconcileWithServer(String userId) async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/runs?user_id=$userId'));
      if (response.statusCode == 200) {
        final List<dynamic> remoteMissions = jsonDecode(response.body);
        
        // 1. Get all local mission IDs
        final localKeys = _box.keys.toSet();

        // 2. Add/Update from remote
        for (var remote in remoteMissions) {
          final String id = remote['id'];
          
          // If already local, just ensure it's marked as synced
          if (localKeys.contains(id)) {
            final localTask = Map<String, dynamic>.from(_box.get(id));
            if (localTask['status'] != 'synced') {
              localTask['status'] = 'synced';
              await _box.put(id, localTask);
            }
          } else {
            // If not local (e.g. app reinstalled), pull it down
            await _box.put(id, {
              'id': id,
              'status': 'synced',
              'createdAt': remote['created_at'],
              'payload': {
                'id': id,
                'user_id': userId,
                'status': remote['status'],
                'created_at': remote['created_at'],
                'distance_km': remote['distance_km'],
                'duration_sec': remote['duration_sec'],
                'path_wkt': remote['path_geometry'],
              }
            });
          }
        }
      }
    } catch (e) {
      // Log reconciliation fail
    }
  }

  List<Map<String, dynamic>> getAllMissions() {
    return _box.values
        .map((e) => Map<String, dynamic>.from(e))
        .toList()
        .reversed
        .toList();
  }
}

final syncQueueServiceProvider = Provider<SyncQueueService>((ref) {
  throw UnimplementedError('SyncQueueService must be initialized');
});
