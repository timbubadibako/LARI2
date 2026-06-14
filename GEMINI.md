# 🚀 LARI2 Development & Production Toggles

This file tracks critical logic that has been disabled or modified for development/testing purposes. Use this as a checklist before moving to production.

## 🛠️ Development Toggles (Currently Modified)

### 1. Minimum Distance to Save
- **Status:** 🔴 DISABLED (Commented out)
- **Location:** `frontend/lib/features/workout/presentation/screens/active_workout_screen.dart`
- **Purpose:** Allows saving workouts with 0.00 KM distance for testing database persistence without moving.
- **Search Key:** `// 🔥 PRODUCTION VALIDASI DISTANCE`

### 2. Speed Limiter (GPS Jump Filter)
- **Status:** 🔴 DISABLED (Commented out)
- **Location:** `frontend/lib/features/workout/application/workout_controller.dart`
- **Purpose:** Allows testing with fast-moving vehicles (motorcycles) without the GPS filter rejecting data.
- **Search Key:** `// 🔥 PRODUCTION SPEED LIMITER`

### 3. Velocity Anomaly Check (Backend)
- **Status:** 🔴 DISABLED (Commented out)
- **Location:** `backend/internal/api/run_handler.go`
- **Purpose:** Stops the Go backend from rejecting runs that exceed 40 km/h (Anti-spoofing).
- **Search Key:** `// 🔥 PRODUCTION SPEED LIMITER`

### 4. Finish Button Hold Duration
- **Status:** 🕒 MODIFIED (Reduced to 3 Seconds)
- **Location:** 
  - Logic: `frontend/lib/features/workout/presentation/screens/active_workout_screen.dart`
  - UI String: `frontend/lib/ui/components/app_strings.dart`
- **Purpose:** Faster iteration during testing.
- **Original Value:** 6 Seconds

---

## 🏗️ How to Re-enable for Production

1.  **Distance:** Uncomment the distance check block in `active_workout_screen.dart`.
2.  **GPS Filter:** Uncomment the outlier jump filter in `workout_controller.dart`.
3.  **Backend Anti-Spoofing:** Uncomment the velocity check in `run_handler.go`.
4.  **Hold Time:** 
    - In `active_workout_screen.dart`, change `1.0 / 30.0` back to `1.0 / 60.0`.
    - In `app_strings.dart`, change `HOLD 3S FINISH` back to `HOLD 6S FINISH`.
