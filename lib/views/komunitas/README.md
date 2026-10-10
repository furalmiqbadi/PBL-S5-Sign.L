# 📁 Folder: `lib/views/komunitas/`

## 🎯 Fungsi Utama
Menyimpan antarmuka halaman Komunitas — tempat pengguna berdiskusi, berbagi pengalaman belajar, dan berlatih bersama pengguna lain.

---

## 👤 Penanggung Jawab
**Frontend Developer (Ihsan)**

---

## 📌 Apa yang Diisi di Sini?
- `komunitas_screen.dart`:
  - **Feed Komunitas**: Daftar postingan/thread pengguna dengan avatar, nama, waktu, dan konten teks/gambar.
  - **Tombol Buat Postingan**: FAB atau tombol untuk menulis postingan baru.
  - **Tab/Filter**: Filter berdasarkan kategori (Diskusi, Tips, Latihan Bareng).
- `komunitas_detail_screen.dart`:
  - Halaman detail satu postingan dengan kolom komentar.
  - Menampilkan jumlah like, komentar, dan tombol interaksi.
- `leaderboard_screen.dart`:
  - Papan peringkat pengguna berdasarkan XP atau streak.
  - Tampilan podium 3 besar + daftar peringkat di bawahnya.

---

## 🔗 Hubungan dengan Komponen Lain
- Header sudah tersedia: `KomunitasHeader` di `lib/views/widgets/komunitas_header.dart`.
- Membaca data dari Controller komunitas (nanti dibuat).
- Data postingan dan leaderboard diambil via Service → Firestore (dikerjakan tim Backend).

---

## ⚠️ Aturan Arsitektur
- ❌ **TIDAK BOLEH** memanggil Firestore atau service langsung dari View.
- ✅ **HANYA** memanggil method Controller via `context.read<T>()` atau `Consumer<T>`.
