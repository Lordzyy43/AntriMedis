# FCM Implementation Tasklist - AntriMedis

**Tujuan:** menambahkan push notification production agar notifikasi tetap masuk saat app background, terminated, atau device idle.  
**Acuan produk:** sistem antrean hari-H, Supabase sebagai source of truth, local notification tetap dipakai sebagai fallback/foreground UX.  
**Status awal:** future scope dari `docs/prd_status_roadmap.md`.

---

## 1. Target yang Ingin Dicapai

FCM di AntriMedis bukan menggantikan inbox notifikasi Supabase. FCM hanya lapisan delivery ke device.

Target akhir:

- Notifikasi tetap masuk saat app ditutup.
- Notifikasi tetap tampil saat app di background.
- Saat app terbuka, UI tetap bisa menampilkan inbox dari Supabase.
- Local notification tetap dipakai untuk foreground dan fallback.
- Setiap notifikasi penting tetap tersimpan di tabel `notifications`.

Jenis event yang masuk push:

- `queue_created`
- `queue_near`
- `queue_called`
- `queue_missed`
- `queue_skipped`
- `queue_cancelled`
- `queue_expired`
- `schedule_changed` jika memang dianggap penting untuk pasien

---

## 2. Arsitektur Yang Disarankan

Alur yang disarankan:

```txt
Admin / RPC / Trigger / Edge Function
-> insert row ke public.notifications
-> resolve device token pasien
-> kirim FCM push
-> mobile menampilkan push notification
-> app opened
-> mobile sync inbox dari Supabase
```

Prinsip penting:

- `notifications` table tetap source of truth.
- FCM hanya media delivery.
- Device token disimpan per user dan bisa lebih dari satu device.
- Jika push gagal, inbox Supabase tetap menyimpan notifikasi.
- Local notification tetap dipakai saat app foreground atau untuk fallback tertentu.

---

## 3. Phase 0 - Keputusan Produk

Checklist keputusan sebelum coding:

- [ ] Tentukan apakah FCM dipakai untuk semua notifikasi atau hanya event penting.
- [ ] Tentukan apakah `queue_near` juga harus dikirim sebagai push atau cukup `queue_called` dan status final.
- [ ] Tentukan apakah notifikasi `schedule_changed` memang perlu push ke pasien.
- [ ] Tentukan fallback policy saat push gagal.
- [ ] Tentukan apakah satu user boleh login di banyak device dan menerima push di semua device.
- [ ] Tentukan apakah notifikasi penting harus tampil sebagai `high priority` di Android.

Rekomendasi produk:

- Push untuk semua event antrean penting.
- Inbox Supabase tetap lengkap.
- Multi-device aktif.
- `queue_near` boleh dipakai, tapi pastikan tidak terlalu spam.

---

## 4. Phase 1 - Data Model dan Token Management

Tujuan fase ini: sistem tahu device mana yang harus dikirimi push.

### 4.1 Tambah tabel device token

Checklist:

- [ ] Buat tabel baru untuk menyimpan token FCM device.
- [ ] Simpan `user_id`.
- [ ] Simpan `fcm_token`.
- [ ] Simpan `platform` seperti `android`, `ios`, `web` jika diperlukan.
- [ ] Simpan `device_name` atau `device_id` opsional.
- [ ] Simpan `is_active`.
- [ ] Simpan `last_seen_at`.
- [ ] Simpan `created_at` dan `updated_at`.
- [ ] Tambah unique constraint untuk `fcm_token`.
- [ ] Tambah index untuk `user_id`.

Rekomendasi schema minimal:

```sql
public.user_device_tokens
```

Kolom minimal:

- `id`
- `user_id`
- `fcm_token`
- `platform`
- `device_name`
- `is_active`
- `last_seen_at`
- `created_at`
- `updated_at`

### 4.2 RLS dan akses token

Checklist:

- [ ] Hanya user pemilik token yang boleh read token miliknya.
- [ ] User boleh insert token miliknya sendiri.
- [ ] User boleh update token miliknya sendiri.
- [ ] User boleh deactivate token miliknya sendiri.
- [ ] Service role / Edge Function boleh membaca token untuk pengiriman push.

Catatan:

- Token FCM adalah data sensitif operasional.
- Jangan buka token ke user lain.

### 4.3 Normalisasi token lifecycle

Checklist:

- [ ] Saat app login pertama kali, daftar token disimpan.
- [ ] Saat token refresh, row lama diperbarui atau diganti.
- [ ] Saat logout, token ditandai inactive atau dihapus.
- [ ] Saat user uninstall app, token lama boleh dibersihkan lewat strategi TTL atau invalid response handling.

---

## 5. Phase 2 - Flutter Integration

Tujuan fase ini: mobile bisa register, refresh, dan mengelola token FCM.

### 5.1 Tambah dependency

Checklist:

- [ ] Tambahkan `firebase_core`.
- [ ] Tambahkan `firebase_messaging`.
- [ ] Jika perlu, pertimbangkan `flutter_local_notifications` tetap dipakai sebagai companion.
- [ ] Pastikan dependency tidak bentrok dengan Supabase dan local notification yang sudah ada.

### 5.2 Konfigurasi Firebase project

Ini bagian paling awal yang harus beres sebelum masuk ke coding Flutter.

Checklist:

- [ ] Buat / pakai Firebase project khusus AntriMedis.
- [ ] Pakai nama project yang konsisten dengan app, misalnya `AntriMedis`.
- [ ] Putuskan apakah Firebase Analytics perlu diaktifkan sekarang atau nanti.
- [ ] Catat `project id`, `project number`, dan owner akun Google untuk dokumentasi internal.
- [ ] Pastikan billing/quota project dipahami sejak awal jika nanti ada fitur tambahan.
- [ ] Tambah Android app ke Firebase.
- [ ] Tambah iOS app ke Firebase jika target iOS ingin didukung.
- [ ] Download `google-services.json`.
- [ ] Download `GoogleService-Info.plist`.
- [ ] Simpan aset konfigurasi sesuai struktur Flutter.

Output yang harus kamu punya setelah setup ini:

- `google-services.json` untuk Android
- `GoogleService-Info.plist` untuk iOS
- referensi package name dan bundle identifier yang valid

### 5.2.1 Android app registration

Checklist:

- [ ] Daftarkan Android app di Firebase Console.
- [ ] Isi package name sesuai `applicationId` Flutter.
- [ ] Tambahkan nickname kalau memudahkan identifikasi.
- [ ] Download `google-services.json` setelah registrasi selesai.
- [ ] Simpan file ke lokasi Android yang benar.
- [ ] Jangan pakai file config lama dari project lain.

Lokasi yang biasanya dipakai:

```txt
android/app/google-services.json
```

Catatan:

- Jangan rename file config.
- Jangan commit credential server-side ke repo Flutter.

### 5.2.2 iOS app registration

Checklist:

- [ ] Daftarkan iOS app di Firebase Console.
- [ ] Isi bundle identifier sesuai target iOS Flutter.
- [ ] Download `GoogleService-Info.plist`.
- [ ] Tambahkan file ke target iOS yang benar.
- [ ] Catat kalau iOS belum jadi target segera, supaya setup bisa ditunda tanpa lupa.

Lokasi yang biasanya dipakai:

```txt
ios/Runner/GoogleService-Info.plist
```

Catatan:

- Kalau targetmu saat ini Android-only, iOS boleh menyusul.
- Tapi struktur backend tetap sebaiknya tidak Android-only dari awal.

### 5.2.3 Firebase CLI toolchain

Checklist:

- [ ] Install Firebase CLI jika belum ada.
- [ ] Install FlutterFire CLI jika kamu ingin generate config otomatis.
- [ ] Login ke akun Google yang benar di CLI.
- [ ] Verifikasi CLI bisa melihat project Firebase yang baru dibuat.
- [ ] Simpan catatan command setup agar repeatable kalau install ulang.

Rekomendasi:

- Kalau ingin workflow lebih rapi, gunakan FlutterFire CLI.
- Kalau ingin manual, itu juga valid, tapi dokumentasinya harus rapi.

### 5.2.4 Sanity check config

Checklist:

- [ ] Pastikan package name Android tidak typo.
- [ ] Pastikan bundle identifier iOS tidak typo.
- [ ] Pastikan file config berasal dari project Firebase yang sama.
- [ ] Pastikan tidak ada file config duplikat dari project percobaan.
- [ ] Pastikan file config sesuai build variant yang dipakai.

### 5.3 Inisialisasi Firebase di app

Checklist:

- [ ] Panggil `Firebase.initializeApp()` sebelum `runApp()`.
- [ ] Pastikan `Supabase.initialize()` tetap jalan.
- [ ] Pastikan `NotificationService.initialize()` tetap aman dipanggil.
- [ ] Jangan ubah alur bootstrap auth/profile yang sudah ada.
- [ ] Pastikan init Firebase tidak mengganggu splash screen atau startup gate.
- [ ] Pastikan error init bisa kelihatan di log.

Urutan bootstrap yang disarankan:

```txt
WidgetsFlutterBinding.ensureInitialized()
-> dotenv.load()
-> Firebase.initializeApp()
-> Supabase.initialize()
-> NotificationService.initialize()
-> runApp()
```

Catatan:

- Kalau file config Firebase belum benar, app bisa gagal di startup.
- Karena itu setup project dan file config harus selesai dulu sebelum coding handler token.

### 5.4 Permission request

Checklist:

- [ ] Request permission notifikasi saat onboarding atau setelah user login.
- [ ] Jelaskan manfaatnya dengan copy yang jelas.
- [ ] Tampilkan fallback jika permission ditolak.
- [ ] Di Android 13+, pastikan runtime permission notifikasi ditangani.
- [ ] Di iOS, tangani permission request sesuai Apple flow.

### 5.5 Token fetch dan sync

Checklist:

- [ ] Ambil token FCM setelah user login sukses.
- [ ] Pastikan user sudah terautentikasi sebelum token disimpan.
- [ ] Kirim token ke backend Supabase.
- [ ] Update token saat refresh token berubah.
- [ ] Update `last_seen_at` saat app dibuka.
- [ ] Hapus / nonaktifkan token saat logout.
- [ ] Tangani kasus token belum tersedia saat startup pertama.
- [ ] Tangani kasus permission ditolak tetapi app tetap bisa berjalan.

Urutan token lifecycle yang disarankan:

```txt
app start
-> Firebase ready
-> user login
-> get FCM token
-> send token ke Supabase
-> listen token refresh
-> sync ulang saat token berubah
```

### 5.6 Background handler

Checklist:

- [ ] Tambahkan background message handler.
- [ ] Pastikan handler hanya melakukan pekerjaan ringan.
- [ ] Jangan mengandalkan state provider aktif di background isolate.
- [ ] Tetap simpan notifikasi di inbox lewat backend, bukan hanya dari client.

### 5.7 Foreground presentation

Checklist:

- [ ] Tentukan apakah foreground message tetap memunculkan local notification.
- [ ] Hindari double notification saat app aktif jika push dan local sama-sama jalan.
- [ ] Terapkan aturan deduplikasi.

Rekomendasi:

- Saat app foreground, tampilkan local notification dari payload push atau dari event realtime, tapi jangan dua kali.
- Saat app background/terminated, biarkan FCM yang tampil.

### 5.8 Verifikasi awal setup

Setelah setup Firebase selesai, lakukan verifikasi cepat sebelum lanjut ke backend:

- [ ] App bisa build tanpa error Firebase.
- [ ] `Firebase.initializeApp()` berhasil dijalankan.
- [ ] Permission prompt muncul sesuai platform.
- [ ] Token FCM bisa diambil dan dilog.
- [ ] App tidak crash saat startup setelah Firebase diaktifkan.

Kalau salah satu gagal:

- cek package name / bundle id
- cek lokasi file config
- cek dependency Firebase yang dipasang
- cek urutan init di `main.dart`

---

## 6. Phase 3 - Backend Push Pipeline

Tujuan fase ini: saat event antrean terjadi, sistem otomatis mengirim push.

### 6.1 Pilih titik pemicu

Checklist:

- [ ] Tentukan apakah push dipicu dari trigger PostgreSQL.
- [ ] Tentukan apakah push dipicu dari Supabase Edge Function yang dipanggil RPC/trigger.
- [ ] Tentukan apakah event tertentu cukup dibuat di DB lalu dikirim async oleh function.

Rekomendasi:

- Tetap simpan event/notifikasi di database.
- Kirim push dari Edge Function agar service account dan FCM server key tidak bocor ke client.

### 6.2 Edge Function delivery

Checklist:

- [ ] Buat Edge Function untuk delivery push.
- [ ] Function menerima payload notifikasi.
- [ ] Function resolve semua token aktif milik user target.
- [ ] Function kirim ke FCM endpoint.
- [ ] Function catat hasil sukses/gagal per token.
- [ ] Function menghapus token invalid jika FCM mengembalikan invalid registration token.

### 6.3 Payload standardization

Checklist:

- [ ] Standarkan payload `notification`.
- [ ] Standarkan payload `data`.
- [ ] Sertakan `notification_id`.
- [ ] Sertakan `type`.
- [ ] Sertakan `ticket_id` jika relevan.
- [ ] Sertakan `queue_code` jika relevan.
- [ ] Sertakan `screen` atau `route` untuk deep link.
- [ ] Sertakan timestamp event.

Contoh payload data:

```txt
notification_id
type
ticket_id
queue_code
screen
created_at
```

### 6.4 Delivery retry dan dedup

Checklist:

- [ ] Tambahkan idempotency key per notifikasi.
- [ ] Cegah pengiriman push ganda untuk event yang sama.
- [ ] Tentukan retry policy untuk network failure.
- [ ] Pisahkan retry sementara dan token invalid permanen.

### 6.5 Delivery status

Checklist:

- [ ] Simpan status delivery jika dibutuhkan.
- [ ] Simpan `sent_at`.
- [ ] Simpan `failed_at`.
- [ ] Simpan alasan gagal bila tersedia.
- [ ] Pisahkan status `queued`, `sent`, `failed`, `invalid_token`.

Rekomendasi:

- Minimal cukup simpan sukses/gagal.
- Kalau waktu cukup, simpan status per device token.

---

## 7. Phase 4 - Notifikasi dan Inbox Sync

Tujuan fase ini: push dan inbox tidak saling bertabrakan.

### 7.1 Satu event, dua jalur

Checklist:

- [ ] Saat event terjadi, insert dulu ke `notifications`.
- [ ] Setelah itu kirim push.
- [ ] Jika push gagal, inbox tetap ada.
- [ ] Jika push sukses, inbox tetap menjadi histori.

### 7.2 Mapping tipe notifikasi

Checklist:

- [ ] Cocokkan `notification_type` di DB dengan payload FCM.
- [ ] Cocokkan icon/warna di UI inbox dengan type yang sama.
- [ ] Pastikan type yang baru tidak merusak UI lama.

Type mapping yang umum:

- `queue_created`
- `queue_near`
- `queue_called`
- `queue_missed`
- `queue_skipped`
- `queue_cancelled`
- `queue_expired`
- `schedule_changed`

### 7.3 Deep link target

Checklist:

- [ ] Tentukan target layar saat user tap push.
- [ ] Untuk antrean aktif, arahkan ke tracking.
- [ ] Untuk inbox umum, arahkan ke notifications page.
- [ ] Jika user belum login, arahkan ke login lalu resume target.

Rekomendasi:

- `queue_called` -> tracking page
- `queue_near` -> tracking page
- `queue_created` -> tracking page atau history detail
- `schedule_changed` -> home
- final status -> notifications page atau history page

---

## 8. Phase 5 - Android Setup

Tujuan fase ini: push benar-benar jalan di device Android.

### 8.1 Gradle dan manifest

Checklist:

- [ ] Tambahkan konfigurasi Firebase Android sesuai dokumentasi resmi.
- [ ] Pastikan namespace dan application id konsisten.
- [ ] Pastikan permission notifikasi Android 13+ ditangani.
- [ ] Pastikan default notification channel disiapkan.
- [ ] Pastikan icon notifikasi jelas dan tidak pecah di status bar.

### 8.2 Background dan terminated behavior

Checklist:

- [ ] Uji notifikasi saat app background.
- [ ] Uji notifikasi saat app swipe away / terminated.
- [ ] Uji notifikasi saat device terkunci.
- [ ] Uji tap notification membuka app ke layar yang benar.

### 8.3 Android priority

Checklist:

- [ ] Gunakan channel dengan importance tinggi untuk antrean penting.
- [ ] Pastikan suara/vibration sesuai kebutuhan klinik.
- [ ] Hindari spam untuk notifikasi berulang.

---

## 9. Phase 6 - iOS Setup

Tujuan fase ini: kalau target iPhone/iPad nanti aktif, path iOS sudah siap.

Checklist:

- [ ] Tambahkan Firebase iOS configuration.
- [ ] Set capability yang dibutuhkan.
- [ ] Minta permission notifikasi dengan benar.
- [ ] Tambahkan foreground presentation options.
- [ ] Uji background dan terminated behavior pada iOS device.

Catatan:

- Jika iOS belum target, fase ini boleh ditunda.
- Namun struktur backend sebaiknya dari awal tidak Android-only.

---

## 10. Phase 7 - Client UX dan Guardrails

Tujuan fase ini: pengalaman pengguna tetap rapi dan tidak dobel.

### 10.1 Deduplikasi notifikasi

Checklist:

- [ ] Hindari satu event memunculkan push dan local notification dua kali.
- [ ] Gunakan aturan priority source.
- [ ] Jika app foreground, pilih salah satu jalur yang paling pas.

Rekomendasi aturan:

- Foreground: local notification atau inline UI update.
- Background/terminated: FCM.
- Inbox: Supabase.

### 10.2 Permission education

Checklist:

- [ ] Jelaskan kenapa notifikasi perlu diaktifkan.
- [ ] Jelaskan bahwa user akan menerima panggilan antrean.
- [ ] Tawarkan tombol lanjut tanpa permission jika user menolak.

### 10.3 Notification settings

Checklist:

- [ ] Tambahkan toggle notifikasi jika perlu.
- [ ] Tambahkan pilihan jenis notifikasi jika scope memungkinkan.
- [ ] Simpan preferensi per user.
- [ ] Sinkronkan preferensi dengan backend delivery rule.

Rekomendasi minimal:

- `queue_called` selalu aktif.
- `queue_near` bisa jadi opsional jika ingin kurangi spam.

---

## 11. Phase 8 - Testing dan QA

Tujuan fase ini: memastikan FCM benar-benar lebih baik dari local-only, bukan justru bikin chaos.

### 11.1 Unit test

Checklist:

- [ ] Test mapping payload FCM ke model notifikasi.
- [ ] Test token registration dan sync logic.
- [ ] Test dedup logic.
- [ ] Test fallback saat push gagal.
- [ ] Test route deep link target.

### 11.2 Integration test

Checklist:

- [ ] Test login -> register token -> receive push.
- [ ] Test logout -> token inactive.
- [ ] Test token refresh -> token update.
- [ ] Test app background -> push masuk.
- [ ] Test app terminated -> push masuk.

### 11.3 Manual QA checklist

- [ ] Install app fresh.
- [ ] Login sebagai pasien.
- [ ] Allow notification permission.
- [ ] Ambil nomor antrean.
- [ ] Biarkan app background.
- [ ] Kirim `queue_called`.
- [ ] Pastikan push muncul.
- [ ] Swipe away app.
- [ ] Kirim `queue_missed` atau `queue_skipped`.
- [ ] Pastikan push masih muncul.
- [ ] Buka push dan pastikan deep link benar.
- [ ] Cek inbox Supabase tetap lengkap.
- [ ] Logout.
- [ ] Pastikan token tidak lagi aktif untuk user itu.

### 11.4 Failure QA

- [ ] Permission ditolak.
- [ ] Token expired / invalid.
- [ ] Device offline saat notifikasi dikirim.
- [ ] User punya dua device aktif.
- [ ] User reinstall app dan token berubah.
- [ ] Edge Function timeout.
- [ ] FCM credential salah.

---

## 12. Phase 9 - Observability dan Operasional

Tujuan fase ini: kalau push gagal, kamu tahu letaknya di mana.

Checklist:

- [ ] Log request delivery ke Edge Function.
- [ ] Log status per token.
- [ ] Log invalid token cleanup.
- [ ] Log payload yang dikirim, tanpa data sensitif berlebihan.
- [ ] Simpan error reason dari FCM jika tersedia.
- [ ] Buat cara mudah untuk audit notifikasi mana yang sudah dikirim.

Rekomendasi:

- Minimal simpan `push_delivery_logs`.
- Jika belum sempat, simpan cukup di log function + notification row.

---

## 13. Phase 10 - Security Review

Tujuan fase ini: mencegah FCM jadi pintu bocor baru.

Checklist:

- [ ] Simpan service credentials hanya di server/Edge Function.
- [ ] Jangan taruh server key di Flutter app.
- [ ] Jangan expose token device user lain.
- [ ] Pastikan user hanya bisa manage token miliknya.
- [ ] Pastikan push function hanya menerima request dari jalur yang sah.
- [ ] Audit ulang RLS untuk table token.
- [ ] Audit ulang auth context saat token disimpan.

---

## 14. Implementasi Urutan Yang Paling Aman

Urutan kerja yang paling masuk akal:

1. Buat tabel token device dan RLS.
2. Tambahkan Firebase ke Flutter.
3. Simpan token saat login.
4. Kirim token ke Supabase.
5. Buat Edge Function push.
6. Sambungkan event antrean ke delivery push.
7. Tambahkan dedup dan retry.
8. Uji background dan terminated.
9. Tambahkan deep link ke tracking/inbox.
10. Rapikan logging dan cleanup token invalid.

---

## 15. Definition of Done

FCM dianggap selesai kalau:

- [ ] Pasien menerima push saat app background.
- [ ] Pasien menerima push saat app terminated.
- [ ] Inbox Supabase tetap berisi histori notifikasi.
- [ ] Token device tersimpan dan bisa diperbarui.
- [ ] Logout menonaktifkan token.
- [ ] Device invalid dibersihkan.
- [ ] Notifikasi tidak dobel di foreground.
- [ ] Tap notification membuka layar yang tepat.
- [ ] Semua event antrean penting lolos QA manual.
- [ ] Fallback local notification tetap aman jika FCM belum ready atau permission ditolak.

---

## 16. Scope Yang Sebaiknya Ditunda

Jangan dikerjakan dulu sebelum push dasar stabil:

- [ ] Analytics notifikasi advanced.
- [ ] Segmentasi kampanye/promo.
- [ ] Multi-clinic push routing.
- [ ] Per-device preference yang terlalu granular.
- [ ] Rich media notification.
- [ ] In-app inbox realtime rewrite.

---

## 17. Ringkasan Praktis

Kalau targetmu production-like, FCM memang layak ditambahkan.
Kalau targetmu UAS atau demo cepat, local notification + Supabase realtime masih cukup.

Rekomendasi paling sehat untuk AntriMedis:

- Supabase tetap sumber data.
- Local notification tetap dipakai.
- FCM ditambahkan sebagai delivery layer untuk app yang terminated/background.
