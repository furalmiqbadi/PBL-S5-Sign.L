# 📁 Folder: `lib/models/` (Model Layer)

## 🎯 Fungsi Utama
Folder ini digunakan khusus untuk menyimpan **class data murni (Data Transfer Objects / Entities)**. Model merepresentasikan struktur data objek yang digunakan di seluruh aplikasi, baik yang didapat dari Firebase Firestore, respon Machine Learning, maupun penyimpanan lokal.

---

## 📌 Apa yang Diisi di Sini?
1. **Class Model Data**: Hanya definisi properti, konstruktor, method serialisasi (`fromJson` / `toJson`, atau `fromFirestore` / `toFirestore`), dan helper sederhana (seperti `copyWith`).
2. **Tidak Boleh Berisi**:
   - ❌ Logika bisnis atau kalkulasi berat.
   - ❌ Pemanggilan Firebase, HTTP request, atau TFLite secara langsung.
   - ❌ Kode yang berhubungan dengan tampilan (UI / Flutter Widgets).

---

## 📄 Contoh File yang Akan Dibuat di Sini:
1. `user_model.dart`:
   - Data profil pengguna: `id`, `name`, `email`, `photoUrl`, `level`, `xp`, `streak`, `createdAt`.
2. `progress_model.dart`:
   - Data capaian belajar: `userId`, `moduleId`, `completedLessons`, `lastAccessed`, `isUnlocked`.
3. `gesture_result_model.dart`:
   - Data hasil inferensi AI: `detectedLabel`, `confidenceScore` (persentase akurasi), `isCorrect`, `timestamp`.
4. `lesson_model.dart`:
   - Data materi pembelajaran: `id`, `title`, `description`, `targetGesture`, `xpReward`.

---

## 👥 Penanggung Jawab Tim:
- **Backend Developers (Rifo & Fatahillah)**: Membuat skema data model yang cocok dengan koleksi Firestore.
- **ML Engineer (Abdul Ghofur)**: Menentukan format output hasil prediksi AI di `gesture_result_model.dart`.
