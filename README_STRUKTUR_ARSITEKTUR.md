# 📘 Panduan Struktur & Arsitektur Proyek Sign.L
> **Arsitektur**: Modified MVC (Thin Controller + Service Layer)  
> **State Management**: `provider` (`ChangeNotifier`)  
> **Target OS Android**: Minimal Android 10 (API 29), Target/Req Android 15 (API 35)

---

## 🏛️ 1. Gambaran Alur Arsitektur (Data Flow)

Dalam pola **Modified MVC (Thin Controller + Service Layer)**, alur data bergerak satu arah secara terstruktur:

```
[ View (UI) ] ── (panggil method) ──> [ Thin Controller ] ── (delegasi logika) ──> [ Service Layer ]
     ▲                                       │                                         │
     │                                (ubah state &                               (ambil/proses data)
     │                              notifyListeners())                                 │
     └──────── (rebuild UI via Provider) ────┴──────── (kembalikan Model data) ────────┘
```

1. **View (UI)**: Halaman atau widget pasif. Hanya mendengarkan perubahan state dari Controller dan memicu aksi pengguna (misal: tombol jepret ditekan). **Dilarang keras memanggil Firebase atau ML langsung.**
2. **Thin Controller (`ChangeNotifier`)**: Pengontrol status tampilan (`isLoading`, `errorMessage`, `gestureResult`). Controller **hanya bertugas menjembatani** View ke Service. Controller tidak mengolah gambar piksel atau query database secara langsung.
3. **Service Layer**: Pusat logika berat (*heavy logic*), komunikasi jaringan Firebase Auth/Firestore, dan inferensi on-device TensorFlow Lite.
4. **Model Layer**: Objek data murni (*pure data classes*) tanpa logika tampilan.

---

## 📁 2. Peta Direktori & Fungsi Folder

```text
pbl_signl/
├── android/app/build.gradle.kts     # Konfigurasi compileSdk 35, minSdk 29 (Android 10), targetSdk 35 (Android 15)
├── pubspec.yaml                     # Dependencies (Provider, Firebase, Camera, TFLite, UI Duolingo)
│
├── assets/
│   ├── animations/                  # Animasi Lottie (.json) untuk maskot, streak api, feedback benar/salah
│   ├── images/                      # Gambar referensi gestur huruf isyarat, logo, banner
│   └── ml/                          # Model AI (model.tflite) dan daftar kelas gestur (labels.txt)
│
└── lib/
    ├── main.dart                    # Inisialisasi Firebase & MultiProvider root
    │
    ├── models/                      # DATA LAYER (Class Data Murni)
    │   ├── user_model.dart          # Data profil, level, streak, XP user
    │   ├── progress_model.dart      # Data capaian belajar & modul yang terbuka
    │   └── gesture_result_model.dart# Hasil prediksi AI (label, confidence score, isCorrect)
    │
    ├── services/                    # SERVICE LAYER (Logika Berat & Integrasi Eksternal)
    │   ├── ml_service.dart          # TFLite inference & image preprocessing (crop, resize, normalize)
    │   ├── auth_service.dart        # Firebase Authentication (Login, Register, Logout)
    │   └── firestore_service.dart   # Cloud Firestore (CRUD data user, progress, leaderboard)
    │
    ├── controllers/                 # CONTROLLER LAYER (Thin Controller dengan ChangeNotifier)
    │   ├── camera_controller.dart   # State kamera & trigger deteksi gestur via MLService
    │   ├── auth_controller.dart     # State form login/register & error handling
    │   └── home_controller.dart     # State progress gamifikasi (XP, Level, Streak)
    │
    └── views/                       # VIEW LAYER (UI Bersih & Pasif)
        ├── auth/                    # Layar Login, Register, Forgot Password
        ├── camera/                  # Layar Kamera + bounding box + bottom sheet hasil AI
        ├── home/                    # Layar Beranda jalur belajar (Learning Path ala Duolingo)
        └── widgets/                 # Reusable Duolingo widgets (3D DuoButton, DuoProgressBar)
```

---

## 👥 3. Pembagian Tugas Tim Berdasarkan Arsitektur

| Peran & Anggota | Fokus Folder Kerja | Tanggung Jawab Utama |
|---|---|---|
| **ML Engineer** (Abdul Ghofur) | `assets/ml/`<br>`lib/services/ml_service.dart`<br>`lib/models/gesture_result_model.dart` | Mengekspor model TFLite, menulis preprocessing gambar 224x224, dan kalkulasi tensor output. |
| **Backend Developers** (Rifo & Fatahillah) | `lib/models/`<br>`lib/services/auth_service.dart`<br>`lib/services/firestore_service.dart` | Merancang skema data Firestore, query profil/progress/leaderboard, serta autentikasi Firebase. |
| **Frontend Developer** (Salma) | `lib/views/**`<br>`lib/controllers/`<br>`assets/animations/ & images/` | Merancang UI interaktif ala Duolingo, widget tombol 3D, animasi Lottie, serta menghubungkan UI ke Controller via Provider. |
| **Frontend Developer — UI Pages** (Ihsan) | `lib/views/home/`<br>`lib/views/camera/`<br>`lib/views/komunitas/`<br>`lib/views/profile/`<br>`lib/views/setting/`<br>`lib/views/edit/` | Membuat UI halaman Beranda (learning path), Kamera (deteksi gestur), Komunitas (forum & leaderboard), Profil (statistik & badge), Pengaturan, dan Edit Profil. |
| **QA / Project Manager** | `test/`<br>Code Review & Architecture Enforcement | Memastikan prinsip Thin Controller tidak dilanggar dan menguji kestabilan kamera serta inferensi di Android 10 s.d. 15. |
