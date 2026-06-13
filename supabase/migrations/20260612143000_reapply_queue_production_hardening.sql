-- Reapply queue production hardening because 20260612120000 was already recorded before later edits.
-- Fix patient queue read access without widening direct table access.
-- Ticket detail/timeline views explicitly enforce ownership, then run with the
-- view owner's privileges so joined lookup rows hidden by RLS do not make a
-- patient's own ticket disappear.

drop policy if exists "Authenticated users can read queue sessions"
on public.queue_sessions;

-- Patients cancel through public.cancel_my_ticket(), which locks the owned row,
-- writes only cancellation fields, and records queue_events/notifications.
-- Keeping direct table UPDATE open would allow same-request tampering of other
-- writable ticket columns while transitioning a waiting ticket to cancelled.
drop policy if exists "Patients can cancel own waiting queue tickets"
on public.queue_tickets;

-- Queue mutations should go through RPCs so status transitions, event writes,
-- notifications, and estimate refreshes stay atomic and auditable.
drop policy if exists "Staff can update queue tickets"
on public.queue_tickets;

drop policy if exists "Staff can manage queue sessions"
on public.queue_sessions;

drop policy if exists "Patients can read own queue sessions"
on public.queue_sessions;

create policy "Patients can read own queue sessions"
on public.queue_sessions for select to authenticated
using (
  public.is_staff()
  or exists (
    select 1
    from public.queue_tickets qt
    where qt.queue_session_id = queue_sessions.id
      and qt.patient_id = auth.uid()
  )
);

create or replace function public.prevent_duplicate_active_patient_queue()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_branch_id uuid;
  v_schedule_date date;
begin
  if new.status not in ('waiting', 'called', 'serving', 'missed') then
    return new;
  end if;

  perform pg_advisory_xact_lock(hashtextextended(new.patient_id::text, 0));

  select ds.branch_id, ds.schedule_date
  into v_branch_id, v_schedule_date
  from public.queue_sessions qs
  join public.doctor_schedules ds on ds.id = qs.schedule_id
  where qs.id = new.queue_session_id;

  if exists (
    select 1
    from public.queue_tickets qt
    join public.queue_sessions qs on qs.id = qt.queue_session_id
    join public.doctor_schedules ds on ds.id = qs.schedule_id
    where qt.patient_id = new.patient_id
      and qt.id <> new.id
      and qt.status in ('waiting', 'called', 'serving', 'missed')
      and ds.branch_id = v_branch_id
      and ds.schedule_date = v_schedule_date
  ) then
    raise exception 'Patient already has active queue today';
  end if;

  return new;
end;
$$;

drop trigger if exists queue_tickets_prevent_duplicate_active_patient_queue
on public.queue_tickets;

create trigger queue_tickets_prevent_duplicate_active_patient_queue
before insert or update of patient_id, queue_session_id, status
on public.queue_tickets
for each row execute function public.prevent_duplicate_active_patient_queue();

drop view if exists public.v_schedule_availability;

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
  schedule_date = local_today as is_current_local_date,
  case
    when schedule_date < local_today or (schedule_date = local_today and local_time >= end_time) then 'ended'
    when schedule_date > local_today or (schedule_date = local_today and local_time < start_time) then 'before_start'
    else 'operating'
  end as operational_phase,
  (
    status = 'open'
    and branch_is_active
    and polyclinic_is_active
    and doctor_is_active
    and queue_session_id is not null
    and queue_session_is_open
    and schedule_date = local_today
    and local_time < end_time
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
    when local_time >= end_time then 'Jam praktik selesai'
    when remaining_quota <= 0 then 'Kuota habis'
    when local_time < start_time then 'Nomor bisa diambil sekarang. Layanan mulai pukul ' || left(start_time::text, 5)
    else 'Siap diambil'
  end as availability_reason
from schedule_base;

grant select on public.v_schedule_availability to authenticated;

create or replace view public.v_queue_ticket_details
with (security_invoker = false) as
select
  qt.id as ticket_id,
  qt.queue_session_id,
  qt.patient_id,
  p.full_name as patient_name,
  qt.queue_number,
  qt.queue_code,
  qt.status,
  case
    when qt.status = 'waiting' then public.calculate_queue_wait_minutes(qt.queue_session_id, qt.queue_number)
    when qt.status in ('called', 'serving', 'missed') then 0
    else qt.estimated_wait_minutes
  end as estimated_wait_minutes,
  qt.created_at,
  qt.called_at,
  qt.serving_started_at,
  qt.completed_at,
  qs.current_number,
  qs.last_number,
  ds.id as schedule_id,
  ds.schedule_date,
  ds.start_time,
  ds.end_time,
  ds.average_service_minutes,
  cb.id as branch_id,
  cb.name as branch_name,
  cb.address as branch_address,
  pc.id as polyclinic_id,
  pc.name as polyclinic_name,
  pc.queue_prefix,
  d.id as doctor_id,
  d.full_name as doctor_name,
  d.specialization,
  qt.status_reason,
  qt.cancel_reason,
  qt.skipped_at,
  qt.cancelled_at,
  qt.expired_at,
  (
    select count(*)
    from public.queue_tickets ahead
    where ahead.queue_session_id = qt.queue_session_id
      and ahead.queue_number < qt.queue_number
      and ahead.status in ('waiting', 'called', 'serving')
  ) as remaining_before_me,
  qt.missed_count
from public.queue_tickets qt
join public.profiles p on p.id = qt.patient_id
join public.queue_sessions qs on qs.id = qt.queue_session_id
join public.doctor_schedules ds on ds.id = qs.schedule_id
join public.clinic_branches cb on cb.id = ds.branch_id
join public.polyclinics pc on pc.id = ds.polyclinic_id
join public.doctors d on d.id = ds.doctor_id
where qt.patient_id = auth.uid()
   or public.is_staff();

grant select on public.v_queue_ticket_details to authenticated;

create or replace view public.v_queue_ticket_timeline
with (security_invoker = false) as
select
  qe.id as event_id,
  qe.queue_ticket_id,
  qe.actor_id,
  actor.full_name as actor_name,
  case
    when qe.actor_id is null then 'system'
    when qe.actor_id = qtd.patient_id then 'patient'
    else 'staff'
  end as actor_type,
  qe.previous_status,
  qe.new_status,
  qe.message,
  qe.created_at,
  qtd.queue_code,
  qtd.patient_id
from public.queue_events qe
join public.v_queue_ticket_details qtd on qtd.ticket_id = qe.queue_ticket_id
left join public.profiles actor on actor.id = qe.actor_id
where qtd.patient_id = auth.uid()
   or public.is_staff();

grant select on public.v_queue_ticket_timeline to authenticated;

-- Keep patient schedule cards realtime after queue_sessions read access is
-- narrowed. Ticket changes touch the public schedule row, which is already in
-- the realtime publication and does not expose other patients' tickets.
create or replace function public.touch_queue_session_on_ticket_change()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_queue_session_id uuid := coalesce(new.queue_session_id, old.queue_session_id);
begin
  update public.queue_sessions
  set updated_at = now()
  where id = v_queue_session_id;

  update public.doctor_schedules ds
  set updated_at = now()
  from public.queue_sessions qs
  where qs.id = v_queue_session_id
    and ds.id = qs.schedule_id;

  return coalesce(new, old);
end;
$$;

