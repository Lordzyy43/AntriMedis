# PRD.md

# Product Requirement Document — AntriMedis

**Sistem Antrean Real-Time Klinik & Estimasi Waktu Tunggu**

---

## 1. Informasi Dokumen

| Item              | Keterangan                                                    |
| ----------------- | ------------------------------------------------------------- |
| Nama Produk       | AntriMedis                                                    |
| Jenis Produk      | Sistem antrean digital klinik                                 |
| Platform Pasien   | Mobile App Flutter                                            |
| Platform Admin    | Web Admin Panel                                               |
| Backend           | Supabase: Auth, PostgreSQL, Realtime, Storage, Edge Functions |
| Target Pengguna   | Pasien, Admin Klinik, Dokter/Petugas Poli, Owner Klinik       |
| Target Proyek     | UAS Mobile + Portfolio Full-Stack                             |
| Tingkat Kesulitan | Hard                                                          |
| Versi Dokumen     | v1.0                                                          |
| Status            | Draft Detail                                                  |

---

## 2. Ringkasan Produk

AntriMedis adalah aplikasi antrean klinik berbasis mobile dan web yang membantu pasien mengambil nomor antrean secara online, melihat posisi antrean secara real-time, mengetahui estimasi waktu tunggu, serta menerima notifikasi ketika antreannya hampir dipanggil.

Sistem terdiri dari dua sisi utama:

1. **Mobile App Flutter** untuk pasien.
2. **Web Admin Panel** untuk admin klinik, dokter/petugas poli, dan owner.

Backend menggunakan Supabase agar sistem memiliki autentikasi, database PostgreSQL yang rapi, fitur realtime, storage, dan kemungkinan penggunaan Edge Functions untuk proses bisnis yang lebih aman.

---

## 3. Masalah yang Ingin Diselesaikan

Banyak klinik masih menggunakan sistem antrean manual. Pasien harus datang lebih awal, mengambil nomor antrean, lalu menunggu tanpa kepastian waktu. Klinik juga sering kesulitan memantau jumlah pasien, status antrean, dan performa pelayanan.

Masalah utama:

1. Pasien tidak tahu estimasi waktu tunggu.
2. Pasien harus menunggu terlalu lama di klinik.
3. Pengambilan nomor antrean masih manual.
4. Admin sulit mengontrol antrean secara transparan.
5. Tidak ada notifikasi saat antrean hampir dipanggil.
6. Data antrean tidak terdokumentasi dengan baik.
7. Klinik sulit melihat laporan operasional harian.

---

## 4. Tujuan Produk

### 4.1 Tujuan Utama

Membangun sistem antrean klinik digital yang memungkinkan pasien mengambil nomor antrean online dan memantau status antrean secara real-time.

### 4.2 Tujuan Khusus

1. Memudahkan pasien mengambil nomor antrean melalui aplikasi Flutter.
2. Menampilkan nomor antrean berjalan secara real-time.
3. Menghitung estimasi waktu tunggu secara dinamis.
4. Memberikan notifikasi ketika antrean pasien hampir dipanggil.
5. Membantu admin klinik mengelola antrean melalui web panel.
6. Menyediakan struktur database yang ternormalisasi dan siap dikembangkan.
7. Menjadi dasar sistem klinik digital yang lebih luas.

---

## 5. Target Pengguna

### 5.1 Pasien

Pasien menggunakan aplikasi mobile untuk mengambil antrean dan memantau statusnya.

Kebutuhan pasien:

- Register dan login.
- Melihat klinik/cabang.
- Melihat poli dan dokter.
- Melihat jadwal dokter.
- Mengambil nomor antrean.
- Melihat posisi antrean.
- Melihat estimasi waktu tunggu.
- Mendapat notifikasi antrean.
- Melihat riwayat antrean.

### 5.2 Admin Klinik

Admin menggunakan web panel untuk mengelola operasional antrean.

Kebutuhan admin:

- Login admin.
- Melihat dashboard antrean hari ini.
- Memanggil antrean berikutnya.
- Mengubah status antrean.
- Mengatur dokter, poli, jadwal, dan kuota.
- Melihat data pasien yang mengambil antrean.
- Melihat ringkasan antrean harian.

### 5.3 Dokter/Petugas Poli

Dokter atau petugas poli dapat memantau antrean sesuai poli/dokter yang ditugaskan.

Kebutuhan dokter/petugas:

- Melihat daftar antrean.
- Menandai pasien sedang dilayani.
- Menandai pelayanan selesai.
- Melihat jumlah pasien tersisa.

### 5.4 Owner Klinik

Owner menggunakan web panel untuk melihat performa klinik.

Kebutuhan owner:

- Melihat total pasien.
- Melihat rata-rata waktu tunggu.
- Melihat performa tiap poli/dokter.
- Melihat laporan antrean harian/mingguan/bulanan.

---

## 6. Platform dan Teknologi

### 6.1 Mobile App

```txt
Platform      : Android
Framework     : Flutter
State Manager : Provider / Riverpod
Backend SDK   : supabase_flutter
Notification  : flutter_local_notifications
UI Helper     : flutter_screenutil
```

Package rekomendasi Flutter:

```yaml
supabase_flutter: latest
provider: latest
flutter_screenutil: latest
intl: latest
uuid: latest
flutter_local_notifications: latest
percent_indicator: latest
cached_network_image: latest
```

### 6.2 Web Admin Panel

```txt
Framework     : React + Vite
Language      : TypeScript
Styling       : Tailwind CSS
Routing       : React Router
Data Fetching : TanStack Query
HTTP/Backend  : Supabase JS Client
Form          : React Hook Form + Zod
State         : Zustand
Icons         : Lucide React
```

Package rekomendasi web:

```bash
npm install @supabase/supabase-js @tanstack/react-query react-router-dom zustand react-hook-form zod @hookform/resolvers lucide-react clsx tailwind-merge
```

### 6.3 Backend Supabase

```txt
Auth           : Supabase Auth
Database       : PostgreSQL
Realtime       : Supabase Realtime
Security       : Row Level Security Policies
Storage        : Supabase Storage
Server Logic   : Supabase Edge Functions
```

---

## 7. Scope Produk

### 7.1 MVP UAS

Fitur wajib untuk versi UAS:

1. Register dan login pasien.
2. Login admin.
3. Pasien melihat daftar klinik/cabang.
4. Pasien memilih poli dan dokter.
5. Pasien melihat jadwal praktik.
6. Pasien mengambil nomor antrean.
7. Pasien melihat status antrean aktif.
8. Admin melihat daftar antrean hari ini.
9. Admin memanggil antrean berikutnya.
10. Admin mengubah status antrean.
11. Data antrean berubah real-time.
12. Estimasi waktu tunggu tampil di aplikasi pasien.
13. Notifikasi lokal saat antrean tersisa 3 nomor.
14. Riwayat antrean pasien.

### 7.2 Pengembangan Lanjutan

Fitur setelah MVP:

1. QR code check-in.
2. Display layar antrean di klinik.
3. Multi-cabang klinik.
4. Dashboard owner.
5. Laporan PDF/Excel.
6. Integrasi WhatsApp notification.
7. Push notification FCM.
8. Rating pelayanan.
9. Pembayaran booking.
10. Rekam medis ringan.
11. Pembatalan dan reschedule antrean.
12. Integrasi Google Maps.
13. Sistem membership pasien.
14. Estimasi waktu tunggu berbasis data historis.

### 7.3 Out of Scope MVP

Fitur yang tidak dikerjakan pada tahap awal:

1. Rekam medis lengkap.
2. E-resep.
3. Telemedicine.
4. Pembayaran online.
5. Chat dokter.
6. Integrasi BPJS/asuransi.
7. AI diagnosis.

---

## 8. Role dan Hak Akses

| Role        | Platform | Hak Akses                                          |
| ----------- | -------- | -------------------------------------------------- |
| patient     | Mobile   | Ambil antrean, lihat status, lihat riwayat         |
| admin       | Web      | Kelola antrean, dokter, poli, jadwal               |
| doctor      | Web      | Lihat antrean poli/dokter, mulai/selesai pelayanan |
| owner       | Web      | Lihat laporan dan dashboard klinik                 |
| super_admin | Web      | Kelola semua klinik/cabang                         |

---

## 9. User Flow

### 9.1 Flow Pasien Ambil Antrean

```txt
Pasien membuka aplikasi
↓
Login/Register
↓
Dashboard pasien
↓
Pilih klinik/cabang
↓
Pilih poli
↓
Pilih dokter/jadwal praktik
↓
Klik Ambil Nomor Antrean
↓
Sistem validasi:
- user sudah login
- jadwal aktif
- kuota masih tersedia
- pasien belum punya antrean aktif pada jadwal tersebut
↓
Sistem membuat nomor antrean
↓
Pasien diarahkan ke halaman tracking antrean
↓
Pasien melihat posisi antrean dan estimasi waktu tunggu
```

### 9.2 Flow Admin Panggil Antrean

```txt
Admin login web panel
↓
Dashboard admin
↓
Pilih cabang/poli/dokter/jadwal
↓
Lihat daftar antrean waiting
↓
Klik Panggil Berikutnya
↓
Sistem mengambil antrean waiting paling awal
↓
Status antrean berubah menjadi called
↓
Nomor berjalan berubah real-time
↓
Aplikasi pasien menerima update
↓
Pasien mendapat notifikasi jika antreannya dekat
```

### 9.3 Flow Pelayanan Dokter

```txt
Admin/dokter melihat antrean called
↓
Klik Mulai Pelayanan
↓
Status berubah menjadi serving
↓
Dokter melayani pasien
↓
Klik Selesai
↓
Status berubah menjadi completed
↓
Sistem menyimpan waktu mulai dan selesai pelayanan
↓
Data dapat dipakai untuk laporan dan estimasi lanjutan
```

### 9.4 Flow Pasien Membatalkan Antrean

```txt
Pasien membuka halaman antrean aktif
↓
Klik Batalkan Antrean
↓
Sistem meminta konfirmasi
↓
Status berubah menjadi cancelled
↓
Admin melihat antrean tersebut batal
```

---

## 10. Fitur Mobile App Flutter

### 10.1 Authentication

Fitur:

- Register pasien.
- Login pasien.
- Logout.
- Session persistence.
- Validasi role `patient`.

Input register:

```txt
full_name
email
password
phone_number
birth_date optional
gender optional
```

Output:

```txt
Supabase auth user dibuat
Row profile dibuat
Role default patient
```

### 10.2 Dashboard Pasien

Data yang tampil:

- Nama pasien.
- Antrean aktif jika ada.
- Tombol ambil antrean.
- Daftar cabang klinik.
- Daftar poli populer.
- Riwayat antrean terbaru.

Komponen:

```txt
PatientHeader
ActiveQueueCard
ClinicBranchCard
PolyclinicCard
RecentQueueHistoryList
```

### 10.3 Halaman Pilih Klinik/Cabang

Data yang tampil:

- Nama cabang.
- Alamat.
- Jam buka.
- Status buka/tutup.
- Nomor telepon.

### 10.4 Halaman Pilih Poli

Data yang tampil:

- Nama poli.
- Deskripsi.
- Jumlah dokter tersedia.
- Status layanan.

### 10.5 Halaman Pilih Jadwal Dokter

Data yang tampil:

- Nama dokter.
- Spesialisasi.
- Hari praktik.
- Jam mulai dan selesai.
- Kuota maksimal.
- Sisa kuota.
- Estimasi durasi pelayanan.

### 10.6 Halaman Ambil Nomor Antrean

Validasi:

- Pasien sudah login.
- Jadwal aktif.
- Kuota belum penuh.
- Pasien belum punya antrean aktif pada jadwal yang sama.
- Pengambilan antrean masih dalam batas waktu.

Output sukses:

```txt
Nomor antrean: A001
Status: waiting
Estimasi waktu tunggu: ± 24 menit
```

### 10.7 Halaman Tracking Antrean

Data utama:

- Nomor antrean pasien.
- Nomor sedang dipanggil.
- Posisi pasien.
- Sisa antrean sebelum pasien.
- Estimasi waktu tunggu.
- Status antrean.
- Nama dokter.
- Nama poli.
- Jam praktik.

Contoh tampilan:

```txt
Nomor Anda      : A012
Sedang Dipanggil: A009
Sisa Antrean    : 3 pasien
Estimasi Tunggu : ± 18 menit
Status          : Menunggu
```

### 10.8 Notifikasi Mobile

Jenis notifikasi MVP:

1. Antrean berhasil dibuat.
2. Antrean tersisa 3 nomor.
3. Nomor antrean sedang dipanggil.
4. Antrean dilewati.
5. Antrean dibatalkan.

Untuk MVP, notifikasi cukup menggunakan local notification yang dipicu oleh realtime listener.

Untuk produksi, gunakan FCM dan Supabase Edge Functions.

### 10.9 Riwayat Antrean

Data yang tampil:

- Tanggal.
- Klinik/cabang.
- Poli.
- Dokter.
- Nomor antrean.
- Status akhir.
- Waktu dibuat.
- Waktu dipanggil.
- Waktu selesai.

---

## 11. Fitur Web Admin Panel

### 11.1 Admin Login

Fitur:

- Login admin.
- Logout.
- Role guard.
- Redirect sesuai role.

Role guard:

```txt
/admin      -> admin, owner, super_admin
/doctor     -> doctor
/owner      -> owner, super_admin
```

### 11.2 Dashboard Admin

Data yang tampil:

- Total antrean hari ini.
- Total waiting.
- Total called.
- Total serving.
- Total completed.
- Total cancelled.
- Rata-rata waktu tunggu.
- Antrean per poli.

### 11.3 Manajemen Antrean

Fitur:

- Filter antrean berdasarkan tanggal.
- Filter berdasarkan cabang.
- Filter berdasarkan poli.
- Filter berdasarkan dokter.
- Lihat daftar antrean.
- Panggil antrean berikutnya.
- Tandai sedang dilayani.
- Tandai selesai.
- Lewati antrean.
- Batalkan antrean.

Status antrean:

```txt
waiting
called
serving
completed
skipped
cancelled
expired
```

### 11.4 Manajemen Klinik/Cabang

Fitur:

- Tambah cabang.
- Edit cabang.
- Aktif/nonaktif cabang.
- Atur jam operasional.

### 11.5 Manajemen Poli

Fitur:

- Tambah poli.
- Edit poli.
- Aktif/nonaktif poli.
- Hubungkan poli dengan cabang.

### 11.6 Manajemen Dokter

Fitur:

- Tambah dokter.
- Edit data dokter.
- Hubungkan dokter dengan poli.
- Aktif/nonaktif dokter.

### 11.7 Manajemen Jadwal Dokter

Fitur:

- Tambah jadwal praktik.
- Edit jadwal.
- Atur kuota antrean.
- Atur rata-rata durasi pelayanan.
- Buka/tutup jadwal.

### 11.8 Dashboard Owner

Data yang tampil:

- Total pasien per hari.
- Total pasien per minggu/bulan.
- Poli paling ramai.
- Dokter paling banyak melayani.
- Rata-rata waktu tunggu.
- Jumlah antrean batal/dilewati.

---

## 12. Aturan Bisnis

### 12.1 Aturan Nomor Antrean

1. Nomor antrean dibuat per jadwal dokter.
2. Format nomor antrean menggunakan prefix poli + angka urut.
3. Contoh:
   - Umum: U001, U002, U003.
   - Gigi: G001, G002, G003.
   - Anak: A001, A002, A003.

4. Nomor yang batal tidak digunakan ulang.
5. Urutan antrean berdasarkan `queue_number` dan `created_at`.

### 12.2 Aturan Kuota

1. Setiap jadwal memiliki `quota_limit`.
2. Pasien tidak bisa mengambil antrean jika kuota penuh.
3. Antrean `cancelled` tetap tercatat, tetapi dapat dipilih apakah mengurangi kuota atau tidak.
4. Untuk MVP, `cancelled` tetap dihitung sebagai nomor antrean yang pernah dibuat, tetapi tidak masuk waiting.

### 12.3 Aturan Antrean Aktif

Pasien hanya boleh memiliki satu antrean aktif pada jadwal yang sama.

Status aktif:

```txt
waiting
called
serving
```

Status tidak aktif:

```txt
completed
cancelled
skipped
expired
```

### 12.4 Aturan Estimasi Waktu Tunggu

Rumus MVP:

```txt
sisa_antrean = jumlah pasien waiting/called/serving sebelum nomor pasien
estimasi_menit = sisa_antrean * average_service_minutes
```

Contoh:

```txt
Nomor pasien: U012
Nomor berjalan: U009
Average service: 8 menit
Sisa antrean: 3
Estimasi: 3 * 8 = 24 menit
```

### 12.5 Aturan Notifikasi

Notifikasi dikirim ketika:

1. Pasien berhasil mengambil nomor antrean.
2. Sisa antrean pasien <= 3.
3. Status antrean berubah menjadi called.
4. Status antrean berubah menjadi skipped/cancelled.

### 12.6 Aturan Realtime

Mobile app harus subscribe ke:

- Row antrean milik pasien.
- Queue sessions berdasarkan schedule.
- Ticket status changes.

Web admin harus subscribe ke:

- Daftar antrean hari ini.
- Perubahan status tiket antrean.
- Perubahan jadwal aktif.

---

## 13. Struktur Database Normalisasi

Desain database dibuat normal supaya:

1. Data tidak duplikatif.
2. Mudah dikembangkan ke multi-cabang.
3. Role user lebih fleksibel.
4. Jadwal dokter dan antrean lebih rapi.
5. Laporan lebih mudah dibuat.

### 13.1 Entitas Utama

```txt
auth.users
profiles
roles
user_roles
clinics
clinic_branches
clinic_staff
polyclinics
doctors
doctor_polyclinics
doctor_schedules
queue_sessions
queue_tickets
queue_events
notifications
```

### 13.2 Relasi Utama

```txt
auth.users 1---1 profiles
auth.users M---M roles melalui user_roles
clinics 1---M clinic_branches
clinic_branches 1---M polyclinics
profiles 1---M doctors
polyclinics M---M doctors melalui doctor_polyclinics
doctors 1---M doctor_schedules
polyclinics 1---M doctor_schedules
doctor_schedules 1---M queue_sessions
queue_sessions 1---M queue_tickets
queue_tickets 1---M queue_events
profiles 1---M queue_tickets sebagai pasien
```

---

## 14. Supabase SQL Schema

> Catatan: Supabase sudah punya tabel `auth.users`. Tabel aplikasi memakai `public.profiles` yang mereferensikan `auth.users(id)`.

### 14.1 Enable Extensions

```sql
create extension if not exists "uuid-ossp";
create extension if not exists "pgcrypto";
```

### 14.2 Enum Types

```sql
create type public.gender_type as enum (
  'male',
  'female',
  'other'
);

create type public.queue_status as enum (
  'waiting',
  'called',
  'serving',
  'completed',
  'skipped',
  'cancelled',
  'expired'
);

create type public.schedule_status as enum (
  'open',
  'closed',
  'full',
  'cancelled'
);

create type public.notification_type as enum (
  'queue_created',
  'queue_near',
  'queue_called',
  'queue_skipped',
  'queue_cancelled',
  'schedule_changed'
);
```

### 14.3 Profiles

```sql
create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  full_name text not null,
  phone_number text,
  birth_date date,
  gender public.gender_type,
  avatar_url text,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index profiles_full_name_idx on public.profiles using gin (to_tsvector('simple', full_name));
```

### 14.4 Roles

```sql
create table public.roles (
  id bigserial primary key,
  code text not null unique,
  name text not null,
  description text,
  created_at timestamptz not null default now()
);

insert into public.roles (code, name, description) values
('patient', 'Patient', 'Pengguna aplikasi mobile'),
('admin', 'Admin', 'Admin operasional klinik'),
('doctor', 'Doctor', 'Dokter atau petugas poli'),
('owner', 'Owner', 'Pemilik klinik'),
('super_admin', 'Super Admin', 'Pengelola seluruh sistem');
```

### 14.5 User Roles

```sql
create table public.user_roles (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  role_id bigint not null references public.roles(id) on delete cascade,
  created_at timestamptz not null default now(),
  unique(user_id, role_id)
);

create index user_roles_user_id_idx on public.user_roles(user_id);
create index user_roles_role_id_idx on public.user_roles(role_id);
```

### 14.6 Clinics

```sql
create table public.clinics (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  description text,
  logo_url text,
  phone_number text,
  email text,
  website text,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
```

### 14.7 Clinic Branches

```sql
create table public.clinic_branches (
  id uuid primary key default gen_random_uuid(),
  clinic_id uuid not null references public.clinics(id) on delete cascade,
  name text not null,
  address text not null,
  city text,
  province text,
  latitude numeric(10, 7),
  longitude numeric(10, 7),
  phone_number text,
  open_time time,
  close_time time,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index clinic_branches_clinic_id_idx on public.clinic_branches(clinic_id);
```

### 14.8 Clinic Staff

Tabel ini menghubungkan user dengan cabang klinik. Admin, dokter, owner, atau petugas dapat ditugaskan ke cabang tertentu.

```sql
create table public.clinic_staff (
  id uuid primary key default gen_random_uuid(),
  branch_id uuid not null references public.clinic_branches(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  staff_title text,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  unique(branch_id, user_id)
);

create index clinic_staff_branch_id_idx on public.clinic_staff(branch_id);
create index clinic_staff_user_id_idx on public.clinic_staff(user_id);
```

### 14.9 Polyclinics

```sql
create table public.polyclinics (
  id uuid primary key default gen_random_uuid(),
  branch_id uuid not null references public.clinic_branches(id) on delete cascade,
  name text not null,
  code text not null,
  description text,
  queue_prefix text not null,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(branch_id, code),
  unique(branch_id, queue_prefix)
);

create index polyclinics_branch_id_idx on public.polyclinics(branch_id);
```

Contoh data poli:

```sql
insert into public.polyclinics (branch_id, name, code, description, queue_prefix)
values
('BRANCH_ID_HERE', 'Poli Umum', 'UMUM', 'Layanan pemeriksaan umum', 'U'),
('BRANCH_ID_HERE', 'Poli Gigi', 'GIGI', 'Layanan pemeriksaan gigi', 'G'),
('BRANCH_ID_HERE', 'Poli Anak', 'ANAK', 'Layanan kesehatan anak', 'A');
```

### 14.10 Doctors

Dokter tetap menggunakan `profiles` sebagai data user umum. Tabel `doctors` menyimpan detail profesi dokter.

```sql
create table public.doctors (
  id uuid primary key default gen_random_uuid(),
  profile_id uuid not null references public.profiles(id) on delete cascade,
  license_number text,
  specialization text,
  bio text,
  photo_url text,
  default_service_minutes int not null default 10 check (default_service_minutes > 0),
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(profile_id)
);

create index doctors_profile_id_idx on public.doctors(profile_id);
```

### 14.11 Doctor Polyclinics

```sql
create table public.doctor_polyclinics (
  id uuid primary key default gen_random_uuid(),
  doctor_id uuid not null references public.doctors(id) on delete cascade,
  polyclinic_id uuid not null references public.polyclinics(id) on delete cascade,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  unique(doctor_id, polyclinic_id)
);

create index doctor_polyclinics_doctor_id_idx on public.doctor_polyclinics(doctor_id);
create index doctor_polyclinics_polyclinic_id_idx on public.doctor_polyclinics(polyclinic_id);
```

### 14.12 Doctor Schedules

Jadwal dokter dibuat per tanggal agar lebih mudah mengontrol kuota harian.

```sql
create table public.doctor_schedules (
  id uuid primary key default gen_random_uuid(),
  branch_id uuid not null references public.clinic_branches(id) on delete cascade,
  polyclinic_id uuid not null references public.polyclinics(id) on delete restrict,
  doctor_id uuid not null references public.doctors(id) on delete restrict,
  schedule_date date not null,
  start_time time not null,
  end_time time not null,
  quota_limit int not null check (quota_limit > 0),
  average_service_minutes int not null default 10 check (average_service_minutes > 0),
  status public.schedule_status not null default 'open',
  notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check (end_time > start_time),
  unique(branch_id, polyclinic_id, doctor_id, schedule_date, start_time)
);

create index doctor_schedules_branch_id_idx on public.doctor_schedules(branch_id);
create index doctor_schedules_polyclinic_id_idx on public.doctor_schedules(polyclinic_id);
create index doctor_schedules_doctor_id_idx on public.doctor_schedules(doctor_id);
create index doctor_schedules_date_idx on public.doctor_schedules(schedule_date);
```

### 14.13 Queue Sessions

Queue session adalah sesi antrean untuk satu jadwal dokter. Satu jadwal idealnya punya satu queue session.

```sql
create table public.queue_sessions (
  id uuid primary key default gen_random_uuid(),
  schedule_id uuid not null references public.doctor_schedules(id) on delete cascade,
  current_number int not null default 0,
  last_number int not null default 0,
  is_open boolean not null default true,
  started_at timestamptz,
  closed_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(schedule_id),
  check (current_number >= 0),
  check (last_number >= 0),
  check (last_number >= current_number)
);

create index queue_sessions_schedule_id_idx on public.queue_sessions(schedule_id);
```

### 14.14 Queue Tickets

Ticket adalah nomor antrean pasien.

```sql
create table public.queue_tickets (
  id uuid primary key default gen_random_uuid(),
  queue_session_id uuid not null references public.queue_sessions(id) on delete cascade,
  patient_id uuid not null references public.profiles(id) on delete cascade,
  queue_number int not null,
  queue_code text not null,
  status public.queue_status not null default 'waiting',
  estimated_wait_minutes int not null default 0,
  checked_in_at timestamptz,
  called_at timestamptz,
  serving_started_at timestamptz,
  completed_at timestamptz,
  skipped_at timestamptz,
  cancelled_at timestamptz,
  expired_at timestamptz,
  cancel_reason text,
  notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(queue_session_id, queue_number),
  unique(queue_session_id, queue_code)
);

create index queue_tickets_session_id_idx on public.queue_tickets(queue_session_id);
create index queue_tickets_patient_id_idx on public.queue_tickets(patient_id);
create index queue_tickets_status_idx on public.queue_tickets(status);
create index queue_tickets_created_at_idx on public.queue_tickets(created_at);
```

### 14.15 Queue Events

Tabel ini menyimpan log perubahan status antrean.

```sql
create table public.queue_events (
  id uuid primary key default gen_random_uuid(),
  queue_ticket_id uuid not null references public.queue_tickets(id) on delete cascade,
  actor_id uuid references public.profiles(id) on delete set null,
  previous_status public.queue_status,
  new_status public.queue_status not null,
  message text,
  created_at timestamptz not null default now()
);

create index queue_events_ticket_id_idx on public.queue_events(queue_ticket_id);
create index queue_events_actor_id_idx on public.queue_events(actor_id);
```

### 14.16 Notifications

```sql
create table public.notifications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  type public.notification_type not null,
  title text not null,
  body text not null,
  data jsonb,
  is_read boolean not null default false,
  created_at timestamptz not null default now(),
  read_at timestamptz
);

create index notifications_user_id_idx on public.notifications(user_id);
create index notifications_is_read_idx on public.notifications(is_read);
```

---

## 15. Database Helper Functions

### 15.1 Function: Check Role

```sql
create or replace function public.has_role(target_role text)
returns boolean
language sql
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.user_roles ur
    join public.roles r on r.id = ur.role_id
    where ur.user_id = auth.uid()
      and r.code = target_role
  );
$$;
```

### 15.2 Function: Get User Role Codes

```sql
create or replace function public.get_my_roles()
returns table(role_code text)
language sql
security definer
set search_path = public
as $$
  select r.code
  from public.user_roles ur
  join public.roles r on r.id = ur.role_id
  where ur.user_id = auth.uid();
$$;
```

### 15.3 Function: Generate Queue Ticket

Fungsi ini sebaiknya dipakai untuk membuat nomor antrean agar aman dari race condition.

```sql
create or replace function public.create_queue_ticket(p_queue_session_id uuid)
returns public.queue_tickets
language plpgsql
security definer
set search_path = public
as $$
declare
  v_session public.queue_sessions%rowtype;
  v_schedule public.doctor_schedules%rowtype;
  v_polyclinic public.polyclinics%rowtype;
  v_next_number int;
  v_queue_code text;
  v_ticket public.queue_tickets%rowtype;
  v_existing_active int;
  v_taken_count int;
begin
  if auth.uid() is null then
    raise exception 'Unauthorized';
  end if;

  select * into v_session
  from public.queue_sessions
  where id = p_queue_session_id
  for update;

  if not found then
    raise exception 'Queue session not found';
  end if;

  if v_session.is_open = false then
    raise exception 'Queue session is closed';
  end if;

  select * into v_schedule
  from public.doctor_schedules
  where id = v_session.schedule_id;

  if not found then
    raise exception 'Schedule not found';
  end if;

  if v_schedule.status <> 'open' then
    raise exception 'Schedule is not open';
  end if;

  select count(*) into v_taken_count
  from public.queue_tickets
  where queue_session_id = p_queue_session_id
    and status <> 'cancelled';

  if v_taken_count >= v_schedule.quota_limit then
    raise exception 'Queue quota is full';
  end if;

  select count(*) into v_existing_active
  from public.queue_tickets
  where queue_session_id = p_queue_session_id
    and patient_id = auth.uid()
    and status in ('waiting', 'called', 'serving');

  if v_existing_active > 0 then
    raise exception 'Patient already has active queue in this session';
  end if;

  select * into v_polyclinic
  from public.polyclinics
  where id = v_schedule.polyclinic_id;

  v_next_number := v_session.last_number + 1;
  v_queue_code := v_polyclinic.queue_prefix || lpad(v_next_number::text, 3, '0');

  update public.queue_sessions
  set last_number = v_next_number,
      updated_at = now()
  where id = p_queue_session_id;

  insert into public.queue_tickets (
    queue_session_id,
    patient_id,
    queue_number,
    queue_code,
    status,
    estimated_wait_minutes
  ) values (
    p_queue_session_id,
    auth.uid(),
    v_next_number,
    v_queue_code,
    'waiting',
    greatest((v_next_number - v_session.current_number - 1), 0) * v_schedule.average_service_minutes
  )
  returning * into v_ticket;

  insert into public.queue_events (
    queue_ticket_id,
    actor_id,
    previous_status,
    new_status,
    message
  ) values (
    v_ticket.id,
    auth.uid(),
    null,
    'waiting',
    'Queue ticket created'
  );

  return v_ticket;
end;
$$;
```

### 15.4 Function: Call Next Queue

```sql
create or replace function public.call_next_queue(p_queue_session_id uuid)
returns public.queue_tickets
language plpgsql
security definer
set search_path = public
as $$
declare
  v_ticket public.queue_tickets%rowtype;
begin
  if not (public.has_role('admin') or public.has_role('doctor') or public.has_role('owner') or public.has_role('super_admin')) then
    raise exception 'Forbidden';
  end if;

  select * into v_ticket
  from public.queue_tickets
  where queue_session_id = p_queue_session_id
    and status = 'waiting'
  order by queue_number asc
  limit 1
  for update skip locked;

  if not found then
    raise exception 'No waiting queue found';
  end if;

  update public.queue_tickets
  set status = 'called',
      called_at = now(),
      updated_at = now()
  where id = v_ticket.id
  returning * into v_ticket;

  update public.queue_sessions
  set current_number = v_ticket.queue_number,
      updated_at = now()
  where id = p_queue_session_id;

  insert into public.queue_events (
    queue_ticket_id,
    actor_id,
    previous_status,
    new_status,
    message
  ) values (
    v_ticket.id,
    auth.uid(),
    'waiting',
    'called',
    'Queue called by staff'
  );

  return v_ticket;
end;
$$;
```

### 15.5 Function: Update Queue Status

```sql
create or replace function public.update_queue_status(
  p_ticket_id uuid,
  p_new_status public.queue_status,
  p_message text default null
)
returns public.queue_tickets
language plpgsql
security definer
set search_path = public
as $$
declare
  v_ticket public.queue_tickets%rowtype;
  v_old_status public.queue_status;
begin
  if not (public.has_role('admin') or public.has_role('doctor') or public.has_role('owner') or public.has_role('super_admin')) then
    raise exception 'Forbidden';
  end if;

  select * into v_ticket
  from public.queue_tickets
  where id = p_ticket_id
  for update;

  if not found then
    raise exception 'Queue ticket not found';
  end if;

  v_old_status := v_ticket.status;

  update public.queue_tickets
  set status = p_new_status,
      serving_started_at = case when p_new_status = 'serving' then now() else serving_started_at end,
      completed_at = case when p_new_status = 'completed' then now() else completed_at end,
      skipped_at = case when p_new_status = 'skipped' then now() else skipped_at end,
      cancelled_at = case when p_new_status = 'cancelled' then now() else cancelled_at end,
      expired_at = case when p_new_status = 'expired' then now() else expired_at end,
      updated_at = now()
  where id = p_ticket_id
  returning * into v_ticket;

  insert into public.queue_events (
    queue_ticket_id,
    actor_id,
    previous_status,
    new_status,
    message
  ) values (
    p_ticket_id,
    auth.uid(),
    v_old_status,
    p_new_status,
    coalesce(p_message, 'Queue status updated')
  );

  return v_ticket;
end;
$$;
```

---

## 16. Views untuk Query Aplikasi

### 16.1 View Queue Ticket Detail

```sql
create or replace view public.v_queue_ticket_details as
select
  qt.id as ticket_id,
  qt.queue_session_id,
  qt.patient_id,
  p.full_name as patient_name,
  qt.queue_number,
  qt.queue_code,
  qt.status,
  qt.estimated_wait_minutes,
  qt.created_at,
  qt.called_at,
  qt.serving_started_at,
  qt.completed_at,
  qs.current_number,
  qs.last_number,
  ds.id as schedule_id,
  ds.schedule_date,
  ds.start_time,
  ds.end_time,
  ds.average_service_minutes,
  cb.id as branch_id,
  cb.name as branch_name,
  cb.address as branch_address,
  pc.id as polyclinic_id,
  pc.name as polyclinic_name,
  pc.queue_prefix,
  d.id as doctor_id,
  dp.full_name as doctor_name,
  d.specialization
from public.queue_tickets qt
join public.profiles p on p.id = qt.patient_id
join public.queue_sessions qs on qs.id = qt.queue_session_id
join public.doctor_schedules ds on ds.id = qs.schedule_id
join public.clinic_branches cb on cb.id = ds.branch_id
join public.polyclinics pc on pc.id = ds.polyclinic_id
join public.doctors d on d.id = ds.doctor_id
join public.profiles dp on dp.id = d.profile_id;
```

### 16.2 View Schedule Availability

```sql
create or replace view public.v_schedule_availability as
select
  ds.id as schedule_id,
  ds.branch_id,
  cb.name as branch_name,
  ds.polyclinic_id,
  pc.name as polyclinic_name,
  pc.queue_prefix,
  ds.doctor_id,
  dp.full_name as doctor_name,
  d.specialization,
  ds.schedule_date,
  ds.start_time,
  ds.end_time,
  ds.quota_limit,
  ds.average_service_minutes,
  ds.status,
  coalesce(qs.id, null) as queue_session_id,
  coalesce(qs.current_number, 0) as current_number,
  coalesce(qs.last_number, 0) as last_number,
  count(qt.id) filter (where qt.status <> 'cancelled') as total_taken,
  ds.quota_limit - count(qt.id) filter (where qt.status <> 'cancelled') as remaining_quota
from public.doctor_schedules ds
join public.clinic_branches cb on cb.id = ds.branch_id
join public.polyclinics pc on pc.id = ds.polyclinic_id
join public.doctors d on d.id = ds.doctor_id
join public.profiles dp on dp.id = d.profile_id
left join public.queue_sessions qs on qs.schedule_id = ds.id
left join public.queue_tickets qt on qt.queue_session_id = qs.id
group by ds.id, cb.name, pc.name, pc.queue_prefix, dp.full_name, d.specialization, qs.id, qs.current_number, qs.last_number;
```

---

## 17. Row Level Security Plan

### 17.1 Enable RLS

```sql
alter table public.profiles enable row level security;
alter table public.roles enable row level security;
alter table public.user_roles enable row level security;
alter table public.clinics enable row level security;
alter table public.clinic_branches enable row level security;
alter table public.clinic_staff enable row level security;
alter table public.polyclinics enable row level security;
alter table public.doctors enable row level security;
alter table public.doctor_polyclinics enable row level security;
alter table public.doctor_schedules enable row level security;
alter table public.queue_sessions enable row level security;
alter table public.queue_tickets enable row level security;
alter table public.queue_events enable row level security;
alter table public.notifications enable row level security;
```

### 17.2 Profiles Policies

```sql
create policy "Users can read own profile"
on public.profiles
for select
to authenticated
using (id = auth.uid());

create policy "Users can update own profile"
on public.profiles
for update
to authenticated
using (id = auth.uid())
with check (id = auth.uid());

create policy "Staff can read profiles"
on public.profiles
for select
to authenticated
using (
  public.has_role('admin')
  or public.has_role('doctor')
  or public.has_role('owner')
  or public.has_role('super_admin')
);
```

### 17.3 Public Read Master Data

Untuk MVP, pasien boleh membaca data klinik, cabang, poli, dokter, dan jadwal yang aktif.

```sql
create policy "Authenticated users can read active clinics"
on public.clinics
for select
to authenticated
using (is_active = true);

create policy "Authenticated users can read active branches"
on public.clinic_branches
for select
to authenticated
using (is_active = true);

create policy "Authenticated users can read active polyclinics"
on public.polyclinics
for select
to authenticated
using (is_active = true);

create policy "Authenticated users can read active doctors"
on public.doctors
for select
to authenticated
using (is_active = true);

create policy "Authenticated users can read open schedules"
on public.doctor_schedules
for select
to authenticated
using (status in ('open', 'full', 'closed'));

create policy "Authenticated users can read queue sessions"
on public.queue_sessions
for select
to authenticated
using (true);
```

### 17.4 Queue Tickets Policies

```sql
create policy "Patients can read own queue tickets"
on public.queue_tickets
for select
to authenticated
using (patient_id = auth.uid());

create policy "Patients can create own queue tickets"
on public.queue_tickets
for insert
to authenticated
with check (patient_id = auth.uid());

create policy "Staff can read queue tickets"
on public.queue_tickets
for select
to authenticated
using (
  public.has_role('admin')
  or public.has_role('doctor')
  or public.has_role('owner')
  or public.has_role('super_admin')
);

create policy "Staff can update queue tickets"
on public.queue_tickets
for update
to authenticated
using (
  public.has_role('admin')
  or public.has_role('doctor')
  or public.has_role('owner')
  or public.has_role('super_admin')
);
```

> Untuk produksi, insert ticket lebih aman dilakukan hanya lewat RPC `create_queue_ticket`, bukan insert langsung dari client.

### 17.5 Notifications Policies

```sql
create policy "Users can read own notifications"
on public.notifications
for select
to authenticated
using (user_id = auth.uid());

create policy "Users can update own notifications"
on public.notifications
for update
to authenticated
using (user_id = auth.uid())
with check (user_id = auth.uid());
```

---

## 18. Realtime Subscription Plan

### 18.1 Mobile App

Mobile subscribe ke:

```txt
queue_tickets
filter: patient_id = auth.uid()
```

Kebutuhan:

- Melihat perubahan status antrean sendiri.
- Memicu local notification saat status berubah.
- Mengupdate UI tracking antrean.

Mobile juga bisa subscribe ke:

```txt
queue_sessions
filter: id = active_queue_session_id
```

Kebutuhan:

- Melihat nomor berjalan.
- Menghitung sisa antrean.
- Menghitung estimasi waktu tunggu.

### 18.2 Web Admin

Web admin subscribe ke:

```txt
queue_tickets
filter: queue_session_id = selected_queue_session_id
```

Kebutuhan:

- Menampilkan daftar antrean real-time.
- Melihat pasien baru yang mengambil nomor.
- Melihat perubahan status.

---

## 19. API/RPC Contract

Karena Supabase digunakan langsung oleh Flutter dan React, kontrak utama berupa query table, view, dan RPC.

### 19.1 Auth

```txt
signUp(email, password)
signInWithPassword(email, password)
signOut()
getSession()
getUser()
```

### 19.2 Patient RPC

#### Create Queue Ticket

```ts
const { data, error } = await supabase.rpc("create_queue_ticket", {
  p_queue_session_id: queueSessionId,
});
```

Response:

```json
{
  "id": "uuid",
  "queue_session_id": "uuid",
  "patient_id": "uuid",
  "queue_number": 12,
  "queue_code": "U012",
  "status": "waiting",
  "estimated_wait_minutes": 24
}
```

### 19.3 Admin RPC

#### Call Next Queue

```ts
const { data, error } = await supabase.rpc("call_next_queue", {
  p_queue_session_id: queueSessionId,
});
```

#### Update Queue Status

```ts
const { data, error } = await supabase.rpc("update_queue_status", {
  p_ticket_id: ticketId,
  p_new_status: "serving",
  p_message: "Patient is being served",
});
```

---

## 20. Struktur Folder Flutter

```txt
lib/
├── main.dart
├── app.dart
├── core/
│   ├── config/
│   │   ├── app_config.dart
│   │   └── supabase_config.dart
│   ├── constants/
│   │   ├── app_colors.dart
│   │   ├── app_strings.dart
│   │   └── app_routes.dart
│   ├── errors/
│   │   └── failure.dart
│   ├── services/
│   │   ├── supabase_service.dart
│   │   ├── notification_service.dart
│   │   └── realtime_service.dart
│   ├── theme/
│   │   └── app_theme.dart
│   └── utils/
│       ├── date_formatter.dart
│       └── queue_estimator.dart
├── data/
│   ├── models/
│   │   ├── profile_model.dart
│   │   ├── clinic_model.dart
│   │   ├── branch_model.dart
│   │   ├── polyclinic_model.dart
│   │   ├── doctor_model.dart
│   │   ├── schedule_model.dart
│   │   ├── queue_session_model.dart
│   │   └── queue_ticket_model.dart
│   └── repositories/
│       ├── auth_repository.dart
│       ├── clinic_repository.dart
│       ├── schedule_repository.dart
│       └── queue_repository.dart
├── providers/
│   ├── auth_provider.dart
│   ├── clinic_provider.dart
│   ├── schedule_provider.dart
│   └── queue_provider.dart
├── presentation/
│   ├── auth/
│   │   ├── login_page.dart
│   │   └── register_page.dart
│   ├── patient/
│   │   ├── patient_home_page.dart
│   │   ├── branch_list_page.dart
│   │   ├── polyclinic_list_page.dart
│   │   ├── schedule_list_page.dart
│   │   ├── queue_confirmation_page.dart
│   │   ├── queue_tracking_page.dart
│   │   └── queue_history_page.dart
│   └── widgets/
│       ├── active_queue_card.dart
│       ├── branch_card.dart
│       ├── polyclinic_card.dart
│       ├── schedule_card.dart
│       ├── queue_status_badge.dart
│       └── primary_button.dart
└── routes/
    └── app_router.dart
```

---

## 21. Struktur Folder Web Admin

```txt
src/
├── app/
│   ├── providers.tsx
│   └── router.tsx
├── config/
│   └── env.ts
├── lib/
│   ├── supabase.ts
│   ├── utils.ts
│   └── date.ts
├── types/
│   ├── auth.ts
│   ├── clinic.ts
│   ├── schedule.ts
│   └── queue.ts
├── features/
│   ├── auth/
│   │   ├── pages/LoginPage.tsx
│   │   ├── services/authService.ts
│   │   └── hooks/useAuth.ts
│   ├── dashboard/
│   │   ├── pages/AdminDashboardPage.tsx
│   │   └── components/StatsCard.tsx
│   ├── queues/
│   │   ├── pages/QueueManagementPage.tsx
│   │   ├── components/QueueTable.tsx
│   │   ├── components/QueueActionButtons.tsx
│   │   ├── services/queueService.ts
│   │   └── hooks/useQueues.ts
│   ├── clinics/
│   │   ├── pages/BranchManagementPage.tsx
│   │   └── services/clinicService.ts
│   ├── polyclinics/
│   │   ├── pages/PolyclinicManagementPage.tsx
│   │   └── services/polyclinicService.ts
│   ├── doctors/
│   │   ├── pages/DoctorManagementPage.tsx
│   │   └── services/doctorService.ts
│   └── schedules/
│       ├── pages/ScheduleManagementPage.tsx
│       └── services/scheduleService.ts
├── components/
│   ├── layout/
│   │   ├── AdminLayout.tsx
│   │   ├── Sidebar.tsx
│   │   └── Header.tsx
│   └── ui/
│       ├── Button.tsx
│       ├── Input.tsx
│       ├── Modal.tsx
│       └── Badge.tsx
└── main.tsx
```

---

## 22. UI/UX Mobile App

### 22.1 Gaya Visual

Konsep desain:

```txt
Clean medical
Modern blue-green
Rounded card
Soft background
Readable typography
Friendly and calm
```

Warna rekomendasi:

```txt
Primary       : #0EA5A4
Primary Dark  : #087F7E
Secondary     : #2563EB
Background    : #F6FAFB
Surface       : #FFFFFF
Text Primary  : #0F172A
Text Muted    : #64748B
Success       : #16A34A
Warning       : #F59E0B
Danger        : #DC2626
```

### 22.2 Halaman Mobile

```txt
SplashPage
OnboardingPage optional
LoginPage
RegisterPage
PatientHomePage
BranchListPage
PolyclinicListPage
ScheduleListPage
QueueConfirmationPage
QueueTrackingPage
QueueHistoryPage
ProfilePage
```

### 22.3 Komponen Penting

```txt
ActiveQueueCard
QueueNumberDisplay
EstimatedWaitCard
ProgressQueueIndicator
DoctorScheduleCard
PolyclinicCard
HistoryQueueTile
StatusBadge
```

---

## 23. UI/UX Web Admin

### 23.1 Gaya Visual

Konsep desain:

```txt
Professional admin dashboard
Clean table layout
Fast action buttons
Medical SaaS look
Data-first interface
```

### 23.2 Halaman Admin

```txt
LoginPage
AdminDashboardPage
QueueManagementPage
ScheduleManagementPage
DoctorManagementPage
PolyclinicManagementPage
BranchManagementPage
OwnerReportPage
SettingsPage
```

### 23.3 Komponen Penting

```txt
StatsCard
QueueTable
QueueStatusBadge
CallNextButton
QueueFilterBar
ScheduleFormModal
DoctorFormModal
ConfirmDialog
```

---

## 24. Acceptance Criteria

### 24.1 Pasien Register/Login

```gherkin
Given user membuka aplikasi
When user melakukan register dengan data valid
Then akun berhasil dibuat
And profile pasien tersimpan
And user masuk ke dashboard pasien
```

### 24.2 Pasien Ambil Nomor Antrean

```gherkin
Given pasien sudah login
And jadwal dokter tersedia
And kuota belum penuh
When pasien klik ambil nomor antrean
Then sistem membuat queue ticket
And nomor antrean tampil di aplikasi
And status awal adalah waiting
```

### 24.3 Admin Memanggil Antrean

```gherkin
Given admin sudah login
And terdapat antrean waiting
When admin klik panggil berikutnya
Then antrean paling awal berubah menjadi called
And current_number pada queue session berubah
And pasien menerima update real-time
```

### 24.4 Estimasi Waktu Tunggu

```gherkin
Given pasien memiliki nomor antrean
And ada beberapa antrean sebelum pasien
When nomor berjalan berubah
Then estimasi waktu tunggu ikut berubah
```

### 24.5 Notifikasi Antrean Dekat

```gherkin
Given pasien memiliki antrean waiting
When sisa antrean pasien kurang dari atau sama dengan 3
Then aplikasi menampilkan local notification
```

---

## 25. Prioritas Pengerjaan

### Phase 1 — Database & Supabase Setup

1. Buat project Supabase.
2. Buat schema database.
3. Buat enum, table, view, function.
4. Aktifkan RLS.
5. Setup initial seed data.
6. Test RPC di Supabase SQL Editor.

### Phase 2 — Mobile Auth & Dashboard

1. Setup Flutter project.
2. Install Supabase Flutter.
3. Setup login/register.
4. Buat patient dashboard.
5. Tampilkan list cabang dan poli.

### Phase 3 — Queue Core

1. Tampilkan jadwal dokter.
2. Buat fitur ambil antrean.
3. Buat halaman tracking antrean.
4. Setup realtime listener.
5. Hitung estimasi waktu tunggu.

### Phase 4 — Web Admin

1. Setup React + Vite + TypeScript.
2. Setup Supabase client.
3. Login admin.
4. Dashboard admin.
5. Queue management page.
6. Call next queue.
7. Update queue status.

### Phase 5 — Notification & Polish

1. Setup local notification Flutter.
2. Trigger notifikasi saat sisa antrean <= 3.
3. Polish UI mobile.
4. Polish UI web admin.
5. Testing end-to-end.

---

## 26. Data Dummy untuk MVP

### 26.1 Clinic

```txt
Klinik Sehat Sentosa
Jl. Merdeka No. 10, Jember
08:00 - 20:00
```

### 26.2 Branch

```txt
Cabang Utama
Jl. Merdeka No. 10, Jember
```

### 26.3 Polyclinic

```txt
Poli Umum  -> Prefix U
Poli Gigi  -> Prefix G
Poli Anak  -> Prefix A
```

### 26.4 Doctor

```txt
Dr. Andi Pratama    -> Poli Umum
Dr. Sinta Maharani  -> Poli Gigi
Dr. Budi Santoso    -> Poli Anak
```

### 26.5 Schedule

```txt
Dr. Andi Pratama
Poli Umum
Tanggal hari ini
08:00 - 12:00
Kuota 30
Rata-rata layanan 8 menit
```

---

## 27. Risiko Teknis

| Risiko                                          | Dampak                             | Solusi                                                 |
| ----------------------------------------------- | ---------------------------------- | ------------------------------------------------------ |
| Race condition saat banyak pasien ambil antrean | Nomor antrean bisa duplikat        | Gunakan RPC `create_queue_ticket` dengan `for update`  |
| RLS terlalu longgar                             | Data pasien bisa terbaca user lain | Buat policy ketat berdasarkan role dan owner data      |
| Realtime tidak aktif                            | UI tidak update otomatis           | Enable realtime pada tabel penting di Supabase         |
| Notifikasi local tidak muncul                   | UX kurang kuat                     | Test permission notification sejak awal                |
| Admin web belum selesai                         | Demo kurang lengkap                | Buat minimal queue management page terlebih dahulu     |
| Scope terlalu besar                             | UAS tidak selesai                  | Fokus MVP: auth, jadwal, antrean, realtime, admin call |

---

## 28. Definisi Selesai MVP

MVP dianggap selesai jika:

1. Pasien bisa register dan login.
2. Pasien bisa melihat jadwal dokter.
3. Pasien bisa mengambil nomor antrean.
4. Pasien bisa melihat nomor antrean aktif.
5. Admin bisa login web.
6. Admin bisa melihat daftar antrean.
7. Admin bisa memanggil antrean berikutnya.
8. Status antrean berubah real-time di mobile.
9. Estimasi waktu tunggu tampil.
10. Local notification berjalan minimal untuk antrean dekat.
11. Database sudah normal dan tidak hardcode.

---

## 29. Roadmap Pengembangan

### MVP UAS

```txt
Auth pasien
Auth admin
Master data klinik/poli/dokter/jadwal
Ambil antrean
Tracking realtime
Admin call queue
Estimasi waktu tunggu
Local notification
```

### Version 1.1

```txt
QR check-in
Cancel queue by patient
Queue display screen
Dashboard owner basic
```

### Version 1.2

```txt
Laporan harian/mingguan
Export PDF/Excel
Push notification FCM
WhatsApp reminder
```

### Version 2.0

```txt
Multi-branch advanced
Payment booking
Rating pelayanan
Rekam medis ringan
Smart estimation berbasis historis
```

---

## 30. Kesimpulan

AntriMedis adalah proyek yang kuat untuk UAS karena memiliki masalah nyata, fitur real-time, backend terstruktur, dan pembagian platform yang jelas antara mobile app pasien dan web admin. Dengan Supabase sebagai backend, proyek ini dapat dibangun lebih cepat tetapi tetap memiliki pondasi yang rapi dan scalable.

Fokus pengerjaan sebaiknya dimulai dari database Supabase, karena struktur data antrean menentukan alur mobile dan web admin. Setelah schema stabil, pengembangan dapat dilanjutkan ke Flutter untuk pasien, lalu React web untuk admin.
