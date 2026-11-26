# Design: Arah "Soft UI" Sign.L

Status: **DRAFT, menunggu persetujuan**. Belum menggantikan gaya Duolingo di kode utama.

## 1. Arah gaya
- **Nada**: bersih, tenang, hangat. Latar putih, kedalaman dari bayangan lembut, bukan garis tebal.
- **Warna**: mengikuti logo aplikasi (biru, toska, kuning), disimpan di `lib/views/theme/app_colors.dart`. Nama token lama `pinkSoft`/`pinkSofter`/`purpleSoft` dipertahankan agar kode tidak berubah, nilainya kini biru muda dan toska muda.
- **Referensi**: aplikasi storage bergaya Dropbox (kartu putih bersudut besar, satu kartu biru sebagai fokus, daftar item rapi).
- **Yang dipertahankan**: gamifikasi (streak, XP, level) dan **bottom navbar**. Yang berubah hanya tampilan, bukan alur atau fitur.
- **Mode gelap**: tidak (belum ada di PRD).

## 2. Token desain (didefinisikan sekali, dipakai ulang)
| Token | Nilai | Catatan |
|---|---|---|
| `primary` | `#0062EE` | aksen utama; kontras putih ~5.3:1 |
| `pinkSoft` / `pinkSofter` | `#E6F0FF` / `#F3F8FF` | latar ikon, chip aktif, lintasan progres |
| `secondary` / `purpleSoft` | `#0BB59E` / `#DDF6F1` | toska; tint kategori, tidak untuk teks kecil |
| `tertiary` / `orangeSoft` | `#F59E0B` / `#FFF1D6` | kuning (streak, bintang); **bukan** teks di atas putih (kontras rendah) |
| `brandGradient` | biru `#0062EE` ke toska `#0BB59E` | hanya tombol tengah navbar |
| `bg` / `surface` | `#FFFFFF` | latar layar dan kartu; kartu dipisahkan dengan bayangan |
| `fieldFill` | `#F3F6FB` | isi kolom input, chip nonaktif, kartu terkunci |
| `textPrimary` / `textSecondary` | `#0F172A` / `#5B6676` | kontras teks >= 4.5:1 |
| Radius | 16 (input, tombol) / 24 (kartu) / 28 (navbar) | skala 4/8 |
| Spasi | 4, 8, 12, 16, 24, 32 | tidak ada angka lepas |
| Bayangan | blur 20, offset (0,4), hitam 5% | satu level untuk semua kartu |
| Font | satu keluarga (Plus Jakarta Sans), bobot 400/600/700 | judul 22-28, isi 14-16 |

Lokasi kode: `lib/views/theme/modern_theme.dart` (sementara). Bila disetujui, nilai dipindah ke `app_colors.dart` dan `app_text_styles.dart` agar tidak ada dua sumber tema.

## 3. Bottom navbar tetap dipakai
Referensi memakai menu hamburger, tetapi untuk aplikasi belajar bottom navbar lebih mudah dijangkau jempol. Penyesuaiannya:

- **Bentuk**: pil putih **melayang** (margin 16 kiri/kanan, 12 bawah), radius 28, bayangan lembut.
- **Item aktif**: ikon + label berwarna `primary` dengan latar `primarySoft`. Item nonaktif `textGray`.
- **Tombol tengah "Materi"** tetap ada (sudah didukung `AppBottomNavBar.centerIndex`), berupa lingkaran dengan `brandGradient`.
- **Teknis**: tetap `Scaffold.bottomNavigationBar`, jadi konten otomatis tidak tertutup. Margin kiri/kanan 16 dan jarak bawah 12 diatur di `AppBottomNavBar`.
- **Target sentuh** >= 48 dp. Pindah tab tanpa animasi berat (150-250 ms).
- Struktur lima tab dan `PageView` di `main_shell.dart` **tidak berubah**.

## 4. Komponen kunci
| Komponen | Ciri |
|---|---|
| Kartu progres utama | satu kartu `primary` per layar sebagai fokus, bar progres putih (teks putih di atas gradasi oranye tidak lolos kontras) |
| Kartu materi | putih, ikon dalam kotak `primarySoft`, judul + keterangan jumlah |
| Chip filter | pil; aktif `primary`, nonaktif putih |
| Input | isi putih, tanpa garis tepi, label jelas |
| Tombol utama | `primary`, tinggi 56, radius 16, kata kerja spesifik ("Masuk", "Mulai belajar") |

Setiap komponen wajib punya state: default, ditekan, nonaktif, memuat, kosong, error.

## 5. Larangan (dari `design-rules`)
- Tidak memakai emoji sebagai ikon. Satu set ikon saja (Material Rounded).
- Gradasi brand hanya di satu tempat (tombol tengah navbar), tidak di setiap kartu. Tidak ada glassmorphism berlebihan.
- Teks sentence case, tanpa lorem ipsum.

## 6. Rencana bertahap
1. **Preview** (selesai): `preview/*.html` dan `lib/views/**/*_modern_preview.dart`.
2. Tinjau dan setujui arah (dokumen ini).
3. Terapkan tema + navbar melayang.
4. Terapkan ke Login, lalu Beranda, lalu Materi.
5. Halaman lain (Kuis, Komunitas, Profil) menyusul.

## 7. Kriteria penerimaan
- [ ] Login, Beranda, Materi memakai token yang sama, tanpa warna atau radius lepas.
- [ ] Bottom navbar melayang, lima tab tetap berfungsi, konten tidak tertutup.
- [ ] Fitur dan alur tidak berubah (login Supabase, progres, navigasi).
- [ ] `flutter analyze` bersih, tampil benar di layar kecil dan besar.
- [ ] Kontras teks >= 4.5:1, target sentuh >= 48 dp.

## 8. Asumsi dan pertanyaan terbuka
- Gradasi brand hanya di tombol tengah navbar. Apakah boleh dipakai juga di kartu progres utama? Saat ini tidak.
- ID paket Android masih `com.example.pbl_signl`; harus diganti sebelum upload ke Play Store.
- Apakah maskot dan animasi Lottie lama tetap dipakai?
- Backend sudah Supabase (`lib/services/supabase_config.dart`); skema tabel dibahas di `docs-backend`, bukan di dokumen ini.

## 9. Riwayat
| Tanggal | Perubahan |
|---|---|
| 2026-11-05 | Draft awal arah Soft UI dan bottom navbar melayang |
| 2026-11-05 | Warna diganti dari biru ke palet brand (`app_colors.dart`) |
| 2026-11-05 | Latar jadi putih; diterapkan ke tema, Login/Daftar/Lupa sandi, Beranda, Materi, navbar melayang |
| 2026-11-05 | Palet mengikuti logo (biru/toska/kuning); logo, wordmark, nama dan ikon aplikasi diganti |
| 2026-11-05 | Soft UI diterapkan ke Kuis, Komunitas, Profil, Pengaturan, Chat, Notifikasi, detail dan isi materi |
