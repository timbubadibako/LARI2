# 🚀 STRIDE.IO - MVP FINAL PUSH ROADMAP (2026-06-14)

Target: Sistem Production-Ready dengan Cloud Backend & UI Polish.

## 🟩 PHASE 1: CLOUD INFRASTRUCTURE (Backend & DB)
- [x] **Supabase Setup:**
    - [x] Eksekusi Schema PostGIS (Tabel `territories`, `pending_trails`, `profiles`, `runs`).
    - [x] Konfigurasi RLS (Row Level Security) agar data aman.
    - [x] Ambil `Connection String` (DATABASE_URL) untuk Go.
- [ ] **Go Deployment (HF Spaces):**
    - [ ] Push folder `backend/` ke Hugging Face Docker Space.
    - [ ] Set Env Variables: `DATABASE_URL` (Supabase) & `PORT=7860`.
    - [ ] Verifikasi Endpoint `/health` via Browser.

## 🟦 PHASE 2: FLUTTER UI/UX OPTIMIZATION
- [x] **Dynamic Theming:**
    - [x] Hubungkan `territory_color` faksi ke ekor lari (Active Polyline).
    - [x] Update `MapRouteLineLayerController` untuk mendukung pergantian warna real-time.
- [x] **Conquest Feedback:**
    - [x] Tambahkan animasi/overlay "TERRITORY_SECURED" saat loop berhasil.
    - [x] Tambahkan Haptic Feedback (Getar) saat loop tertutup.
- [ ] **Telemetry Polish:**
    - [ ] Perhalus transisi angka PACE dan DISTANCE agar tidak berkedip (vibration filter).

## 🟨 PHASE 3: MULTIPLAYER & SYNC LOGIC
- [x] **Real-time Grid:**
    - [x] Implementasi Supabase Stream di Flutter untuk melihat area user lain.
    - [x] Update `MapRouteLineLayerController` untuk render area lawan (warna berbeda).
- [ ] **Batch Sync Optimization:**
    - [ ] Tes pengiriman 20-titik/30-detik ke HF Spaces.
    - [ ] Pastikan algoritma `ST_Polygonize` di Cloud berhasil memotong area lawan.

## 🟥 PHASE 4: SIMPLE ADMIN PANEL (Web/Internal)
- [x] **Admin Dashboard:**
    - [x] Buat screen sederhana (atau webview) untuk monitor:
        - [x] Total active agents (users).
        - [x] Total area captured globally.
        - [x] List aktivitas lari terbaru (Real-time feed).
- [ ] **Moderation Tools:**
    - [ ] Tombol "Nuke" untuk mereset area tertentu jika terdeteksi spoofing.

---
*Status: 🛠️ In Progress*
*Goal: EOD Production Ready.*
