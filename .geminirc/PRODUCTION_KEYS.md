# 🔑 SUPABASE & HF CONFIGURATION

Silakan isi data ini dari Dashboard Supabase & Hugging Face kamu untuk referensi kita:

### 1. Supabase Connection (Untuk Go Backend)
- **DATABASE_URL:** `postgres://postgres.[PROJECT_REF]:[PASSWORD]@aws-0-[REGION].pooler.supabase.com:6543/postgres?sslmode=disable`
  > *Tips: Ambil di Supabase Settings > Database > Connection String (Mode: Transaction/Session).*

### 2. Supabase Client (Untuk Flutter)
- **SUPABASE_URL:** `https://[PROJECT_REF].supabase.co`
- **SUPABASE_ANON_KEY:** `[YOUR_ANON_KEY]`

### 3. Hugging Face Space URL (Setelah Deploy)
- **HF_API_URL:** `https://[USER_NAME]-[SPACE_NAME].hf.space`

---

# 🚀 STEP-BY-STEP PRODUCTION DEPLOY (GO TO HF SPACES)

Ikuti langkah ini untuk menaikkan Backend Go kamu:

### Langkah 1: Buat Space Baru di Hugging Face
1. Buka [huggingface.co/new-space](https://huggingface.co/new-space).
2. Nama Space: `lari-backend` (bebas).
3. SDK: Pilih **Docker**.
4. Template: Pilih **Blank**.
5. Privacy: **Public** (agar Flutter bisa akses).

### Langkah 2: Set Environment Variables (PENTING)
1. Di Space kamu, masuk ke tab **Settings**.
2. Cari bagian **Variables and secrets**.
3. Tambahkan Variable Baru:
   - Key: `DATABASE_URL`
   - Value: (Isi dengan Connection String Supabase kamu di atas).
   - Key: `PORT`
   - Value: `7860`

### Langkah 3: Push Code
Karena laptop mati, jika kamu bisa akses Git dari device lain atau lewat Web Interface HF:
1. Pastikan folder `backend/` memiliki file `Dockerfile` yang sudah kita buat tadi.
2. Upload/Push seluruh isi folder `backend/` (termasuk `go.mod`, `cmd/`, `internal/`, dll) ke root repository Space tersebut.

### Langkah 4: Verifikasi
1. Tunggu proses **Building** selesai (lihat log di tab App).
2. Jika sudah **Running**, coba akses: `https://[USER_NAME]-[SPACE_NAME].hf.space/health`
3. Jika muncul `{"status":"up"}`, selamat! Backend Go kamu sudah hidup di awan.

---
*Next Action: Beritahu saya jika sudah "UP", kita akan langsung update Flutter agar menembak ke URL baru tersebut!*
