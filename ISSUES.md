# ISSUE — Lari-Lari Implementation Backlog for AI / Agent

Dokumen ini adalah sumber kebenaran untuk AI/agent yang akan mengerjakan repo Lari-Lari.  
Agent **harus** membaca file ini, lalu membaca `SUPABASE.md`, lalu membaca daftar GitHub Issues yang relevan sebelum mulai implementasi.

## Cara kerja agent
1. Baca `ISSUE.md`
2. Baca `SUPABASE.md`
3. Baca issues yang terbuka dan cocok dengan backlog di bawah
4. Implementasikan task dalam branch terpisah
5. Buat PR
6. Setelah PR merge, update issue terkait:
   - ubah checklist dari `- [ ]` menjadi `- [V]`
   - tambahkan komentar berisi link PR
   - tambahkan label `status:done`

---

## Aturan umum
- Jangan menebak struktur DB; ikuti `SUPABASE.md`
- Kalau task menyentuh backend, pastikan RLS dan RPC ikut dibahas
- Kalau task menyentuh Social/Profile, pastikan ia terkoneksi ke Supabase
- Kalau task sudah selesai, tandai checklist terkait dengan `- [V]`
- Jangan menutup issue tanpa komentar PR dan tanpa update checklist

---

## Prioritas pengerjaan
### P0 — Supabase foundation
- schema
- RLS
- RPC
- storage buckets
- sync queue
- realtime helpers

### P1 — Social
- parties
- QR sync
- presence
- leaderboard / lobby flow

### P1 — Profile
- profile view/edit
- avatar upload
- privacy toggles
- integrations state

### P2 — Workout sync & claims
- persist summary
- raw points upload
- worker import
- finalize/claim RPC flow

### P3 — Share / exports
- exports bucket
- share file flow
- GPX / image exports

---

# A. Dashboard (MapDashboard)
Bagian ini sebagian besar sudah done. Agent hanya perlu memastikan wiring tetap sinkron dengan data backend dan tidak merusak UX.

## A1. Fitur fungsional
- [V] MapLibre base layer (vector style) terpasang, tiles & attribution benar.
- [V] Map centering & follow mode (user-follow / free-roam toggle).
- [V] Scan/scan-status widget:
  - states: idle, acquiring GPS, GPS locked, scanning sectors, sector found.
  - microcopy per state.
- [V] Layer: DisplayPoints polyline (live route) toggleable (dev).
- [V] Layer: Presence lines (coarse) — show only if user opted-in.
- [V] H3 hex overlay visual (visual-only toggle on/off).
- [V] Telemetry HUD: region label, GPS badge, LVL + XP left-to-right bar, zone control segmented bar.
- [V] TopAppBar edge-to-edge, status tray scrim (black background), small/action icons (stats, settings).
- [V] START CTA floating (full circle) separated from nav.
- [V] Bottom nav pill:
  - icon-only
  - active pill background
  - short underline indicator under active icon
  - long-press tooltips
- [V] Debug overlay (dev mode): lastAccuracy, sampleRate, queueLength, debug toggles (show raw/display points).
- [V] Permissions CTA: if no location access, show obvious but non-blocking CTA to open settings.

## A2. UI / UX polish
- [V] Glow discipline: only START + scanning core + XP highlight glow.
- [V] Vignette radial top/bottom to emphasize HUD.
- [V] Telemetry card spacing/padding consistent (8/16/24 grid).
- [V] Animations: scanning pulse, small map ping on new sector found.
- [V] Accessibility: contrast ratio, large tap targets >=48dp.
- [V] Skeletons: map loading, telemetry loading, presence list.

## A3. State & wiring
- [V] Read telemetry data from providers: appModeProvider, workoutController, geospatialController.
- [V] MapRoute controller subscribes to controller.displayPoints (throttle 800–1200ms).
- [V] Telemetry HUD listens to `profileProvider` for level/xp values and to `locationController` for GPS badge.
- [V] Toggle handlers (presence on/off, map overlays) persist user prefs.

## A4. Persistence & backend hooks
- [V] Subscribe to realtime ownership updates (later), but panel should be able to show “last sync time”.
- [V] Queue of local events (presence publish) when offline.

## A5. Tests & QA
- [V] Manual: Start/Stop fake-run reproduces polyline growth; toggle map follow/free-roam works.
- [V] Test: permission denied flow shows CTA and does not crash.
- [V] Perf: on mid-range device, map frame drops < 16ms typical, polyline updates throttled.
- [V] Unit: MapRoute controller debounce logic.

## A6. Edge cases & acceptance
- [V] If many presence lines visible, performance acceptable (cull or simplify).
- [V] If no GPS lock > X seconds, HUD shows “Acquiring GPS” and suggests moving to open sky.

---

# B. Active Workout (ActiveWorkoutScreen)

## B1. Fitur fungsional (core tracking)
- [V] Start / Pause / Resume / End actions wired to WorkoutController.
- [V] WorkoutController: subscription to locationStreamProvider, timer Ticker, states (idle/running/paused/ended).
- [V] RawPoints buffer (append-only) persisted to local DB in chunks or on end.
- [V] DisplayPoints buffer for map + encoded polyline generation on end.
- [V] Distance calc using Haversine between accepted points; guard against bad accuracy.
- [V] Pace calculation (instant & avg) and smoothing rules.
- [V] Skip-first-segment-after-resume logic to prevent teleport jumps.
- [V] Heart-rate integration (if wearable connected): show HR tile & live updates.
- [V] Territory candidate accumulation (local) – H3 conversion per accepted point (dev mode simple).
- [V] Ghost mode toggle: records locally but no territory claims/presence.

## B2. UI / UX polish
- [V] Hex Sync widget (animated) with numeric % sync — map to real state or fake state.
- [V] Metric Bento: Dist / Pace / Time / BPM tiles, animated numeric transitions.
- [V] Territory Acquired widget with progress + animated increment when claim occurs.
- [ ] Pause modal confirmation (optional): “Pause run?” with quick resume.
- [ ] Haptic feedback on Start / End / Claim events.
- [ ] Safety CTA: "Hold to End" or confirm to prevent accidental end.

## B3. State & wiring
- [V] WorkoutController exposes stream of WorkoutSession state or uses Riverpod StateNotifier.
- [V] UI binds only to derived state (elapsed, distanceMeters, pace, displayPoints).
- [V] Location gating: ignore sample if accuracy > threshold (configurable) but still record raw sample with flag (for audit).
- [V] Implement `processPositionSample()` that:
  - stores raw sample
  - decides acceptance for displayPoints
  - computes distance increment
  - updates H3 candidate

## B4. Persistence & backend hooks
- [V] Save snapshot periodically locally (every N seconds or every M points) to survive app kills.
- [V] On end: generate encoded polyline & save summary + raw points to local DB; enqueue sync job.
- [V] On resume after crash: option to restore last session (dev toggle).

## B5. Tests & QA
- [V] Manual: start → move device/simulate → distance increases plausibly.
- [V] Manual: pause → move device → resume → no huge jump.
- [V] Unit: distance calculation & resume-skip logic.
- [V] Integration: feed FakeLocationService stream and assert workoutController final distance ≈ expected.

## B6. Edge cases & acceptance
- [V] Dropouts / low accuracy: ensure logic discards bad points for distance but keep raw for debugging.
- [V] Battery/cpu: ensure timer and map updates don't keep the device hot (profiling).
- [V] Background behavior: if implemented, verify minimal wakeups and persisted points.

---

# C. Post-Run Summary (PostRunSummaryScreen)

## C1. Fitur fungsional
- [V] Accept/work with session snapshot: startedAt, endedAt, duration, distance, avgPace, calories (if estimated), encoded polyline.
- [V] Map preview using encoded polyline (or displayPoints).
- [V] Stats cards: distance, time, pace, elevation gain (if available), cadence/HR average.
- [V] Faction points / rank jump / total area (game metrics) if available.
- [V] Save workout (local) and Enqueue backend sync (summary + polyline, raw points optional).
- [V] Share options: deep-link / social / Strava export (oauth flow) — wired and working.
- [V] View Domination: opens modal/page for territory results (uses final capture candidates).

## C2. UI / UX polish
- [ ] Celebration animation (confetti, badge unlock) if a threshold reached.
- [V] CTA primary: Share; secondary: View Domination; tertiary: Save/Close.
- [V] Clear affordance for editing title/notes for workout before saving.
- [V] Skeleton/loading when computing summary (e.g., if analysing raw points for area).

## C3. State & wiring
- [V] Inputs from WorkoutController final state or a separate `FinalizeWorkout` use case that computes derived metrics (area, polygon, capture candidates).
- [V] Save flow should be atomic: write local DB then enqueue upload.

## C4. Persistence & backend hooks
- [ ] Upload summary + encoded polyline first; raw points uploaded in background (chunked).
- [ ] Retry logic + exponential backoff for failed uploads.
- [ ] When uploading claims: call server RPC to validate; handle rejection gracefully and show reason.

## C5. Tests & QA
- [V] Manual: End run → summary shows correct distance/time/pace consistent with ActiveWorkout.
- [ ] Manual: Share to Strava (mock) triggers OAuth and returns success.
- [ ] Unit: encoder/decoder polyline/points roundtrip.

## C6. Edge cases & acceptance
- [ ] If save fails (e.g., DB full), show helpful error & attempt local fallback.
- [ ] If upload rejected by server (anti-cheat), display reason and keep local copy for appeals.

---

# D. Share (Share functionality)

## D1. Fitur fungsional
- [V] Share sheet for:
  - encoded polyline + summary text
  - social links (Strava, Twitter, Instagram)
  - image export (map snapshot with overlay & metrics)
  - GPX/TCX export option
- [ ] Strava integration:
  - OAuth connect/disconnect
  - Upload workout via Strava API (summary + polyline/geojson)
  - Map privacy handling (option: share with truncated coordinates or full)
- [V] Native share: invoke platform share for text + image/file.
- [ ] In-app “Copy link” for deep link to workout.

## D2. UI / UX polish
- [V] Share preview modal: shows what will be shared (image + text).
- [V] Default text template (editable): "I ran 5.12 km in 28:45 - #Lari-Lari"
- [V] Quality of exported image: map snapshot + gradient overlay + icons + stats in a shareable aspect ratio.

## D3. State & wiring
- [V] Use PostRunSummary session snapshot as input.
- [V] When sharing image: create map snapshot offscreen (MapLibre snapshot API or canvas render).
- [V] Ensure share operations do not block UI (use background thread).

## D4. Persistence & backend hooks
- [ ] For Strava, save tokens securely (secure storage), respect token expiration & refresh flow.
- [ ] For sharing GPX: generate file, cache locally, and clean up temp file after share.

## D5. Tests & QA
- [V] Manual:
  - share image via native share → recipient sees expected image and text.
  - Strava connect flow works in dev (mock).
- [ ] Edge case: network failure during Strava upload shows retry option.

## D6. Edge cases & acceptance
- [ ] User revokes Strava access: app handles 401 gracefully and prompts re-auth.
- [ ] Large raw points: only upload summary+encoded polyline in foreground, raw in background or allow user opt-in.

---

# E. Supabase Foundation

Bagian ini WAJIB dikerjakan dengan membaca `SUPABASE.md` terlebih dahulu.

## E1. Schema
- [ ] Apply initial schema from `SUPABASE.md`
- [ ] Create/verify tables:
  - `user_profiles`
  - `workouts`
  - `workout_points`
  - `hex_ownership`
  - `hex_claims`
  - `presence`
  - `parties`
  - `party_members`
  - `sync_queue`
- [ ] Create/verify indexes:
  - composite indexes for time-series tables
  - GiST indexes for spatial columns
  - primary keys and foreign keys
- [ ] Create storage buckets:
  - `raw_points`
  - `exports`
  - `avatars`

## E2. RLS
- [ ] Enable RLS on user-owned tables
- [ ] Ensure `auth.uid()` is required for user-owned inserts/selects/updates
- [ ] Restrict writes to `hex_ownership` to RPC/service role only
- [ ] Verify policies on:
  - `workouts`
  - `workout_points`
  - `presence`
  - `user_profiles`
  - `parties`
  - `party_members`

## E3. RPC / Functions
- [ ] Implement `claim_hexes(p_workout_id, p_user_id, p_candidates jsonb)`
- [ ] Implement `get_hex_ownership_for_bbox(lon_min, lat_min, lon_max, lat_max)`
- [ ] Implement `join_party_by_code(code)` or equivalent Edge Function
- [ ] Implement `finalize_workout(workout_id)` if server-side finalize is used
- [ ] Implement `get_capture_candidates(workout_id)` if needed

## E4. Sync / Worker
- [ ] Implement `sync_queue` processing worker
- [ ] Import raw points from storage into `workout_points`
- [ ] Handle retries and failed jobs
- [ ] Call claim RPC after validation if needed

## E5. Testing
- [ ] Test workout insert/select with authenticated user
- [ ] Test presence upsert with owner-only rule
- [ ] Test claim RPC rejects unauthorized workout
- [ ] Test worker import with sample file

---

# F. Social

Fokus sosial: party, lobby, QR, presence, leaderboard.

## F1. Parties
- [ ] Create party
- [ ] Generate share code
- [ ] Join party by code
- [ ] Leave party
- [ ] Show party members
- [ ] Handle duplicate join gracefully
- [ ] Persist party state in Supabase

## F2. QR Sync
- [ ] Generate QR from share code
- [ ] Scan QR to join
- [ ] Fallback manual code entry
- [ ] Show success/error states

## F3. Presence
- [ ] Publish coarse presence line
- [ ] Toggle public presence on/off
- [ ] Respect ghost mode / privacy
- [ ] Subscribe realtime to nearby/public presence
- [ ] Render presence as coarse only, no exact path leakage

## F4. Leaderboard / Lobby
- [ ] Local leaderboard
- [ ] Faction leaderboard
- [ ] Nearby users / lobby list
- [ ] Loading and empty states

## F5. Acceptance
- [ ] Party create/join flow works
- [ ] QR scan/join flow works
- [ ] Presence opt-in works
- [ ] Public presence hides precise GPS data

---

# G. Profile

Profile adalah pusat identitas, privacy, dan integrations.

## G1. Profile view/edit
- [ ] Read profile from `user_profiles`
- [ ] Update display name
- [ ] Update avatar
- [ ] Update tagline/bio
- [ ] Update faction if allowed
- [ ] Show level and XP

## G2. Privacy
- [ ] Toggle ghost mode
- [ ] Toggle public profile
- [ ] Toggle public presence
- [ ] Persist privacy settings in Supabase

## G3. Integrations
- [ ] Show Strava integration state
- [ ] Show Health / wearable integration state
- [ ] Connect/disconnect placeholder if backend belum ready
- [ ] Store integration metadata in Supabase

## G4. Acceptance
- [ ] Profile updates persist
- [ ] Avatar upload works
- [ ] Privacy toggles survive restart
- [ ] Integration state shows correctly

---

# H. Dev / QA tools
- [V] FakeLocationService & DevMenu to simulate runs
- [V] GPX replay helper for emulator/device testing
- [ ] Fake presence generator for Social screen testing
- [ ] Debug overlay for Supabase sync queue length
- [ ] Dev preset for 5km / 30min loop
- [ ] Dev preset for 5km / 5min loop

---

# I. What the agent must do when it completes a task
1. Open PR
2. Add tests if applicable
3. Update related issue checklist:
   - `- [ ]` → `- [V]`
4. Add comment with PR link and short test result
5. Update labels to `status:done`

Example comment:
Implemented party join-by-code flow.  
PR: https://github.com/timbubadibako/Lari-Lari/pull/123  
Tests:
- join by code succeeds
- duplicate join is ignored
- presence remains unaffected

---

# J. Suggested order of implementation
1. Supabase schema + RLS
2. Profile
3. Social / Parties / QR
4. Presence
5. Sync worker
6. Workout persistence hooks
7. Finalize / claim RPC integration
8. Share export persistence
9. Polishing and tests

---

# K. Acceptance criteria summary
Project is considered healthy when:
- Dashboard, Active Workout, Post-Run Summary, and Share stay working
- Social and Profile are connected to Supabase
- Schema/RLS/RPC exist and are documented in `SUPABASE.md`
- Issues are updated with `- [V]` after work is merged
- Agent follows this file as the backlog source

---

# L. Files the agent must read
- `ISSUE.md`
- `SUPABASE.md`
- `README.md`
- Open GitHub Issues
- Relevant feature files in `lib/`

---

# M. End note
If something is unclear, the agent should:
- read `SUPABASE.md`
- inspect the open issues
- implement the smallest safe change
- keep PRs atomic
- mark completed checklist items with `- [V]`