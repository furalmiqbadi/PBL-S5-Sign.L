# 📁 Folder: `lib/views/auth/`

## 🎯 Fungsi Utama
Menyimpan seluruh layar/halaman yang berkaitan dengan proses autentikasi pengguna.

---

## 📌 Apa yang Diisi di Sini?
- `auth_views.dart`: `LoginPage`, `RegisterPage`, `ForgotPage`, `ResetPage`, plus
  helper navigasi `openHome`, `openSesuaiRole`, dan `konfirmasiKeluar` (dialog
  keluar yang dipakai bersama oleh tab Profil, Pengaturan, dan panel admin).
- `register_profile_page.dart`: langkah kedua pendaftaran (foto profil + nama
  tampilan) yang dibuka otomatis setelah akun dibuat. Bisa dilewati.
- `auth_recovery_listener.dart`: menangkap event `PASSWORD_RECOVERY` dan membuka
  `ResetPage`.
- `role_select_page.dart`: halaman pilihan role saat pendaftaran.

## Alur pendaftaran
1. `RegisterPage` — username, email, kata sandi, konfirmasi, setuju S&K.
2. `RegisterProfilePage` — foto profil + nama tampilan, lalu masuk otomatis ke
   beranda/panel admin sesuai role.

## Simpan sesi (save login)
`Supabase.initialize` di `main.dart` memakai `persistSession: true`,
`autoRefreshToken: true`, dan `localStorage: SecureSessionStorage`, sehingga
token disimpan **terenkripsi** (Android Keystore / iOS Keychain), bukan sebagai
teks biasa di `SharedPreferences`. Saat aplikasi dibuka lagi:

1. `_determineInitialHome` melihat ada tidaknya sesi tersimpan.
2. Bila ada, `_SessionGate` memanggil `SessionBootstrap.periksa()` — sesi yang
   kedaluwarsa diperbarui dengan refresh token (batas 10 detik).
3. Sesi ditolak server → sesi dibersihkan dan `LoginPage` tampil. Gagal karena
   jaringan → pengguna tetap dianggap masuk agar aplikasi bisa dipakai lagi saat
   koneksi pulih.
4. `_SessionLanding` membaca role lalu membuka beranda/panel admin.

Logout (`konfirmasiKeluar` → `AuthService.logout`) menghapus sesi tersimpan
sehingga pembukaan berikutnya kembali ke `LoginPage`.

---

## 🔗 Hubungan dengan Komponen Lain:
- Menggunakan `AuthController` untuk mengirimkan data input form ke `AuthService`.
- Menampilkan indikator loading saat proses login/register sedang berjalan berdasarkan state dari `AuthController.isLoading`.
- Menampilkan popup dialog error atau snackbar jika login gagal (`AuthController.errorMessage`).
