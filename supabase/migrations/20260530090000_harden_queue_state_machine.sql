-- Harden queue business rules for production-like operation.
-- This migration keeps every status change inside an explicit state machine,
-- prevents patients from holding multiple same-day active queues in one branch,
-- and adds a patient-owned cancellation RPC for mobile.

create or replace function public.validate_queue_ticket_status_transition()
returns trigger
language plpgsql
set search_path = public
as $$
begin
  if new.status = old.status then
    return new;
  end if;

  if old.status = 'waiting'
     and new.status in ('called', 'skipped', 'cancelled', 'expired') then
    return new;
  end if;

  if old.status = 'called'
     and new.status in ('serving', 'skipped', 'cancelled', 'expired') then
    return new;
  end if;

  if old.status = 'serving'
     and new.status in ('completed', 'skipped', 'cancelled', 'expired') then
    return new;
  end if;

  raise exception 'Invalid queue status transition from % to %', old.status, new.status;
end;
$$;

drop trigger if exists queue_tickets_validate_status_transition on public.queue_tickets;

create trigger queue_tickets_validate_status_transition
before update of status on public.queue_tickets
for each row execute function public.validate_queue_ticket_status_transition();

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

  select * into v_polyclinic
  from public.polyclinics
  where id = v_schedule.polyclinic_id;

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
    greatest((v_next_number - v_session.current_number - 1), 0) * v_schedule.average_service_minutes
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

  return v_ticket;
end;
$$;

create or replace function public.call_next_queue(p_queue_session_id uuid)
returns public.queue_tickets
language plpgsql
security definer
set search_path = public
as $$
declare
  v_ticket public.queue_tickets%rowtype;
  v_session public.queue_sessions%rowtype;
  v_schedule public.doctor_schedules%rowtype;
  v_unresolved_count int;
begin
  if not public.is_staff() then
    raise exception 'Forbidden';
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

  select count(*) into v_unresolved_count
  from public.queue_tickets
  where queue_session_id = p_queue_session_id
    and status in ('called', 'serving');

  if v_unresolved_count > 0 then
    raise exception 'Current queue must be resolved before calling next';
  end if;

  select * into v_ticket
  from public.queue_tickets
  where queue_session_id = p_queue_session_id
    and status = 'waiting'
  order by queue_number asc
  limit 1
  for update skip locked;

  if not found then
    raise exception 'No waiting queue found';
  end if;

  update public.queue_tickets
  set status = 'called',
      called_at = now()
  where id = v_ticket.id
  returning * into v_ticket;

  update public.queue_sessions
  set current_number = v_ticket.queue_number
  where id = p_queue_session_id;

  perform public.refresh_queue_estimates(p_queue_session_id);

  insert into public.queue_events (
    queue_ticket_id,
    actor_id,
    previous_status,
    new_status,
    message
  ) values (
    v_ticket.id,
    auth.uid(),
    'waiting',
    'called',
    'Queue called by staff'
  );

  insert into public.notifications (user_id, type, title, body, data)
  values (
    v_ticket.patient_id,
    'queue_called',
    'Nomor antrean dipanggil',
    'Nomor ' || v_ticket.queue_code || ' sedang dipanggil.',
    jsonb_build_object('ticket_id', v_ticket.id, 'queue_code', v_ticket.queue_code)
  );

  return v_ticket;
end;
$$;

create or replace function public.update_queue_status(
  p_ticket_id uuid,
  p_new_status public.queue_status,
  p_message text default null
)
returns public.queue_tickets
language plpgsql
security definer
set search_path = public
as $$
declare
  v_ticket public.queue_tickets%rowtype;
  v_old_status public.queue_status;
begin
  if not public.is_staff() then
    raise exception 'Forbidden';
  end if;

  select * into v_ticket
  from public.queue_tickets
  where id = p_ticket_id
  for update;

  if not found then
    raise exception 'Queue ticket not found';
  end if;

  v_old_status := v_ticket.status;

  if v_old_status = p_new_status then
    return v_ticket;
  end if;

  if not (
    (v_old_status = 'waiting' and p_new_status in ('skipped', 'cancelled', 'expired')) or
    (v_old_status = 'called' and p_new_status in ('serving', 'skipped', 'cancelled', 'expired')) or
    (v_old_status = 'serving' and p_new_status in ('completed', 'skipped', 'cancelled', 'expired'))
  ) then
    raise exception 'Invalid queue status transition from % to %', v_old_status, p_new_status;
  end if;

  update public.queue_tickets
  set status = p_new_status,
      serving_started_at = case when p_new_status = 'serving' then now() else serving_started_at end,
      completed_at = case when p_new_status = 'completed' then now() else completed_at end,
      skipped_at = case when p_new_status = 'skipped' then now() else skipped_at end,
      cancelled_at = case when p_new_status = 'cancelled' then now() else cancelled_at end,
      expired_at = case when p_new_status = 'expired' then now() else expired_at end
  where id = p_ticket_id
  returning * into v_ticket;

  insert into public.queue_events (
    queue_ticket_id,
    actor_id,
    previous_status,
    new_status,
    message
  ) values (
    p_ticket_id,
    auth.uid(),
    v_old_status,
    p_new_status,
    coalesce(p_message, 'Queue status updated')
  );

  if p_new_status in ('skipped', 'cancelled') then
    insert into public.notifications (user_id, type, title, body, data)
    values (
      v_ticket.patient_id,
      case when p_new_status = 'skipped' then 'queue_skipped' else 'queue_cancelled' end,
      case when p_new_status = 'skipped' then 'Antrean dilewati' else 'Antrean dibatalkan' end,
      case when p_new_status = 'skipped'
        then 'Nomor ' || v_ticket.queue_code || ' dilewati oleh petugas.'
        else 'Nomor ' || v_ticket.queue_code || ' dibatalkan.'
      end,
      jsonb_build_object('ticket_id', v_ticket.id, 'queue_code', v_ticket.queue_code)
    );
  end if;

  perform public.refresh_queue_estimates(v_ticket.queue_session_id);

  return v_ticket;
end;
$$;

create or replace function public.cancel_my_ticket(
  p_ticket_id uuid,
  p_message text default 'Dibatalkan oleh pasien'
)
returns public.queue_tickets
language plpgsql
security definer
set search_path = public
as $$
declare
  v_ticket public.queue_tickets%rowtype;
begin
  if auth.uid() is null then
    raise exception 'Unauthorized';
  end if;

  select * into v_ticket
  from public.queue_tickets
  where id = p_ticket_id
    and patient_id = auth.uid()
  for update;

  if not found then
    raise exception 'Queue ticket not found';
  end if;

  if v_ticket.status <> 'waiting' then
    raise exception 'Only waiting queue can be cancelled by patient';
  end if;

  update public.queue_tickets
  set status = 'cancelled',
      cancel_reason = p_message,
      cancelled_at = now()
  where id = p_ticket_id
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
    'waiting',
    'cancelled',
    p_message
  );

  insert into public.notifications (user_id, type, title, body, data)
  values (
    auth.uid(),
    'queue_cancelled',
    'Antrean dibatalkan',
    'Nomor ' || v_ticket.queue_code || ' berhasil dibatalkan.',
    jsonb_build_object('ticket_id', v_ticket.id, 'queue_code', v_ticket.queue_code)
  );

  perform public.refresh_queue_estimates(v_ticket.queue_session_id);

  return v_ticket;
end;
$$;

grant execute on function public.cancel_my_ticket(uuid, text) to authenticated;
