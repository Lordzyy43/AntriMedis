# User-Side DB Field Map

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

Field aksi:
- `queue_session_id` - dipakai saat pasien mengambil nomor.

## v_queue_ticket_details

Sumber tracking antrean pasien.

Field yang disajikan:
- `queue_code`, `queue_number`, `status`
- `estimated_wait_minutes`
- `current_number`, `last_number`
- `branch_name`, `branch_address`
- `polyclinic_name`, `queue_prefix`
- `doctor_name`, `specialization`
- `schedule_date`, `start_time`, `end_time`
- `created_at`, `called_at`, `serving_started_at`, `completed_at`

Field aksi:
- `ticket_id`
- `queue_session_id`

## queue_tickets

Dipakai untuk aksi lanjutan.

User-side yang masih perlu dibuat:
- Cancel antrean: update status `waiting` menjadi `cancelled`.
- Riwayat antrean: tampilkan tiket `completed`, `skipped`, `cancelled`, `expired`.

Field penting:
- `status`
- `cancel_reason`
- timestamp status: `called_at`, `serving_started_at`, `completed_at`, `skipped_at`, `cancelled_at`, `expired_at`.

## notifications

Dipakai untuk notification inbox.

User-side yang masih perlu dibuat:
- Daftar notifikasi.
- Tandai sudah dibaca.

Field yang disajikan:
- `type`
- `title`
- `body`
- `is_read`
- `created_at`
- `read_at`
- `data`
