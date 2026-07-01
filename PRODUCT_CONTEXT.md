# PRODUCT_CONTEXT.md

## 1. Product Summary

LARI2, also referred to in parts of the repo as Lari-Lari, is a gamified outdoor running app built around real-world territory conquest. Users run in the physical world, generate route loops, and convert those loops into claimed map areas inside the app.

The product combines:

- running tracker behavior similar to fitness apps
- geospatial territory capture
- local competition through guilds and leaderboards
- tactical neon UI presentation

## 2. Core User Experience

The main gameplay loop is:

1. Open the map dashboard.
2. Start a workout.
3. Run a route in the real world.
4. Form a closed loop.
5. Convert the enclosed area into claimed territory.
6. Review the post-run summary, captured area, and progression.
7. Return later to expand, defend, or overlap other territory.

The app should feel like a fitness tracker fused with a tactical conquest game, not just a standard run logger with cosmetic gamification.

## 3. Core Game Mechanic

### Loop Conquest

- Users claim territory by closing a running loop.
- The area inside the loop becomes claimable territory.
- Overlapping another user's territory cuts into that territory rather than requiring a huge enclosing loop.
- Backend territory handling follows a cookie-cutter model using spatial operations.

### Multi-Day Continuation

- A loop does not always have to be completed in a single session.
- The product design references `pending_trails` and a continuation window of up to 72 hours.
- This means some territory capture flows may depend on accumulated path state across sessions.

## 4. Competitive Structure

### Early Progression

- New players begin as individual competitors.
- Progression is tied to area claimed, loop count, XP, and level.

### Guild Phase

- At a later level threshold, players join a guild.
- Guild competition is designed to be hyper-local.
- The current design references seven guilds per local administrative area.

### Map Scale

- Competition is intended to be local, not worldwide in practice.
- The emotional target is neighborhood or district rivalry rather than abstract global ranking.

## 5. Product Pillars

- Real physical movement should directly affect the game world.
- Territory ownership must feel visible, consequential, and contestable.
- The app should reward repeated movement in familiar real-world areas.
- Social and guild systems should reinforce local rivalry and identity.
- The UI should feel intentional, tactical, and distinct from generic fitness apps.

## 6. Main Application Surfaces

### Map Dashboard

- Primary entry point and tactical overview.
- Shows map state, user position, scanning state, territory context, and workout launch CTA.

### Active Workout

- Real-time tracking surface for distance, pace, time, and route capture.
- Feeds location samples into display, storage, and conquest candidate logic.

### Post-Run Summary

- Mission-style recap after a run.
- Expected to show route summary, performance stats, and conquest outcomes.

### History

- Archive of previous runs and territory-related activity.

### Social

- Covers party/lobby behavior, presence, social sharing, and local competition surfaces.

### Profile / Settings

- Identity, privacy, progression, guild status, and integration settings.

## 7. Technical Context

### Frontend

- Flutter + Dart
- Riverpod state management
- MapLibre for map rendering
- Supabase Flutter client present in dependencies

Key frontend concerns:

- live workout state
- map rendering performance
- route display vs raw tracking data
- local persistence and sync
- maintaining the established tactical UI language

### Backend

- Go
- spatial engine and geospatial logic
- WebSocket support for realtime/presence
- SQL schema under `backend/internal/db/`

Key backend concerns:

- run ingestion and validation
- anti-spoofing checks
- territory overlap and clipping logic
- workers for cleanup and seasonal processes

## 8. Important Domain Terms

- `territory conquest`: claiming real-world map area through completed route loops
- `cookie-cutter`: spatial clipping behavior where new claims cut overlapping existing territory
- `pending_trails`: multi-session route continuation state
- `ghost mode`: user can record locally without normal territory/presence behavior
- `presence`: coarse social visibility of user activity
- `guild`: later-stage competitive affiliation
- `season`: periodic reset/reward structure for territorial competition

## 9. Current Product Status

Based on local docs and repo structure:

- core dashboard, workout, summary, and share flows already exist
- social and profile flows exist but are still evolving
- guild and local competition systems are partially implemented
- season logic exists in backend workers/handlers but the full player-facing loop is not yet complete
- some product decisions remain open, especially around season cadence, overlap rules, and progression thresholds

## 10. Development Caveats

The repository currently contains explicit development toggles documented in `.local_docs/GEMINI.md`. These affect validation and anti-spoofing behavior, so any reasoning about current app behavior must account for the fact that some production checks are intentionally relaxed.

## 11. Naming Notes

The repo uses both `LARI2` and `Lari-Lari` naming. Treat them as the same product unless a task is specifically about branding cleanup or copy consistency.

## 12. Guidance For External AI

If this file is taken into another AI tool, the safest assumptions are:

- this is a location-sensitive, stateful fitness/game product
- territory logic is the product differentiator
- workout tracking accuracy and anti-cheat logic matter
- social systems should remain privacy-aware
- local docs should be treated as stronger signals than generic app assumptions
