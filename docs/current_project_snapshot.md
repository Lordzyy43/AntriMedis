# Current Project Snapshot - AntriMedis

**Tanggal:** 4 Juni 2026  
**Scope:** Satu klinik, satu cabang utama  
**Status:** UAS-ready beta / production-like MVP

Dokumen ini adalah ringkasan cepat kondisi project saat ini. Gunakan dokumen ini saat ingin tahu "sekarang project sudah sampai mana" tanpa membaca PRD penuh.

---

## 1. Ringkasan Kondisi

AntriMedis sudah memiliki dua aplikasi utama:

- **Mobile app pasien**: Flutter.
- **Web admin panel**: React + TypeScript + Vite.

Backend memakai Supabase untuk:

- Auth email/password dan Google OAuth.
- PostgreSQL schema.
- Row Level Security.
- RPC bisnis antrean.
- Realtime subscription.
- Storage avatar.

Flow inti sudah hidup:

```txt
Pasien login
-> melengkapi profil
-> memilih jadwal hari ini
-> mengambil nomor antrean
-> admin memanggil nomor
-> status berubah realtime di mobile
-> admin menyelesaikan layanan
-> pasien melihat history
```

Untuk detail aturan antrean terbaru, gunakan `queue_business_flow.md` sebagai acuan utama.

---

## 2. Modul Mobile yang Sudah Ada

| Modul | Kondisi |
| --- | --- |
| Auth email/password | Selesai |
| Google OAuth | Selesai |
| Profile completion | Selesai |
| Avatar profil | Selesai |
| Home/jadwal | Selesai |
| Ambil antrean | Selesai |
| Tracking realtime | Selesai |
| Estimasi waktu tunggu | Selesai sebagai perkiraan |
| Local notification | Selesai untuk MVP |
| Notification inbox | Selesai untuk event antrean |
| Riwayat antrean | Selesai |
| Floating navigation | Selesai |

Catatan: notifikasi full production saat app mati total butuh FCM + Edge Function.

---

## 3. Modul Admin Panel yang Sudah Ada

| Modul | Kondisi |
| --- | --- |
| Login admin | Selesai |
| Protected route | Selesai |
| Dashboard | Selesai |
| Readiness banner | Selesai |
| Activity feed | Selesai dari `queue_events` |
| Queue management hari ini | Selesai |
| Detail antrean | Selesai |
| Missed/recall/no-show flow | Selesai |
| Close session operasional | Selesai |
| Jadwal | Selesai |
| Duplikasi jadwal | Selesai |
| Dokter | Selesai dengan CRUD, pagination, safe delete |
| Poli | Selesai dengan CRUD, pagination, safe delete |
| Form modal | Selesai |
| Toast feedback | Selesai |

Catatan: queue management sengaja hanya untuk pelayanan hari ini. Jadwal future dibuat dari halaman Jadwal, bukan halaman Antrean.

---

## 4. Backend dan Database

Migration utama:

```txt
20260525152410_initial_antrimedis_schema.sql
20260530090000_harden_queue_state_machine.sql
20260530093000_schedule_session_rpc.sql
20260530100000_queue_event_feed_view.sql
20260530113000_admin_safe_delete_rpcs.sql
20260601090000_soft_delete_used_master_data.sql
20260602173000_allow_after_hours_queue_draining.sql
20260602180000_close_queue_session.sql
20260603101000_missed_queue_recall_flow.sql
20260603102000_missed_queue_detail_view_and_active_guard.sql
20260604090000_realtime_doctor_schedules.sql
20260604093000_close_online_queue_at_end_time.sql
```

RPC penting:

```txt
create_queue_ticket
cancel_my_ticket
call_next_queue
recall_missed_queue
update_queue_status
close_queue_session
create_schedule_with_session
update_schedule_with_session
delete_schedule_if_empty
delete_doctor_if_unused
delete_polyclinic_if_unused
```

View penting:

```txt
v_schedule_availability
v_queue_ticket_details
v_queue_event_feed
```

Aturan penting:

- Pasien hanya boleh punya satu antrean aktif per hari pada cabang utama.
- Pasien boleh mengambil nomor sebelum jam mulai pada hari yang sama jika waktu sekarang masih sebelum jam selesai.
- Pasien tidak boleh mengambil nomor tepat saat atau setelah jam operasional selesai.
- Admin tidak boleh memanggil sebelum jam mulai.
- Admin boleh menghabiskan antrean yang sudah masuk saat atau setelah jam operasional selesai.
- Admin tidak bisa `call next` jika masih ada tiket `called` atau `serving`.
- `missed` baru boleh dipanggil ulang setelah `waiting` habis.
- Recall memakai nomor lama, bukan tiket/nomor baru.
- Tutup sesi mengubah `waiting` menjadi `expired` dan `missed` menjadi `skipped`.
- Kuota dihitung dari tiket yang sudah diambil dan tidak naik saat pasien selesai.
- Status final tidak bisa dikembalikan ke status aktif.
- Dokter/poli yang sudah pernah dipakai tidak dihapus paksa, tetapi diarsipkan.
- Realtime patient schedule feed mendengar `queue_sessions` dan `doctor_schedules`, sehingga perubahan jadwal admin ikut me-refresh home pasien.

---

## 5. Seed Demo

Akun admin profesional:

```txt
Email    : admin@antrimedis.test
Password : AdminMedis2026!
Role     : admin
```

Dataset demo profesional berisi master data klinik, cabang, poli, dan dokter. Data jadwal/session/tiket/event/notification dapat dikosongkan saat ingin testing dari awal agar admin membuat jadwal sendiri.

Reset operasional aman tersedia di:

```txt
apps/supabase/patches/20260604_reset_operational_data_keep_master.sql
```

Patch ini menghapus jadwal, session, tiket, event, dan notifikasi antrean, tetapi menjaga akun, dokter, poli, klinik, cabang, role, dan staff.

Akun pasien QA mudah:

```txt
pasien1@antrimedis.test  sampai  pasien10@antrimedis.test
Password semua: PatientMedis2026!
```

---

## 6. Validasi Terakhir

Mobile:

```powershell
flutter analyze
flutter test
```

Kondisi terakhir: pass pada 4 Juni 2026.

Admin panel:

```powershell
npm run lint
npm run build
```

Kondisi terakhir: pass pada 4 Juni 2026.

Catatan admin build: ada warning chunk Vite lebih dari 500 kB. Ini bukan error, hanya catatan optimasi bundle.

---

## 7. Yang Belum Perlu Dikerjakan Sekarang

- Multi-klinik/global clinic picker.
- Role dokter penuh.
- Owner analytics.
- FCM push notification production.
- Internal testing/upload release jika package id final dari dosen berbeda dari `com.ti24a6.antrimedis`.
- Fitur apotek, obat, pembayaran, BPJS, atau rekam medis.

---

## 8. Next Step Paling Sehat

Urutan yang paling aman:

1. Simpan dokumentasi ini sebagai baseline kondisi project.
2. Saat siap lanjut, jalankan QA E2E penuh dari admin dan mobile.
3. Jika dosen meminta format package khusus, sesuaikan package id dari `com.ti24a6.antrimedis`, lalu build release.
4. Tambahkan automated test minimal setelah flow final tidak sering berubah.
5. Baru pertimbangkan scope baru seperti FCM, report, atau role dokter.

---

## 9. Prinsip Pengembangan

AntriMedis sebaiknya tetap diposisikan sebagai **produk antrean klinik satu instansi** untuk tahap ini. Bukan marketplace klinik dan bukan sistem informasi klinik lengkap.

Fokus nilai produk:

- Pasien tidak perlu menunggu tanpa kepastian.
- Admin punya kontrol antrean yang rapi.
- Klinik punya data operasional yang tercatat.
- Realtime membuat status antrean terasa hidup.

