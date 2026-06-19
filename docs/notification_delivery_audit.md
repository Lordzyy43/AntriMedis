# Notification Delivery Audit - AntriMedis

Status: production guardrail diterapkan.

Dokumen ini memetakan semua event notifikasi pasien, sumber pengirimannya, dan aturan copy/delivery agar inbox, push FCM, dan local fallback tetap satu makna.

## Prinsip

- `public.notifications` adalah source of truth untuk inbox pasien.
- Push FCM dikirim dari trigger `notifications_dispatch_push` ke Edge Function `send-push`.
- Local notification dipakai untuk foreground fallback dan event lokal yang tidak perlu masuk FCM.
- Push adalah versi ringkas.
- Inbox adalah versi lengkap tetapi tetap pendek.
- Local fallback mengikuti push/inbox dan tidak boleh menambah makna baru.
- Copy admin tidak dipakai untuk pasien. Admin boleh melihat alasan internal di `queue_events.message` atau field reason, tetapi body notifikasi pasien harus netral.

## Gaya Bahasa

| Kategori | Tujuan | Pola Copy |
| --- | --- | --- |
| Informatif | Memberi kepastian tanpa menuntut aksi cepat. | Konteks + detail pendek. |
| Tindakan langsung | Meminta pasien bergerak atau memperhatikan status saat ini. | Konteks + aksi utama. |
| Final/status selesai | Menjelaskan status akhir tanpa menyalahkan pasien. | Status final + detail kecil bila perlu. |

Aturan tone:

- Singkat, jelas, sopan, dan operasional.
- Hindari alasan internal panjang di body pasien.
- Hindari kata yang emosional seperti "gagal", "terlambat", atau "kesalahan pasien".
- Selalu sebut `queue_code` untuk event antrean.
- `schedule_changed` hanya dipakai untuk perubahan yang signifikan bagi pasien.

## Event Matrix

| Event | Kategori | Sumber Saat Ini | Inbox | Push FCM | Local | Keputusan Production |
| --- | --- | --- | --- | --- | --- | --- |
| `queue_created` | Informatif | RPC `create_queue_ticket` insert ke `notifications` | Ya | Ya | Foreground fallback dari FCM/realtime jika ada | Tetap ada. Memberi kepastian nomor sudah didapat. |
| `queue_near` | Informatif | App realtime/polling di `QueueProvider._maybeNotify` | Tidak saat ini | Tidak | Ya, hanya saat sisa 1-2 antrean | Jangan dipush dulu agar tidak noise. Local-only dan sekali per tiket. |
| `queue_called` | Tindakan langsung | RPC `call_next_queue` dan `recall_missed_queue` insert ke `notifications` | Ya | Ya | Ya | Wajib ada. Ini event paling penting karena pasien harus bergerak. |
| `queue_missed` | Tindakan langsung | RPC `update_queue_status` saat status menjadi `missed` | Ya | Ya | Ya | Tetap ada. Copy harus jelas tapi tidak menyalahkan pasien. |
| `queue_skipped` | Final/status selesai | RPC `update_queue_status` atau `close_queue_session` untuk missed yang selesai | Ya | Ya | Ya | Tetap ada. Body pasien netral, alasan internal tidak dimasukkan ke body. |
| `queue_cancelled` | Final/status selesai | RPC `cancel_my_ticket` atau `update_queue_status` | Ya | Ya | Ya | Tetap ada. Copy netral untuk pasien dan bisa berbeda dari catatan admin. |
| `queue_expired` | Final/status selesai | RPC `update_queue_status` atau `close_queue_session` | Ya | Ya | Ya | Tetap ada. Dipakai khusus sesi layanan ditutup. |
| `schedule_changed` | Informatif | Belum ada RPC aktif yang membuat event ini untuk pasien | Ya jika dibuat | Ya jika signifikan | Ya | Tetap tersedia, tapi jangan dipakai untuk perubahan kecil. |

## Standar Copy

| Event | Inbox Title | Inbox Body | Push Title | Push Body | Local Title | Local Body |
| --- | --- | --- | --- | --- | --- | --- |
| `queue_created` | Nomor antrean berhasil dibuat | Nomor antrean Anda adalah `{queue_code}`. | Sama | Sama | Sama | Sama |
| `queue_near` | Giliran Anda semakin dekat | Nomor `{queue_code}` tinggal `{remaining}` antrean lagi. Mohon bersiap. | Tidak dikirim saat ini | Tidak dikirim saat ini | Giliran Anda semakin dekat | Nomor `{queue_code}` tinggal `{remaining}` antrean lagi. Mohon bersiap. |
| `queue_called` | Nomor Anda dipanggil | Nomor `{queue_code}` sedang dipanggil. Segera menuju poli. | Sama | Sama | Sama | Sama |
| `queue_missed` | Nomor Anda terlewat | Nomor `{queue_code}` terlewat. Tunggu panggilan ulang setelah antrean reguler selesai. | Sama | Sama | Sama | Sama |
| `queue_skipped` | Antrean dilewati | Nomor `{queue_code}` dilewati oleh petugas. | Sama | Sama | Sama | Sama |
| `queue_cancelled` | Antrean dibatalkan | Nomor `{queue_code}` dibatalkan. | Sama | Sama | Sama | Sama |
| `queue_expired` | Antrean kedaluwarsa | Nomor `{queue_code}` kedaluwarsa karena sesi layanan telah ditutup. | Sama | Sama | Sama | Sama |
| `schedule_changed` | Jadwal layanan berubah | Jadwal layanan Anda berubah. Cek detail terbaru di aplikasi. | Sama | Sama | Sama | Sama |

## Guardrail Delivery

1. Semua event penting tetap masuk `public.notifications`, kecuali `queue_near` yang saat ini local-only.
2. Trigger `dispatch_notification_push` memanggil `should_dispatch_notification_push(type)` sebelum mengirim FCM.
3. `queue_near` tidak dikirim via FCM karena rawan noise dan sudah cukup sebagai local signal saat app aktif.
4. Edge Function `send-push` mengambil title/body dari row `notifications`, bukan membangun copy sendiri.
5. Payload FCM hanya membawa data navigasi minimal:
   - `notification_id`
   - `type`
   - `ticket_id`
   - `queue_code`
   - `remaining`
   - `route`
   - `created_at`
6. Dedup local memakai kombinasi `type + queue_code/ticket_id/notification_id`, sehingga foreground FCM dan realtime tidak menampilkan event yang sama dua kali dalam window pendek.
7. Delivery log memakai guard `notification_id + user_device_token_id` dan trigger `ensure_push_delivery_user_match`, sehingga push tidak dicatat untuk device milik user lain.

## Admin vs Pasien

| Status | Pasien | Admin/Internal |
| --- | --- | --- |
| `queue_skipped` | "Nomor `{queue_code}` dilewati oleh petugas." | Alasan operasional boleh disimpan di `status_reason` atau `queue_events.message`. |
| `queue_cancelled` | "Nomor `{queue_code}` dibatalkan." | Alasan pasien/petugas boleh tampil di panel admin, bukan body push pasien. |
| `queue_missed` | "Tunggu panggilan ulang..." | Admin boleh melihat bahwa status berasal dari nomor yang tidak hadir saat dipanggil. |
| `queue_expired` | "Sesi layanan telah ditutup." | Admin boleh melihat alasan penutupan sesi. |

## QA Checklist

- Ambil nomor dengan akun pasien A dan pastikan hanya pasien A melihat `queue_created`.
- Login pasien B di device lain dan pastikan inbox/push pasien A tidak muncul.
- Panggil antrean dan cek `queue_called` di foreground, background, dan terminated.
- Ubah status menjadi `missed`, `skipped`, `cancelled`, dan `expired`, lalu cek title/body di inbox dan push tetap sama makna.
- Pastikan `queue_near` hanya muncul saat remaining 1-2 dan tidak masuk push delivery log.
- Cek dua device untuk akun yang sama: keduanya boleh menerima push yang sama, tetapi log delivery harus per-device.
- Cek layar kecil Android: body tetap pendek dan tidak ambigu.
