# LARI - UI & Branding Guidelines (Midnight Sapphire)

## 1. Aesthetic Concept: "Elite Stealth Luxe"
Meninggalkan gaya lama (Neobrutalism), LARI kini menggunakan desain **Modern Glassmorphism** dengan nuansa teknologi elit.
*   **Vibe:** Profesional, Analitis, Taktis, Mewah.
*   **Kata Kunci:** Liquid Glass, Platinum, Midnight, Precision.

## 2. Typography
*   **Branding & Headers (Bulky Formal):** `DM Serif Display`. Digunakan khusus untuk teks raksasa (Hero), nama aplikasi "Zenith/LARI", dan angka statistik utama.
*   **Body & UI Data:** `Jost` (Light, Regular, Medium, Bold). Digunakan untuk teks label, tombol, dan instruksi fungsional agar mudah dibaca di layar kecil.

## 3. Core Color Palette
*   **Background:** Deep Navy/Obsidian (`#010413` atau `#020617`).
*   **Primary Accent (Sapphire):** Sky Blue (`#38bdf8` to `#0ea5e9`).
*   **Success/Claim:** Emerald Green (`#10b981`).
*   **Alert/Emergency:** Crimson Red (`#ef4444`).
*   **Text:** Platinum Silver (`#f1f5f9` & gradien teks silver).

## 4. Dominion Colors (Territory & Guild Mapping)
Gunakan palet "Cool Tones" untuk area di peta agar tidak merusak tema Stealth:
*   *Sapphire Blue, Emerald, Indigo, Violet, Cyan, Slate, Platinum.*
*   Maksimal 8-12 warna berbeda di layar agar map tidak berantakan.

## 5. UI Components & Glassmorphism Rules
*   **Glass Containers:** Selalu gunakan `backdrop-filter: blur(20px)` ke atas. Background hitam/navy transparan (`rgba(15, 23, 42, 0.6)`).
*   **Borders:** Border sangat tipis (`1px solid rgba(255, 255, 255, 0.05)`).
*   **Glow:** Hindari drop-shadow biasa. Gunakan shadow berwarna senada dengan aksen (misal: shadow biru untuk tombol biru) untuk menciptakan efek *Glow* teknologi tinggi.
*   **Input Forms:** Gunakan style *Underlined* transparan, bukan kotak input biasa. Garis bawah menyala saat di-klik (Focus state).

## 6. Interaction Logic
*   **Start:** Sekali tap biasa.
*   **Pause:** Ditahan (Hold) 2 detik.
*   **Claim/Close Loop:** Tap 2 kali dengan cepat (Double tap).
*   **SOS/Emergency:** Ditahan (Hold) 3 detik pada widget khusus.
*   **Pocket Mode:** Digeser (Swipe to unlock) untuk menghindari salah pencet.

*Rujukan visual: Buka `.geminirc/refrensi/*.html` di browser.*
