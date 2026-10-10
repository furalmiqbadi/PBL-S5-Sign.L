# 📁 Folder: `lib/views/edit/`

## 🎯 Fungsi Utama
Menyimpan antarmuka halaman Edit Profil — form untuk mengubah data profil pengguna seperti foto, nama, username, bio, dan kata sandi.

---

## 👤 Penanggung Jawab
**Frontend Developer (Ihsan)**

---

## 📌 Apa yang Diisi di Sini?
- `edit_profile_screen.dart`:
  - **Foto Profil**: Avatar besar dengan tombol kamera overlay untuk mengganti foto (akses galeri / kamera).
  - **Form Field**:
    - Nama Lengkap
    - Username
    - Bio (teks pendek)
    - Email (read-only / tampilkan saja)
  - **Tombol Simpan**: `GradientButton` yang memanggil Controller untuk menyimpan perubahan.
  - **Validasi Inline**: Pesan error di bawah field jika input tidak valid (mis. username sudah terpakai, nama terlalu pendek).
- `change_password_screen.dart`:
  - Form terpisah untuk mengubah kata sandi (password lama, password baru, konfirmasi).
  - Indikator kekuatan password (lemah/sedang/kuat).

---

## 🔗 Hubungan dengan Komponen Lain
- Diakses dari tombol "Edit Profil" di halaman `ProfileScreen`.
- Juga bisa diakses dari baris profil ringkas di `SettingScreen`.
- Ini adalah halaman terpisah (di-push), **bukan** tab di `MainShell`.
- Data profil disimpan via Controller → Service → Firestore (dikerjakan tim Backend).
- Ganti foto memanfaatkan image picker (bisa ditambahkan nanti ke dependencies).

---

## ⚠️ Aturan Arsitektur
- ❌ **TIDAK BOLEH** memanggil Firestore atau service langsung dari View.
- ✅ **HANYA** memanggil method Controller via `context.read<T>()` atau `Consumer<T>`.
