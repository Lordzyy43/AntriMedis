-- Make patient wait estimates dynamic and queue-aware.
-- Estimate only counts active tickets still ahead of the patient. Cancelled,
-- skipped, completed, and expired tickets no longer inflate wait time.

create or replace function public.refresh_queue_estimates(p_queue_session_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_average_minutes int;
begin
  select ds.average_service_minutes
  into v_average_minutes
  from public.queue_sessions qs
  join public.doctor_schedules ds on ds.id = qs.schedule_id
  where qs.id = p_queue_session_id;

  update public.queue_tickets target
  set estimated_wait_minutes =
    case
      when target.status = 'waiting' then
        (
          select count(*)
          from public.queue_tickets ahead
          where ahead.queue_session_id = target.queue_session_id
            and ahead.queue_number < target.queue_number
            and ahead.status in ('waiting', 'called', 'serving')
        ) * coalesce(v_average_minutes, 0)
      when target.status in ('called', 'serving') then 0
      else target.estimated_wait_minutes
    end
  where target.queue_session_id = p_queue_session_id
    and target.status in ('waiting', 'called', 'serving');
end;
$$;

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

  if v_local_time < v_schedule.start_time then
    raise exception 'Queue has not started yet';
  end if;

  if v_local_time > v_schedule.end_time then
    raise exception 'Queue can only be taken during schedule time';
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
    and qt.status in ('waiting', 'called', 'serving')
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

create or replace view public.v_queue_ticket_details
with (security_invoker = true) as
select
  qt.id as ticket_id,
  qt.queue_session_id,
  qt.patient_id,
  p.full_name as patient_name,
  qt.queue_number,
  qt.queue_code,
  qt.status,
  qt.estimated_wait_minutes,
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
  ) as remaining_before_me
from public.queue_tickets qt
join public.profiles p on p.id = qt.patient_id
join public.queue_sessions qs on qs.id = qt.queue_session_id
join public.doctor_schedules ds on ds.id = qs.schedule_id
join public.clinic_branches cb on cb.id = ds.branch_id
join public.polyclinics pc on pc.id = ds.polyclinic_id
join public.doctors d on d.id = ds.doctor_id;

revoke all on function public.refresh_queue_estimates(uuid) from public, anon, authenticated;
