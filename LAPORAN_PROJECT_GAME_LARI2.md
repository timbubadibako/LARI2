# Laporan Project Pembuatan Game 2024

## Konteks Proyek

LARI2 adalah aplikasi kebugaran berbasis mobile yang mengadopsi pendekatan gamifikasi ke dalam aktivitas lari di dunia nyata. Dalam proyek ini, aktivitas berlari tidak hanya berfungsi sebagai olahraga, tetapi juga menjadi mekanik utama permainan. Pemain bergerak di lingkungan nyata, merekam lintasan GPS, membentuk rute tertutup, lalu mengklaim wilayah digital pada peta sebagai bentuk pencapaian dalam permainan.

Pendekatan ini menempatkan LARI2 pada irisan antara aplikasi fitness tracker dan location-based game. Dengan demikian, proyek ini dapat diposisikan sebagai game berbasis kebugaran dengan sistem territory conquest, progression, dan kompetisi antarpemain.

---

# A. Proposal Project Game (Initiation)

## 1. Nama Aplikasi Permainan

**LARI2: Your City, Your Territory**

## 2. Latar Belakang dan Motivasi

Saat ini banyak aplikasi kebugaran hanya berfokus pada pencatatan aktivitas seperti jarak tempuh, durasi, dan kalori. Walaupun bermanfaat, pendekatan tersebut sering kali kurang mampu menjaga motivasi pengguna dalam jangka panjang. Sebaliknya, game memiliki kekuatan dalam membangun keterlibatan melalui tujuan, tantangan, reward, kompetisi, dan rasa progres.

Berdasarkan kondisi tersebut, LARI2 dikembangkan sebagai aplikasi permainan berbasis kebugaran yang menggabungkan aktivitas lari dengan mekanik penaklukan wilayah. Motivasi utama dari pengembangan aplikasi ini adalah:

- meningkatkan minat masyarakat untuk berolahraga secara konsisten;
- menjadikan aktivitas lari lebih menarik melalui elemen permainan;
- menciptakan pengalaman fitness yang kompetitif, sosial, dan berbasis lokasi nyata;
- memanfaatkan data GPS dan peta digital untuk menghadirkan gameplay yang inovatif.

Dengan pendekatan ini, pengguna tidak hanya “berlari untuk sehat”, tetapi juga “berlari untuk menguasai wilayah”.

## 3. Deskripsi Aplikasi Permainan

### a. Deskripsi Game

LARI2 adalah game berbasis lokasi nyata di mana pemain melakukan aktivitas lari di dunia fisik untuk membentuk lintasan tertutup. Jika lintasan tersebut berhasil menutup area tertentu, maka area di dalam lintasan akan diklaim sebagai wilayah milik pemain pada peta digital. Semakin banyak area yang dikuasai, semakin tinggi posisi pemain dalam sistem persaingan.

Game ini menggabungkan unsur fitness tracking, geospatial territory control, dan kompetisi sosial. Data GPS pemain menjadi input utama yang menentukan hasil permainan.

### b. Storytelling atau Cerita dari Aplikasi Permainan

LARI2 membawa tema futuristik-taktikal di mana setiap pemain berperan sebagai agen lapangan yang ditugaskan untuk memperluas dominasi wilayah di kota mereka. Setiap misi lari adalah operasi lapangan. Ketika agen berhasil menutup lintasan, sistem akan menandai area tersebut sebagai zona yang berhasil direbut.

Dalam narasi permainan, kota dibagi menjadi area-area yang dapat diperebutkan. Pemain harus terus bergerak, memperluas pengaruh, mempertahankan dominasi, dan bersaing dengan agen lain untuk menjadi penguasa wilayah terbaik.

### c. Genre

Genre utama dari LARI2 adalah:

- **Real World Simulation**
- **Strategy**
- **Location-Based Fitness Game**
- **Gamified Sports Application**

### d. Competition Modes

Mode kompetisi yang digunakan pada LARI2 adalah:

- **Single Player Progression**
  Pemain dapat berlari sendiri untuk meningkatkan statistik, XP, level, dan total area.
- **Competitive Multiplayer**
  Pemain bersaing secara tidak langsung melalui penguasaan wilayah dan leaderboard.
- **Guild-Based Competition**
  Pada fase lanjutan, pemain dapat bergabung dengan guild dan berkontribusi terhadap dominasi wilayah guild.

### e. Level Permainan

LARI2 tidak menggunakan level tradisional seperti stage 1, stage 2, atau map linear. Sebagai gantinya, permainan menggunakan:

- level pemain berbasis XP;
- tingkat progres berdasarkan total area yang diklaim;
- tingkat kompetisi berbasis leaderboard;
- fase perkembangan dari pemain individu menuju anggota guild.

### f. Target Audience

Target pengguna dari aplikasi permainan ini adalah:

- mahasiswa dan pekerja muda yang menyukai olahraga ringan hingga sedang;
- pengguna aplikasi lari atau fitness tracker;
- pemain yang menyukai game kompetitif berbasis progres;
- masyarakat usia produktif yang tertarik pada gamifikasi aktivitas sehari-hari.

### g. Platform Game

Platform utama game ini adalah:

- **Mobile Game**
- sistem operasi yang ditargetkan: **Android** dan berpotensi **iOS**

Pemilihan platform mobile dilakukan karena game sangat bergantung pada GPS, mobilitas pengguna, serta penggunaan di luar ruangan.

### h. Game Bisnis Konsep

Konsep bisnis LARI2 dapat dikembangkan melalui beberapa model, antara lain:

- kostumisasi tampilan profil, warna wilayah, badge, atau efek visual premium;
- event musiman atau seasonal challenge;
- sistem guild premium atau komunitas eksklusif;
- sponsor brand olahraga dalam bentuk event atau challenge tertentu;
- integrasi fitur ekspor, statistik lanjutan, atau social sharing premium.

Konsep bisnis ini tetap menjaga gameplay inti agar tidak pay-to-win, melainkan lebih berfokus pada peningkatan pengalaman pengguna.

## 4. Algoritma yang Akan Digunakan

Dalam pengembangan LARI2, algoritma yang relevan dan digunakan sebagai dasar mekanik sistem meliputi:

- **Haversine Formula**
  Digunakan untuk menghitung jarak antar titik GPS.
- **Loop Closure Detection**
  Digunakan untuk menentukan apakah lintasan pemain membentuk rute tertutup.
- **Polygonization pada data lintasan**
  Digunakan untuk mengubah lintasan GPS menjadi area polygon yang dapat diklaim.
- **Area Calculation**
  Digunakan untuk menghitung luas area yang berhasil dikuasai.
- **Spatial Intersection dan Difference**
  Digunakan untuk mendeteksi konflik wilayah dan memotong area lawan jika terjadi overlap.
- **Ranking Algorithm**
  Digunakan untuk menyusun leaderboard berdasarkan total area yang dikuasai.

Secara konsep, algoritma-algoritma tersebut menjadi inti dari sistem permainan karena menentukan hasil dari aktivitas fisik pemain di dunia nyata.

---

# B. Game Design Document (Pre Production)

## 1. Mechanics and Players’ Role

LARI2 adalah permainan yang menjadikan aktivitas lari di dunia nyata sebagai input utama permainan. Pemain bergerak secara fisik sambil membawa perangkat mobile yang merekam koordinat GPS. Setiap lintasan lari akan divisualisasikan sebagai garis pada peta. Jika pemain berhasil membentuk lintasan tertutup, sistem akan mengubah area tertutup tersebut menjadi wilayah klaim.

Peran pemain adalah sebagai agen lapangan yang menjalankan misi ekspansi wilayah. Pemain harus memilih rute, bergerak secara strategis, menutup loop, dan mengoptimalkan penguasaan area untuk naik peringkat.

## 2. GameFlow / Game Layout Chart

Alur permainan LARI2 secara umum adalah sebagai berikut:

1. Pemain membuka aplikasi.
2. Pemain melihat dashboard peta dan status wilayah.
3. Pemain memulai sesi workout / misi lari.
4. Sistem mulai merekam titik GPS pemain.
5. Pemain berlari membentuk lintasan tertentu.
6. Sistem memeriksa apakah lintasan membentuk loop tertutup.
7. Jika loop tertutup valid, sistem membentuk area polygon.
8. Area tersebut dihitung luasnya dan diterapkan sebagai klaim wilayah.
9. Jika terjadi overlap dengan wilayah lawan, sistem memotong wilayah lawan sesuai area overlap.
10. Hasil lari ditampilkan pada summary.
11. XP, area, dan leaderboard diperbarui.
12. Pemain kembali ke dashboard untuk memulai misi berikutnya.

## 3. Core Loop

Core loop pada LARI2 adalah:

**Start Run -> Track GPS Route -> Close Loop -> Claim Territory -> Gain Progress -> Compete Again**

Penjelasan:

- pemain memulai aktivitas lari;
- sistem melacak lintasan;
- pemain berusaha membentuk loop tertutup;
- loop menghasilkan wilayah klaim;
- pemain memperoleh progres berupa area, XP, dan posisi kompetitif;
- pemain terdorong untuk kembali berlari agar memperluas wilayah atau mengalahkan lawan.

Core loop ini menunjukkan bahwa aktivitas fisik dan sistem permainan saling terhubung langsung.

## 4. Objective

Tujuan utama permainan adalah:

- mengklaim wilayah sebanyak mungkin;
- memperluas total area kekuasaan pemain;
- meningkatkan level dan progres akun;
- mendominasi leaderboard lokal;
- berkontribusi pada dominasi guild pada fase lanjutan.

Secara jangka pendek, pemain ingin menyelesaikan satu loop yang valid. Secara jangka menengah, pemain ingin memperbesar area total. Secara jangka panjang, pemain ingin menjadi pemain atau guild paling dominan di wilayah tertentu.

## 5. Player Roles and Mechanics Rules

### a. Player Roles

Dalam permainan ini pemain berperan sebagai:

- pelari;
- penakluk wilayah;
- kompetitor dalam leaderboard;
- anggota guild pada fase progression lanjutan.

### b. Mechanics Rules

Aturan inti permainan:

1. Pemain harus mengaktifkan GPS untuk memulai permainan.
2. Aktivitas lari direkam sebagai sekumpulan titik latitude-longitude.
3. Titik GPS yang terlalu buruk akurasinya dapat diabaikan dalam proses validasi.
4. Loop dianggap valid jika pemain kembali mendekati titik awal atau titik anchor tertentu dalam jarak toleransi tertentu.
5. Loop harus memiliki displacement minimum agar tidak dianggap hasil jitter GPS.
6. Area klaim hanya diberikan jika luas area melampaui threshold minimum.
7. Jika area klaim bertabrakan dengan wilayah lawan, bagian overlap akan diproses sebagai konflik teritorial.
8. Wilayah pemain diperbarui setelah proses merge dan clipping selesai.
9. Hasil run dapat berstatus selesai biasa, pending trail, atau captured.

### c. Win Condition

Karena LARI2 bersifat persisten dan tidak berbasis match pendek, kondisi menang dapat didefinisikan sebagai:

- berhasil menutup loop dan mengklaim area;
- menempati posisi tertinggi di leaderboard;
- menjadi penguasa sektor tertentu pada akhir season;
- membawa guild menjadi dominan di wilayah kompetisi.

### d. Lose Condition

Lose condition dalam konteks permainan ini bersifat relatif, misalnya:

- gagal menutup lintasan sehingga tidak mendapatkan klaim area;
- area yang dikuasai direbut pemain lain;
- gagal mempertahankan posisi leaderboard;
- run ditolak jika tidak memenuhi validasi sistem.

## 6. Competition Modes

LARI2 mengandung beberapa bentuk kompetisi:

- **Single Player Challenge**
  Pemain fokus pada pencapaian pribadi.
- **Asynchronous Multiplayer Competition**
  Pemain saling bersaing melalui wilayah dan ranking tanpa harus online bersamaan.
- **Guild Competition**
  Pemain berkontribusi terhadap akumulasi area guild.
- **Seasonal Competition**
  Pada periode tertentu, hasil dominasi wilayah dibandingkan untuk menentukan pemenang season.

## 7. Genre

Genre LARI2 dapat dijelaskan sebagai:

- game kebugaran berbasis lokasi;
- strategy conquest;
- real world simulation;
- gamified sports application.

## 8. Target Audience

### a. Usia

Target usia utama:

- 17 tahun ke atas
- terutama 18 sampai 35 tahun

### b. Penggemar game / genre game

Target pengguna yang cocok:

- penggemar aplikasi lari dan fitness tracker;
- pengguna yang menyukai kompetisi non-konvensional;
- pemain game strategi ringan;
- pengguna yang tertarik pada aplikasi berbasis peta dan GPS;
- komunitas olahraga yang ingin pengalaman lebih interaktif.

## 9. Story Board

Storyboard sederhana LARI2 adalah sebagai berikut:

### Scene 1: Dashboard Awal

Pemain membuka aplikasi dan melihat peta wilayah, status profil, level, dan area yang telah dikuasai.

### Scene 2: Memulai Misi

Pemain menekan tombol start untuk memulai sesi lari. Sistem mengaktifkan tracking GPS dan timer.

### Scene 3: Aktivitas Lari

Pemain bergerak di dunia nyata. Jalur pergerakan ditampilkan sebagai garis pada peta.

### Scene 4: Loop Ditutup

Pemain berhasil kembali ke area awal atau anchor point. Sistem mendeteksi loop tertutup.

### Scene 5: Klaim Wilayah

Sistem membentuk polygon wilayah dari lintasan, menghitung luas, dan menampilkan area yang berhasil dikuasai.

### Scene 6: Hasil Misi

Pemain melihat summary run: jarak, waktu, pace, area baru, dan progres akun.

### Scene 7: Kompetisi Berlanjut

Pemain kembali ke dashboard untuk melihat perubahan wilayah dan posisi leaderboard.

## 10. User Interface

Konsep antarmuka LARI2 menggunakan gaya taktis, futuristik, dan sporty. Fokus UI berada pada peta dan informasi misi.

Komponen UI utama:

- **Map Dashboard**
  Menampilkan peta utama, wilayah, lokasi pemain, dan informasi status.
- **Workout Screen**
  Menampilkan metrik real-time seperti jarak, pace, waktu, dan status tracking.
- **Summary Screen**
  Menampilkan hasil akhir run dan area yang diklaim.
- **Profile dan Progress**
  Menampilkan level, XP, statistik total, dan rank.
- **Leaderboard / Social**
  Menampilkan posisi pemain atau guild dibanding pemain lain.

Prinsip UI:

- jelas dibaca saat aktivitas outdoor;
- memprioritaskan peta sebagai elemen utama;
- menggunakan identitas visual yang kuat agar terasa seperti game, bukan sekadar aplikasi pencatat lari biasa.

## 11. Dynamics

### a. General Summary of Progression

Sistem progression LARI2 dibangun dari beberapa lapisan:

- jumlah run yang diselesaikan;
- total jarak lari;
- jumlah loop yang berhasil ditutup;
- total area yang dikuasai;
- XP dan level akun;
- kontribusi ke guild;
- pencapaian season dan badge.

Progress pemain tidak hanya ditentukan oleh seberapa jauh ia berlari, tetapi juga seberapa strategis ia membentuk rute untuk memaksimalkan klaim wilayah.

### b. Level

Level pada LARI2 merepresentasikan perkembangan pemain dari pengguna baru menjadi pemain kompetitif. Kenaikan level berkaitan dengan:

- akumulasi XP;
- frekuensi aktivitas;
- keberhasilan klaim area;
- kontribusi kompetitif.

Pada desain sistem ini, level juga dapat menjadi syarat untuk membuka fitur tertentu seperti guild participation, event, atau tantangan lanjutan.

## 12. Core Mechanic

### a. Control

Kontrol utama pemain bersifat sederhana:

- menekan tombol start, pause, resume, dan end untuk workout;
- menggerakkan karakter secara nyata dengan tubuh pengguna;
- melihat hasil klaim dan progres dari UI.

Karena ini adalah game berbasis dunia nyata, bentuk kontrol utama bukan joystick virtual, tetapi gerakan fisik pemain itu sendiri.

### b. Object Game

Objek utama dalam permainan meliputi:

- titik GPS pemain;
- garis rute/lintasan;
- area polygon hasil loop;
- wilayah milik pemain dan lawan;
- elemen progres seperti XP, level, rank, dan badge.

## 13. Penjelasan Konsep Algoritma yang Digunakan

Bagian ini sangat penting karena LARI2 memiliki fondasi game mechanic yang erat dengan pemrosesan data geospasial.

### 1. Haversine Formula

Algoritma ini digunakan untuk menghitung jarak antar titik koordinat GPS. Dalam LARI2, rumus Haversine dipakai untuk:

- menghitung total jarak lari;
- membantu validasi perpindahan antar titik;
- mendukung logika deteksi loop.

### 2. GPS Filtering

Data GPS mentah dapat mengandung noise atau akurasi buruk. Oleh karena itu, sistem menerapkan penyaringan titik agar:

- lintasan lebih stabil;
- hasil perhitungan jarak lebih masuk akal;
- proses area claim tidak rusak oleh loncatan GPS yang tidak valid.

### 3. Loop Closure Detection

Algoritma ini mengecek apakah titik akhir lintasan kembali mendekati titik awal atau anchor tertentu. Selain kedekatan titik, sistem juga melihat apakah lintasan sempat menjauh cukup jauh agar loop yang terdeteksi bukan sekadar jitter GPS.

Konsep ini menjadi inti mekanik karena tanpa loop tertutup, area tidak dapat diklaim.

### 4. Polygonization

Setelah loop dinyatakan valid, rangkaian titik GPS diubah menjadi line geometry lalu dibentuk menjadi polygon. Polygon inilah yang merepresentasikan wilayah hasil lari.

Dalam konsep implementasinya, linework diproses menjadi area tertutup sehingga sistem dapat mengetahui batas wilayah klaim.

### 5. Area Calculation

Setelah polygon terbentuk, sistem menghitung luas area dalam satuan meter persegi. Nilai ini digunakan untuk:

- menentukan apakah klaim memenuhi batas minimum;
- menambahkan total area pemain;
- menyusun leaderboard.

### 6. Spatial Intersection dan Cookie-Cutter Conflict

Jika area klaim baru bertabrakan dengan wilayah milik pemain lain, sistem melakukan deteksi intersection. Bagian wilayah lawan yang overlap dengan klaim baru dipotong dan dipindahkan sesuai aturan permainan.

Mekanik ini penting karena membuat game tidak hanya tentang “menambah area kosong”, tetapi juga tentang “merebut area lawan”.

### 7. Leaderboard Ranking

Setelah total area tiap pemain tersimpan, sistem menyusun ranking berdasarkan nilai area yang dikuasai. Ini memberikan motivasi kompetitif dan menjadi bentuk reward sosial bagi pemain.

---

# Kesimpulan

LARI2 merupakan proyek yang menggabungkan pendekatan gamifikasi dengan aplikasi kebugaran melalui pemanfaatan data GPS, peta digital, dan sistem territory conquest. Dalam konteks tugas pembuatan game, LARI2 dapat diposisikan sebagai game berbasis aktivitas nyata yang memiliki elemen inti permainan berupa objective, mechanics, progression, challenge, reward, dan competition.

Keunggulan utama konsep ini adalah kemampuannya mengubah aktivitas olahraga menjadi pengalaman yang lebih menarik, kompetitif, dan bermakna. Dengan memanfaatkan algoritma geospasial seperti loop detection, polygonization, dan area conflict resolution, LARI2 tidak hanya menjadi aplikasi pencatat lari, tetapi juga sistem permainan yang memiliki nilai teknis dan inovatif.

Dokumen ini dapat dijadikan dasar untuk penyusunan proposal formal dan GDD yang kemudian disesuaikan kembali dengan format kelas, identitas mahasiswa, dan kebutuhan presentasi.
