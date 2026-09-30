# 📁 Folder: `lib/services/` (Service Layer)

## 🎯 Fungsi Utama
Folder ini adalah **jantung logika berat (Heavy Business Logic) dan integrasi eksternal**. Semua komunikasi dengan pihak ketiga (Firebase, Machine Learning TFLite, Sensor Kamera, Local Storage) diletakkan di sini.

---

## 📌 Aturan & Batasan Arsitektur:
1. **Pemisahan Logika**:
   - Seluruh pemrosesan berat (seperti memanipulasi byte gambar, kalkulasi tensor, operasi CRUD Firestore, login FirebaseAuth) HANYA boleh ada di dalam file service.
2. **Bebas State UI**:
   - Service **TIDAK BOLEH** mengelola state UI (seperti `isLoading`, `errorMessage`, `notifyListeners()`). State UI adalah tanggung jawab Controller.
   - Service mengembalikan nilai data mentah/model (`Future<UserModel>`, `Future<GestureResultModel>`, `Stream`, dsb.) atau melempar exception jika terjadi kegagalan.

---

## 📄 3 File Utama yang Wajib Dibuat di Sini:
1. `ml_service.dart`:
   - Memuat file model AI (`assets/ml/model.tflite`) dan label (`assets/ml/labels.txt`) menggunakan `tflite_flutter`.
   - Melakukan pra-pemrosesan gambar (crop, resize ke 224x224, normalisasi pixel 0.0 - 1.0) menggunakan package `image`.
   - Menjalankan inferensi pada tensor input dan mengembalikan prediksi gestur beserta tingkat kepercayaan (*confidence*).
2. `auth_service.dart`:
   - Menangani autentikasi Firebase (`firebase_auth`).
   - Fungsi: `signInWithEmail`, `signUpWithEmail`, `signInWithGoogle`, `signOut`, dan mendengarkan stream perubahan status user (`authStateChanges`).
3. `firestore_service.dart`:
   - Menangani operasi database Cloud Firestore (`cloud_firestore`).
   - Fungsi: `createUserProfile`, `getUserProfile`, `updateUserXpAndStreak`, `saveLessonProgress`, dan stream data leaderboard.
4. *(Opsional)* `local_storage_service.dart`:
   - Menyimpan cache sementara (seperti token sesi atau cache streak) menggunakan `shared_preferences`.

---

## 👥 Penanggung Jawab Tim:
- **ML Engineer (Abdul Ghofur)**: Penanggung jawab penuh untuk `ml_service.dart`.
- **Backend Developers (Rifo & Fatahillah)**: Penanggung jawab penuh untuk `auth_service.dart` dan `firestore_service.dart`.
