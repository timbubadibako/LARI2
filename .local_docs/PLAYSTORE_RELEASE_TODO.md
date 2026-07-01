# Play Store Release TODO

Status: checklist operasional untuk membawa build saat ini ke kondisi `tester-ready`.

Referensi:
- `.local_docs/WORKOUT_FEATURE_AUDIT.md`
- `.local_docs/GEMINI.md`
- `.local_docs/GAME_DESIGN.md`

## Release Goal

Target cycle ini bukan `production-ready`, tetapi `tester-ready` untuk dibagikan ke rekan sebagai batch tester awal Android.

Kriteria sukses utama:
- loop conquest stabil untuk sekitar 20 tester
- semua tester berada di 1 kecamatan yang sama
- territory final hanya publish setelah backend selesai validasi
- overlap/cookie-cutter benar-benar mengubah world state
- contested zone tampil stabil sebagai indikator visual
- run gagal sync atau claim gagal tidak hilang dari history lokal
- `lasso run` valid: `A -> B -> ... -> B`
- `pending_trail` bertahan 72 jam untuk lanjutan run berikutnya

## Dev Toggle Yang Sengaja Ditahan

Untuk cycle test ini, fitur berikut tetap nonaktif dan harus diperlakukan sebagai `TODO(production)`:
- minimum distance guard
- frontend speed limiter / GPS jump limiter
- backend velocity anomaly / anti-spoofing strict mode

Catatan:
- `hold to finish` tetap `3s` untuk phase test ini
- sebelum kandidat produksi, tiga guard di atas wajib diaktifkan kembali

## Out Of Scope Saat Ini

- social polish lanjutan
- profile polish lanjutan
- realtime gameplay update saat user masih berlari
- contested zone yang mempengaruhi rules conquest
- balancing leaderboard, guild, XP lanjutan

## Product Rules Yang Terkunci

- publish territory ke user lain hanya setelah final state tersimpan
- target finalisasi claim setelah finish: 5-15 detik dalam kondisi normal
- `lasso run` valid jika terbentuk sub-loop tertutup dengan area cukup, tanpa harus kembali ke titik start awal
- tail yang tidak ikut tertutup harus tetap tersimpan sebagai `pending_trail`
- window lanjutan `pending_trail` adalah 72 jam
- jika claim gagal:
  - run tetap ada di history
  - territory tidak berubah
  - user mendapat alasan singkat

## Contested Zone Rules

- contested zone hanya indikator visual untuk rilis awal
- sumber data: semua runner aktif
- radius dasar per runner aktif: 500m
- hotspot ditampilkan hanya dalam radius 20km dari viewer
- severity:
  - 1-2 runner: kuning
  - 3-4 runner: oranye
  - 5+ runner: merah
- overlap beberapa runner membentuk cluster
- cluster padat bisa membuat center gabungan dan radius lebih besar
- saat jumlah runner turun, warna turun bertahap merah -> oranye -> kuning
- saat semua runner cluster nonaktif, hotspot memudar lalu hilang

## P0 Release Gate

P0 adalah syarat minimum supaya build aman dites 2 akun lalu dibagikan ke 20 tester.

- [x] Archive lokal sekarang menyimpan `created_at`, `retry_count`, `last_error`, dan `path_wkt`
- [x] History sekarang menampilkan local run berstatus `pending`, `processing`, dan `quarantined`
- [x] Backend `/sync/run` sekarang menolak payload `user_id` yang tidak cocok dengan JWT
- [x] Backend conquest logging sekarang mencatat pending trail merge, cookie-cutter clip, dan result status
- [ ] Verifikasi alur `finish run -> archive lokal -> sync -> backend final -> history`
- [ ] Verifikasi `lasso run A -> B -> ... -> B` menghasilkan claim valid
- [ ] Verifikasi tail non-closed tetap tersimpan sebagai `pending_trail`
- [ ] Verifikasi `pending_trail` masih bisa dipakai lanjut run dalam window 72 jam
- [ ] Verifikasi run gagal sync tidak hilang dari archive/history lokal
- [ ] Verifikasi claim gagal tidak menghapus run dan memberi alasan singkat
- [ ] Verifikasi akun B hanya melihat territory baru setelah backend final
- [ ] Verifikasi overlap benar-benar memotong territory lawan di persistence backend
- [ ] Verifikasi skenario `A claim -> B overlap -> A terpotong -> B bertambah`
- [ ] Verifikasi final claim masih masuk akal di target 5-15 detik pada environment HF

## P1 Field Stability

P1 adalah stabilitas lapangan yang sangat mempengaruhi hasil test, walau tidak selalu memblok total.

- [ ] Audit GPS noise yang mempengaruhi loop closure dan area
- [x] Auto-pause dan auto-resume 15 detik sudah ada di controller
- [x] Resume baseline sekarang tidak menambah lonjakan distance langsung setelah resume
- [ ] Audit pause/resume agar tidak menambah segmen palsu setelah berhenti
- [ ] Verifikasi finish saat koneksi buruk atau app sempat di-background-kan
- [ ] Verifikasi retry sync aman dan tidak membuat double claim
- [x] Status run untuk tester sekarang mencakup `pending`, `processing`, `captured`, `finished`, `quarantined`
- [ ] Verifikasi stale cache map tidak menahan state lama terlalu lama
- [x] Logging minimum untuk investigasi sync failure dan dispute claim sudah ditambah di backend

## P2 Contested Zone

P2 tetap penting untuk cycle ini karena user menandai contested zone sebagai prioritas.

- [x] Presence stale runner sekarang dipangkas otomatis agar hotspot tidak hidup terus
- [x] Own runner position sekarang di-dedupe supaya tidak double count dengan echo presence
- [ ] Verifikasi source of truth runner aktif untuk hotspot
- [ ] Verifikasi radius dasar 500m per runner aktif
- [ ] Verifikasi severity `kuning/oranye/merah` sesuai jumlah runner
- [ ] Verifikasi cluster overlap membentuk hotspot gabungan yang masuk akal
- [ ] Verifikasi hotspot dibatasi ke radius 20km dari viewer
- [ ] Verifikasi fade down saat runner berkurang
- [ ] Verifikasi hotspot hilang saat semua runner nonaktif
- [ ] Verifikasi overlay dan icon warning tetap ringan di device tester

## P3 Tester Ops

P3 fokus ke kesiapan operasi test, observability, dan handoff ke batch tester.

- [ ] Tentukan kecamatan uji tunggal
- [ ] Siapkan minimal 2 akun inti untuk test overlap terstruktur
- [ ] Siapkan panduan singkat untuk tester umum
- [ ] Siapkan checklist hasil test yang bisa diisi manual
- [ ] Catat log yang wajib dicek saat terjadi sync fail atau claim aneh
- [ ] Catat acceptance gate sebelum APK dibagikan lebih luas

## P4 Production Deferred

Jangan diaktifkan di cycle test ini. Cukup dicatat dan dikomentari jelas untuk aktivasi nanti.

- [ ] Aktifkan minimum distance guard
- [ ] Aktifkan frontend speed limiter
- [ ] Aktifkan backend velocity anomaly
- [ ] Naikkan `hold to finish` ke durasi produksi
- [ ] Tambahkan accuracy gating per sample
- [ ] Tambahkan suspicious-run handling yang lebih strict

## Acceptance Gate Sebelum Share Ke Tester

- [ ] Skenario `A claim -> B lihat -> B overlap` lolos end-to-end
- [ ] `lasso run` lolos tanpa harus kembali ke titik start awal
- [ ] `pending_trail` tidak hilang setelah run belum closed
- [ ] contested zone tampil dan turun severity dengan benar
- [ ] sync fail tidak menghapus run lokal
- [ ] history tetap menampilkan run pending/quarantined/failed
- [ ] backend logs cukup jelas untuk debug auth, sync, claim, dan overlap

## Open Questions Yang Bisa Diputuskan Nanti

- threshold cluster overlap yang paling masuk akal untuk contested zone
- radius eskalasi hotspot besar saat cluster padat
- kapan contested zone mulai mempengaruhi gameplay
- kapan dev guard dikembalikan untuk produksi
