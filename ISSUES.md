# Checklist detail — Dashboard (MapDashboard)

A. Fitur fungsional
- [ ] MapLibre base layer (vector style) terpasang, tiles & attribution benar.
- [ ] Map centering & follow mode (user-follow / free-roam toggle).
- [ ] Scan/scan-status widget:
  - states: idle, acquiring GPS, GPS locked, scanning sectors, sector found.
  - microcopy per state.
- [ ] Layer: DisplayPoints polyline (live route) toggleable (dev).
- [ ] Layer: Presence lines (coarse) — show only if user opted-in.
- [ ] H3 hex overlay visual (visual-only toggle on/off).
- [ ] Telemetry HUD: region label, GPS badge, LVL + XP left-to-right bar, zone control segmented bar.
- [ ] TopAppBar edge-to-edge, status tray scrim (black background), small/action icons (stats, settings).
- [ ] START CTA floating (full circle) separated from nav.
- [ ] Bottom nav pill:
  - icon-only
  - active pill background
  - short underline indicator under active icon
  - long-press tooltips
- [ ] Debug overlay (dev mode): lastAccuracy, sampleRate, queueLength, debug toggles (show raw/display points).
- [ ] Permissions CTA: if no location access, show obvious but non-blocking CTA to open settings.

B. UI / UX polish
- [ ] Glow discipline: only START + scanning core + XP highlight glow.
- [ ] Vignette radial top/bottom to emphasize HUD.
- [ ] Telemetry card spacing/padding consistent (8/16/24 grid).
- [ ] Animations: scanning pulse, small map ping on new sector found.
- [ ] Accessibility: contrast ratio, large tap targets >=48dp.
- [ ] Skeletons: map loading, telemetry loading, presence list.

C. State & wiring
- [ ] Read telemetry data from providers: appModeProvider, workoutController, geospatialController.
- [ ] MapRoute controller subscribes to controller.displayPoints (throttle 800–1200ms).
- [ ] Telemetry HUD listens to `profileProvider` for level/xp values and to `locationController` for GPS badge.
- [ ] Toggle handlers (presence on/off, map overlays) persist user prefs.

D. Persistence & backend hooks
- [ ] Subscribe to realtime ownership updates (later), but panel should be able to show “last sync time”.
- [ ] Queue of local events (presence publish) when offline.

E. Tests & QA
- [ ] Manual: Start/Stop fake-run reproduces polyline growth; toggle map follow/free-roam works.
- [ ] Test: permission denied flow shows CTA and does not crash.
- [ ] Perf: on mid-range device, map frame drops < 16ms typical, polyline updates throttled.
- [ ] Unit: MapRoute controller debounce logic.

F. Edge cases & acceptance
- [ ] If many presence lines visible, performance acceptable (cull or simplify).
- [ ] If no GPS lock > X seconds, HUD shows “Acquiring GPS” and suggests moving to open sky.

---

# Checklist detail — Active Workout (ActiveWorkoutScreen)

A. Fitur fungsional (core tracking)
- [ ] Start / Pause / Resume / End actions wired to WorkoutController.
- [ ] WorkoutController: subscription to locationStreamProvider, timer Ticker, states (idle/running/paused/ended).
- [ ] RawPoints buffer (append-only) persisted to local DB in chunks or on end.
- [ ] DisplayPoints buffer for map + encoded polyline generation on end.
- [ ] Distance calc using Haversine between accepted points; guard against bad accuracy.
- [ ] Pace calculation (instant & avg) and smoothing rules.
- [ ] Skip-first-segment-after-resume logic to prevent teleport jumps.
- [ ] Heart-rate integration (if wearable connected): show HR tile & live updates.
- [ ] Territory candidate accumulation (local) – H3 conversion per accepted point (dev mode simple).
- [ ] Ghost mode toggle: records locally but no territory claims/presence.

B. UI / UX polish
- [ ] Hex Sync widget (animated) with numeric % sync — map to real state or fake state.
- [ ] Metric Bento: Dist / Pace / Time / BPM tiles, animated numeric transitions.
- [ ] Territory Acquired widget with progress + animated increment when claim occurs.
- [ ] Pause modal confirmation (optional): “Pause run?” with quick resume.
- [ ] Haptic feedback on Start / End / Claim events.
- [ ] Safety CTA: "Hold to End" or confirm to prevent accidental end.

C. State & wiring
- [ ] WorkoutController exposes stream of WorkoutSession state or uses Riverpod StateNotifier.
- [ ] UI binds only to derived state (elapsed, distanceMeters, pace, displayPoints).
- [ ] Location gating: ignore sample if accuracy > threshold (configurable) but still record raw sample with flag (for audit).
- [ ] Implement `processPositionSample()` that:
  - stores raw sample
  - decides acceptance for displayPoints
  - computes distance increment
  - updates H3 candidate

D. Persistence & backend hooks
- [ ] Save snapshot periodically locally (every N seconds or every M points) to survive app kills.
- [ ] On end: generate encoded polyline & save summary + raw points to local DB; enqueue sync job.
- [ ] On resume after crash: option to restore last session (dev toggle).

E. Tests & QA
- [ ] Manual: start → move device/simulate → distance increases plausibly.
- [ ] Manual: pause → move device → resume → no huge jump.
- [ ] Unit: distance calculation & resume-skip logic.
- [ ] Integration: feed FakeLocationService stream and assert workoutController final distance ≈ expected.

F. Edge cases & acceptance
- [ ] Dropouts / low accuracy: ensure logic discards bad points for distance but keep raw for debugging.
- [ ] Battery/cpu: ensure timer and map updates don't keep the device hot (profiling).
- [ ] Background behavior: if implemented, verify minimal wakeups and persisted points.

---

# Checklist detail — Post-Run Summary (PostRunSummaryScreen)

A. Fitur fungsional
- [ ] Accept/work with session snapshot: startedAt, endedAt, duration, distance, avgPace, calories (if estimated), encoded polyline.
- [ ] Map preview using encoded polyline (or displayPoints).
- [ ] Stats cards: distance, time, pace, elevation gain (if available), cadence/HR average.
- [ ] Faction points / rank jump / total area (game metrics) if available.
- [ ] Save workout (local) and Enqueue backend sync (summary + polyline, raw points optional).
- [ ] Share options: deep-link / social / Strava export (oauth flow) — wired and working.
- [ ] View Domination: opens modal/page for territory results (uses final capture candidates).

B. UI / UX polish
- [ ] Celebration animation (confetti, badge unlock) if a threshold reached.
- [ ] CTA primary: Share; secondary: View Domination; tertiary: Save/Close.
- [ ] Clear affordance for editing title/notes for workout before saving.
- [ ] Skeleton/loading when computing summary (e.g., if analysing raw points for area).

C. State & wiring
- [ ] Inputs from WorkoutController final state or a separate `FinalizeWorkout` use case that computes derived metrics (area, polygon, capture candidates).
- [ ] Save flow should be atomic: write local DB then enqueue upload.

D. Persistence & backend hooks
- [ ] Upload summary + encoded polyline first; raw points uploaded in background (chunked).
- [ ] Retry logic + exponential backoff for failed uploads.
- [ ] When uploading claims: call server RPC to validate; handle rejection gracefully and show reason.

E. Tests & QA
- [ ] Manual: End run → summary shows correct distance/time/pace consistent with ActiveWorkout.
- [ ] Manual: Share to Strava (mock) triggers OAuth and returns success.
- [ ] Unit: encoder/decoder polyline/points roundtrip.

F. Edge cases & acceptance
- [ ] If save fails (e.g., DB full), show helpful error & attempt local fallback.
- [ ] If upload rejected by server (anti-cheat), display reason and keep local copy for appeals.

---

# Checklist detail — Share (Share functionality)

A. Fitur fungsional
- [ ] Share sheet for:
  - encoded polyline + summary text
  - social links (Strava, Twitter, Instagram)
  - image export (map snapshot with overlay & metrics)
  - GPX/TCX export option
- [ ] Strava integration:
  - OAuth connect/disconnect
  - Upload workout via Strava API (summary + polyline/geojson)
  - Map privacy handling (option: share with truncated coordinates or full)
- [ ] Native share: invoke platform share for text + image/file.
- [ ] In-app “Copy link” for deep link to workout.

B. UI / UX polish
- [ ] Share preview modal: shows what will be shared (image + text).
- [ ] Default text template (editable): "I ran 5.12 km in 28:45 - #StrideIO"
- [ ] Quality of exported image: map snapshot + gradient overlay + icons + stats in a shareable aspect ratio.

C. State & wiring
- [ ] Use PostRunSummary session snapshot as input.
- [ ] When sharing image: create map snapshot offscreen (MapLibre snapshot API or canvas render).
- [ ] Ensure share operations do not block UI (use background thread).

D. Persistence & backend hooks
- [ ] For Strava, save tokens securely (secure storage), respect token expiration & refresh flow.
- [ ] For sharing GPX: generate file, cache locally, and clean up temp file after share.

E. Tests & QA
- [ ] Manual:
  - share image via native share → recipient sees expected image and text.
  - Strava connect flow works in dev (mock).
- [ ] Edge case: network failure during Strava upload shows retry option.

F. Edge cases & acceptance
- [ ] User revokes Strava access: app handles 401 gracefully and prompts re-auth.
- [ ] Large raw points: only upload summary+encoded polyline in foreground, raw in background or allow user opt-in.

---

# Cross-cutting concerns & suggestions

1. Telemetry & logging
- Log events for Start/Pause/Resume/End, Save, Upload attempts, Share actions.
- Capture key metrics (time to GPS lock, average accuracy) for later UX tuning.

2. Dev / QA tools
- FakeLocationService & DevMenu (already discussed) to simulate runs and presence.
- GPX replay tool to validate map visuals & exports.

3. Performance & memory
- Throttle map updates; do not rebuild map widget each second.
- Batch writes to local DB (every N points or every T seconds).
- Avoid heavy backdrop blur; prefer thin gradient + border.

4. Accessibility
- Provide alt text for share images, label buttons, ensure color contrast.

5. Security & privacy
- Default ghost/presence OFF.
- Store sensitive tokens in secure storage.
- Provide clear privacy strings for location usage.

---

# Acceptance checklist (combined final)
- Dashboard: map live, telemetry HUD correct, START CTA floats and works, bottom nav icon-only with active underline, system tray dark scrim.
- Active Workout: start/pause/resume/end work; distance & pace reasonable; map polyline grows; raw + display points stored; resume-skip logic prevents teleport leaps.
- Post-Run Summary: final metrics & route preview, save locally, share flows present; view-domination accessible.
- Share: native share, image export, Strava (mock) integration path, GPX export.
- Social + Profile (remaining): party create/join, QR sync, presence opt-in, profile edit + integrations toggles.

---
