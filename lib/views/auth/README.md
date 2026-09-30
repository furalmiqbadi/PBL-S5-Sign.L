# 📁 Folder: `lib/views/auth/`

## 🎯 Fungsi Utama
Menyimpan seluruh layar/halaman yang berkaitan dengan proses autentikasi pengguna.

---

## 📌 Apa yang Diisi di Sini?
- `login_view.dart`: Tampilan form login dengan email & kata sandi, serta tombol login via Google.
- `register_view.dart`: Tampilan form pendaftaran akun baru (Nama, Email, Password).
- `forgot_password_view.dart`: Tampilan reset kata sandi melalui pengiriman email.

---

## 🔗 Hubungan dengan Komponen Lain:
- Menggunakan `AuthController` untuk mengirimkan data input form ke `AuthService`.
- Menampilkan indikator loading saat proses login/register sedang berjalan berdasarkan state dari `AuthController.isLoading`.
- Menampilkan popup dialog error atau snackbar jika login gagal (`AuthController.errorMessage`).
