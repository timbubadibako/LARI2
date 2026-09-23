# 🚀 LARI2 (Lari-Lari) — Developer & AI Agent Central Hub

> **Tujuan Dokumen:** Berkas ini dirancang sebagai panduan tunggal (Single Source of Truth) lintas AI agent dan developer untuk memahami produk, arsitektur teknis, aturan pengembangan, serta alur kerja dalam proyek **LARI2**.

---

## 1. Ringkasan Produk & Konsep Inti
**LARI2** adalah aplikasi kebugaran berbasis lokasi (*geospatial location-based fitness app*) yang menggabungkan pelacakan lari fisik dengan sistem perebutan wilayah digital (*territory conquest*).

### A. Gameplay Loop Utama
1. **Mulai Workout:** Pemain memulai sesi lari dari dashboard taktis.
2. **Pelacakan GPS:** Pergerakan fisik pemain dilacak secara real-time.
3. **Loop Conquest:** Pemain berlari membentuk rute melingkar tertutup (*closed loop*).
4. **Klaim Wilayah:** Saat rute tertutup terdeteksi, area di dalam lingkaran rute otomatis diklaim sebagai wilayah milik pemain/guild pada peta digital.
5. **Cookie-Cutter Territory:** Pemain dapat merebut wilayah pemain lain dengan cara membuat rute baru yang bertumpang tindih (*overlap*). Bagian yang overlap akan otomatis dipotong dan kepemilikannya dialihkan ke pemain baru.

### B. Struktur Kompetisi & Guild
* **Fase Awal (Individu):** Pemain mengklaim wilayah untuk progres pribadi (XP, Level, Area).
* **Fase Lanjut (Guild):** Setelah melewati batas level tertentu, pemain wajib bergabung ke salah satu dari **7 guild eksklusif per kecamatan/kelurahan**. Seluruh klaim wilayah akan berkontribusi langsung pada peringkat guild di tingkat kecamatan.
* **Season System:** Reset wilayah secara periodik (misal bulanan) dengan pemberian hadiah berdasarkan statistik di season sebelumnya.

---

## 2. Struktur Repositori (Repo Shape)
Repositori proyek dibagi menjadi tiga direktori utama:

```
├── frontend/          # Aplikasi mobile berbasis Flutter & Dart
├── backend/           # API server, spatial engine, & database schema (Go/Golang)
├── .local_docs/       # Dokumentasi lokal, backlog issues, dan status pengembangan
└── docs/              # Dokumentasi eksternal dan aset gambar/desain
```

---

## 3. Tech Stack Lengkap

### A. Frontend (Aplikasi Mobile)
* **Framework:** Flutter & Dart
* **State Management:** Riverpod (Notifier & Providers)
* **Map Engine:** MapLibre GL (untuk merender peta taktis & batas wilayah)
* **Penyimpanan Lokal:** Hive (untuk menyimpan data workout secara offline)
* **Klien Integrasi:** Supabase Flutter Client

### B. Backend & Spatial Engine
* **Bahasa Pemrograman:** Go (Golang)
* **Database:** PostgreSQL dengan ekstensi **PostGIS** untuk operasi spasial presisi tinggi
* **Real-time & Sinkronisasi:** WebSockets untuk sinkronisasi pergerakan/kehadiran (*presence*) pemain
* **Spatial Processing:** Menggunakan PostgreSQL spatial functions (seperti `ST_Difference` untuk cookie-cutter, `ST_Area` untuk luas wilayah, dan `ST_Polygonize` untuk pembentukan rute).

---

## 4. Algoritma Inti Geospasial
Dalam memproses pergerakan fisik menjadi area digital, sistem menggunakan algoritma berikut:
* **GPS Filtering:** Menyaring data koordinat GPS yang memiliki akurasi rendah untuk menghindari distorsi lintasan.
* **Haversine Formula:** Digunakan untuk kalkulasi jarak antar koordinat latitude/longitude.
* **Loop Closure Detection:** Logika untuk memverifikasi apakah koordinat terakhir lari telah mendekati titik awal rute dalam jarak toleransi tertentu dan memiliki perpindahan jarak (*displacement*) minimum agar tidak terhitung sebagai jitter GPS.
* **Polygonization:** Mengonversi daftar koordinat dari rute tertutup menjadi bentuk geometri wilayah (*polygon*).
* **Spatial Intersection & Difference:** Digunakan untuk menghitung konflik wilayah dan memotong polygon lawan jika terjadi *overlapping* klaim.

---

## 5. Konfigurasi Pengembangan vs Produksi (GEMINI Toggles)
Untuk mempercepat iterasi pengujian tanpa harus berlari secara fisik di luar ruangan, beberapa validasi telah dimodifikasi atau dinonaktifkan di lingkungan pengembangan (**Development Mode**).

> [!WARNING]
> Sebelum melakukan kompilasi/rilis untuk **Produksi**, pastikan nilai-nilai berikut dikembalikan ke konfigurasi aslinya:

| No | Fitur / Validasi | Status Dev | Lokasi Kode | Catatan |
|---|---|---|---|---|
| 1 | **Minimum Distance to Save** | 🔴 DISABLED | `frontend/lib/features/workout/presentation/screens/active_workout_screen.dart` | Di-comment agar workout jarak 0.00 KM bisa disimpan. (Cari: `// 🔥 PRODUCTION VALIDASI DISTANCE`) |
| 2 | **GPS Jump Filter (Speed Limiter)** | 🔴 DISABLED | `frontend/lib/features/workout/application/workout_controller.dart` | Di-comment agar pengujian menggunakan kendaraan cepat tidak ditolak. (Cari: `// 🔥 PRODUCTION SPEED LIMITER`) |
| 3 | **Velocity Anomaly Check** | 🔴 DISABLED | `backend/internal/api/run_handler.go` | Di-comment agar backend Go tidak menolak run > 40 km/h. (Cari: `// 🔥 PRODUCTION SPEED LIMITER`) |
| 4 | **Finish Button Hold Duration** | 🕒 MODIFIED (3 Detik) | `active_workout_screen.dart` & `app_strings.dart` | Dikurangi dari 6 detik ke 3 detik untuk mempercepat penutupan sesi latihan. |

---

## 6. Protokol Lintas AI Agent & Aturan Kerja
Setiap AI agent yang bekerja di repositori ini **wajib** mematuhi pedoman operasional berikut:

### A. Alur Kerja Sebelum Melakukan Perubahan
1. **Baca Konteks Terlebih Dahulu:** Bacalah minimum berkas berikut sebelum melakukan modifikasi kode:
   * `README.md`
   * `PRODUCT_CONTEXT.md`
   * `.local_docs/ISSUES.md` (Gunakan berkas ini sebagai sumber backlog utama)
   * `.local_docs/GAME_DESIGN.md`
   * `.local_docs/GEMINI.md`
2. **Gunakan CodeGraph:** Manfaatkan alat `codegraph_explore` terlebih dahulu untuk memahami call-path dan ketergantungan simbol sebelum melakukan grep atau pembacaan file manual.
3. **Pahami Kontrak API:** Jika perubahan memengaruhi sinkronisasi data atau auth, periksa skema database di `backend/internal/db/` sebelum berasumsi tentang struktur data.

### B. Gaya Penulisan Kode & UI
* **Konsistensi UI:** Pertahankan bahasa desain taktis/neon cyberpunk yang sudah ada, kecuali ada permintaan khusus untuk perbaikan UI.
* **Tipografi:** Gunakan *sans-serif* yang bersih dan profesional untuk elemen fungsional. **Dilarang keras** menggunakan font bergaya ekspresif atau dekoratif (seperti 'font-cloude').
* **Pilihan Istilah (Copywriting):** Hindari kata **"Ritual"** untuk merujuk pada pesanan, langganan, atau proses bisnis. Gunakan istilah bisnis standar seperti *Pesanan*, *Kemitraan*, atau *Berlangganan*.

### C. Standar Verifikasi
Setiap perubahan kode harus diverifikasi secara mandiri menggunakan pengujian lokal yang relevan sebelum diserahkan:
* **Frontend:** Jalankan `flutter test` atau analisis statis `flutter analyze`.
* **Backend:** Jalankan pengujian Go menggunakan `go test ./...`.

---

## 7. Status Fitur Aplikasi

| Fitur | Status | Detail Teknis |
|---|---|---|
| **Loop Conquest** | ✅ Selesai | Validasi satu sesi lari |
| **Multi-Day Loop** | 🚧 Parsial | Backend support di DB (`pending_trails`), frontend perlu diintegrasikan |
| **Territory Cookie-Cutter** | ✅ Selesai | Diimplementasikan di Go spatial engine |
| **Guild System (7/Kecamatan)** | 🚧 Parsial | Backend siap, frontend dalam tahap pengerjaan |
| **Ghost Mode** | ✅ Selesai | Pelacakan lokal tanpa presence geospasial |
| **Season Reset & Leaderboard**| 🚧 Parsial | Struktur database dan logika worker backend sudah ada |
| **Social / Party Mode** | ❌ Belum Ada | Masuk dalam rencana pengembangan lanjutan |
