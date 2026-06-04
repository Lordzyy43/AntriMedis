# Collaboration Setup Guide

Panduan ini dipakai untuk collaborator yang baru clone project AntriMedis Mobile dari GitHub dan ingin menjalankannya seperti environment lokal owner.

Project ini terhubung ke Supabase remote yang sama dengan Admin Panel. Mobile app dipakai oleh pasien, sedangkan Admin Panel dipakai petugas klinik untuk membuat jadwal, mengelola master data, dan menjalankan antrean.

## Repository

Mobile Flutter:

```txt
https://github.com/Lordzyy43/AntriMedis.git
```

Admin Panel Web:

```txt
https://github.com/Lordzyy43/AdminpanelAntriMedis.git
```

Collaborator yang hanya mengerjakan mobile cukup clone repository mobile. Jika perlu mengetes flow penuh dari admin sampai pasien, clone kedua repository.

## Akses Yang Dibutuhkan

Untuk menjalankan mobile app, collaborator membutuhkan:

- akses repository GitHub mobile,
- Flutter SDK,
- Android Studio atau emulator/device Android,
- file `.env`,
- Supabase URL,
- Supabase anon/publishable key,
- akun pasien test.

Collaborator tidak perlu akses penuh ke dashboard Supabase jika hanya mengerjakan UI, page flow, atau logic client.

## Kapan Perlu Akses Supabase Dashboard?

Tidak wajib untuk:

- menjalankan mobile app,
- testing login pasien,
- testing ambil antrean,
- testing tracking realtime,
- mengerjakan UI Flutter,
- memperbaiki bug yang hanya terjadi di client.

Perlu akses Supabase Dashboard jika collaborator akan:

- mengubah schema database,
- membuat atau mengubah migration,
- mengubah RPC/function,
- mengubah RLS policy,
- mengatur Realtime publication,
- membuat seed/reset data,
- debug langsung dari SQL editor,
- mengatur Auth provider seperti Google OAuth,
- mengelola Storage bucket.

Untuk keamanan, hanya collaborator yang menangani backend/database yang sebaiknya diinvite ke Supabase project.

## Cara Mendapatkan Supabase URL Dan Anon Key

Ya, anon key didapat dari Supabase.

Cara mengambilnya:

1. Buka Supabase Dashboard.
2. Pilih project AntriMedis.
3. Buka bagian Connect atau Project Settings.
4. Masuk ke API Keys.
5. Ambil Project URL.
6. Ambil anon/publishable key untuk client.

Catatan Supabase terbaru:

- Supabase merekomendasikan mengambil key dari Connect dialog jika hanya butuh setup cepat.
- Jika ingin melihat daftar key lengkap, buka Project Settings > API Keys.
- Untuk project yang masih memakai legacy key, anon key ada di bagian Legacy anon/service_role API keys.

Jangan berikan `service_role` key ke collaborator frontend. `service_role` melewati RLS dan harus dianggap sebagai secret backend.

Referensi resmi: https://supabase.com/docs/guides/getting-started/api-keys

## Setup Setelah Clone

Clone repository:

```powershell
git clone https://github.com/Lordzyy43/AntriMedis.git
cd AntriMedis
```

### Urutan Setup Environment Mobile

Mobile Flutter memakai file `.env` sebagai asset aplikasi. Karena itu, file `.env` wajib ada di root repository mobile sebelum menjalankan `flutter pub get`, `flutter analyze`, atau `flutter run`.

Urutan yang benar:

1. Biarkan `.env.example` tetap ada sebagai template.
2. Copy `.env.example` menjadi `.env`.
3. Isi `.env` dengan Supabase URL dan anon key asli.
4. Jangan commit `.env`.
5. Buat `.env.local` hanya jika perlu menjalankan script lokal atau smoke test.

Perbedaan file environment:

```txt
.env.example  -> template untuk collaborator, boleh commit
.env          -> env asli untuk Flutter app, wajib ada lokal, jangan commit
.env.local    -> env lokal untuk script/smoke test, opsional, jangan commit
```

Copy template menjadi `.env`:

```powershell
Copy-Item .env.example .env
```

Isi `.env` dengan nilai asli:

```txt
SUPABASE_URL=https://vicwdxxjaoekppembbvt.supabase.co
SUPABASE_ANON_KEY=isi_anon_or_publishable_key_dari_supabase
SUPABASE_OAUTH_REDIRECT_URL=antrimedis://login-callback/
```

Jika perlu `.env.local` untuk script/smoke test, copy setelah `.env` sudah benar:

```powershell
Copy-Item .env .env.local
```

Jangan rename `.env.example` menjadi `.env`. Gunakan copy, supaya `.env.example` tetap tersedia di GitHub sebagai panduan collaborator.

Install dependency:

```powershell
flutter pub get
```

Jalankan app:

```powershell
flutter run
```

Jika ada lebih dari satu device/emulator:

```powershell
flutter devices
flutter run -d device_id
```

## Akun Test Pasien

Gunakan salah satu akun berikut:

```txt
pasien1@antrimedis.test
pasien2@antrimedis.test
pasien3@antrimedis.test
pasien4@antrimedis.test
pasien5@antrimedis.test
pasien6@antrimedis.test
pasien7@antrimedis.test
pasien8@antrimedis.test
pasien9@antrimedis.test
pasien10@antrimedis.test
```

Password semua akun pasien:

```txt
PatientMedis2026!
```

## Flow Testing Mobile

Flow minimal untuk memastikan mobile app berjalan:

1. Jalankan Admin Panel.
2. Login sebagai admin.
3. Buat jadwal dokter/poli untuk hari ini.
4. Buka mobile app.
5. Login sebagai pasien.
6. Lengkapi profil jika diminta.
7. Buka Beranda.
8. Pilih jadwal yang masih bisa mengambil antrean.
9. Ambil nomor antrean.
10. Pantau halaman tracking.
11. Dari Admin Panel, panggil nomor berikutnya.
12. Pastikan status di mobile berubah otomatis.

Jika tidak ada jadwal hari ini, mobile app tetap berjalan, tetapi pasien tidak bisa mengambil nomor antrean.

## Validasi Development

Sebelum mengirim pull request atau memberi hasil ke owner, jalankan:

```powershell
flutter analyze
flutter test
```

Untuk build APK debug:

```powershell
flutter build apk --debug
```

## Hal Yang Tidak Boleh Di-commit

Jangan commit file berikut:

- `.env`
- `.env.local`
- key pribadi,
- service role key,
- database password,
- file build sementara.

File `.env.example` boleh diubah jika hanya menambah nama variable tanpa nilai secret.

## Troubleshooting

Jika muncul error environment:

- pastikan file `.env` ada di root repository mobile,
- jika hanya ada `.env.local`, Flutter tetap akan error karena `pubspec.yaml` mendaftarkan `.env` sebagai asset,
- buat `.env` dengan `Copy-Item .env.example .env` atau `Copy-Item .env.local .env`,
- pastikan `SUPABASE_URL` benar,
- pastikan `SUPABASE_ANON_KEY` berasal dari project Supabase yang sama,
- jalankan ulang app setelah mengubah `.env`.

Jika VS Code menampilkan error `The asset file '.env' doesn't exist`:

- penyebabnya adalah file `.env` belum ada di root mobile,
- `.env.example` tidak otomatis dibaca Flutter,
- `.env.local` juga tidak otomatis dibaca Flutter,
- solusinya buat file `.env`, isi anon key, lalu jalankan `flutter pub get`.

Jika login gagal:

- pastikan akun test sudah ada di Supabase Auth,
- pastikan email dan password benar,
- pastikan app memakai Supabase URL dan key project AntriMedis.

Jika data jadwal kosong:

- cek Admin Panel apakah sudah ada jadwal hari ini,
- cek apakah jadwal masih aktif,
- cek apakah jam jadwal belum melewati batas pengambilan antrean.

Jika realtime tidak berubah:

- pastikan device punya koneksi internet,
- refresh halaman atau restart app,
- pastikan Admin Panel dan mobile memakai project Supabase yang sama,
- cek apakah perubahan status benar-benar terjadi di Admin Panel.

## Aturan Kerja Kolaborasi

Gunakan branch terpisah untuk setiap pekerjaan:

```powershell
git checkout -b feature/nama-fitur
```

Contoh:

```powershell
git checkout -b feature/polish-tracking-page
```

Sebelum push:

```powershell
flutter analyze
flutter test
git status
```

Jika pekerjaan menyentuh database, diskusikan dulu dengan owner sebelum mengubah migration atau RPC.
