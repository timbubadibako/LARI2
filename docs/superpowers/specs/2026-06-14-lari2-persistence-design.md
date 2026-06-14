# Spec: LARI2 Modular Persistence System (Offline-First)

**Date:** 2026-06-14  
**Status:** DRAFT (Awaiting Approval)  
**Topic:** Data Persistence with Null-Safe Guild Unlocking

## 1. Overview
The LARI2 persistence system follows a modular, offline-first architecture. It separates real-time workout tracking from the network synchronization logic, ensuring data integrity even in poor connectivity.

## 2. Key Components

### A. `WorkoutController` (Tracking Engine)
- **Role:** Real-time state management for active runs.
- **Responsibilities:**
  - GPS sampling and filtering (Speed limiters disabled for dev).
  - Calculating live distance (KM) and duration.
  - Temporary memory storage of coordinate points.
  - Resetting state after successful hand-off to the sync service.

### B. `LariSyncService` (Sync & Queue Manager)
- **Role:** Handles the bridge between local Hive storage and remote PostgreSQL.
- **Responsibilities:**
  - Persisting completed runs to Hive immediately with `status: PENDING`.
  - Executing asynchronous HTTP POST requests to the Go Backend (`/sync/run`).
  - Handling retry logic if the server is offline.
  - Clearing or marking tasks as `SYNCED` upon success.

## 3. Data Integrity & Null Safety (Guild Unlocking)
To support the requirement of **"Guilds unlock at Level 5"**, the system will handle `guild_id` as an optional/nullable field.

### Frontend (Flutter):
- `UserProfile.guildId`: `String?` (Optional).
- `WorkoutSession.guildId`: `String?` (Optional).
- **Rule:** If the user is < Level 5, `guildId` will be sent as `null` or an empty string. The UI will gate the guild selection until the level threshold is met.

### Backend (Go/PostgreSQL):
- **Tabel `runs`:** `guild_id` is nullable.
- **Tabel `user_territories`:** `guild_id` is nullable.
- **Sync Logic:** The Go handler will bind the JSON payload using `omitempty` or pointers to correctly handle the absence of a guild ID without throwing errors.

## 4. Proposed Payload (JSON)
```json
{
  "id": "uuid-v4",
  "user_id": "uuid-v4",
  "guild_id": null, // Nullable: used only when unlocked (> Lvl 5)
  "distance_km": 0.0,
  "duration_sec": 0,
  "points": [
    {
      "lat": -6.225,
      "lng": 106.827,
      "timestamp": "2026-06-14T15:30:00Z",
      "accuracy": 5.0
    }
  ],
  "status": "finished",
  "created_at": "2026-06-14T15:30:00Z"
}
```

## 5. Persistence Workflow
1. User holds **FINISH (3s)**.
2. `WorkoutController` captures final stats.
3. `LariSyncService.enqueue()` is called (Atomic save to Hive).
4. `PostRunSummaryScreen` is shown immediately (UI is snappy).
5. `LariSyncService.processQueue()` runs in background.
6. Upon HTTP 200/201, local task status is updated.

---

**Apakah desain dengan penanganan Null-Safe Guild ini sudah oke, Bro?**
Kalau sudah setuju, saya akan commit file spec ini dan mulai membangun kodenya.
