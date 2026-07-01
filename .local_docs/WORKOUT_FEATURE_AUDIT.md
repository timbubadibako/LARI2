# Workout Feature Audit

Status: audit implementasi aktif per 2026-07-01 untuk membandingkan MVP saat ini, target rilis awal, dan proteksi/fasilitas workout yang hilang atau nonaktif.

## 1. Ringkasan Cepat

MVP workout yang benar-benar aktif saat ini:
- login lalu mulai run
- tracking GPS dasar
- hitung jarak, durasi, pace dasar
- pause/resume manual
- finish dengan hold
- loop closure sederhana
- post-run summary
- enqueue ke local sync queue
- kirim ke backend Go
- history menampilkan remote run dan local run yang belum sinkron

Hal penting yang tidak aktif / tidak ada:
- minimum distance guard produksi
- speed limiter / GPS jump filter frontend
- accuracy gating per sample
- raw/display point separation
- restore session after crash
- heart-rate / wearable
- ghost mode yang benar-benar terhubung ke flow aktif

## 2. Status Fitur Utama

| Fitur | Status | Catatan | Lokasi |
|---|---|---|---|
| Start run | Ada | Menginisialisasi session baru dan langsung subscribe tracking | `frontend/lib/features/workout/application/workout_controller.dart` |
| Manual pause | Ada | Hanya via double tap tombol pause | `frontend/lib/features/workout/presentation/screens/active_workout_screen.dart` |
| Manual resume | Ada | Hanya via double tap tombol resume | `frontend/lib/features/workout/presentation/screens/active_workout_screen.dart` |
| Hold to finish | Ada | Masih mode dev 3 detik | `frontend/lib/features/workout/presentation/screens/active_workout_screen.dart` |
| Post-run summary | Ada | Sudah direvisi untuk preview map summary | `frontend/lib/features/workout/presentation/screens/post_run_summary_screen.dart` |
| Local sync queue | Ada | Run dimasukkan ke Hive queue lalu dicoba sync background | `frontend/lib/core/services/lari_sync_service.dart` |
| History merge local + remote | Ada | Pending dan quarantined sekarang tampil lagi | `frontend/lib/features/history/application/history_controller.dart` |
| Loop closure detection | Ada | Rule sederhana: displacement > 30m lalu kembali <= 25m | `frontend/lib/features/workout/application/workout_controller.dart` |
| Auto pause | Ada | Auto-pause saat speed rendah stabil 15 detik | `frontend/lib/features/workout/application/workout_controller.dart` |
| Auto resume 15 detik | Ada | Auto-resume saat gerak stabil 15 detik | `frontend/lib/features/workout/application/workout_controller.dart` |
| Minimum distance guard | Nonaktif | Blok validasi dikomentari untuk dev mode | `frontend/lib/features/workout/presentation/screens/active_workout_screen.dart` |
| Speed limiter frontend | Nonaktif | Semua gap langsung ditambahkan ke distance | `frontend/lib/features/workout/application/workout_controller.dart` |
| Velocity anomaly backend | Longgar / perlu cek deploy | Di local code sebelumnya didokumentasikan sebagai dev toggle sensitif | `.local_docs/GEMINI.md`, `backend/internal/api/run_handler.go` |
| Accuracy gating | Tidak ada | Sample akurasi buruk tidak difilter | `frontend/lib/features/workout/application/workout_controller.dart` |
| Resume jump protection | Ada dasar | Baseline resume dibuang dari jarak, tetapi route masih belum dipisah segmen | `frontend/lib/features/workout/application/workout_controller.dart` |
| Raw points vs display points | Tidak ada | Hanya ada satu list `points` aktif | `frontend/lib/core/domain/models/workout_session.dart`, `frontend/lib/features/workout/application/workout_controller.dart` |
| Restore interrupted session | Tidak terlihat aktif | Tidak ada flow aktif untuk restore dari storage | `frontend/lib/features/workout/application/workout_controller.dart` |
| Heart rate tile/integration | Tidak ada | Tidak ada BPM stream atau widget aktif | repo search |
| Ghost mode in active flow | Tidak terlihat aktif | Model punya field, tapi flow aktif tidak expose toggle/behavior | `frontend/lib/core/domain/models/workout_session.dart` |

## 3. Fitur Yang Dicari User: Ada / Tidak Ada / Nonaktif

### Ada
- start run
- pause/resume manual
- finish run
- hitung distance/time/pace dasar
- loop close detection
- sync ke backend
- history dasar

### Tidak Ada
- accuracy-based sample rejection
- motion-quality validation
- warning bahwa run sedang invalid / kurang gerak
- restore run setelah app kill/crash
- HR / cadence / wearable support

### Nonaktif / Dilonggarkan
- minimum distance validation
- speed limiter frontend
- beberapa proteksi anti-spoofing backend/dev
- finish hold production duration

## 4. Bukti Implementasi Aktif

### Workout controller aktif sangat tipis

Di `workout_controller.dart`:
- `start()` membuat session dan mulai tracking
- `pause()` hanya cancel timer dan subscription
- `resume()` hanya set state ke running lalu `_startTracking()`
- `_startTracking()`:
  - timer tambah durasi per detik
  - setiap sample:
    - hitung gap ke titik terakhir
    - langsung tambahkan ke distance
    - append point
    - cek loop closure sederhana
  - auto-pause saat speed rendah stabil
  - auto-resume saat gerak kembali stabil
  - baseline resume tidak ikut menambah distance

Tidak ada:
- gating akurasi
- deteksi loncatan GPS

### Minimum finish guard memang sengaja dimatikan

Di `active_workout_screen.dart`, blok:
- `// 🔥 PRODUCTION VALIDASI DISTANCE`

sudah dikomentari, sehingga run sangat pendek tetap bisa masuk flow finish selama punya cukup titik.

### Guard end-run yang tersisa sangat minimal

Di `workout_controller.dart`, `end()` hanya membuang session jika:
- `state.points.length < 2`

Artinya:
- bukan minimum distance
- bukan minimum durasi
- bukan minimum movement quality

### Sync & history sekarang lebih kuat

Di `lari_sync_service.dart` dan `history_controller.dart`:
- queue lokal menyimpan `created_at`, `retry_count`, `last_error`, dan `path_wkt`
- state lokal `pending`, `processing`, dan `quarantined` ikut tampil di history
- sync gagal tidak langsung menghapus archive lokal
- history card sekarang bisa menampilkan error sync singkat

## 5. Fitur Pendukung Alur Game Yang Seharusnya Ada

Untuk rilis awal gameplay conquest yang stabil, fitur penunjang yang paling penting:

### Validitas Run
- minimum distance save guard
- minimum durasi atau minimum displacement guard
- GPS jump / speed limiter
- accuracy threshold untuk sample
- suspicious run marker jika pola terlalu aneh

### Pause Intelligence
- auto pause saat user benar-benar berhenti
- auto resume setelah gerak stabil 10-15 detik
- skip first segment setelah resume
- visual state jelas: running / auto-paused / paused-manual

### Sync Resilience
- retry yang jelas
- local archive tetap aman walau sync gagal
- reason error yang bisa dibaca user/dev
- dedupe upload agar run tidak dobel

### Claim Clarity
- indikator loop hampir tertutup
- indikator loop valid
- penjelasan saat run selesai tapi claim gagal
- status run final yang konsisten: `pending`, `processing`, `captured`, `finished`, `quarantined`

### Recovery & Safety
- restore session setelah app mati mendadak
- save snapshot periodik
- accidental finish protection final

## 6. Prioritas Rilis

### P0
- hidupkan kembali minimum distance guard
- hidupkan kembali speed limiter frontend
- audit backend velocity anomaly
- implement resume jump protection
- pastikan run gagal sync tetap muncul di history

### P1
- implement auto pause / auto resume 15 detik
- tambah accuracy gating
- tambah run validity feedback di UI
- finalize status run flow

### P2
- restore interrupted session
- ghost mode yang benar-benar aktif
- richer workout telemetry

## 7. Kesimpulan

Workout MVP saat ini cukup untuk demo loop sederhana:
- start
- lari
- finish
- sync
- lihat history

Namun untuk rilis awal yang stabil, proteksi validitas run masih kurang. Beberapa fitur yang user anggap “hilang” ternyata memang:
- belum ada
- atau pernah ada sebagai intent/backlog
- atau sengaja dinonaktifkan untuk testing

Audit ini sebaiknya dipakai sebagai acuan sebelum mengaktifkan batch perbaikan workout production-readiness.

## 8. Conquest Rule Clarification

Rule gameplay yang harus diikuti implementasi aktif:
- loop conquest tidak boleh dibatasi hanya `start A -> kembali ke A`
- `lasso run` valid:
  - user berangkat dari `A`
  - menuju `B`
  - membentuk loop tertutup di sekitar `B`
  - kembali dekat ke `B`
- hasilnya:
  - area loop di sekitar `B` bisa diklaim
  - segmen `A -> B` yang tidak ikut tertutup tetap menjadi `pending_trail`
- `pending_trail` punya window lanjutan 72 jam sesuai schema dan game design
