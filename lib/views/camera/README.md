# 📁 Folder: `lib/views/camera/`

## 🎯 Fungsi Utama
Menyimpan antarmuka halaman kamera interaktif untuk verifikasi dan latihan gestur bahasa isyarat.

---

## 👤 Penanggung Jawab
**Frontend Developer (Ihsan)** 

---

## 📌 Apa yang Diisi di Sini?
- `camera_screen.dart`:
  - Menampilkan preview lensa kamera HP (`CameraPreview`).
  - Overlay panduan gestur tangan (bingkai posisi tangan).
  - Tombol "Deteksi" menjepret satu frame lalu menjalankan inferensi.
  - Kartu petunjuk huruf/isyarat target (misal: "Bentuk huruf 'A' sekarang").
  - Hasil deteksi (cocok/tidak + keyakinan) tampil lewat `showAppBottomSheet`.

---

## 🔗 Hubungan dengan Komponen Lain:
- Inferensi model ada di `lib/services/ml_service.dart` (`MlService.instance`),
  memakai `assets/ml/model.tflite` + `assets/ml/labels.txt`.
- Bila berkas model belum valid, UI menampilkan pesan "model belum tersedia"
  (tidak crash). Ganti `model.tflite` dengan model hasil training terbaru.

