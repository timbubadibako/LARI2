# LARI2 Modular Persistence Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Rebuild the workout tracking and persistence system with a modular, offline-first architecture for LARI2.

**Architecture:** 
- `LariSyncService`: Manages a Hive-backed queue for asynchronous PostgreSQL synchronization.
- `WorkoutController`: Handles real-time GPS tracking and metrics, handing off completed sessions to the sync service.
- Backend Alignment: Updates the Go `SyncRun` handler to support null-safe guild IDs and standardized schema.

**Tech Stack:** Flutter (Riverpod, Hive, HTTP), Go (Echo, pgx).

---

### Task 1: Foundation - Sync Service (Offline-First Queue)

**Files:**
- Create: `frontend/lib/core/services/lari_sync_service.dart`
- Modify: `frontend/lib/main.dart`

- [ ] **Step 1: Implement LariSyncService**
Create the base service with Hive integration and background processing logic.

```dart
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
```

- [ ] **Step 2: Initialize in main.dart**
Replace the old `SyncQueueService` with `LariSyncService`.

```dart
// Modify main.dart around line 35
final syncBox = await Hive.openBox('lari_sync_queue');
// ...
final lariSyncService = LariSyncService(syncBox, container);
// ...
overrides: [
  lariSyncServiceProvider.overrideWithValue(lariSyncService),
  // ...
]
```

- [ ] **Step 3: Commit**
`git add . && git commit -m "feat: implement modular LariSyncService"`

### Task 2: Brains - Workout Controller (Tracking Engine)

**Files:**
- Create: `frontend/lib/features/workout/application/workout_controller.dart`

- [ ] **Step 1: Implement WorkoutController**
Rebuild the controller with optimized tracking and hand-off to `LariSyncService`.

```dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:uuid/uuid.dart';
import '../../../core/domain/models/workout_session.dart';
import '../../../core/domain/models/position_sample.dart';
import '../../../core/domain/repositories/tracking_source.dart';
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
```

- [ ] **Step 2: Commit**
`git add . && git commit -m "feat: implement modular WorkoutController"`

### Task 3: Server - Backend Alignment (Null-Safe Sync)

**Files:**
- Modify: `backend/internal/api/run_handler.go`

- [ ] **Step 1: Update Go Structs and Logic**
Ensure the backend handles `guild_id` correctly as a pointer/nullable string.

```go
// Modify SyncRunRequest in backend/internal/api/run_handler.go
type SyncRunRequest struct {
	ID          string          `json:"id"`
	UserID      string          `json:"user_id"`
	GuildID     *string         `json:"guild_id"` // Nullable
	DistanceKm  float64         `json:"distance_km"`
	DurationSec int             `json:"duration_sec"`
	Points      []service.Point `json:"points"`
	Status      string          `json:"status"`
	CreatedAt   time.Time       `json:"created_at"`
}

// Update the ProcessConquest call in SyncRun handler
guildIDStr := ""
if req.GuildID != nil {
    guildIDStr = *req.GuildID
}
capturedArea, err := h.spatial.ProcessConquest(ctx, req.UserID, guildIDStr, req.Points)
```

- [ ] **Step 2: Commit**
`git add . && git commit -m "fix: align backend with null-safe modular sync"`

### Task 4: UI Glue - Wiring it all together

**Files:**
- Modify: `frontend/lib/features/workout/presentation/screens/active_workout_screen.dart`
- Modify: `frontend/lib/features/workout/presentation/screens/post_run_summary_screen.dart`

- [ ] **Step 1: Clean up UI screens**
Remove old references to `saveAndEnqueueSync` and replace with the new modular flow.

- [ ] **Step 2: Final Verification**
Run `flutter run` and `go run backend/cmd/server/main.go`. Verify logcat for `SYNC_SUCCESS`.
