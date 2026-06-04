# PRD Status & Roadmap - AntriMedis

**Tanggal update:** 4 Juni 2026  
**Dokumen acuan:** `docs/prd.md`  
**Dokumen business flow antrean:** `docs/queue_business_flow.md`  
**Status project:** UAS-ready beta / production-like MVP  
**Scope aktif:** Satu klinik, satu cabang utama, dua role utama: pasien dan admin klinik

---

## 1. Executive Summary

AntriMedis saat ini sudah melewati tahap prototype UI. Project sudah memiliki mobile app pasien, web admin panel, Supabase Auth, PostgreSQL schema, RLS, RPC, realtime subscription, Storage avatar, local notification, notification inbox, safe CRUD master data, dan business logic antrean yang dijaga dari sisi database.

Keputusan produk saat ini tetap sehat: **fokus sebagai sistem antrean digital untuk satu klinik terlebih dahulu**. Struktur database memang sudah siap dikembangkan ke multi-klinik/multi-cabang, tetapi UI global picker, owner analytics, role dokter penuh, FCM production push, dan fitur klinik lain tetap future scope.

Flow utama yang harus terus dijaga:

```txt
Pasien login
-> lengkapi profil
-> lihat jadwal hari ini
-> ambil nomor antrean
-> admin memanggil antrean
-> mobile berubah realtime
-> estimasi diperbarui
-> status selesai/history tercatat
```

---

## 2. Keputusan Produk Saat Ini

| Area | Keputusan |
| --- | --- |
| Model produk | Sistem antrean satu klinik dulu |
| Platform pasien | Flutter mobile app |
| Platform admin | React + TypeScript + Vite web admin |
| Backend | Supabase Auth, PostgreSQL, RLS, RPC, Realtime, Storage |
| Role MVP | Pasien dan admin klinik |
| Role future | Dokter, owner, super admin |
| Auth pasien | Email/password dan Google OAuth |
| Auth admin | Email/password dengan role/staff dari database |
| Jadwal | Bisa dibuat untuk hari ini/besok/dst dari admin |
| Antrean | Pelayanan hari-H, bukan booking future |
| Notifikasi MVP | Local notification dipicu realtime saat app aktif/background ringan |
| Notifikasi production penuh | FCM + Edge Function, future scope |
| Scope klinik | Satu klinik/cabang utama untuk UAS |

---

## 3. Skala Capaian Project

| Area | Estimasi capaian | Interpretasi |
| --- | ---: | --- |
| User-side mobile PRD | 90% | Core pasien sudah berjalan. Tinggal QA manual final, polish minor, dan edge case. |
| Web admin PRD | 92% | Dashboard, antrean, jadwal, dokter, poli, pagination, modal, dan safe CRUD sudah kuat. |
| Supabase backend | 92% | Schema, RLS, RPC, realtime, storage, state machine, dan read model sudah matang untuk MVP. |
| UX profesional | 86% | Sudah proper untuk demo dan portfolio. Masih bisa dipoles setelah QA visual final. |
| Demo UAS readiness | 90% | Layak demo setelah checklist E2E dijalankan ulang dengan data fresh. |
| Production readiness belajar | 76% | Fondasi production sudah terasa, tetapi belum full production karena FCM, deployment, monitoring, automated test, dan package identity final belum selesai. |
| Scope expansion readiness | 70% | Sudah mulai siap, tetapi sebaiknya scope baru dibuka setelah QA dan release identity aman. |

Kesimpulan: AntriMedis berada di level **production-like MVP**. Untuk ukuran UAS, capaiannya sudah kuat. Untuk disebut production-grade penuh, masih perlu disiplin release, monitoring, automated tests, push notification backend, dan audit security final.

---

## 4. Status Implementasi Berdasarkan PRD

### 4.1 Mobile App Pasien

| Requirement | Kondisi saat ini | Status | Catatan |
| --- | --- | --- | --- |
| Register/login email | Supabase Auth email/password | Selesai | Password disimpan di schema `auth`, bukan table public. |
| Login Google | Google OAuth + deep link | Selesai | Menggunakan redirect `antrimedis://login-callback/`. |
| Profile completion | Gate profil sebelum ambil antrean | Selesai | Membantu memastikan data pasien tidak kosong. |
| Avatar profil | Upload, sync avatar Google, remove avatar | Selesai | Menggunakan Storage dan `image_picker`. |
| Melihat jadwal | Home membaca `v_schedule_availability` | Selesai | Menampilkan poli, dokter, kuota, dan jam praktik. |
| Ambil nomor antrean | RPC `create_queue_ticket` | Selesai, hardened | Dibatasi satu antrean aktif per hari per cabang. |
| Konfirmasi ambil nomor | Dialog konfirmasi sebelum create ticket | Selesai | Mengurangi accidental tap. |
| Tracking realtime | Subscribe ke ticket/session | Selesai | Update dari admin mengubah mobile. |
| Jadwal realtime | Subscribe ke session dan jadwal | Selesai | Perubahan `queue_sessions` dan `doctor_schedules` me-refresh home pasien. |
| Estimasi tunggu | `estimated_wait_minutes` + wording perkiraan | Selesai | Estimasi adalah perkiraan operasional, bukan presisi mutlak. |
| Cancel antrean | RPC `cancel_my_ticket` | Selesai, hardened | Hanya bisa cancel saat status `waiting`. |
| Notifikasi lokal/inbox | Near/called/missed/skipped/cancelled/expired | MVP selesai | Full production saat app mati total butuh FCM. |
| Riwayat antrean | Tiket aktif dan history | Selesai | Perlu QA dengan banyak status. |
| Navigasi | Floating navigation custom | Selesai | Sudah lebih distinctive daripada default bottom nav. |
| Empty state tracking | Empty state dengan CTA kembali ke jadwal | Selesai | Lebih proper ketika tidak ada antrean aktif. |

### 4.2 Web Admin Panel

| Requirement | Kondisi saat ini | Status | Catatan |
| --- | --- | --- | --- |
| Login admin | Supabase Auth + protected route | Selesai | Membutuhkan role/staff di DB. |
| Dashboard | Operational overview | Selesai | Ada stats, activity feed, readiness banner, dan jadwal. |
| Activity feed | Dari `queue_events` via `v_queue_event_feed` | Selesai, hardened | Lebih valid daripada menyimpulkan dari tiket terbaru. |
| Queue management | Panggil, layani, selesai, no-show, recall, skip, cancel, close session | Selesai, hardened | Hari-H only, after-hours draining, dan mengikuti state machine DB. |
| Detail antrean | Detail pasien dan posisi antrean | Selesai | Operator bisa inspect sebelum aksi. |
| Jadwal | Create/update via RPC transaction | Selesai, hardened | Schedule dan queue session atomic. |
| Duplikasi jadwal | Per baris dan massal ke tanggal target | Selesai | `full` menjadi `open`, `cancelled` tidak diduplikasi. |
| Detail jadwal | Detail operasional | Selesai | Menampilkan kapasitas, status, session, dan konteks. |
| Dokter | Halaman terpisah dengan CRUD, pagination, safe delete | Selesai | Data terpakai akan diarsipkan, bukan merusak history. |
| Poli | Halaman terpisah dengan CRUD, pagination, safe delete | Selesai | Prefix antrean dikelola dari admin. |
| Form admin | Modal terpusat | Selesai | Lebih profesional daripada form inline/sidebar panjang. |
| Loading/empty state | Skeleton/table empty state | Selesai | Tetap perlu QA visual final. |

### 4.3 Supabase Backend

| Area | Kondisi saat ini | Status | Catatan |
| --- | --- | --- | --- |
| Schema utama | Klinik, cabang, staff, poli, dokter, jadwal, session, tiket, event, notification | Selesai | Struktur sudah scalable. |
| RLS | Policy pasien/staff | Selesai, perlu final audit | Normal flow sudah diperbaiki dari issue profile/RLS. |
| RPC ambil antrean | `create_queue_ticket` | Hardened | Mengunci quota, session open, schedule open, active queue, dan menolak tepat/sesudah jam selesai. |
| RPC panggil antrean | `call_next_queue` | Hardened | Tidak bisa call next bila masih ada called/serving. |
| RPC recall terlewat | `recall_missed_queue` | Selesai, hardened | Hanya aktif setelah waiting habis dan tidak ada called/serving. |
| RPC update status | `update_queue_status` | Hardened | Transisi status dibatasi. |
| RPC tutup sesi | `close_queue_session` | Selesai, hardened | Waiting menjadi expired, missed menjadi skipped, called/serving wajib selesai dulu. |
| RPC cancel pasien | `cancel_my_ticket` | Selesai | Pasien tidak direct update table lagi. |
| Trigger state machine | `queue_tickets_validate_status_transition` | Selesai | DB menolak transisi status ilegal. |
| RPC jadwal | `create_schedule_with_session`, `update_schedule_with_session` | Selesai | Jadwal dan session atomic. |
| RPC safe delete | `delete_doctor_if_unused`, `delete_polyclinic_if_unused`, `delete_schedule_if_empty` | Selesai | Menjaga history tetap valid. |
| Read model | `v_schedule_availability`, `v_queue_ticket_details`, `v_queue_event_feed` | Selesai | Frontend tidak perlu join manual kompleks. |
| Realtime | `queue_tickets`, `queue_sessions`, `doctor_schedules`, `queue_events`, `notifications` | Selesai | Cukup untuk demo realtime admin-mobile. |
| Storage avatar | Bucket/policy avatar | Selesai | Cleanup file lama masih bisa di-hardening. |

---

## 5. Production Hardening yang Sudah Dikerjakan

### 5.1 Queue State Machine

Database membatasi transisi status antrean:

```txt
waiting -> called / skipped / cancelled / expired
called  -> serving / missed / skipped / cancelled / expired
serving -> completed / skipped / cancelled / expired
missed  -> called / skipped / cancelled / expired
```

Status final tidak bisa dikembalikan ke status aktif. Frontend membantu UX, tetapi database tetap menjadi penjaga aturan final.

Recall `missed -> called` dilakukan lewat `recall_missed_queue`, bukan update manual biasa. Nomor antrean tetap sama saat recall.

### 5.2 Call Next Guard

Admin tidak bisa memanggil nomor berikutnya jika masih ada tiket `called` atau `serving` pada sesi yang sama. Ini menjaga operasional agar tidak ada dua pasien aktif bersamaan tanpa diselesaikan.

Admin juga tidak bisa memanggil sebelum jam mulai praktik. Tepat saat jam selesai, loket online pasien sudah tutup; setelah itu admin tetap boleh menghabiskan waiting yang sudah terlanjur masuk sebelum jam selesai.

Contoh aturan jam: untuk jadwal `15:00-18:00`, pasien masih bisa ambil nomor pada `17:59`, tetapi sudah ditolak pada `18:00`. Admin tetap dapat memanggil sisa waiting setelah `18:00`.

### 5.3 Active Queue Policy

Pasien dibatasi agar tidak memiliki lebih dari satu antrean aktif pada hari yang sama di cabang yang sama. Untuk scope satu klinik, aturan ini lebih aman daripada membiarkan pasien mengambil banyak nomor.

### 5.4 Patient Cancel RPC

Mobile membatalkan antrean lewat RPC `cancel_my_ticket`, sehingga DB bisa memastikan user adalah pemilik tiket, status masih `waiting`, event tercatat, notification tercatat, dan estimasi di-refresh.

### 5.5 Schedule Transaction RPC

Admin membuat dan mengubah jadwal lewat:

- `create_schedule_with_session`
- `update_schedule_with_session`

Jika session gagal, schedule ikut rollback.

### 5.6 Event Feed

Dashboard admin membaca aktivitas dari `queue_events` melalui `v_queue_event_feed`, sehingga histori operasional lebih benar daripada sekadar mengambil tiket terbaru.

### 5.7 Missed, Recall, dan Close Session

Pasien yang tidak hadir saat panggilan pertama masuk status `missed`, bukan langsung final. Admin memproses waiting reguler terlebih dahulu. Setelah waiting habis, admin dapat memanggil ulang missed paling awal lewat `recall_missed_queue`.

Jika pasien tetap tidak hadir setelah recall, status menjadi `skipped` final. Saat sesi ditutup, waiting menjadi `expired` dan missed menjadi `skipped` final.

### 5.8 Safe Delete Master Data

Dokter dan poli yang belum pernah dipakai bisa dihapus. Dokter dan poli yang sudah dipakai jadwal/history akan diarsipkan (`is_active=false`) agar data lama tetap konsisten.

---

## 6. Gap yang Masih Perlu Ditutup

### 6.1 High Priority

| Gap | Dampak | Rekomendasi |
| --- | --- | --- |
| E2E QA belum dicatat sebagai checklist final | Flow bisa tampak benar tapi gagal pada urutan tertentu | Jalankan checklist admin-mobile dari awal sampai selesai sebelum demo. |
| Package id final dosen mungkin berbeda | Perlu penyesuaian sebelum upload/internal test | Saat ini memakai `com.antrimedis.app`; ganti bila dosen memberi format khusus. |
| RLS final audit belum terdokumentasi detail | Risiko akses terlalu luas/sempit | Audit policy sebelum final deploy/demo besar. |
| Avatar cleanup belum final | Storage bisa menumpuk file lama | Hapus avatar lama saat upload/remove atau gunakan path deterministic. |

### 6.2 Medium Priority

| Gap | Dampak | Rekomendasi |
| --- | --- | --- |
| Push notification belum FCM | Notifikasi tidak full production saat app mati total | Jadikan future scope jika waktu cukup. |
| Automated test coverage masih tipis | Regression bisa tidak ketahuan | Tambahkan unit/widget tests untuk queue provider, error mapping, dan UI state. |
| Admin staff management belum ada | Admin baru masih perlu setup manual | Untuk UAS cukup seed/manual. Untuk production perlu halaman staff. |
| Activity/report historis belum advanced | Dashboard masih harian/basic | Tambahkan report setelah core stabil. |
| Monitoring/logging belum ada | Sulit debug production | Minimal dokumentasikan cara cek Supabase logs. |

### 6.3 Low Priority / Future Scope

| Gap | Catatan |
| --- | --- |
| Multi-klinik/global picker | Jangan dikerjakan dulu. Core satu klinik harus benar-benar stabil. |
| Role dokter penuh | DB mendukung arah ini, tetapi UI/flow belum perlu. |
| Owner analytics | Bisa jadi portfolio enhancement setelah UAS. |
| Export laporan | Menarik, tapi bukan core PRD. |
| QR check-in/display antrean | Bagus untuk produk klinik lanjutan, bukan prioritas sekarang. |

---

## 7. Definition of Done Sebelum Scope Dilebarkan

- Mobile pasien login Google dan email/password berhasil.
- Pasien baru diarahkan ke profile completion.
- Pasien tidak bisa ambil antrean sebelum profil lengkap.
- Admin bisa membuat dokter, poli, dan jadwal hari ini.
- Jadwal yang dibuat admin muncul di mobile.
- Pasien bisa ambil nomor antrean setelah konfirmasi.
- Pasien ditolak mengambil nomor tepat saat atau setelah jam selesai jadwal.
- Pasien tidak bisa punya dua antrean aktif di hari/cabang yang sama.
- Admin melihat tiket pasien di queue management.
- Admin memanggil antrean pertama.
- Mobile berubah realtime ke status dipanggil.
- Admin tidak bisa call next sebelum tiket called/serving diselesaikan, dilewati, atau dibatalkan.
- Admin bisa mengubah `called -> serving -> completed`.
- Admin bisa skip/cancel tiket aktif sesuai aturan.
- Pasien bisa cancel sendiri hanya saat `waiting`.
- History pasien mencatat status akhir.
- Dashboard activity membaca event dari `queue_events`.
- `flutter analyze` pass.
- `flutter test` pass.
- `npm run lint` pass.
- `npm run build` pass.
- Supabase migration local dan remote sama.
- Tidak ada error RLS pada flow normal.

---

## 8. Roadmap Berikutnya

### Phase A - QA Core Flow

Prioritas paling dekat adalah membuktikan flow dari database real:

1. Siapkan jadwal open hari ini.
2. Login admin.
3. Login pasien.
4. Lengkapi profil pasien.
5. Ambil nomor antrean.
6. Cek ticket muncul di admin.
7. Admin call next.
8. Cek mobile update realtime.
9. Admin mulai pelayanan.
10. Admin selesaikan.
11. Cek history pasien.
12. Ulangi untuk skip/cancel.
13. Uji after-hours: tepat/sesudah jam selesai pasien ditolak, admin masih bisa menyelesaikan sisa waiting.

### Phase B - Release Identity

Menunggu package name dari dosen:

1. Konfirmasi apakah `com.antrimedis.app` sudah boleh dipakai.
2. Ganti Android `applicationId`/namespace jika dosen memberi format khusus.
3. Rapikan app icon jika ingin asset final khusus.
4. Rapikan splash screen jika ingin asset final khusus.
5. Build APK debug/release sesuai kebutuhan.
6. Jalankan final QA checklist.

### Phase C - Test Coverage Minimal

Tambahkan automated guardrail setelah flow final:

1. Test model/logic estimasi antrean.
2. Test friendly error mapping queue.
3. Test provider create/cancel dengan mocked repository.
4. Test widget empty/error state dasar.
5. Untuk admin, mulai dari test utility jika Vitest ditambahkan.

### Phase D - Optional Production Enhancement

Kerjakan hanya jika waktu cukup:

1. FCM push notification.
2. Staff management admin.
3. Report harian/mingguan.
4. Export antrean.
5. Multi-klinik picker.

---

## 9. Skenario Demo Paling Aman

1. Buka admin panel.
2. Login admin.
3. Tunjukkan dashboard dan activity feed.
4. Buka dokter dan poli untuk menunjukkan master data.
5. Buka jadwal, tunjukkan detail dan duplikasi jadwal.
6. Pastikan ada jadwal open hari ini.
7. Buka mobile app.
8. Login pasien.
9. Lengkapi profil.
10. Ambil nomor antrean dengan dialog konfirmasi.
11. Tunjukkan tracking page.
12. Kembali ke admin queue management.
13. Buka detail antrean.
14. Panggil antrean.
15. Tunjukkan mobile berubah realtime.
16. Mulai pelayanan.
17. Selesaikan pelayanan.
18. Tunjukkan history pasien dan activity dashboard.

Narasi demo:

> Project ini bukan hanya tampilan. Logic penting antrean dijaga di Supabase RPC dan trigger, jadi walaupun UI stale atau salah klik, database tetap menolak transisi status yang tidak valid.

---

## 10. Risiko dan Mitigasi

| Risiko | Dampak | Mitigasi |
| --- | --- | --- |
| Google OAuth meminta login ulang | User mengira harusnya langsung pilih akun | Jelaskan Google mengikuti session browser/device. |
| App mati total tidak menerima local notification | Notifikasi belum full production | Untuk MVP cukup, production butuh FCM. |
| Jadwal demo tidak open | Mobile terlihat kosong | Siapkan jadwal hari ini sebelum presentasi. |
| Ada tiket called/serving belum selesai | Admin tidak bisa call next | Ini aturan benar; selesaikan/skip/cancel dulu. |
| Package name belum final | Belum bisa internal test/upload | Tunggu format dari dosen. |
| RLS memblokir akun admin baru | Admin panel error | Pastikan akun admin punya `user_roles` dan `clinic_staff`. |
| Data lama membingungkan QA | Tester salah membaca status antrean | Gunakan seed bersih tanpa demo pasien/tiket sebelum flow penting. |

---

## 11. Hal yang Jangan Dikerjakan Dulu

- Jangan pindah backend dari Supabase.
- Jangan membuat global clinic picker sebelum core flow final.
- Jangan membuat role dokter/owner penuh sebelum UAS flow aman.
- Jangan membuat fitur apotek/obat dulu.
- Jangan membuat payment/BPJS/integrasi besar.
- Jangan mengklaim push notification full production sebelum FCM.
- Jangan upload internal test sebelum package name final.

---

## 12. Kesimpulan

AntriMedis sudah berada di jalur yang kuat untuk UAS dan portfolio. Fitur inti PRD sudah terimplementasi, dan beberapa bagian sudah melewati MVP dasar: state machine antrean, RPC transaction jadwal, event feed, profile avatar, Google OAuth, realtime mobile-admin, safe CRUD master data, dan admin workflow yang lebih rapi.

Langkah berikutnya yang paling sehat:

1. Jalankan QA E2E penuh saat siap.
2. Rapikan release identity setelah package name final.
3. Tambahkan test minimal setelah flow final stabil.
4. Baru pertimbangkan scope tambahan.

Dengan strategi ini, project tetap fokus, terlihat profesional, dan tidak jatuh ke overengineering.
