# Queue Business Flow - AntriMedis

**Tanggal update:** 4 Juni 2026  
**Scope:** Sistem antrean real-time klinik, satu klinik/cabang utama  
**Acuan implementasi:** Mobile pasien Flutter, Admin Panel React, Supabase PostgreSQL/RPC/Realtime

Dokumen ini menjadi acuan utama untuk business logic antrean AntriMedis. Tujuannya agar flow pasien, flow admin, status lifecycle, realtime, dan edge case operasional tidak berubah-ubah tanpa alasan yang jelas.

---

## 1. Prinsip Produk

AntriMedis adalah **sistem antrean hari-H**, bukan booking appointment future.

Artinya:

- Pasien mengambil nomor antrean untuk jadwal layanan pada tanggal yang sama.
- Pasien boleh mengambil nomor sebelum jam praktik dimulai, selama masih pada hari yang sama dan waktu sekarang masih sebelum jam selesai.
- Pasien tidak memilih slot jam pribadi seperti booking.
- Urutan tetap berdasarkan nomor antrean pada sesi tersebut.
- Admin mengelola pemanggilan, pelayanan, tidak hadir, recall, dan penutupan sesi.

Perbedaan dengan booking:

| Aspek | Antrean AntriMedis | Booking |
| --- | --- | --- |
| Tujuan | Ambil nomor urut pelayanan hari ini | Reservasi slot waktu tertentu |
| Urutan | Berdasarkan nomor antrean | Berdasarkan jam booking |
| Pasien datang | Tetap mengikuti jam operasional poli | Datang sesuai slot |
| Estimasi | Dinamis berdasarkan sisa antrean dan ritme layanan | Berdasarkan slot tetap |
| Admin | Memanggil dan menyelesaikan nomor | Mengelola jadwal reservasi |

---

## 2. Entitas Utama

| Entitas | Fungsi |
| --- | --- |
| `doctor_schedules` | Jadwal praktik dokter/poli pada tanggal tertentu. |
| `queue_sessions` | Sesi antrean untuk satu jadwal. Idealnya satu jadwal punya satu session. |
| `queue_tickets` | Nomor antrean pasien. |
| `queue_events` | Histori event setiap perubahan status tiket. |
| `notifications` | Notifikasi untuk pasien terkait antrean. |
| `v_schedule_availability` | Read model jadwal dan kuota untuk mobile/admin. |
| `v_queue_ticket_details` | Read model tiket lengkap untuk tracking/admin. |
| `v_queue_event_feed` | Read model activity feed admin. |

RPC penting:

| RPC | Fungsi |
| --- | --- |
| `create_queue_ticket` | Pasien mengambil nomor antrean. |
| `cancel_my_ticket` | Pasien membatalkan antrean miliknya sendiri. |
| `call_next_queue` | Admin memanggil waiting paling awal. |
| `recall_missed_queue` | Admin memanggil ulang missed paling awal setelah waiting habis. |
| `update_queue_status` | Admin mengubah status tiket sesuai state machine. |
| `close_queue_session` | Admin menutup sesi dan mem-finalisasi sisa antrean tertentu. |
| `create_schedule_with_session` | Admin membuat jadwal dan queue session secara atomic. |
| `update_schedule_with_session` | Admin mengubah jadwal dan session secara atomic. |

---

## 3. Status Antrean

| Status | Makna | Final? |
| --- | --- | --- |
| `waiting` | Pasien sudah mengambil nomor dan belum dipanggil. | Tidak |
| `called` | Nomor sudah dipanggil oleh admin. | Tidak |
| `serving` | Pasien sedang dilayani. | Tidak |
| `missed` | Pasien tidak hadir saat panggilan pertama dan menunggu recall. | Tidak |
| `completed` | Pelayanan selesai. | Ya |
| `skipped` | Nomor dilewati final oleh admin. | Ya |
| `cancelled` | Antrean dibatalkan oleh pasien/admin. | Ya |
| `expired` | Waiting dibuat kedaluwarsa saat sesi ditutup. | Ya |

Status aktif untuk operasional:

```txt
waiting
called
serving
missed
```

Status final untuk history:

```txt
completed
skipped
cancelled
expired
```

---

## 4. State Machine

Transisi utama yang valid:

```txt
waiting -> called
waiting -> cancelled
waiting -> expired

called -> serving
called -> missed
called -> skipped
called -> cancelled
called -> expired

serving -> completed
serving -> skipped
serving -> cancelled
serving -> expired

missed -> called    lewat recall_missed_queue
missed -> skipped
missed -> cancelled
missed -> expired

completed -> final
skipped   -> final
cancelled -> final
expired   -> final
```

Catatan penting:

- Status final tidak boleh kembali ke status aktif.
- Admin tidak boleh memanggil nomor berikutnya jika masih ada `called` atau `serving` pada sesi yang sama.
- `missed -> called` tidak dilakukan lewat update manual biasa, tetapi lewat RPC `recall_missed_queue`.
- Recall mempertahankan nomor lama. Contoh: `G006` tetap `G006`, bukan dibuat nomor baru.

---

## 5. Flow Pasien

### 5.1 Ambil Nomor

Flow:

```txt
Pasien login
-> profil lengkap
-> lihat jadwal hari ini
-> pilih poli/jadwal
-> konfirmasi ambil nomor
-> create_queue_ticket
-> tiket waiting dibuat
-> tracking realtime aktif
```

Rule:

- Pasien harus login.
- Profil pasien harus lengkap.
- Jadwal harus memiliki queue session.
- Jadwal harus tanggal hari ini.
- Jadwal harus berstatus operasional yang bisa menerima antrean.
- Pasien boleh mengambil nomor sebelum jam mulai praktik pada hari yang sama.
- Pasien tidak boleh mengambil nomor saat atau setelah jam selesai praktik.
- Pasien tidak boleh punya lebih dari satu antrean aktif pada hari yang sama di cabang yang sama.
- Kuota harus masih tersedia.

### 5.2 Tracking

Tracking pasien membaca:

- nomor antrean
- status tiket
- sisa pasien sebelum dirinya
- estimasi waktu tunggu
- status jadwal/poli
- perubahan realtime dari admin

Realtime yang diharapkan:

| Perubahan Admin/DB | Dampak di Mobile |
| --- | --- |
| Tiket dibuat | Tracking menampilkan nomor pasien. |
| Admin call next | Status pasien terkait berubah menjadi dipanggil. |
| Admin mulai layanan | Status berubah menjadi dilayani. |
| Admin selesai | Tiket masuk history selesai. |
| Admin tidak hadir | Tiket menjadi terlewat dan menunggu recall. |
| Admin recall | Tiket menjadi dipanggil lagi dengan nomor yang sama. |
| Admin skip/cancel | Tiket masuk history final. |
| Sesi ditutup | Waiting menjadi expired, missed menjadi skipped final. |
| Tiket lain berubah | Sisa antrean dan estimasi ikut ter-refresh. |

### 5.3 Cancel oleh Pasien

Pasien hanya boleh cancel sendiri saat status tiket masih `waiting`.

Alasan:

- Jika sudah `called`, pasien sudah masuk keputusan operasional admin.
- Jika sudah `serving`, pelayanan sedang berjalan.
- Jika sudah final, tidak ada aksi yang bisa diubah.

Flow:

```txt
waiting
-> pasien klik batalkan
-> cancel_my_ticket
-> status cancelled
-> event dan notifikasi tercatat
-> tiket masuk history
```

---

## 6. Flow Admin

### 6.1 Buat Jadwal

Admin membuat jadwal dari halaman Jadwal.

Saat jadwal dibuat:

- `doctor_schedules` dibuat.
- `queue_sessions` dibuat otomatis.
- Operasi dilakukan secara atomic lewat RPC.

Jika session gagal dibuat, jadwal ikut rollback.

### 6.2 Panggil Berikutnya

Admin memanggil pasien melalui `call_next_queue`.

Rule:

- Sesi harus ada.
- Sesi belum ditutup.
- Jadwal sudah masuk jam mulai.
- Waiting harus ada.
- Tidak boleh ada tiket `called` atau `serving` yang belum selesai.
- Jika jam operasional sudah lewat, admin tetap boleh memanggil waiting yang sudah terlanjur masuk sebelum jam selesai.

Flow normal:

```txt
waiting paling awal
-> called
-> queue_sessions.current_number diperbarui
-> queue_events tercatat
-> notification pasien dibuat
-> estimasi waiting lain diperbarui
```

### 6.3 Mulai Pelayanan

Jika pasien hadir:

```txt
called -> serving
```

Admin menekan `Layani`.

### 6.4 Selesaikan Pelayanan

Jika pelayanan selesai:

```txt
serving -> completed
```

Tiket masuk final history.

### 6.5 Tidak Hadir Pertama

Jika pasien tidak hadir saat dipanggil pertama:

```txt
called -> missed
```

Makna:

- Pasien tidak langsung final.
- Nomor disimpan sebagai terlewat.
- Admin lanjut memanggil waiting berikutnya.
- Pasien missed baru boleh dipanggil ulang setelah waiting reguler habis.

### 6.6 Recall Terlewat

Recall tersedia jika:

- tidak ada `called`
- tidak ada `serving`
- `waiting = 0`
- `missed > 0`
- sesi belum ditutup
- jadwal tidak berada di fase sebelum jam mulai

Flow:

```txt
missed paling awal
-> called
```

Jika pasien hadir setelah recall:

```txt
called -> serving -> completed
```

Jika pasien tetap tidak hadir setelah recall:

```txt
called -> skipped
```

Rule penting:

- Recall tidak membuat tiket baru.
- Nomor antrean tetap sama.
- Pasien hanya mendapat satu kesempatan recall dalam flow MVP.

### 6.7 Batalkan oleh Admin

Admin dapat membatalkan tiket aktif sesuai state machine.

Penggunaan ideal:

- pasien meminta pembatalan lewat petugas
- data tiket salah
- kondisi operasional mengharuskan pembatalan

Admin wajib menulis alasan agar histori jelas.

### 6.8 Tutup Sesi

Admin dapat menutup sesi lewat `close_queue_session`.

Rule:

- Sesi belum ditutup.
- Tidak boleh ada `called` atau `serving`.
- Jika masih ada `waiting`, tiket tersebut menjadi `expired`.
- Jika masih ada `missed`, tiket tersebut menjadi `skipped` final.
- Session berubah menjadi closed.

Flow:

```txt
waiting -> expired
missed  -> skipped
session -> closed
```

Tutup sesi dipakai saat operasional benar-benar selesai atau dihentikan.

---

## 7. Aturan Jam Operasional

### 7.1 Sebelum Jam Mulai

Pasien:

- boleh mengambil nomor pada hari yang sama
- tracking menunjukkan antrean akan dimulai saat jam praktik

Admin:

- tidak boleh memanggil pasien sebelum jam mulai
- dashboard/queue control memberi arahan menunggu jam operasional

Alasan:

- Mengambil nomor lebih awal mempercepat proses datang dan mengurangi rebutan nomor.
- Pemanggilan tetap mengikuti jam layanan klinik.

### 7.2 Saat Jam Operasional Berjalan

Pasien:

- boleh mengambil nomor selama kuota tersedia

Admin:

- memanggil waiting
- melayani pasien
- menandai tidak hadir jika pasien tidak ada
- menyelesaikan atau membatalkan sesuai kondisi

### 7.3 Saat atau Setelah Jam Operasional Selesai

Pasien:

- tidak boleh mengambil nomor baru saat waktu sudah mencapai jam selesai

Admin:

- tetap boleh menghabiskan antrean yang sudah masuk sebelum jam selesai
- dapat memanggil waiting tersisa
- dapat recall missed setelah waiting habis
- dapat menutup sesi setelah tidak ada called/serving

Alasan:

- Pasien baru tidak boleh masuk saat layanan sudah mencapai jam selesai.
- Pasien yang sudah mengambil nomor sebelum jam selesai tetap perlu keputusan operasional yang jelas.

---

## 8. Kuota

Kuota dihitung dari kapasitas sesi.

Format tampilan yang disarankan:

```txt
Sisa kuota / total kuota
```

Contoh:

```txt
8/10
```

Makna: masih ada 8 slot dari total 10.

Rule:

- Saat pasien mengambil nomor, sisa kuota berkurang.
- Jika 2 pasien sudah mengambil tiket dari kuota 10, sisa kuota adalah `8/10`.
- Sisa kuota tidak naik kembali ketika pasien selesai dilayani.
- `completed`, `skipped`, `cancelled`, dan `expired` tetap bagian dari nomor yang pernah terambil pada sesi tersebut.

Alasan:

- Kuota adalah kapasitas penerimaan nomor, bukan jumlah kursi kosong saat ini.
- Jika kuota naik lagi setelah pasien selesai, sistem akan berubah menjadi model kapasitas berjalan, bukan antrean sesi.
- Untuk klinik, lebih aman menjaga batas jumlah pasien yang masuk pada satu jadwal.

---

## 9. Estimasi Waktu Tunggu

Estimasi adalah perkiraan operasional, bukan janji waktu presisi.

Perhitungan ideal:

```txt
jumlah antrean aktif sebelum pasien x rata-rata durasi layanan
```

Sumber:

- `remaining_before_me`
- `average_service_minutes`
- status tiket lain dalam session

Perilaku:

- Waiting melihat estimasi menit.
- Called menampilkan konteks bahwa giliran sedang dipanggil.
- Serving menampilkan konteks sedang dilayani.
- Final tidak perlu estimasi aktif.
- Saat admin mengubah status tiket, estimasi waiting lain di-refresh.

Catatan produk:

- Estimasi boleh berjalan/dinamis, tetapi jangan dibuat seperti countdown presisi detik.
- Lebih cocok memakai label seperti `~ 20 menit`, `Segera`, `Giliran Anda`, atau `Sedang dilayani`.
- Jika ingin countdown visual, gunakan wording "perkiraan diperbarui realtime", bukan "wajib tepat".

---

## 10. Realtime

Realtime utama:

| Channel/Table | Dipakai Untuk |
| --- | --- |
| `queue_tickets` | Perubahan status tiket dan tabel admin. |
| `queue_sessions` | Sinyal refresh session, current number, last number, closed status. |
| `doctor_schedules` | Sinyal refresh jadwal pasien saat admin membuat/mengubah jadwal. |
| `queue_events` | Activity feed admin. |
| `notifications` | Inbox/local notification pasien. |

Target realtime:

- Admin melihat tiket baru tanpa reload manual.
- Admin melihat perubahan status setelah aksi.
- Dashboard admin refresh saat session/ticket/event berubah.
- Mobile pasien melihat status tiketnya berubah.
- Mobile pasien melihat sisa kuota dan estimasi ikut berubah saat tiket lain berubah.
- Notification pasien muncul untuk event penting.

Event penting untuk notifikasi:

| Event | Notifikasi |
| --- | --- |
| Ticket created | Nomor antrean dibuat. |
| Queue near | Nomor pasien sudah dekat. |
| Queue called | Nomor pasien dipanggil. |
| Queue missed | Pasien terlewat dan menunggu panggil ulang. |
| Queue skipped | Nomor dilewati final. |
| Queue cancelled | Antrean dibatalkan. |
| Queue expired | Antrean kedaluwarsa saat sesi ditutup. |

---

## 11. Admin UI Ideal

Dashboard admin berfungsi sebagai radar operasional:

- sesi yang perlu aksi
- sesi siap recall
- sesi lewat jam yang masih punya antrean
- jumlah waiting/missed/aktif/final
- activity feed dari event

Queue Control berfungsi sebagai meja kerja operator:

- tombol `Panggil Berikutnya`
- tombol `Panggil Ulang`
- tombol `Tutup Sesi`
- panel langkah operator
- panel pasien aktif
- daftar waiting, aktif, missed, dan history
- detail ticket dan timeline
- dialog konfirmasi dengan konteks aksi

Prinsip UI admin:

- Tombol yang mati harus punya alasan yang terlihat di guidance.
- Aksi berisiko wajib konfirmasi.
- Aksi final atau negatif wajib alasan.
- Operator tidak perlu menebak flow berikutnya.

---

## 12. User UI Ideal

Home pasien:

- menampilkan jadwal hari ini
- menampilkan poli, dokter, jam, sisa kuota, dan estimasi awal
- menjelaskan status jadwal lewat label, bukan paragraf panjang
- tombol ambil nomor hanya aktif saat rule backend memungkinkan

Tracking pasien:

- nomor pasien harus menjadi fokus utama
- status harus jelas
- estimasi dan sisa antrean harus realtime
- jika missed, pasien diberi tahu bahwa sedang menunggu panggil ulang
- jika final, tampilkan hasil akhir dan arahkan ke history

History:

- tampilkan status final dengan label berbeda
- cancelled oleh pasien/admin perlu konteks alasan
- expired berbeda dari cancelled
- skipped berbeda dari completed

---

## 13. Edge Case dan Expected Behavior

| Kondisi | Expected Behavior |
| --- | --- |
| Pasien ambil nomor sebelum jam mulai | Boleh, selama hari yang sama dan waktu sekarang masih sebelum jam selesai. |
| Admin call sebelum jam mulai | Ditolak. |
| Pasien ambil nomor tepat/sesudah jam selesai | Ditolak. |
| Admin call tepat/sesudah jam selesai | Boleh untuk waiting yang sudah terlanjur masuk. |
| Ada called/serving, admin call next | Ditolak. |
| Pasien called tidak hadir pertama | `called -> missed`. |
| Masih ada waiting dan missed | Waiting diproses dulu. Recall belum aktif. |
| Waiting habis, missed ada | Recall aktif. |
| Pasien recall tidak hadir | `called -> skipped`. |
| Admin close session saat called/serving ada | Ditolak. |
| Admin close session saat waiting ada | Waiting menjadi expired. |
| Admin close session saat missed ada | Missed menjadi skipped final. |
| Pasien selesai dilayani | Kuota tidak naik kembali. |
| Dua pasien melihat sisa kuota | Harus sama secara global, bukan berdasarkan tiket masing-masing. |
| Ticket final | Tidak bisa aktif lagi. |

---

## 14. Manual QA Checklist

### 14.1 Setup Awal

- [ ] Admin login berhasil.
- [ ] Dokter aktif tersedia.
- [ ] Poli aktif tersedia.
- [ ] Jadwal kosong atau data operasional sudah dibersihkan.
- [ ] Admin membuat jadwal hari ini.
- [ ] Jadwal muncul di Admin Jadwal.
- [ ] Jadwal muncul di mobile pasien.

### 14.2 Ambil Nomor dan Kuota

- [ ] Pasien QA 1 ambil nomor.
- [ ] Pasien QA 2 ambil nomor.
- [ ] Nomor berbeda dan berurutan.
- [ ] Sisa kuota turun global. Contoh dari 10 menjadi 8/10.
- [ ] POV pasien QA 1 dan QA 2 melihat sisa kuota yang sama.
- [ ] Dashboard admin melihat total tiket masuk.
- [ ] Queue Control melihat waiting bertambah.

### 14.3 Call dan Serving

- [ ] Admin klik `Panggil Berikutnya`.
- [ ] Nomor pertama menjadi `called`.
- [ ] Mobile pasien pertama realtime menjadi dipanggil.
- [ ] Tombol call next terkunci selama ada called.
- [ ] Admin klik `Layani`.
- [ ] Status menjadi `serving`.
- [ ] Admin klik `Selesai`.
- [ ] Status menjadi `completed`.
- [ ] Pasien melihat history selesai.

### 14.4 Tidak Hadir dan Recall

- [ ] Admin panggil nomor berikutnya.
- [ ] Admin pilih `Tidak Hadir`.
- [ ] Status menjadi `missed`.
- [ ] Jika masih ada waiting, tombol recall belum aktif.
- [ ] Admin memproses semua waiting sampai habis.
- [ ] Tombol `Panggil Ulang` aktif saat waiting 0 dan missed > 0.
- [ ] Admin klik `Panggil Ulang`.
- [ ] Nomor missed menjadi `called` dengan nomor yang sama.
- [ ] Jika pasien hadir, `called -> serving -> completed`.
- [ ] Jika pasien tidak hadir lagi, `called -> skipped`.

### 14.5 After-Hours

- [ ] Buat jadwal dengan jam selesai yang sudah tercapai/lewat, atau tunggu sampai jam selesai.
- [ ] Pasien tidak bisa mengambil nomor baru tepat saat atau setelah jam selesai.
- [ ] Jika ada waiting dari sebelum jam selesai, admin masih bisa call next.
- [ ] Guidance admin menunjukkan mode penyelesaian sisa antrean.
- [ ] Setelah waiting habis, missed masih bisa recall.
- [ ] Sesi bisa ditutup saat tidak ada called/serving.

### 14.6 Tutup Sesi

- [ ] Close session ditolak jika masih ada called/serving.
- [ ] Close session saat waiting ada membuat waiting menjadi expired.
- [ ] Close session saat missed ada membuat missed menjadi skipped final.
- [ ] Session menjadi closed.
- [ ] Mobile pasien melihat status final yang sesuai.
- [ ] Admin dashboard tidak lagi menganggap session aktif.

### 14.7 Cancel

- [ ] Pasien bisa cancel saat waiting.
- [ ] Pasien tidak bisa cancel saat called/serving/missed/final.
- [ ] Admin bisa cancel tiket aktif dengan alasan.
- [ ] Alasan tampil di detail/history jika tersedia.

### 14.8 Realtime

- [ ] Admin tidak perlu refresh untuk melihat tiket baru.
- [ ] Mobile tidak perlu refresh untuk melihat status called/serving/completed.
- [ ] Sisa kuota berubah pada semua POV.
- [ ] Estimasi berubah setelah status antrean lain berubah.
- [ ] Notification/inbox pasien menerima event penting.

---

## 15. Data Reset Operasional

Jika ingin mulai testing dari jadwal kosong tetapi tetap mempertahankan dokter dan poli:

Versi siap jalan tersedia di:

```txt
apps/supabase/patches/20260604_reset_operational_data_keep_master.sql
```

```sql
with deleted_notifications as (
  delete from public.notifications
  where type::text like 'queue_%'
  returning 1
),
deleted_events as (
  delete from public.queue_events
  returning 1
),
deleted_tickets as (
  delete from public.queue_tickets
  returning 1
),
deleted_sessions as (
  delete from public.queue_sessions
  returning 1
),
deleted_schedules as (
  delete from public.doctor_schedules
  returning 1
)
select
  (select count(*) from deleted_notifications) as notifications_deleted,
  (select count(*) from deleted_events) as events_deleted,
  (select count(*) from deleted_tickets) as tickets_deleted,
  (select count(*) from deleted_sessions) as sessions_deleted,
  (select count(*) from deleted_schedules) as schedules_deleted;
```

Yang ikut dibersihkan:

- jadwal
- queue session
- tiket antrean
- queue event
- notifikasi antrean

Yang tetap aman:

- akun pasien/admin
- klinik/cabang
- poli
- dokter
- role/staff

---

## 16. Batasan MVP dan Future Scope

MVP saat ini:

- antrean hari-H
- satu klinik/cabang utama
- pasien dan admin
- local notification berbasis realtime
- estimasi operasional
- recall satu kali

Future scope:

- booking appointment future
- multi-cabang penuh di UI
- role dokter khusus
- display nomor antrean untuk ruang tunggu
- FCM production push saat app mati total
- analytics/report historis
- QR check-in
- dynamic service time berbasis data real dokter/poli

---

## 17. Ringkasan Keputusan Penting

- AntriMedis adalah antrean hari-H, bukan booking.
- Pasien boleh ambil nomor sebelum jam mulai pada hari yang sama.
- Pasien tidak boleh ambil nomor tepat saat atau setelah jam selesai.
- Admin tidak boleh call sebelum jam mulai.
- Admin boleh menghabiskan antrean tepat/sesudah jam selesai.
- Waiting diprioritaskan sebelum missed.
- Missed baru bisa recall setelah waiting habis.
- Recall memakai nomor lama.
- Tidak hadir setelah recall menjadi skipped final.
- Close session mengubah waiting menjadi expired dan missed menjadi skipped.
- Kuota turun saat tiket diambil dan tidak naik saat pasien selesai.
- Estimasi adalah perkiraan realtime, bukan countdown presisi.
