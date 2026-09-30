# 📁 Folder: `assets/ml/`

## 🎯 Fungsi Utama
Tempat penyimpanan file binary model Machine Learning dan metadata label klasifikasi bahasa isyarat.

---

## 📌 File yang Harus Diletakkan di Sini:
1. `model.tflite`:
   - Model hasil training (misal: MobileNetV2 / MediaPipe Hand Landmark classifier) yang telah dikonversi ke format TensorFlow Lite (.tflite).
2. `labels.txt`:
   - Daftar nama kelas/gestur yang dideteksi (misal: baris per baris berisi huruf A, B, C, ..., Z atau kata isyarat).

---

## 👥 Penanggung Jawab:
- **ML Engineer (Abdul Ghofur)**: Melatih model di Google Colab / server, lalu mengekspor dan meletakkan kedua file ini di folder ini.
