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

create or replace function public.create_queue_ticket(p_queue_session_id uuid)
returns public.queue_tickets
language plpgsql
security definer
set search_path = public
as $$
declare
  v_session public.queue_sessions%rowtype;
  v_schedule public.doctor_schedules%rowtype;
  v_polyclinic public.polyclinics%rowtype;
  v_branch_is_active boolean;
  v_doctor_is_active boolean;
  v_local_today date := timezone('Asia/Jakarta', now())::date;
  v_local_time time := timezone('Asia/Jakarta', now())::time;
  v_next_number int;
  v_queue_code text;
  v_ticket public.queue_tickets%rowtype;
  v_existing_active int;
  v_taken_count int;
begin
  if auth.uid() is null then
    raise exception 'Unauthorized';
  end if;

  select * into v_session
  from public.queue_sessions
  where id = p_queue_session_id
  for update;

  if not found then
    raise exception 'Queue session not found';
  end if;

  if v_session.is_open = false then
    raise exception 'Queue session is closed';
  end if;

  select * into v_schedule
  from public.doctor_schedules
  where id = v_session.schedule_id;

  if not found then
    raise exception 'Schedule not found';
  end if;

  if v_schedule.status <> 'open' then
    raise exception 'Schedule is not open';
  end if;

  if v_schedule.schedule_date < v_local_today then
    raise exception 'Schedule date has passed';
  end if;

  if v_schedule.schedule_date > v_local_today then
    raise exception 'Queue can only be taken on the service date';
  end if;

  if v_local_time >= v_schedule.end_time then
    raise exception 'Queue can only be taken before schedule end time';
  end if;

  select is_active into v_branch_is_active
  from public.clinic_branches
  where id = v_schedule.branch_id;

  if coalesce(v_branch_is_active, false) = false then
    raise exception 'Clinic branch is not active';
  end if;

  select * into v_polyclinic
  from public.polyclinics
  where id = v_schedule.polyclinic_id;

  if not found or v_polyclinic.is_active = false then
    raise exception 'Polyclinic is not active';
  end if;

  select is_active into v_doctor_is_active
  from public.doctors
  where id = v_schedule.doctor_id;

  if coalesce(v_doctor_is_active, false) = false then
    raise exception 'Doctor is not active';
  end if;

  select count(*) into v_taken_count
  from public.queue_tickets
  where queue_session_id = p_queue_session_id
    and status <> 'cancelled';

  if v_taken_count >= v_schedule.quota_limit then
    raise exception 'Queue quota is full';
  end if;

  select count(*) into v_existing_active
  from public.queue_tickets qt
  join public.queue_sessions qs on qs.id = qt.queue_session_id
  join public.doctor_schedules ds on ds.id = qs.schedule_id
  where qt.patient_id = auth.uid()
    and qt.status in ('waiting', 'called', 'serving', 'missed')
    and ds.branch_id = v_schedule.branch_id
    and ds.schedule_date = v_schedule.schedule_date;

  if v_existing_active > 0 then
    raise exception 'Patient already has active queue today';
  end if;

  v_next_number := v_session.last_number + 1;
  v_queue_code := v_polyclinic.queue_prefix || lpad(v_next_number::text, 3, '0');

  update public.queue_sessions
  set last_number = v_next_number
  where id = p_queue_session_id;

  insert into public.queue_tickets (
    queue_session_id,
    patient_id,
    queue_number,
    queue_code,
    status,
    estimated_wait_minutes
  ) values (
    p_queue_session_id,
    auth.uid(),
    v_next_number,
    v_queue_code,
    'waiting',
    0
  )
  returning * into v_ticket;

  insert into public.queue_events (
    queue_ticket_id,
    actor_id,
    previous_status,
    new_status,
    message
  ) values (
    v_ticket.id,
    auth.uid(),
    null,
    'waiting',
    'Queue ticket created'
  );

  insert into public.notifications (user_id, type, title, body, data)
  values (
    auth.uid(),
    'queue_created',
    'Nomor antrean berhasil dibuat',
    'Nomor antrean Anda adalah ' || v_ticket.queue_code,
    jsonb_build_object('ticket_id', v_ticket.id, 'queue_code', v_ticket.queue_code)
  );

  perform public.refresh_queue_estimates(p_queue_session_id);

  select * into v_ticket
  from public.queue_tickets
  where id = v_ticket.id;

  return v_ticket;
end;
$$;

grant execute on function public.create_queue_ticket(uuid) to authenticated;
