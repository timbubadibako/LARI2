# LARI V3: Quick Start & Installation Guide

Ikuti panduan ini setiap kali kamu ingin memulai development atau menjalankan project LARI V3.

---

## 1. Database Setup (Postgres)
Pastikan PostgreSQL kamu sudah jalan dan database `lari` sudah ada.
```bash
# Cek apakah postgres jalan (Linux)
sudo systemctl status postgresql
```

---

## 2. Start Backend (Go)
Buka terminal baru, masuk ke folder root project, lalu jalankan server:
```bash
# Jalankan server dari root
go run backend/cmd/server/main.go
```
*Server akan berjalan di `http://localhost:8080`.*

---

## 3. Physical Device / Emulator Sync (Android)
Jika kamu menggunakan HP Android fisik atau Emulator, kamu **WAJIB** menjalankan command ini agar HP bisa mengakses backend di laptop:
```bash
# Jalankan ini setiap kali HP dicolok ulang atau server restart
adb reverse tcp:8080 tcp:8080
```

---

## 4. Start Frontend (Flutter)
Buka terminal baru, masuk ke folder `frontend`, lalu jalankan aplikasi dengan command khusus ini (untuk mengaktifkan Dev Menu & Filter Log):

```bash
# Jalankan dengan Dev Menu aktif & filter log bersih
flutter run --dart-define=LARI-LARI_ALLOW_DEV_MENU=true | grep -v "ioctl"
```
*Flag `| grep -v "ioctl"` berfungsi untuk menyembunyikan log sampah dari library MapLibre/Linux yang sering mengganggu terminal.*

### Tips Command Cepat (alias):
Kamu bisa simpan ini di `.bashrc` atau `.zshrc` kamu agar tidak perlu ngetik panjang:
```bash
alias run-lari="flutter run --dart-define=LARI-LARI_ALLOW_DEV_MENU=true | grep -v 'ioctl'"
```

---

## 5. Troubleshooting Cepat
- **Username Gak Muncul?** Cek apakah sudah `adb reverse` (Langkah 3).
- **Layar Merah H3?** Abaikan saja, itu log Native H3 di Linux, aplikasi tetap bisa jalan.
- **Data Kosong?** Buka **Dev Menu** (Long press di footer Profile) -> Aktifkan **Fake GPS** -> Lari satu putaran (Loop) -> Klik **Finish**.
