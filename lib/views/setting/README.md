# 📁 Folder: `lib/views/setting/`

## 🎯 Fungsi Utama
Menyimpan antarmuka halaman Pengaturan (Settings) — memungkinkan pengguna mengatur preferensi aplikasi, notifikasi, dan manajemen akun.

---

## 👤 Penanggung Jawab
**Frontend Developer (Ihsan)** — Merancang UI interaktif ala Duolingo.

---

## 📌 Apa yang Diisi di Sini?
- `setting_screen.dart`:
  - **Profil Ringkas**: Baris atas menampilkan foto kecil + nama user + tombol navigasi ke Edit Profil.
  - **Grup Pengaturan** (dikelompokkan dengan section header):
    - 🔔 **Notifikasi**: Toggle pengingat belajar harian, waktu pengingat.
    - 🎨 **Tampilan**: Mode gelap/terang, ukuran font.
    - 🔊 **Suara & Haptic**: Toggle efek suara feedback benar/salah, getaran.
    - 🌐 **Bahasa Aplikasi**: Pilihan bahasa antarmuka (Indonesia / English).
    - 🔒 **Akun & Privasi**: Ubah kata sandi, hapus akun.
    - ℹ️ **Tentang**: Versi aplikasi, lisensi, kebijakan privasi.
  - **Tombol Keluar (Logout)**: Button merah di bagian bawah halaman.

---

## 🔗 Hubungan dengan Komponen Lain
- Diakses dari ikon gear (⚙) di `ProfilHeader` pada halaman Profil.
- Ini adalah halaman terpisah (di-push), **bukan** tab di `MainShell`.
- Preferensi disimpan via `SharedPreferences` (ditangani Service layer).
- Aksi logout memanggil `AuthController.logout()` lalu navigasi ke `LoginPage`.

---

## ⚠️ Aturan Arsitektur
- ❌ **TIDAK BOLEH** memanggil SharedPreferences atau AuthService langsung dari View.
- ✅ **HANYA** memanggil method Controller via `context.read<T>()` atau `Consumer<T>`.
