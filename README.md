# Sign.L

Aplikasi pembelajaran BISINDO interaktif berbasis Flutter, Supabase Auth, Postgres, Storage, Realtime, TensorFlow Lite, dan MediaPipe.

## Menjalankan aplikasi

```bash
flutter pub get
flutter run --dart-define=SUPABASE_URL=<url> --dart-define=SUPABASE_ANON_KEY=<publishable-key>
```

Jangan commit `.env`, token, password, atau signing key. Konfigurasi Supabase dibaca melalui `--dart-define`.

## Autentikasi dan save login

- Sesi aktif Supabase disimpan menggunakan `flutter_secure_storage` (Android Keystore/iOS Keychain), bukan `SharedPreferences`.
- Setelah login berhasil, akun dan sesi terenkripsi disimpan sebagai akun tersimpan di perangkat.
- Password tidak pernah disimpan.
- Token yang kedaluwarsa diperbarui melalui refresh token Supabase. Sesi yang dicabut server akan dikeluarkan.
- Data akun tersimpan dipisahkan berdasarkan email yang dinormalisasi dan dapat dihapus melalui alur pengelolaan akun yang menggunakan `SavedAccountsService`.
- Logout mengakhiri sesi aktif; hapus akun tersimpan untuk menghapus token akun tersebut dari perangkat.

## Validasi sebelum rilis

```bash
dart format .
flutter analyze
flutter test
flutter build apk --release
```

Android QA menggunakan emulator dan artefak disimpan di `testandroid/`.

## Status validasi terakhir

- `flutter analyze`: lulus.
- `flutter test`: lulus, 16 test.
- `flutter build apk --debug`: lulus.
- Instalasi dan launch pada emulator `emulator-5554`: lulus.
- Crash log emulator: disimpan di `testandroid/release-readiness-crash.log`.
- Catatan: build menampilkan warning kompatibilitas plugin Kotlin dan SDK XML; warning ini perlu dibereskan sebelum rilis produksi.
