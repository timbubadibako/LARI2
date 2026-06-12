# LARI V3: Advanced Geospatial Intelligence

Dokumen ini merangkum algoritma akurasi dan mekanik taktis yang digunakan dalam LARI V3 untuk mengalahkan standar aplikasi lari konvensional (Strava-tier).

---

## 1. Algoritma Akurasi (The "Strava-Killer" Engine)

### A. Tactical Boost (Dynamic GPS Sampling)
Berbeda dengan Strava yang biasanya menggunakan interval sampling statis (per 1-5 detik), LARI V3 menggunakan **Adaptive Sampling Rate**:
- **On-Road Mode:** Sampling standar untuk menghemat baterai.
- **Off-Road/High-Speed Mode:** Jika jarak GPS ke jalan terdekat > 15m, frekuensi sampling ditingkatkan ke **1Hz (per 1 detik)** secara otomatis.
- **Loop-Closure Mode:** Saat mendeteksi agent sedang mendekati titik awal (menutup wilayah), sampling diperketat untuk akurasi luas wilayah yang presisi hingga level centimeter.

### B. Map-Match Proxy (Hybrid Snap-to-Road)
Mekanisme pembersihan jalur yang cerdas di sisi backend:
- **Smart Snap:** Menempelkan jalur ke sumbu jalan jika deviasi < 20m.
- **Field Protection:** Jika agent berlari di area terbuka (lapangan/taman), snapping dimatikan agar jalur asli tetap terjaga (tidak ditarik paksa ke jalan raya).

### C. Dead Reckoning (Sensor Fusion) - *PROPOSED*
Menggabungkan data GPS dengan **IMU (Accelerometer + Gyroscope)** HP:
- Jika agent masuk ke bawah jembatan/terowongan (GPS Signal Lost), algoritma akan mengestimasi posisi berdasarkan jumlah langkah dan arah hadap HP.
- Hasilnya: Jalur tidak "terputus" di peta meski sinyal satelit hilang.

---

## 2. Game Mechanics: Faction-Based Conquest

### A. H3 Hexagonal Dominion
- Dunia dibagi menjadi ribuan hexagon (Uber H3 Index).
- Lari di dalam hexagon untuk memberikan "Dominion Points" ke fraksimu (**PHANTOM, VANGUARD, dll**).
- Hexagon yang paling sering dilewati fraksi tertentu akan berubah warna sesuai warna fraksi tersebut di peta global.

### B. Loop Capture (Area Mastery)
- **Mechanic:** Berlari dalam bentuk lingkaran tertutup (A-to-A).
- **Effect:** Seluruh hexagon di dalam lingkaran tersebut otomatis dikuasai (Capture) secara instan.
- **Bonus:** Semakin luas area yang ditutup, semakin besar XP and Rank multiplier yang didapat.

### C. Ghost Recon (Stealth Mode)
- **Mechanic:** Aktifkan **Ghost Mode** untuk lari tanpa muncul di peta real-time lawan.
- **Trade-off:** Kamu tidak bisa melakukan "Capture" area, hanya bisa melakukan "Scouting" (melihat pergerakan fraksi lawan).

---

## 3. Ide Mekanik Masa Depan (Beat the Competition)

1. **Phantom Pace Ghosting:** 
   Visualisasikan "Bayangan" (Ghost) lari terbaikmu sebelumnya atau lari lawan fraksi di peta secara real-time. Kamu harus mengejar dan melewati bayangan tersebut untuk melakukan "Overload" pada hexagon mereka.
   
2. **Sector Overload:**
   Jika sebuah hexagon dikuasai lawan, kamu bisa melakukan "Overload" dengan berlari di sana dalam intensitas tinggi (Pace lebih cepat dari pemilik sebelumnya) untuk merebut kepemilikan.

3. **Supply Drops (Checkpoints):**
   Server menaruh virtual "Supply Drops" di area yang jarang dilewati. Agent yang pertama sampai akan mendapatkan "Boost" (misal: 2x Area Capture radius selama 1km).
