# 📁 Folder: `lib/views/` (View Layer)

## 🎯 Fungsi Utama
Folder ini berisi seluruh tampilan antarmuka (User Interface) aplikasi. Ditulis menggunakan `StatelessWidget` atau `StatefulWidget` yang bersih.

---

## 📌 Aturan & Batasan Arsitektur:
1. **Bersih & Pasif (Dumb/Passive UI)**:
   - View hanya bertanggung jawab menampilkan data dan menerima interaksi sentuhan/gestur pengguna.
   - Menggunakan `Consumer<T>`, `context.watch<T>()`, atau `context.read<T>()` dari package `provider` untuk mendengarkan perubahan data di Controller.
2. **Tidak Boleh Memanggil Service Langsung**:
   - ❌ View **TIDAK BOLEH** memanggil `MLService`, `AuthService`, atau Firestore secara langsung.
   - ✅ View **HANYA BOLEH** memanggil method yang disediakan oleh **Controller**.
3. **Desain UI Ala Duolingo**:
   - Tampilan playful, kontras warna tegas, tombol membal (3D effect), feedback animasi Lottie, dan efek confetti saat berhasil menyelesaikan tugas.

---

## 📂 Sub-Folder di Dalam `views/`:
- `auth/`: Halaman Login, Register, Lupa Password, dan Reset Password. 
- `home/`: Halaman Beranda — jalur belajar (learning path), streak, XP, level.
- `camera/`: Halaman Kamera — preview kamera + bounding box + hasil AI. 
- `komunitas/`: Halaman Komunitas — forum diskusi, latihan bersama, leaderboard.
- `profile/`: Halaman Profil — identitas user, statistik, badge/pencapaian.  
- `setting/`: Halaman Pengaturan — preferensi, notifikasi, akun, logout. 
- `edit/`: Halaman Edit Profil — form ubah foto, nama, username, bio, password.
- `widgets/`: Komponen UI kustom reusable (tombol 3D Duolingo, bar progress, header, dll).
