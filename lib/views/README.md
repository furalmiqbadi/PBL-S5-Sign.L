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
- `auth/`: Halaman Login, Register, Lupa Password, dan Onboarding.
- `camera/`: Halaman Kamera untuk pendeteksian gestur bahasa isyarat secara real-time / jepretan.
- `home/`: Halaman Utama menampilkan jalur modul belajar (learning path), info Level, XP, dan Streak.
- `widgets/`: Komponen UI kustom yang dapat digunakan berulang kali di berbagai halaman (seperti tombol 3D Duolingo, bar progress, dialog hasil).
