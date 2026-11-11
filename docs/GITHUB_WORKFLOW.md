# Alur Kerja Git & GitHub — Sign.L

Dokumen ini adalah aturan main branch, commit, Pull Request (PR), review, dan
CI untuk tim Sign.L.

Tujuannya sederhana: **satu branch untuk satu tugas, satu PR untuk satu
perubahan**, supaya kode mudah dicek dan mudah dibatalkan kalau bermasalah.

---

## 1. Struktur branch

| Branch | Fungsi |Aturan |
|---|---|---|
| `main` | Versi siap rilis/demo | Tidak boleh commit langsung. Hanya menerima PR dari `develop`. |
| `develop` | Gabungan semua fitur yang sudah lolos review | Tidak boleh commit langsung. Menerima PR dari `feature/*` dan `fix/*`. |
| `feature/*` | Satu fitur baru | Dibuat dari `develop`, umur maksimal 3 hari kerja. |
| `fix/*` | Satu perbaikan bug | Dibuat dari `develop`, umur maksimal 3 hari kerja. |
| `hotfix/*` | Perbaikan darurat dari `main` | Setelah selesai, merge ke `main` **dan** `develop`. |

Alur normal:

```text
feature/kuis-berbayar
        │
        ▼ PR + review + CI
     develop
        │
        ▼ PR rilis
       main
```

Contoh nama branch:

```text
feature/kuis-berbayar
feature/integrasi-supabase
feature/chat-realtime
fix/chat-rls
fix/login-session
hotfix/crash-kamera
```

Hindari nama seperti `update`, `coba`, `fix-bug`, atau `branch-baru`.

---

## 2. Mulai bekerja

Selalu mulai dari `develop` yang terbaru:

```bash
git switch develop
git pull origin develop
git switch -c feature/kuis-berbayar
```

Kalau `develop` belum ada di komputer lain:

```bash
git fetch origin
git switch -c develop origin/develop
```

Selesai bekerja:

```bash
git add <file-yang-relevan>
git commit -m "feat(kuis): tambah pembelian kuis dengan diamond"
git push -u origin feature/kuis-berbayar
```

Jangan memakai `git add .` kalau masih ada file sementara, screenshot, atau
hasil build di folder kerja.

---

## 3. Format commit

```text
tipe(bagian): apa yang berubah
```

Tipe yang dipakai:

| Tipe | Untuk |
|---|---|
| `feat` | Fitur baru |
| `fix` | Perbaikan bug |
| `refactor` | Ubah struktur tanpa mengubah perilaku |
| `docs` | Dokumentasi |
| `test` | Menambah atau memperbaiki test |
| `chore` | Konfigurasi, dependency, tooling |
| `style` | Format kode saja |

Contoh benar:

```text
feat(kuis): tambah pembelian kuis dengan diamond
fix(chat): cegah non-anggota membaca pesan
docs(db): tambah README Supabase
refactor(leaderboard): pindahkan logika ke service
test(auth): tambah test login gagal
```

Contoh yang dihindari:

```text
fix bug
update
final beneran
asdf
```

Satu commit sebaiknya berisi satu perubahan yang masuk akal. Kalau ada
perubahan yang tidak berhubungan, pisahkan commit-nya.

---

## 4. Pull Request

PR selalu menuju `develop`, kecuali PR rilis menuju `main`.

Judul PR memakai format commit:

```text
feat(kuis): pembelian kuis dengan diamond
```

Isi PR minimal:

- **Masalah** — apa yang salah atau belum ada.
- **Solusi** — apa yang diubah.
- **Cara uji** — langkah reproduksi untuk memastikan perubahan bekerja.
- **Screenshot** — wajib untuk perubahan UI.
- **Closes #nomor** — kalau ada issue terkait.

Ukuran PR yang sehat:

- kurang dari 300 baris perubahan;
- selesai kurang dari 3 hari kerja;
- tidak mencampur fitur, refactor besar, dan perbaikan bug.

Template PR tersedia di `.github/pull_request_template.md`.

---

## 5. Review

Alur review:

```text
Buka PR → teman review → perbaiki → disetujui → merge
```

Yang dicari reviewer:

1. Dua potensi bug atau kasus tepi.
2. Satu masalah susunan layer.
3. Satu test yang kurang.
4. Satu saran supaya kode lebih mudah dibaca.

Cara memberi komentar:

```text
Lihat  : build() terlalu panjang.
Dampak: validasi sulit dites dan mudah terlewat.
Usul  : pindahkan validasi ke service/validator.
```

Hindari komentar seperti “kode ini jelek, perbaiki” tanpa penjelasan.

Reviewer memutuskan **Approve** atau **Request changes**. PR tidak di-merge
sebelum komentar penting diselesaikan.

---

## 6. CI

Workflow ada di `.github/workflows/ci.yml` dan berjalan otomatis saat:

- ada PR ke `develop` atau `main`;
- ada push ke `develop`.

Yang dijalankan:

```text
flutter pub get
flutter analyze
flutter test
```

`dart format` belum dijadikan wajib karena saat aturan ini dibuat masih ada
sekitar 48 file yang belum sesuai format. Format seluruh project sebaiknya
dilakukan di satu PR khusus, baru setelah itu pengecekan format diaktifkan.

Kalau CI gagal, perbaiki dulu sebelum meminta review ulang.

---

## 7. Branch protection

Branch `main` dan `develop` dilindungi di GitHub:

- tidak bisa push langsung;
- perubahan harus lewat PR;
- minimal 1 approval;
- force push dan hapus branch diblokir;
- percakapan review harus diselesaikan sebelum merge;
- admin masih bisa bypass untuk keadaan darurat.

Pengaturan ini dilakukan lewat GitHub Settings → Branches. Kalau repo dipakai
sendirian tanpa reviewer, approval bisa diturunkan menjadi 0, tetapi PR tetap
wajib.

---

## 8. Rilis

Saat aplikasi siap demo atau rilis:

1. Pastikan `develop` hijau dan sudah diuji.
2. Buka PR `develop` → `main`.
3. Review dan merge.
4. Beri tag versi:

```bash
git switch main
git pull origin main
git tag -a v1.0.0 -m "Rilis 1.0.0"
git push origin v1.0.0
```

Jangan merge `main` balik ke `develop` untuk fitur biasa. Kalau ada hotfix,
merge `hotfix/*` ke `main`, lalu merge `main` ke `develop` supaya perbaikannya
tidak hilang.

---

## 9. Branch lama

Branch `fatah`, `miqba`, `rifo`, dan `salma` adalah branch personal. Branch
seperti ini tidak dipakai lagi untuk alur baru.

Kalau masih ada pekerjaan yang belum masuk:

1. Buat `feature/*` dari `develop`.
2. Ambil perubahan yang masih relevan dari branch lama.
3. Buka PR ke `develop`.
4. Setelah masuk, branch lama boleh diarsipkan atau dihapus.

Jangan menghapus branch lama sebelum isinya dipastikan sudah masuk.
