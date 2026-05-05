# 🏃‍♂️ StrideIO

StrideIO is a next-generation, cyberpunk-themed GPS running and activity tracking application built with Flutter. Unlike traditional fitness trackers, StrideIO gamifies your physical activities by allowing you to "capture" geographical territories (Hexagons) in the real world while tracking your telemetry.

---

## ✨ Features

- **📍 Live GPS Tracking & Telemetry**: Monitor your real-time distance, average pace, duration, and calories burned over an interactive MapLibre map layer.
- **⬡ Hex Grid Domination**: Utilizes Uber's H3 spatial index to overlay the world with hexagonal territories. Run through them to claim tiles and earn "Faction Points."
- **👻 Ghost Mode**: Need a break but don't want to stop the tracker? Ghost mode lets you pause and reposition without drawing ugly straight lines across the map.
- **🗺️ Auto-Scaling Post-Run Summary**: View your entire captured route in a beautiful, auto-fitting map hero widget utilizing CartoDB static tiles, neon route painters, and a premium vignette shadow overlay.
- **📸 Social Grid Sharing**: Generate stunning, pixel-perfect social media stories of your workout.
  - Choose from 7 highly-customizable, dynamic Cyber-Grid templates.
  - Features real Web Mercator map projection logic to perfectly trace your route over dark/light mode maps.
  - Export seamlessly to Instagram, WhatsApp, Strava, or save directly to your gallery via `gal` & `share_plus`.

---

## 🛠️ Technology Stack

- **Framework**: Flutter (Dart)
- **State Management**: Riverpod (`flutter_riverpod`)
- **Maps & Geolocation**: MapLibre GL, `h3_flutter`, `latlong2`, `geolocator`
- **Local Storage**: Hive (`hive`, `hive_flutter`), SharedPreferences
- **Media & Export**: `gal` (Gallery saver), `share_plus`, `path_provider`, `permission_handler`

---

## 💻 Dev GPS

StrideIO includes a hidden Dev Menu for fake GPS simulation, highly useful for testing mapping functionality from a desk.

### How to open it:

1. Run the app in debug mode.
2. Open the Profile tab.
3. Long-press the small version footer at the bottom of the page.

### What you can do there:

- Toggle fake GPS on or off.
- Edit fake route config like center, loop distance, duration, and sample interval.
- Start or stop the fake GPS stream.
- Apply presets like 5km / 30min, 5km / 5min, and 1km walk.

### Release safety:

- Fake GPS is disabled by default.
- In release builds, the Dev Menu stays hidden unless you build with a compile-time flag.
- Use `--dart-define=STRIDEIO_ALLOW_DEV_MENU=true` and `--dart-define=STRIDEIO_ALLOW_FAKE_GPS=true` only for internal builds.

### Verification checklist:

- Toggle persists after app restart.
- Fake mode shows `DEV: Fake GPS active` on the workout screen.
- Active workout route line moves when the fake stream is on.
- Toggling off restores the real location source.

---

## 🚀 Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
