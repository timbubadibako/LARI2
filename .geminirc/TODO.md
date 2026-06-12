# LARI - Master Development TODO

## Phase 1: Architecture & UI Overhaul (Current Focus)
- [x] **UI Migration (Midnight Sapphire):** Apply the new "Midnight Sapphire" glassmorphism theme across all screens using Flutter Themes. Use `DM Serif Display` and `Jost` fonts.
- [x] **Navigation System:** Implement the "Floating Tactical Island" (Style A) or "Obsidian Dock" (Style B) from `navbars.html`.
- [x] **Interaction Logic Implementation:** 
  - Code the "Hold to Pause" (2s) safety feature in the `active_workout_screen.dart`.
  - Code the "Double Tap to Claim" logic for closing territory loops.

## Phase 2: Lightweight Tracking Mechanics
- [x] **Geospatial Pipeline:** Integrate path smoothing algorithms to smooth raw GPS location arrays.
- [x] **Chain-Code Extraction:** Implement bearing calculation logic to drop redundant middle coordinates on straight paths, saving only Inflection Points.
- [x] **Client-Side Loop Detection:** Use h3_flutter/latlong2 to detect if the current coordinate is within 20m of the starting coordinate to trigger a "Closed Loop".

## Phase 3: Backend & API (Go + PostGIS)
- [x] **Monorepo Restructuring:** Split into `frontend` and `backend` directories.
- [x] **Go Backend Setup:** Initialize Echo + pgx server connecting to local Postgres.
- [x] **Auth API:** Implement Login/Register endpoints in Go to replace client-side SQL logic.
- [x] **Workout Sync API:** Implement POST `/sync/run` endpoint in Go that accepts WKT and saves to `runs` table.
- [x] **RPC Consolidation:** Migrate `ST_Union` logic to a Go service or Postgres function triggered by API.
- [x] **Leaderboard API:** Implement GET `/leaderboard/:district` using the `leaderboard_cache` table.

## Phase 4: Gamification & Polish
- [x] **Guild System:** Implement Guild creation and assigning "Dominion Colors" to users.
- [x] **Social Share Export:** Implement the UI from `share.html` and use Flutter image export utilities to export the image for Instagram Stories.
- [x] **Haptics & Audio:** Add subtle vibration (`HapticFeedback`) and UI sounds (e.g., on "Hold to Pause" success or "Mission Complete").

## Phase 5: Street Rebel V3 Overhaul (Completed)
- [x] **New Visual Identity:** Implement Monochrome + Neon Green palette.
- [x] **Auth Transformation:** Radical Login/Register with 10px borders.
- [x] **Nexus Transformation:** Full-screen interactive map with vignette and compact HUD.
- [x] **Action HUD:** Massive Bebas Neue telemetry and sharp Pocket Mode.
- [x] **Conquest Summary:** Glowing map hero and parallel slant metrics.
- [x] **Mission Archives:** Dossier-style history log.
- [x] **War Room:** Strategic intel and faction balance visualizers.
- [x] **Identity Dossier:** Compact medals and signature tag customization.

## Phase 6: LARI Core Algorithm (Completed)
- [x] **Moving Time Engine:** Implement 15s stationary filter in Go.
- [x] **Integrity Protocol:** Implement "Chain or Crash" connection validation logic.
- [x] **Elastic Trails:** Setup `pending_trails` PostGIS table with 72h TTL.
- [x] **Conquest Engine:** Integrate `ST_Polygonize` for loop-to-territory conversion.
- [x] **Cleanup Worker:** Build background cron for expired trail pruning.
- [x] **Swagger Sync:** Document all spatial endpoints with Swaggo.

## Phase 7: Advanced Tactical & Real-time (Completed)
- [x] **WebSocket Uplink:** Real-time mission activity broadcast in War Room (Go + StreamProvider).
- [x] **Identity Recon:** Profile stats (KM, Sectors, Rank) synced with real DB metrics.
- [x] **Swipe Navigation:** Lateral PageView transitions for History, War Room, and Profile.
- [x] **Boundary Physics:** Implemented `ClampingScrollPhysics` for a solid UI wall.
- [x] **Auth Hardening:** Strictly rectangular buttons and square ripple effects.
- [x] **Session Persistence:** Keep login state across app restarts using SharedPreferences.

## Phase 8: Strategic Operations HQ (Next Focus)
- [ ] **Faction HQ (Guilds):** Implement full guild management in `GuildScreen` (Members, Alliances).
- [ ] **System Configuration (Settings):** Implement account updates, privacy toggles, and unit selection.
- [ ] **Debug Console 2.0:** Add live Hive/Local DB inspector to the `DebugScreen`.
- [ ] **Graffiti Signature Engine:** Implement custom drawing canvas for territory marking.
- [ ] **Audio/Haptic Detail:** Add robotic UI sound effects and complex haptic patterns.

## Current System State (2026-06-12)
- **Backend:** Go Echo Server + PostGIS active. WebSocket hub online at `/ws`.
- **Frontend:** Flutter + Riverpod. Persistent login session enabled.
- **UI:** Street Rebel V3 theme fully applied with tactical headers and swipeable tabs.

