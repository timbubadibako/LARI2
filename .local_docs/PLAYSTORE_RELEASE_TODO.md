# Play Store Release TODO

Status: working draft untuk rilis awal Android dengan fokus gameplay core.

Referensi audit implementasi workout aktif:
- lihat `.local_docs/WORKOUT_FEATURE_AUDIT.md`

## Release Goal

Rilis awal harus membuktikan bahwa loop conquest dan territory conflict berjalan stabil untuk sekitar 20 tester di 1 kecamatan yang sama.

Target perilaku utama:
- user A menyelesaikan run dan menutup loop
- claim territory divalidasi backend dan tersimpan final
- user B melihat hasil territory user A setelah proses finalisasi
- user B membuat overlap dan territory user A terpotong sesuai cookie-cutter logic
- contested zone tampil sebagai indikator visual near real-time untuk runner aktif
- lasso run valid: user bisa berangkat dari titik A, membentuk loop tertutup di titik B, lalu kembali ke titik B tanpa harus menutup loop ke titik A
- tail yang belum tertutup tetap disimpan sebagai `pending_trail` dengan window lanjutan 72 jam

Catatan implementasi saat ini:
- minimum distance guard, frontend speed limiter, dan backend velocity anomaly sengaja tetap nonaktif untuk mode dev
- jika kandidat rilis sudah stabil, ketiga guard ini harus diaktifkan kembali sebelum final release

## Out Of Scope Untuk Rilis Awal

- social polish
- profile polish
- realtime territory update saat user masih berlari
- contested zone yang mempengaruhi gameplay rules
- leaderboard, guild, XP balancing lanjutan

Catatan:
- poin dasar untuk setiap run selesai tetap harus ada, agar mudah dikoneksikan ke progression nanti

## Product Rules Yang Sudah Terkunci

- publish territory ke user lain hanya setelah validasi dan cookie-cutter selesai
- target waktu finalisasi claim setelah finish: 5-15 detik
- lasso run `A -> B -> ... -> B` dianggap valid jika membentuk sub-loop tertutup dengan area cukup
- bagian tail yang tidak ikut tertutup tetap aktif sebagai `pending_trail`
- window lanjutan `pending_trail` adalah 72 jam
- jika claim gagal:
  - run tetap masuk history
  - territory tidak berubah
  - user mendapat alasan singkat
- semua tester difokuskan di 1 kecamatan yang sama

## Contested Zone Rules

- contested zone adalah indikator visual saja untuk rilis awal
- sumber data: semua runner aktif, bukan hanya yang dekat territory existing
- radius dasar per runner: 500m
- tampil ke semua user, tetapi hanya hotspot dalam radius 20km dari posisi user yang dimuat
- skala warna:
  - 1-2 runner: kuning
  - 3-4 runner: oranye
  - 5+ runner: merah
- jika beberapa radius overlap dalam toleransi yang wajar, sistem membentuk cluster
- cluster besar bisa memakai center gabungan dan radius lebih besar
- hotspot tetap hidup selama masih ada runner aktif di cluster
- saat jumlah runner turun, warna harus turun bertahap merah -> oranye -> kuning
- saat semua runner nonaktif, hotspot memudar bertahap lalu hilang

## A. Core Territory Pipeline

- [ ] Audit flow finish run frontend -> backend -> persistence -> map refresh
- [ ] Pastikan closed-loop detection konsisten dan tidak terlalu sensitif terhadap GPS noise
- [ ] Pastikan payload run yang dikirim cukup untuk final territory calculation
- [ ] Finalize satu kontrak status run yang jelas: pending, processing, captured, rejected
- [ ] Simpan run history walau claim territory gagal
- [ ] Tampilkan alasan singkat saat claim gagal
- [ ] Pastikan publish ke akun lain hanya terjadi setelah final state tersimpan
- [ ] Pastikan final claim target 5-15 detik realistis di environment uji

## B. Cookie-Cutter Overlap

- [ ] Audit implementasi overlap dan pemotongan territory existing di backend
- [ ] Verifikasi bahwa overlap benar-benar mengurangi area lawan, bukan hanya overlay visual
- [ ] Verifikasi multi-user scenario: A claim -> B overlap -> A territory terpotong -> B territory bertambah
- [ ] Verifikasi urutan update persistence agar world state tetap konsisten jika dua finisher hampir bersamaan
- [ ] Definisikan expected behavior untuk overlap kecil, tipis, atau nyaris bersentuhan
- [ ] Tambahkan logging/debug trace untuk investigasi claim dispute

## C. Near Real-Time World Refresh

- [ ] Tentukan mekanisme refresh final state setelah run selesai: push event, invalidation, atau short polling
- [ ] Pastikan akun lain menerima state baru hanya setelah backend final
- [ ] Pastikan map dashboard refresh territory tanpa perlu force restart app
- [ ] Pastikan stale cache tidak membuat user melihat territory lama terlalu lama

## D. Contested Zone System

- [ ] Definisikan model data runner aktif untuk contested zone
- [ ] Tentukan source of truth aktif/nonaktif runner
- [ ] Implement radius dasar 500m per runner aktif
- [ ] Implement density bucketing 1-2 kuning, 3-4 oranye, 5+ merah
- [ ] Implement clustering overlap antar runner aktif
- [ ] Implement merged hotspot center dan radius eskalasi untuk cluster padat
- [ ] Batasi query/render hotspot ke radius 20km dari user
- [ ] Implement fade down bertahap saat jumlah runner berkurang
- [ ] Implement removal saat semua runner cluster nonaktif
- [ ] Tambahkan icon warning yang jelas di hotspot
- [ ] Pastikan overlay tidak merusak performa map

## E. Stability And Anti-Bad-Data

- [ ] Audit GPS noise handling yang mempengaruhi closure dan area
- [ ] Audit pause/resume flow agar tidak menciptakan lompatan area palsu
- [ ] Audit run finish saat koneksi jelek atau app di-background-kan
- [ ] Pastikan sync retry aman tanpa duplikasi claim
- [ ] Pastikan backend validation failure tidak merusak run history
- [ ] Review dev toggles di `.local_docs/GEMINI.md` sebelum kandidat rilis

## F. Minimal Progression Hook

- [ ] Beri poin dasar untuk setiap run selesai
- [ ] Pisahkan poin dasar run dari bonus territory agar progression nanti mudah disambungkan
- [ ] Pastikan data points/per-run reward tersimpan di tempat yang mudah dipakai ulang

## G. Test Readiness For 20 Testers

- [ ] Tentukan kecamatan uji tunggal untuk fase awal
- [ ] Siapkan skenario uji terstruktur untuk 20 tester:
  - [ ] simple loop claim
  - [ ] overlapping claim antar 2 akun
  - [ ] beberapa runner aktif memicu contested zone
  - [ ] retry/network jelek saat finish
  - [ ] claim gagal tapi history tetap tersimpan
- [ ] Buat seed/test accounts dan panduan test ringkas
- [ ] Siapkan observability minimum: logs, failed claims, processing time, overlap disputes

## H. Release Gating

- [ ] Jangan masuk Play Store testing sebelum skenario A claim -> B lihat -> B potong territory A benar-benar lolos end-to-end
- [ ] Jangan masuk Play Store testing sebelum contested zone tampil stabil di map
- [ ] Jangan masuk Play Store testing sebelum run gagal tetap tersimpan dengan benar
- [ ] Jangan masuk Play Store testing sebelum latency finalisasi claim acceptable untuk tester

## Open Questions Yang Masih Bisa Diputuskan Nanti

- threshold toleransi cluster contested zone yang tepat
- radius eskalasi hotspot besar saat cluster padat
- apakah contested zone nanti memberi bonus gameplay
- kapan leaderboard/guild/XP territory mulai disambungkan penuh
