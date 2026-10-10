# 📁 Folder: `lib/views/camera/`

## 🎯 Fungsi Utama
Menyimpan antarmuka halaman kamera interaktif untuk verifikasi dan latihan gestur bahasa isyarat.

---

## 👤 Penanggung Jawab
**Frontend Developer (Ihsan)** — Merancang UI interaktif ala Duolingo.

---

## 📌 Apa yang Diisi di Sini?
- `camera_screen.dart`:
  - Menampilkan preview lensa kamera HP (`CameraPreview`).
  - Overlay panduan gestur tangan (bounding box atau siluet tangan referensi).
  - Tombol aksi jepret / otomatis deteksi frame.
  - Kartu petunjuk huruf/isyarat target (misal: "Bentuk huruf 'A' sekarang").
- `gesture_result_bottom_sheet.dart`:
  - Panel bawah (modal) yang muncul setelah AI memproses gambar.
  - Menampilkan animasi Lottie (hijau jika benar, merah jika salah ala Duolingo).
  - Skor akurasi kepercayaan (*confidence score*), suara/haptic feedback, serta tombol "Lanjut".

---

## 🔗 Hubungan dengan Komponen Lain:
- Mengambil data dan aksi dari `CameraController`.
- Tidak ada inisialisasi TFLite di sini; pemanggilan inferensi dioper ke `CameraController.captureAndDetect()`.
