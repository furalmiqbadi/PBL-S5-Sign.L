# Design: Arah "Soft UI" Sign.L

Status: **Diterapkan**. Arah Soft UI sudah menjadi tema utama aplikasi; dokumen ini jadi acuan token dan aturan visual.

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
| `brandGradient` | biru `#0062EE` ke toska `#0BB59E` | hanya tombol tengah navbar dan kotak logo merek |
| `bg` / `surface` | `#FFFFFF` | latar layar dan kartu; kartu dipisahkan dengan bayangan |
| `fieldFill` | `#F3F6FB` | isi kolom input, chip nonaktif, kartu terkunci |
| `textPrimary` / `textSecondary` | `#0F172A` / `#5B6676` | kontras teks >= 4.5:1 |
| Radius | `AppRadii` 12 / 16 / 20 / 24 / 28 / 999 | input & tombol 16, kartu 24, navbar 28, badge pil 999 |
| Spasi | 4, 8, 12, 16, 20, 24, 32 | tidak ada angka lepas |
| Bayangan | `AppShadows` card / soft / floating | tiga level: kartu, kontrol, elemen melayang |
| Font | satu keluarga (Plus Jakarta Sans), bobot 400/600/700 | judul tab 22, judul halaman 20, judul kartu 14, isi 14-16 |
| Header | tinggi konten 48, tombol 48x48, latar transparan | gradasi latar halaman menyambung tanpa garis potong |
| Latar | `AppBackground`: gradasi `#FBFDFF → #F6F8FC → #EEF3FB` + dua aura lembut | semua tab dan halaman yang di-*push* |

Lokasi kode: warna dan tipografi di `lib/views/theme/app_colors.dart` & `app_text_styles.dart`; tema global di `app_theme.dart`; radius, bayangan dan komponen dasar di `lib/views/widgets/app_ui.dart`; latar kanvas di `app_background.dart`.

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
| Header tab | `SectionHeader`: judul 22 px di kiri, aksi di kanan, tinggi 48, latar transparan, tombol aksi 48x48 putih berbingkai |
| Header halaman (push) | `AppScreenHeader`: judul 20 px + tombol kembali berbingkai, tinggi dan padding sama dengan header tab |
| Kartu progres utama | satu kartu per layar: permukaan putih berbingkai `primary` tipis dengan bayangan biru lembut, atau blok `primary` solid untuk ringkasan; tanpa gradasi |
| Kartu materi | putih, ikon dalam kotak `pinkSoft`, judul + keterangan jumlah |
| Chip filter | pil; aktif `primary`, nonaktif putih |
| Input | isi `fieldFill`, garis tepi `border`, fokus `primary` |
| Tombol utama | `primary` solid, tinggi 48-56, radius 16, kata kerja spesifik ("Masuk", "Mulai belajar") |

Setiap komponen wajib punya state: default, ditekan, nonaktif, memuat, kosong, error.

## 5. Larangan (dari `design-rules`)
- Tidak memakai emoji sebagai ikon. Satu set ikon saja (Material Rounded).
- Gradasi brand (`brandGradient`) hanya untuk tombol tengah navbar dan kotak logo merek. Kartu fokus, FAB, tombol kirim, banner, dan snackbar memakai `primary` solid atau permukaan putih beraksen `primary`. Tidak ada glassmorphism berlebihan.
- Header dan AppBar tidak memakai latar solid; biarkan `AppBackground` terlihat agar tidak ada garis potong dengan konten.
- Tidak ada warna, radius, atau ukuran font lepas di widget; ambil dari token (`AppColors`, `AppRadii`, `AppTextStyles`).
- Teks sentence case, tanpa lorem ipsum.

## 6. Rencana bertahap
1. **Preview** (selesai): `preview/*.html` dan `lib/views/**/*_modern_preview.dart`.
2. Tinjau dan setujui arah (selesai).
3. Terapkan tema + navbar melayang (selesai).
4. Terapkan ke Login, lalu Beranda, lalu Materi (selesai).
5. Halaman lain (Kuis, Komunitas, Profil) menyusul (selesai).

## 7. Kriteria penerimaan
- [x] Login, Beranda, Materi memakai token yang sama, tanpa warna atau radius lepas.
- [x] Bottom navbar melayang, lima tab tetap berfungsi, konten tidak tertutup.
- [x] Fitur dan alur tidak berubah (login Supabase, progres, navigasi).
- [x] Semua header (tab dan halaman push) memakai tinggi 48 dan tombol 48x48 yang sama.
- [ ] `flutter analyze` bersih, tampil benar di layar kecil dan besar. (Diagnostics editor bersih; CLI dan uji layar belum dijalankan ulang.)
- [x] Kontras teks >= 4.5:1, target sentuh >= 48 dp.

## 8. Asumsi dan pertanyaan terbuka
- Gradasi brand hanya di tombol tengah navbar dan kotak logo merek; kartu progres utama memakai `primary` solid atau putih beraksen (diputuskan 2026-11-18).
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
| 2026-11-18 | Header diseragamkan (`SectionHeader` 22 px + aksi 48x48, `AppScreenHeader` 20 px); gradasi brand dihapus dari kartu/FAB/tombol/banner; emoji ikon dibersihkan; halaman push memakai `AppBackground` |
