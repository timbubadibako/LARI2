# 🏃‍♂️ Lari-Lari — Run. Capture. Conquer.

Lari-Lari adalah aplikasi pelacakan lari dan aktivitas bertema cyberpunk yang dibangun dengan Flutter. Bayangkan Strava, lalu tambahkan elemen game: kamu bisa "merebut" kotak-kotak wilayah (hex tiles) di dunia nyata saat berlari. Aplikasi ini memadukan telemetri serius dengan game mechanics ringan — cocok untuk yang suka lari sekaligus main strategi lokasi.

> Tagline: "Run the map. Capture the grid. Play the city."

---

## ✨ Mengapa Lari-Lari?
- Kita rekam lari layaknya Strava: GPS, jarak, pace, durasi, dan ringkasan setelah lari.
- Bedanya: setiap langkahmu punya makna game — kamu bisa mengklaim area (H3 hex) untuk faction-mu.
- Fokus UX: dark cyber/neon theme, polish visual, dan social sharing yang eye-catching.

---

## Fitur unggulan (highlight)
- 📍 Live GPS Tracking & Telemetry (MapLibre)
  - Real-time distance, pace, elapsed time, dan visual route polyline.
- ⬡ Hex Grid Domination (H3)
  - Lewati hex untuk jadi calon klaim; nanti server akan memvalidasi klaim-area.
- ⚔️ Faction HQ & Dominion
  - Pilih aliansi (Guild) dan klaim wilayah untuk timmu. Visualisasi real-time dominasi global.
- 🎨 Graffiti Signature Engine
  - Gambar tag taktismu sendiri untuk menandai wilayah yang dikuasai.
- 🧪 Debug Console 2.0
  - Inspektor Hive, SharedPreferences, dan sistem log real-time untuk developer.
- 📸 Social Grid Sharing
  - 7 templated share images (cyber-grid) yang bisa langsung ke Instagram/WhatsApp/Strava.

---

## Quick start (dev)
1. Clone:
   git clone git@github.com:timbubadibako/Lari-Lari.git
2. Install:
   flutter pub get
3. Run debug:
   flutter run
4. Dev menu & fake GPS:
   - Buka app di mode debug → Profile tab → Long-press versi footer → Dev Menu
   - Toggle `Fake GPS` untuk simulasi loop (default OFF)
   - Untuk internal builds: gunakan --dart-define=LARI-LARI_ALLOW_DEV_MENU=true

---

## Architecture overview (singkat)
- Flutter + Riverpod (state management)
- Map: MapLibre GL
- Geospatial: h3_flutter + latlong2
- Storage: Hive + SharedPreferences
- Share/export: share_plus, image export utilities

---

## UX notes (penting untuk contributor)
- HUD-first: top app bar edge-to-edge; telemetri sebagai HUD card; START CTA dipisah dari nav
- Map updates harus di-throttle (800–1500ms) untuk performa.
- Keep raw GPS points for analytics; use encoded polyline for uploads/previews.

---

## Dev & QA tools
- FakeLocationService (dev): generate loop runs, configurable (center, distance, duration, sample rate).
- Dev overlay: show sampleRate, lastAccuracy, pending upload queue length.
- GPX replay helper for emulator testing.

---

## Documentation
- [Architecture Overview](.geminirc/ARCHITECTURE.md)
- [Tactical Testing Guide](docs/TESTING_TACTICAL.md)
- [Advanced Algorithms & Game Mechanics](docs/ALGORITHMS_AND_MECHANICS.md)
- MVP complete: Dashboard, Active run, Post-run summary, Share (7 templates) — DONE
- Social & Strategic HQ: Guilds, Settings, Graffiti Engine, WebSocket Activity — DONE
- Next: District Conquest Maps, Agent Alliances, Vulnerability Radar, Advanced Telemetry.
- Later: Anti-cheat, wearables, realtime presence filters

---

## Contributing
- Buat branch: feat/your-feature
- Ikuti Conventional Commits (feat/fix/docs/chore)
- Tambahkan test untuk logic kritikal (distance, resume-skip, polyline encode)
- Kembangkan di dev mode (fake GPS) untuk cepat iterasi UI & map

---

## Privacy & safety
- Ghost mode & presence opt-out by default.
- Fake GPS locked behind dev toggle; disabled in release builds unless a compile-time flag is set.
- Tokens (Strava, etc.) must be stored in secure storage; no PII in logs.

---

## Need help?
- Untuk request fitur atau bug: buka issue di GitHub.
- Untuk permintaan checklist/PR generation otomatis, mention @timbubadibako di issue.

Have fun — run the city. Capture the grid.
