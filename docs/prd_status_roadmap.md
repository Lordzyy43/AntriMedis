# PRD Status & Roadmap - AntriMedis

**Tanggal update:** 30 Mei 2026  
**Dokumen acuan:** `docs/prd.md`  
**Status project:** MVP advanced, core flow sudah hidup, sedang masuk production hardening  
**Scope aktif:** Satu klinik, satu cabang utama, dua role utama: pasien dan admin klinik

---

## 1. Executive Summary

AntriMedis saat ini sudah bukan sekadar prototype UI. Project sudah memiliki mobile app pasien, web admin panel, Supabase Auth, PostgreSQL schema, RLS, RPC, realtime subscription, storage avatar, local notification, dan business logic antrean yang mulai dikunci di database.

Keputusan produk paling aman saat ini adalah tetap fokus sebagai **sistem antrean digital untuk satu klinik terlebih dahulu**, bukan marketplace multi-klinik. Struktur database memang sudah mendukung `clinics` dan `clinic_branches`, tetapi UI multi-klinik, owner dashboard, role dokter penuh, dan fitur klinik lain sebaiknya tetap menjadi future scope.

Fokus sekarang bukan menambah fitur besar, tetapi memastikan flow utama stabil:

```txt
Pasien login
-> lengkapi profil
-> lihat jadwal
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
| Notifikasi MVP | Local notification saat app aktif/background ringan |
| Notifikasi production penuh | FCM + Edge Function, future scope |
| Scope klinik | Satu klinik/cabang utama untuk UAS |

---

## 3. Skala Capaian Project

| Area | Estimasi capaian | Interpretasi |
| --- | ---: | --- |
| User-side mobile PRD | 88% | Core pasien sudah berjalan. Tinggal QA, polish, dan edge case. |
| Web admin PRD | 88% | Dashboard, master data, jadwal, antrean, dan detail operasional sudah kuat. |
| Supabase backend | 90% | Schema, RLS, RPC, realtime, storage, dan event feed sudah matang untuk MVP. |
| UX profesional | 82% | Sudah jauh lebih proper. Masih perlu QA visual/manual dan konsistensi kecil. |
| Demo UAS readiness | 88% | Layak demo setelah E2E checklist dijalankan ulang. |
| Production readiness belajar | 72% | Fondasi production mulai kuat, tetapi belum full production karena FCM, deployment, test coverage, package name, dan monitoring belum final. |
| Scope expansion readiness | 65% | Jangan melebar dulu sebelum E2E, docs, dan final QA stabil. |

Kesimpulan: AntriMedis sudah berada di level **MVP advanced / portfolio-grade early product**. Untuk disebut production-grade penuh, masih perlu deployment discipline, automated tests, push notification backend, monitoring, dan release checklist.

---

## 4. Status Implementasi Berdasarkan PRD

### 4.1 Mobile App Pasien

| Requirement | Kondisi saat ini | Status | Catatan |
| --- | --- | --- | --- |
| Register/login email | Supabase Auth email/password | Selesai | Password disimpan di schema `auth`, bukan table public. |
| Login Google | Google OAuth + deep link | Selesai | Menggunakan redirect `antrimedis://login-callback/`. |
| Profile completion | Gate profil sebelum ambil antrean | Selesai | Membantu memastikan data pasien tidak kosong. |
| Avatar profil | Upload, sync avatar Google, remove avatar | Selesai | Perlu cleanup storage lama sebagai hardening berikutnya. |
| Melihat jadwal | Home membaca `v_schedule_availability` | Selesai | Menampilkan poli, dokter, kuota, dan jam praktik. |
| Ambil nomor antrean | RPC `create_queue_ticket` | Selesai, hardened | Sekarang dibatasi satu antrean aktif per hari per cabang. |
| Konfirmasi ambil nomor | Dialog konfirmasi sebelum create ticket | Selesai | Mengurangi accidental tap. |
| Tracking realtime | Subscribe ke ticket/session | Selesai | Update dari admin mengubah mobile. |
| Estimasi tunggu | `estimated_wait_minutes` + wording perkiraan | Selesai | Copy sudah tidak mengklaim presisi mutlak. |
| Cancel antrean | RPC `cancel_my_ticket` | Selesai, hardened | Hanya bisa cancel saat status `waiting`. |
| Notifikasi lokal | Near/called/skipped/cancelled | MVP selesai | Full production butuh FCM. |
| Riwayat antrean | Tiket aktif dan history | Selesai | Perlu QA dengan banyak status. |
| Navigasi | Floating navigation custom | Selesai | Sudah lebih distinctive daripada default bottom nav. |
| Empty state tracking | Empty state dengan CTA kembali ke jadwal | Selesai | Lebih proper ketika tidak ada antrean aktif. |

### 4.2 Web Admin Panel

| Requirement | Kondisi saat ini | Status | Catatan |
| --- | --- | --- | --- |
| Login admin | Supabase Auth + protected route | Selesai | Membutuhkan role/staff di DB. |
| Dashboard | Operational overview | Selesai | Sudah ada stats, activity, readiness, jadwal. |
| Activity feed | Dari `queue_events` via `v_queue_event_feed` | Selesai, hardened | Lebih valid daripada mengambil tiket terbaru saja. |
| Queue management | Panggil, layani, selesai, skip, cancel | Selesai, hardened | Mengikuti state machine DB. |
| Detail antrean | Drawer detail pasien dan posisi antrean | Selesai | Operator bisa inspect sebelum aksi. |
| Jadwal | Create/update via RPC transaction | Selesai, hardened | Schedule dan queue session atomic. |
| Detail jadwal | Drawer detail operasional | Selesai | Menampilkan kapasitas, status, session. |
| Master data dokter | Halaman terpisah | Selesai | Lebih rapi dari tab gabungan. |
| Master data poli | Halaman terpisah | Selesai | Lebih friendly untuk admin. |
| Toast/feedback | Toast success/error di aksi penting | Selesai | Perlu QA copy minor. |
| Loading/empty state | Skeleton dan table empty state | Sebagian besar selesai | Perlu audit visual final. |

### 4.3 Supabase Backend

| Area | Kondisi saat ini | Status | Catatan |
| --- | --- | --- | --- |
| Schema utama | Klinik, cabang, staff, poli, dokter, jadwal, session, tiket, event, notification | Selesai | Struktur sudah scalable. |
| RLS | Policy pasien/staff | Selesai, perlu final audit | Normal flow sudah diperbaiki dari issue profile/RLS. |
| RPC ambil antrean | `create_queue_ticket` | Hardened | Mengunci quota, session open, schedule open, active queue. |
| RPC panggil antrean | `call_next_queue` | Hardened | Tidak bisa call next bila masih ada called/serving. |
| RPC update status | `update_queue_status` | Hardened | Transisi status dibatasi. |
| RPC cancel pasien | `cancel_my_ticket` | Selesai | Pasien tidak direct update table lagi. |
| Trigger state machine | `queue_tickets_validate_status_transition` | Selesai | DB menolak transisi status ilegal. |
| RPC jadwal | `create_schedule_with_session`, `update_schedule_with_session` | Selesai | Jadwal dan session atomic. |
| Read model | `v_schedule_availability`, `v_queue_ticket_details`, `v_queue_event_feed` | Selesai | Frontend tidak perlu join manual kompleks. |
| Realtime | `queue_tickets`, `queue_sessions`, `notifications` | Selesai | Cukup untuk demo realtime. |
| Storage avatar | Bucket/policy avatar | Selesai | Cleanup file lama belum final. |

---

## 5. Production Hardening yang Sudah Dikerjakan

### 5.1 Queue State Machine

Database sekarang membatasi transisi status antrean:

```txt
waiting -> called / skipped / cancelled / expired
called  -> serving / skipped / cancelled / expired
serving -> completed / skipped / cancelled / expired
```

Status final tidak bisa dikembalikan ke status aktif. Ini penting karena UI tidak boleh menjadi satu-satunya penjaga logic. Production pattern yang benar adalah: **frontend membantu UX, database tetap menjaga aturan final.**

### 5.2 Call Next Guard

Admin tidak bisa memanggil nomor berikutnya jika masih ada tiket `called` atau `serving`. Ini mencegah kondisi operasional aneh seperti dua pasien sama-sama sedang dipanggil pada sesi yang sama.

### 5.3 Active Queue Policy

Pasien dibatasi agar tidak memiliki lebih dari satu antrean aktif pada hari yang sama di cabang yang sama. Untuk scope satu klinik, aturan ini lebih aman daripada membiarkan pasien mengambil banyak nomor.

### 5.4 Patient Cancel RPC

Mobile tidak lagi melakukan direct update ke `queue_tickets`. Cancel dilakukan lewat RPC `cancel_my_ticket`, sehingga DB bisa memastikan:

- user adalah pemilik ticket,
- status masih `waiting`,
- event tercatat,
- notification tercatat,
- estimasi di-refresh.

### 5.5 Schedule Transaction RPC

Admin tidak lagi membuat jadwal dan queue session dengan dua query terpisah. Sekarang memakai:

- `create_schedule_with_session`
- `update_schedule_with_session`

Jika session gagal, schedule ikut rollback. Ini pattern production yang lebih aman.

### 5.6 Event Feed

Dashboard admin sekarang membaca aktivitas dari `queue_events` melalui `v_queue_event_feed`. Ini lebih benar daripada menyimpulkan aktivitas dari row tiket terbaru.

---

## 6. Gap yang Masih Perlu Ditutup

### 6.1 High Priority

| Gap | Dampak | Rekomendasi |
| --- | --- | --- |
| E2E QA belum dicatat sebagai checklist final | Flow bisa tampak benar tapi gagal pada urutan tertentu | Jalankan checklist admin-mobile dari awal sampai selesai. |
| Test coverage masih tipis | Regression bisa tidak ketahuan | Tambahkan unit/widget tests untuk queue calculation, provider, dan error mapping. |
| Package name masih `com.example.apps` | Belum siap release/internal test | Ganti setelah dosen memberi package final. |
| Avatar cleanup belum final | Storage bisa menumpuk file lama | Hapus avatar lama saat upload/remove atau gunakan path deterministic. |
| RLS final audit belum terdokumentasi | Risiko akses terlalu luas/sempit | Audit policy sebelum final demo/deploy. |

### 6.2 Medium Priority

| Gap | Dampak | Rekomendasi |
| --- | --- | --- |
| Push notification belum FCM | Notifikasi tidak full production saat app mati | Jadikan future scope jika waktu cukup. |
| Admin staff management belum ada | Admin baru masih perlu setup manual | Untuk UAS cukup seed/manual. Untuk production perlu halaman staff. |
| Activity/report historis belum advanced | Dashboard masih harian/basic | Tambahkan report setelah core stabil. |
| Monitoring/logging belum ada | Sulit debug production | Minimal dokumentasikan cara cek Supabase logs. |
| `.env.example` admin/mobile perlu dipastikan lengkap | Setup project bisa membingungkan | Rapikan env docs sebelum final. |

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

Scope baru boleh dibuka hanya jika checklist ini sudah aman:

- Mobile pasien login Google dan email/password berhasil.
- Pasien baru diarahkan ke profile completion.
- Pasien tidak bisa ambil antrean sebelum profil lengkap.
- Admin bisa membuat dokter, poli, dan jadwal hari ini.
- Jadwal yang dibuat admin muncul di mobile.
- Pasien bisa ambil nomor antrean setelah konfirmasi.
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

1. Reset/siapkan data jadwal hari ini.
2. Login admin.
3. Buat jadwal open.
4. Login pasien.
5. Lengkapi profil.
6. Ambil nomor.
7. Cek ticket muncul di admin.
8. Admin call next.
9. Cek mobile update realtime.
10. Admin mulai pelayanan.
11. Admin selesaikan.
12. Cek history pasien.
13. Ulangi untuk skip/cancel.

### Phase B - Test Coverage Minimal

Tambahkan automated guardrail:

1. Test model `QueueTicketDetail.remainingBeforeMe`.
2. Test friendly error mapping queue.
3. Test provider create/cancel dengan mocked repository.
4. Test widget empty/error state dasar.
5. Untuk admin, mulai dari test utility `friendlySupabaseError` jika Vitest ditambahkan.

### Phase C - Release Identity

Menunggu package name dari dosen:

1. Ganti Android `applicationId`.
2. Ganti namespace jika diperlukan.
3. App icon.
4. Splash screen.
5. Build APK debug/release sesuai kebutuhan.
6. README final setup.

### Phase D - Optional Production Enhancement

Kerjakan hanya jika waktu cukup:

1. FCM push notification.
2. Staff management admin.
3. Report harian/mingguan.
4. Export antrean.
5. Multi-klinik picker.

---

## 9. Skenario Demo Paling Aman

Gunakan satu klinik agar cerita produk fokus.

1. Buka admin panel.
2. Login admin.
3. Tunjukkan dashboard dan activity feed.
4. Buka master data dokter/poli.
5. Buka jadwal, tunjukkan detail drawer.
6. Buat atau pilih jadwal open hari ini.
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

> "Project ini bukan hanya tampilan. Logic penting antrean dijaga di Supabase RPC dan trigger, jadi walaupun UI salah klik atau stale, database tetap menolak transisi status yang tidak valid."

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
| Test coverage tipis | Regression tidak tertangkap | Tambahkan test minimal setelah QA manual. |

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

AntriMedis sudah berada di jalur yang sangat kuat untuk UAS dan portfolio. Fitur inti PRD sudah terimplementasi, dan beberapa bagian bahkan sudah melewati MVP dasar: state machine antrean, RPC transaction jadwal, event feed, profile avatar, Google OAuth, realtime mobile-admin, dan admin drawer operasional.

Langkah berikutnya yang paling sehat:

1. Jalankan QA E2E penuh.
2. Tambahkan test minimal.
3. Rapikan identity build setelah package name final.
4. Baru pertimbangkan scope tambahan.

Dengan strategi ini, project tetap fokus, terlihat profesional, dan tidak jatuh ke overengineering.
