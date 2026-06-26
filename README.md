# AntriMedis Mobile App

Mobile app pasien untuk sistem antrean klinik AntriMedis. Aplikasi ini berfokus pada alur pasien: autentikasi, pelengkapan profil, melihat jadwal praktik, mengambil nomor antrean, tracking realtime, estimasi waktu tunggu, notifikasi lokal, riwayat antrean, dan profil/avatar.

## Status

Status per 4 Juni 2026:

- Scope aktif: satu klinik/cabang utama.
- Role mobile: pasien.
- Backend: Supabase Auth, PostgreSQL, RLS, RPC, Realtime, dan Storage avatar.
- Flow utama sudah berjalan end-to-end dengan web admin.
- App identity sudah memakai nama AntriMedis dan package id Android `com.ti24a6.antrimedis`.

Dokumen status lengkap ada di [docs/prd_status_roadmap.md](docs/prd_status_roadmap.md).

## Fitur Utama

- Login/register email dan password.
- Login Google OAuth dengan deep link `antrimedis://login-callback/`.
- Profile completion sebelum pasien mengambil antrean.
- Upload, sinkronisasi, dan hapus avatar profil.
- Daftar jadwal praktik dari `v_schedule_availability`.
- Ambil nomor antrean lewat RPC `create_queue_ticket`.
- Tracking status antrean realtime.
- Estimasi waktu tunggu berbasis jumlah antrean sebelum pasien dan rata-rata durasi layanan.
- Local notification untuk antrean dibuat, hampir dipanggil, dipanggil, dilewati, atau dibatalkan.
- Riwayat antrean pasien.
- Floating navigation custom.

## Tech Stack

- Flutter
- Provider
- Supabase Flutter
- flutter_dotenv
- flutter_local_notifications
- percent_indicator
- image_picker
- intl

## Setup

1. Copy env example menjadi `.env`.

Flutter membaca `.env` sebagai asset aplikasi, jadi file ini wajib ada secara lokal. Jangan rename `.env.example`; gunakan copy supaya template tetap tersedia untuk collaborator.

```powershell
Copy-Item .env.example .env
```

2. Isi `.env`:

```txt
SUPABASE_URL=https://vicwdxxjaoekppembbvt.supabase.co
SUPABASE_ANON_KEY=your_anon_key
SUPABASE_OAUTH_REDIRECT_URL=antrimedis://login-callback/
```

3. Jika perlu script/smoke test lokal, buat `.env.local` dari `.env`:

```powershell
Copy-Item .env .env.local
```

Ringkasnya:

```txt
.env.example  -> template, ikut GitHub
.env          -> wajib untuk Flutter, lokal saja
.env.local    -> opsional untuk script, lokal saja
```

4. Install dependency:

```powershell
flutter pub get
```

5. Jalankan app:

```powershell
flutter run
```

## Validasi

Command yang dipakai untuk guardrail development:

```powershell
flutter analyze
flutter test
```

Terakhir dicek: keduanya pass.

## Catatan Operasional

- Password user tidak disimpan di tabel public. Supabase menyimpannya secara aman di schema `auth`.
- Tabel `profiles` hanya menyimpan data profil pasien seperti nama, nomor telepon, tanggal lahir, gender, dan avatar.
- Pasien hanya boleh memiliki satu antrean aktif per hari pada cabang utama.
- Realtime pada app berarti UI berubah ketika admin memanggil/melayani/menyelesaikan antrean selama app aktif atau masih bisa menerima event.
- Notifikasi production penuh saat app mati total membutuhkan FCM dan Edge Function. Ini masih future scope.
- Untuk reset data operasional tanpa menghapus dokter/poli/master data, gunakan `supabase/patches/20260604_reset_operational_data_keep_master.sql`.

## Dokumen Terkait

- [PRD](docs/prd.md)
- [Status & Roadmap](docs/prd_status_roadmap.md)
- [Current Project Snapshot](docs/current_project_snapshot.md)
- [Collaboration Setup Guide](docs/collaboration_setup.md)
- [User Side DB Fields](docs/user_side_db_fields.md)
- [Documentation Strategy](docs/documentation_strategy.md)
