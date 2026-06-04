-- Fix patient quota visibility.
-- The schedule availability view must expose aggregate queue capacity for the
-- whole session. With security_invoker enabled, RLS on queue_tickets made each
-- patient count only their own ticket, so two waiting patients both saw 9/10.

create or replace view public.v_schedule_availability
with (security_invoker = false) as
with schedule_base as (
  select
    ds.id as schedule_id,
    ds.branch_id,
    cb.name as branch_name,
    ds.polyclinic_id,
    pc.name as polyclinic_name,
    pc.queue_prefix,
    ds.doctor_id,
    d.full_name as doctor_name,
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
    ds.quota_limit - count(qt.id) filter (where qt.status <> 'cancelled') as remaining_quota,
    cb.is_active as branch_is_active,
    pc.is_active as polyclinic_is_active,
    d.is_active as doctor_is_active,
    coalesce(qs.is_open, false) as queue_session_is_open,
    timezone('Asia/Jakarta', now())::date as local_today,
    timezone('Asia/Jakarta', now())::time as local_time
  from public.doctor_schedules ds
  join public.clinic_branches cb on cb.id = ds.branch_id
  join public.polyclinics pc on pc.id = ds.polyclinic_id
  join public.doctors d on d.id = ds.doctor_id
  left join public.queue_sessions qs on qs.schedule_id = ds.id
  left join public.queue_tickets qt on qt.queue_session_id = qs.id
  group by
    ds.id,
    cb.name,
    cb.is_active,
    pc.name,
    pc.queue_prefix,
    pc.is_active,
    d.full_name,
    d.specialization,
    d.is_active,
    qs.id,
    qs.current_number,
    qs.last_number,
    qs.is_open
)
select
  schedule_id,
  branch_id,
  branch_name,
  polyclinic_id,
  polyclinic_name,
  queue_prefix,
  doctor_id,
  doctor_name,
  specialization,
  schedule_date,
  start_time,
  end_time,
  quota_limit,
  average_service_minutes,
  status,
  queue_session_id,
  current_number,
  last_number,
  total_taken,
  remaining_quota,
  (
    status = 'open'
    and branch_is_active
    and polyclinic_is_active
    and doctor_is_active
    and queue_session_id is not null
    and queue_session_is_open
    and schedule_date = local_today
    and local_time >= start_time
    and local_time <= end_time
    and remaining_quota > 0
  ) as is_takeable,
  case
    when not branch_is_active then 'Cabang sedang tidak aktif'
    when not polyclinic_is_active then 'Poli sedang tidak aktif'
    when not doctor_is_active then 'Dokter sedang tidak aktif'
    when status <> 'open' then 'Jadwal ditutup klinik'
    when queue_session_id is null then 'Sesi antrean belum dibuka'
    when not queue_session_is_open then 'Sesi antrean ditutup'
    when schedule_date < local_today then 'Jadwal sudah lewat'
    when schedule_date > local_today then 'Belum hari layanan'
    when local_time < start_time then 'Belum mulai'
    when local_time > end_time then 'Jam praktik selesai'
    when remaining_quota <= 0 then 'Kuota habis'
    else 'Siap diambil'
  end as availability_reason
from schedule_base;

grant select on public.v_schedule_availability to authenticated;
