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
     and new.status in ('serving', 'missed', 'skipped', 'cancelled', 'expired') then
    return new;
  end if;

  if old.status = 'missed'
     and new.status in ('called', 'skipped', 'cancelled', 'expired') then
    return new;
  end if;

  if old.status = 'serving'
     and new.status in ('completed', 'skipped', 'cancelled', 'expired') then
    return new;
  end if;

  raise exception 'Invalid queue status transition from % to %', old.status, new.status;
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
  v_reason text := coalesce(nullif(trim(p_message), ''), 'Queue status updated');
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
    (v_old_status = 'called' and p_new_status in ('serving', 'missed', 'skipped', 'cancelled', 'expired')) or
    (v_old_status = 'missed' and p_new_status in ('skipped', 'cancelled', 'expired')) or
    (v_old_status = 'serving' and p_new_status in ('completed', 'skipped', 'cancelled', 'expired'))
  ) then
    raise exception 'Invalid queue status transition from % to %', v_old_status, p_new_status;
  end if;

  if v_old_status = 'called' and p_new_status = 'missed' and v_ticket.missed_count >= 1 then
    raise exception 'Queue can only be missed once before final resolution';
  end if;

  update public.queue_tickets
  set status = p_new_status,
      status_reason = case
        when p_new_status in ('missed', 'skipped', 'cancelled', 'expired') then v_reason
        else status_reason
      end,
      cancel_reason = case when p_new_status = 'cancelled' then v_reason else cancel_reason end,
      missed_count = case when p_new_status = 'missed' then missed_count + 1 else missed_count end,
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
    v_reason
  );

  if p_new_status in ('missed', 'skipped', 'cancelled', 'expired') then
    insert into public.notifications (user_id, type, title, body, data)
    values (
      v_ticket.patient_id,
      case
        when p_new_status = 'missed' then 'queue_missed'
        when p_new_status = 'skipped' then 'queue_skipped'
        when p_new_status = 'expired' then 'queue_expired'
        else 'queue_cancelled'
      end::public.notification_type,
      case
        when p_new_status = 'missed' then 'Nomor antrean terlewat'
        when p_new_status = 'skipped' then 'Antrean dilewati'
        when p_new_status = 'expired' then 'Antrean kedaluwarsa'
        else 'Antrean dibatalkan'
      end,
      case
        when p_new_status = 'missed' then 'Nomor ' || v_ticket.queue_code || ' terlewat. Petugas dapat memanggil ulang setelah antrean reguler habis.'
        when p_new_status = 'skipped' then 'Nomor ' || v_ticket.queue_code || ' dilewati oleh petugas.'
        when p_new_status = 'expired' then 'Nomor ' || v_ticket.queue_code || ' kedaluwarsa.'
        else 'Nomor ' || v_ticket.queue_code || ' dibatalkan.'
      end,
      jsonb_build_object('ticket_id', v_ticket.id, 'queue_code', v_ticket.queue_code)
    );
  end if;

  perform public.refresh_queue_estimates(v_ticket.queue_session_id);

  return v_ticket;
end;
$$;

create or replace function public.recall_missed_queue(p_queue_session_id uuid)
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
  v_waiting_count int;
  v_local_today date := timezone('Asia/Jakarta', now())::date;
  v_local_time time := timezone('Asia/Jakarta', now())::time;
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

  if v_schedule.schedule_date <> v_local_today then
    raise exception 'Queue recall is only allowed on the service date';
  end if;

  if v_local_time < v_schedule.start_time then
    raise exception 'Queue recall is only allowed after schedule start time';
  end if;

  select count(*) into v_unresolved_count
  from public.queue_tickets
  where queue_session_id = p_queue_session_id
    and status in ('called', 'serving');

  if v_unresolved_count > 0 then
    raise exception 'Current queue must be resolved before recalling missed queue';
  end if;

  select count(*) into v_waiting_count
  from public.queue_tickets
  where queue_session_id = p_queue_session_id
    and status = 'waiting';

  if v_waiting_count > 0 then
    raise exception 'Regular waiting queues must be completed before recalling missed queue';
  end if;

  select * into v_ticket
  from public.queue_tickets
  where queue_session_id = p_queue_session_id
    and status = 'missed'
  order by queue_number asc
  limit 1
  for update skip locked;

  if not found then
    raise exception 'No missed queue found';
  end if;

  update public.queue_tickets
  set status = 'called',
      called_at = now(),
      status_reason = null
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
    'missed',
    'called',
    'Queue recalled by staff'
  );

  insert into public.notifications (user_id, type, title, body, data)
  values (
    v_ticket.patient_id,
    'queue_called'::public.notification_type,
    'Nomor antrean dipanggil ulang',
    'Nomor ' || v_ticket.queue_code || ' dipanggil ulang. Silakan menuju poli.',
    jsonb_build_object('ticket_id', v_ticket.id, 'queue_code', v_ticket.queue_code)
  );

  return v_ticket;
end;
$$;

create or replace function public.close_queue_session(p_queue_session_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_session public.queue_sessions%rowtype;
  v_blocking_count int;
  v_expired_count int := 0;
  v_skipped_missed_count int := 0;
  v_expired_reason text := 'Sesi ditutup petugas sebelum nomor dipanggil';
  v_skipped_reason text := 'Sesi ditutup petugas setelah nomor terlewat dan tidak dipanggil ulang';
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
    raise exception 'Queue session is already closed';
  end if;

  select count(*) into v_blocking_count
  from public.queue_tickets
  where queue_session_id = p_queue_session_id
    and status in ('called', 'serving');

  if v_blocking_count > 0 then
    raise exception 'Resolve called or serving queues before closing session';
  end if;

  with expired_tickets as (
    update public.queue_tickets
    set status = 'expired',
        status_reason = v_expired_reason,
        expired_at = now()
    where queue_session_id = p_queue_session_id
      and status = 'waiting'
    returning id, patient_id, queue_code
  ),
  inserted_expired_events as (
    insert into public.queue_events (
      queue_ticket_id,
      actor_id,
      previous_status,
      new_status,
      message
    )
    select id, auth.uid(), 'waiting', 'expired', v_expired_reason
    from expired_tickets
    returning queue_ticket_id
  ),
  inserted_expired_notifications as (
    insert into public.notifications (user_id, type, title, body, data)
    select
      patient_id,
      'queue_expired'::public.notification_type,
      'Antrean kedaluwarsa',
      'Nomor ' || queue_code || ' kedaluwarsa karena sesi layanan telah ditutup.',
      jsonb_build_object('ticket_id', id, 'queue_code', queue_code)
    from expired_tickets
    returning id
  )
  select count(*) into v_expired_count
  from expired_tickets;

  with skipped_missed_tickets as (
    update public.queue_tickets
    set status = 'skipped',
        status_reason = v_skipped_reason,
        skipped_at = now()
    where queue_session_id = p_queue_session_id
      and status = 'missed'
    returning id, patient_id, queue_code
  ),
  inserted_skipped_events as (
    insert into public.queue_events (
      queue_ticket_id,
      actor_id,
      previous_status,
      new_status,
      message
    )
    select id, auth.uid(), 'missed', 'skipped', v_skipped_reason
    from skipped_missed_tickets
    returning queue_ticket_id
  ),
  inserted_skipped_notifications as (
    insert into public.notifications (user_id, type, title, body, data)
    select
      patient_id,
      'queue_skipped'::public.notification_type,
      'Antrean dilewati',
      'Nomor ' || queue_code || ' dilewati karena sesi layanan telah ditutup.',
      jsonb_build_object('ticket_id', id, 'queue_code', queue_code)
    from skipped_missed_tickets
    returning id
  )
  select count(*) into v_skipped_missed_count
  from skipped_missed_tickets;

  update public.queue_sessions
  set is_open = false,
      closed_at = coalesce(closed_at, now())
  where id = p_queue_session_id;

  perform public.refresh_queue_estimates(p_queue_session_id);

  return jsonb_build_object(
    'queue_session_id', p_queue_session_id,
    'expired_count', v_expired_count,
    'skipped_missed_count', v_skipped_missed_count,
    'closed_at', now()
  );
end;
$$;

grant execute on function public.update_queue_status(uuid, public.queue_status, text) to authenticated;
grant execute on function public.recall_missed_queue(uuid) to authenticated;
grant execute on function public.close_queue_session(uuid) to authenticated;
