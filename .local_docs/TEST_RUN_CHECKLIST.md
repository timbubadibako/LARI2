# Test Run Checklist

Status: template hasil uji lapangan untuk cycle `tester-ready`.

Cara pakai:
- jalankan skenario
- isi hasil aktual di setiap bagian
- jangan hapus skenario yang gagal; catat gejala dan waktu kejadian
- setelah terisi, file ini jadi sumber koreksi berikutnya

## Environment

- Tanggal test:
- Build/frontend commit:
- Backend deploy/version:
- Device A:
- Device B:
- Network:
- Kecamatan uji:
- Catatan awal:

## Result Legend

- `PASS`: perilaku sesuai ekspektasi
- `FAIL`: perilaku salah atau tidak selesai
- `PARTIAL`: sebagian jalan tetapi ada gap
- `NOT TESTED`: belum diuji

---

## P0.1 Simple Loop Claim

Tujuan:
- memastikan satu user bisa finish run, sync, dan claim territory final

Langkah:
1. Login sebagai User A.
2. Mulai run.
3. Buat loop sederhana yang jelas tertutup.
4. Finish run.
5. Tunggu sync dan finalisasi backend.
6. Cek history User A.
7. Cek map User A.

Ekspektasi:
- run tersimpan
- status run tidak hilang
- territory baru muncul setelah finalisasi
- tidak ada kehilangan archive lokal

Hasil:
- Status: `PASS`
- Waktu finish:
- Waktu territory muncul:
- History:
- Map:
- Log backend terkait:
- Catatan: lolos pada batch 2026-07-02, lanjut fokus ke skenario berikutnya besok.



## P0.2 Lasso Run A -> B -> ... -> B

Tujuan:
- memastikan loop tidak wajib kembali ke titik start awal

Langkah:
1. Login sebagai User A.
2. Mulai dari titik A.
3. Bergerak ke titik B.
4. Bentuk loop tertutup di sekitar B.
5. Finish dekat titik B.

Ekspektasi:
- claim valid
- area tertutup di sekitar B tercapture
- segmen A ke B tidak dianggap area tertutup

Hasil:
- Status: `NOT TESTED`
- Claim valid:
- Bentuk area sesuai:
- Catatan: dijadwalkan lanjut besok.

## P0.3 Pending Trail 72 Jam

Tujuan:
- memastikan tail non-closed tidak hilang dan tetap bisa dilanjutkan

Langkah:
1. Mulai run yang belum menutup loop penuh.
2. Finish atau hentikan flow sesuai skenario aplikasi.
3. Cek state/history lokal.
4. Lanjutkan run berikutnya dalam window yang sama.

Ekspektasi:
- pending trail tetap ada
- trail bisa dilanjutkan
- tidak dibersihkan prematur

Hasil:
- Status: `NOT TESTED`
- Pending trail terlihat:
- Lanjutan berhasil:
- Catatan: dijadwalkan lanjut besok.

## P0.4 Overlap A vs B

Tujuan:
- memastikan cookie-cutter benar-benar mengubah world state

Langkah:
1. User A claim territory lebih dulu.
2. User B refresh sampai territory A terlihat final.
3. User B buat run overlap yang memotong area A.
4. User B finish dan tunggu finalisasi.
5. Cek map User A dan User B.

Ekspektasi:
- area A berkurang
- area B bertambah
- hasil bukan sekadar overlay visual

Hasil:
- Status: `PASS`
- Territory A sebelum:
- Territory A sesudah:
- Territory B sesudah:
- Delay propagasi:
- Log backend terkait:
- Catatan: overlap/cookie-cutter sudah lolos pada batch 2026-07-02.

## P0.5 Sync Fail Preservation

Tujuan:
- memastikan run tidak hilang saat sync gagal

Langkah:
1. Jalankan satu run pendek untuk test.
2. Putus koneksi atau paksa backend reject.
3. Finish run.
4. Cek history dan archive lokal.
5. Kembalikan koneksi bila perlu lalu retry.

Ekspektasi:
- run tetap muncul lokal
- ada status error/pending yang jelas
- retry tidak membuat run dobel

Hasil:
- Status: `PASS`
- Run tetap terlihat:
- Retry berhasil:
- Duplicate claim:
- Error message:
- Catatan: preservasi history lokal saat sync fail sudah lolos pada batch 2026-07-02.

## P1.1 Finish Saat Koneksi Buruk

Tujuan:
- memastikan finish flow tidak korup saat jaringan jelek

Langkah:
1. Mulai run normal.
2. Saat finish, buat jaringan lambat/tidak stabil.
3. Cek hasil lokal, sync queue, dan history.

Ekspektasi:
- run aman di lokal
- tidak hilang
- sync bisa diulang

Hasil:
- Status: `NOT TESTED`
- Queue lokal:
- History:
- Catatan: dijadwalkan lanjut besok.

## P1.2 Pause Resume Noise

Tujuan:
- memastikan pause/resume tidak menciptakan lonjakan distance palsu

Langkah:
1. Mulai run.
2. Pause manual.
3. Bergerak sedikit atau tunggu.
4. Resume.
5. Cek distance dan route.

Ekspektasi:
- tidak ada lonjakan jarak aneh setelah resume
- route tetap masuk akal

Hasil:
- Status: `NOT TESTED`
- Distance jump:
- Route:
- Catatan: dijadwalkan lanjut besok.

## P2.1 Contested Zone Severity

Tujuan:
- memastikan warna hotspot mengikuti jumlah runner

Langkah:
1. Aktifkan 1-2 runner di area berdekatan.
2. Cek hotspot.
3. Tambah jadi 3-4 runner.
4. Tambah jadi 5+ runner.

Ekspektasi:
- 1-2 kuning
- 3-4 oranye
- 5+ merah

Hasil:
- Status: `FAIL`
- 1-2 runner:
- 3-4 runner:
- 5+ runner:
- Catatan: masih ada gap pada contested zone severity, perlu dilanjutkan besok.

## P2.2 Contested Zone Fade Down

Tujuan:
- memastikan hotspot turun intensitas lalu hilang saat runner nonaktif

Langkah:
1. Buat hotspot merah atau oranye.
2. Hentikan runner satu per satu.
3. Amati perubahan warna dan hilangnya hotspot.

Ekspektasi:
- merah turun ke oranye lalu kuning
- hotspot hilang saat tidak ada runner aktif

Hasil:
- Status: `NOT TESTED`
- Urutan fade:
- Waktu hilang:
- Catatan: dijadwalkan lanjut besok.

## P3.1 Share Readiness

Tujuan:
- menentukan apakah build layak dibagikan ke tester umum

Checklist:
- [x] P0.1 lolos
- [ ] P0.2 lolos
- [x] P0.4 lolos
- [x] P0.5 lolos
- [ ] P2.1 lolos
- [ ] P2.2 minimal `PARTIAL` tanpa bug berat
- [ ] log backend cukup untuk debug masalah lapangan

Keputusan:
- Layak dibagikan: `NO`
- Alasan: P0 inti sebagian sudah lolos, tetapi P0.2, P0.3, P1.1, P1.2, P2.2 belum diuji dan P2.1 masih gagal. Lanjut besok dari item-item ini.
- Catatan final:

## Bug Log Tambahan

Gunakan section ini untuk bug yang tidak pas dimasukkan ke skenario di atas.

### Bug 1
- Waktu:
- Skenario:
- Gejala:
- Dugaan:
- Log terkait:

### Bug 2
- Waktu:
- Skenario:
- Gejala:
- Dugaan:
- Log terkait:
