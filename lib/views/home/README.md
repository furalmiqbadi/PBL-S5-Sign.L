# 📁 Folder: `lib/views/home/`

## 🎯 Fungsi Utama
Menyimpan antarmuka halaman beranda (Home) yang mengusung konsep gamifikasi ala Duolingo.

---

## 👤 Penanggung Jawab
**Frontend Developer (Ihsan)** — Merancang UI interaktif ala Duolingo.

---

## 📌 Apa yang Diisi di Sini?
- `home_screen.dart`:
  - **Header Gamifikasi**: Menampilkan status streak harian (ikon api), total koin/permata, dan total XP user.
  - **Learning Path / Map**: Peta jalur belajar berkelok-kelok dengan node lingkaran level (level terkunci, level aktif, dan level yang sudah selesai/bintang emas).
- `level_node_widget.dart`:
  - Komponen lingkaran level yang bisa diklik untuk memulai sesi belajar gestur.
- `streak_dialog.dart`:
  - Dialog pop-up harian yang merayakan konsistensi belajar user dengan efek confetti.

---

## 🔗 Hubungan dengan Komponen Lain:
- Membaca state dari `HomeController` (progres level, poin XP, streak).
- Menavigasi user ke `CameraScreen` saat sebuah modul latihan dipilih.
