# 📁 Folder: `lib/views/profile/`

## 🎯 Fungsi Utama
Menyimpan antarmuka halaman Profil pengguna — menampilkan identitas, statistik belajar, pencapaian (badge/achievement), dan akses ke pengaturan akun.

---

## 👤 Penanggung Jawab
**Frontend Developer (Ihsan)** — Merancang UI interaktif ala Duolingo.

---

## 📌 Apa yang Diisi di Sini?
- `profile_screen.dart`:
  - **Kartu Profil**: Foto profil besar, nama, username, bio singkat, dan tombol "Edit Profil".
  - **Statistik Ringkas**: Card/pill yang menampilkan total XP, level saat ini, streak terpanjang, dan jumlah gestur yang dikuasai.
  - **Grafik Progres**: Visualisasi progres belajar (bisa bar chart mingguan atau ring/donut chart persentase penguasaan materi).
  - **Badge / Pencapaian**: Grid ikon pencapaian (mis. "Streak 7 Hari", "100 Gestur Benar", "Level 10") — yang terkunci ditampilkan abu-abu.
- `badge_detail_dialog.dart`:
  - Dialog yang muncul saat badge ditekan, menjelaskan syarat pencapaian dan progres saat ini.

---

## 🔗 Hubungan dengan Komponen Lain
- Header sudah tersedia: `ProfilHeader` di `lib/views/widgets/profil_header.dart`.
- Tombol gear (⚙) di `ProfilHeader` menavigasi ke `SettingScreen` (folder `setting/`).
- Tombol "Edit Profil" menavigasi ke `EditProfileScreen` (folder `edit/`).
- Membaca data dari Controller profil (nanti dibuat) → Service → Firestore.

---

## ⚠️ Aturan Arsitektur
- ❌ **TIDAK BOLEH** memanggil Firestore atau service langsung dari View.
- ✅ **HANYA** memanggil method Controller via `context.read<T>()` atau `Consumer<T>`.
