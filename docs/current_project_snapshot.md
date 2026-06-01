# Current Project Snapshot - AntriMedis

**Tanggal:** 1 Juni 2026  
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
```

RPC penting:

```txt
create_queue_ticket
cancel_my_ticket
call_next_queue
update_queue_status
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
- Admin tidak bisa `call next` jika masih ada tiket `called` atau `serving`.
- Status final tidak bisa dikembalikan ke status aktif.
- Dokter/poli yang sudah pernah dipakai tidak dihapus paksa, tetapi diarsipkan.

---

## 5. Seed Demo

Akun admin profesional:

```txt
Email    : admin@antrimedis.test
Password : AdminMedis2026!
Role     : admin
```

Dataset demo profesional berisi master data klinik, cabang, poli, dokter, jadwal, dan session. Data pasien/tiket/event/notification sengaja tidak di-seed agar flow testing memakai akun pasien asli yang sedang login.

---

## 6. Validasi Terakhir

Mobile:

```powershell
flutter analyze
flutter test
```

Kondisi terakhir: pass.

Admin panel:

```powershell
npm run lint
npm run build
```

Kondisi terakhir: pass.

Catatan admin build: ada warning chunk Vite lebih dari 500 kB. Ini bukan error, hanya catatan optimasi bundle.

---

## 7. Yang Belum Perlu Dikerjakan Sekarang

- Multi-klinik/global clinic picker.
- Role dokter penuh.
- Owner analytics.
- FCM push notification production.
- Internal testing/upload release sebelum package name final.
- Fitur apotek, obat, pembayaran, BPJS, atau rekam medis.

---

## 8. Next Step Paling Sehat

Urutan yang paling aman:

1. Simpan dokumentasi ini sebagai baseline kondisi project.
2. Saat siap lanjut, jalankan QA E2E penuh dari admin dan mobile.
3. Setelah package name final dari dosen, rapikan Android identity, icon, splash, dan build release.
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

