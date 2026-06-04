# User-Side DB Field Map

**Tanggal update:** 4 Juni 2026

Dokumen ini memetakan field database/read model yang dipakai mobile pasien. Untuk aturan bisnis antrean lengkap, gunakan `queue_business_flow.md`.

## Auth

Password tidak disimpan di schema `public`. Email, provider Google, dan password hash dikelola oleh Supabase Auth di `auth.users`.

User-side hanya perlu membaca email dari `Supabase.auth.currentUser`.

## profiles

Dipakai untuk data pasien aplikasi.

Field yang perlu diisi user:
- `full_name` - wajib.
- `phone_number` - wajib untuk MVP pasien.
- `gender` - wajib untuk MVP pasien. Nilai: `male`, `female`, `other`.
- `birth_date` - opsional.

Field yang disajikan:
- `avatar_url` - dari Google metadata jika ada.
- `updated_at` - opsional untuk info perubahan terakhir.

Field sistem:
- `id` - sama dengan `auth.users.id`.
- `is_active`, `created_at`, `updated_at`.

## v_schedule_availability

Sumber utama halaman home pasien.

Field yang disajikan:
- `branch_name`
- `polyclinic_name`
- `queue_prefix`
- `doctor_name`
- `specialization`
- `schedule_date`
- `start_time`, `end_time`
- `quota_limit`
- `average_service_minutes`
- `current_number`, `last_number`
- `total_taken`, `remaining_quota`
- `is_takeable`
- `availability_reason`

Field aksi:
- `queue_session_id` - dipakai saat pasien mengambil nomor.

Catatan logic:
- `is_takeable` berasal dari backend dan menjadi acuan utama tombol ambil nomor.
- Pasien hanya bisa ambil nomor pada tanggal layanan sebelum `end_time`.
- Tepat saat `end_time`, loket online sudah tutup dan backend menolak `create_queue_ticket`.
- `remaining_quota` adalah sisa kuota global sesi. Jika kuota 10 dan dua pasien sudah mengambil tiket, semua POV pasien melihat `8/10`.
- Kuota tidak naik lagi saat pasien selesai dilayani.
- Home pasien me-refresh realtime dari perubahan `queue_sessions` dan `doctor_schedules`.

## v_queue_ticket_details

Sumber tracking antrean pasien.

Field yang disajikan:
- `queue_code`, `queue_number`, `status`
- `estimated_wait_minutes`
- `remaining_before_me`, `missed_count`
- `current_number`, `last_number`
- `branch_name`, `branch_address`
- `polyclinic_name`, `queue_prefix`
- `doctor_name`, `specialization`
- `schedule_date`, `start_time`, `end_time`
- `created_at`, `called_at`, `serving_started_at`, `completed_at`
- `skipped_at`, `cancelled_at`, `expired_at`
- `missed_count`
- `status_reason`, `cancel_reason`

Field aksi:
- `ticket_id`
- `queue_session_id`

## queue_tickets

Dipakai untuk aksi lanjutan.

User-side:
- Cancel antrean memakai RPC `cancel_my_ticket`, bukan update table langsung.
- Cancel dari pasien hanya valid saat status `waiting`.
- Riwayat antrean menampilkan tiket final: `completed`, `skipped`, `cancelled`, `expired`.
- Status `missed` masih aktif dan berarti pasien menunggu panggil ulang, bukan history final.
- Active ticket pasien mencakup `waiting`, `called`, `serving`, dan `missed`.

Field penting:
- `status`
- `cancel_reason`
- `status_reason`
- `missed_count`
- timestamp status: `called_at`, `serving_started_at`, `completed_at`, `skipped_at`, `cancelled_at`, `expired_at`.

## notifications

Dipakai untuk notification inbox dan local notification MVP.

Field yang disajikan:
- `type`
- `title`
- `body`
- `is_read`
- `created_at`
- `read_at`
- `data`

Tipe antrean yang relevan:
- `queue_created`
- `queue_called`
- `queue_missed`
- `queue_skipped`
- `queue_cancelled`
- `queue_expired`

Catatan: local notification berbasis realtime cukup untuk MVP saat app aktif/background ringan. Untuk production saat app mati total, gunakan FCM dan Supabase Edge Function.
