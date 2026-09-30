# 📁 Folder: `lib/controllers/` (Thin Controller Layer - Provider)

## 🎯 Fungsi Utama
Folder ini berisi class **Thin Controller** yang mewarisi `ChangeNotifier` dari package `provider`. Controller bertindak sebagai jembatan (mediator) antara **View (UI)** dan **Service (Backend/ML)**.

---

## 📌 Aturan Kritis Arsitektur (Thin Controller):
1. **Hanya Mengelola State UI**:
   - Berisi variabel status seperti `bool isLoading`, `String? errorMessage`, data hasil proses untuk UI, dsb.
   - Menggunakan method `notifyListeners()` setiap kali state berubah agar UI melakukan rebuild.
2. **DILARANG Keras Menaruh Logika Berat**:
   - ❌ **JANGAN** taruh pemrosesan gambar, kalkulasi matematika, atau query langsung Firebase di sini.
   - ✅ Controller hanya bertugas memanggil method dari class yang ada di `lib/services/`.
   - Contoh alur: View memanggil `controller.detectGesture(image)` -> Controller set `isLoading = true; notifyListeners();` -> Controller panggil `_mlService.predict(image)` -> Controller simpan hasil -> `isLoading = false; notifyListeners();`.

---

## 📄 File Controller yang Akan Dibuat di Sini:
1. `camera_controller.dart` (atau `gesture_controller.dart`):
   - Mengontrol state kamera (apakah kamera sudah siap, apakah sedang memproses frame/foto).
   - Memanggil `MLService` untuk verifikasi gestur tangan yang ditangkap kamera.
   - Menyimpan hasil prediksi akhir (`GestureResultModel`) untuk dibaca oleh `CameraScreen`.
2. `auth_controller.dart`:
   - Mengelola state form autentikasi (loading saat login/register, pesan error jika password salah).
   - Memanggil `AuthService` dan `FirestoreService`.
3. `home_controller.dart`:
   - Mengambil data profil user (Level, total XP, status streak harian).
   - Mengatur state animasi progress dan daftar level belajar.
4. `learning_controller.dart`:
   - Mengatur navigasi modul belajar, pengecekan jawaban kuis, dan update progres setelah level selesai.

---

## 👥 Penanggung Jawab Tim:
- **Frontend Developer (Salma)** didukung oleh **Backend & ML Engineer**:
  - Salma mendefinisikan state apa saja yang dibutuhkan UI.
  - Backend/ML menghubungkan method Controller ke Service yang telah mereka buat.
- **QA / Project Manager**: Memeriksa bahwa controller tetap tipis (*thin*) dan tidak terkontaminasi logika database/tensor secara langsung.
