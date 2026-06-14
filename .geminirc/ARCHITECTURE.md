# LARI - Core Architecture (Lightweight Backend Strategy)

## 1. System Philosophy: "Thick Client, Thin Server"
Untuk menjaga biaya server (Supabase) tetap rendah dan performa tetap tinggi, LARI menggunakan pendekatan di mana **sebagian besar kalkulasi geospasial berat dilakukan di perangkat pengguna (Client-Side)** menggunakan **h3_flutter/latlong2**, bukan membebani database.

## 2. GPS Data Optimization Pipeline (Anti-Lag & Payload Reduction)
Masalah utama aplikasi lari adalah data koordinat yang masif (bisa ribuan titik per sesi).

*   **Langkah 1: Raw Tracking (Geolocator)**
    Merekam titik GPS setiap detik ke dalam stream Riverpod.
*   **Langkah 2: Real-time Jitter Smoothing (latlong2)**
    Menggunakan algoritma penyederhanaan jalur secara *real-time* di client untuk membuang getaran GPS (garis zigzag) agar lintasan lurus.
*   **Langkah 3: Chain-Code Angle Extraction (Pengurangan 90% Payload)**
    Sistem menghitung *bearing* antar titik. Jika berlari lurus di jalan yang sama, titik tengah **dibuang**. Sistem hanya menyimpan **Inflection Points** (titik belokan/sudut). 
    *Hasil: Payload JSON yang dikirim ke Supabase menjadi sangat kecil (hanya bentuk geometrisnya saja, bukan riwayat detiknya).*

## 3. Territory Capture & PostGIS Strategy
Mengklaim wilayah membutuhkan pengecekan tumpang tindih (*intersection*).

*   **Client-Side Check:** App mendeteksi *Closed-Loop* (jalur lari bertemu dengan jalur awal radius 20m) menggunakan latlong2. Jika tertutup, app mengirimkan array "Polygon" ke Supabase.
*   **Backend Validation (PostGIS):** 
    Backend tidak menyimpan ribuan poligon yang bertumpuk. Saat user berhasil mengklaim area baru, Supabase mengeksekusi RPC (Remote Procedure Call) yang memanggil `ST_Union`.
    *Fungsi:* Menggabungkan poligon baru dengan wilayah lama milik user tersebut menjadi satu `MultiPolygon`. Database hanya menyimpan 1 Row wilayah per user per kecamatan, bukan ratusan row sesi lari.

## 4. Leaderboard & Gamification (Caching)
*   Jangan memanggil query Leaderboard setiap kali user buka app.
*   Gunakan **Supabase pg_cron** untuk mengkalkulasi Rank per Kecamatan setiap 10 menit dan menyimpannya di tabel statis `leaderboard_cache`.
*   Client cukup mengambil (SELECT) dari tabel *cache* ini, membuatnya sangat cepat dan murah.

## 5. Real-time Intelligence (WebSocket Hub)
LARI menggunakan Go WebSocket Hub untuk menyiarkan aktivitas lari secara instan ke seluruh agen yang sedang aktif di "War Room".
*   **Broadcast Trigger:** Setiap kali user berhasil melakukan `/sync/run`, server mengirimkan notifikasi ke Hub.
*   **Live Feed:** Client mendengarkan stream WebSocket dan melakukan invalidasi state (Riverpod) secara otomatis untuk memicu refresh data tanpa polling manual.

## 7. Advanced Geospatial Intelligence (The Accuracy Core)
LARI V3 menggunakan sistem "Dead Reckoning" dan "Adaptive Sampling" untuk mengalahkan standar akurasi aplikasi lari konvensional.
*   **Sensor Fusion (IMU):** Menggabungkan GPS dengan Accelerometer HP. Jika GPS hilang (tunnels), sistem memproyeksikan jalur berdasarkan langkah dan arah hadap fisik.
*   **Tactical Boost:** Secara dinamis meningkatkan frekuensi GPS ke 1Hz (per detik) saat mendeteksi pergerakan *off-road* atau manuver penutupan wilayah (Looping).
*   **Map-Match Proxy:** Algoritma backend yang melakukan *Snap-to-Road* secara cerdas (deviasi < 20m) namun memberikan proteksi jalur asli saat agen lari di area terbuka (lapangan/taman).

## 8. Persistence & Resiliency Strategy
*   **Cache-First UI:** Menggunakan SharedPreferences untuk menyimpan *snapshot* profil terakhir agar UI (Dashboard) tampil instan tanpa menunggu network.
*   **Network Timeouts:** Seluruh request memiliki limit 10 detik dengan *Auto-Fallback* ke data lokal/statis untuk mencegah *infinite loading loops*.
*   **Hybrid Cloud (Supabase Migration):** Migrasi dari Postgres Lokal ke Supabase untuk sinkronisasi data global, sementara Go Backend tetap berfungsi sebagai *High-Performance Spatial Compute Engine*.
