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
    raise exception 'Queue calling is only allowed on the service date';
  end if;

  if v_local_time < v_schedule.start_time then
    raise exception 'Queue calling is only allowed after schedule start time';
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
    case
      when v_local_time > v_schedule.end_time then
        'Queue called by staff after schedule end time'
      else
        'Queue called by staff'
    end
  );

  insert into public.notifications (user_id, type, title, body, data)
  values (
    v_ticket.patient_id,
    'queue_called'::public.notification_type,
    'Nomor antrean dipanggil',
    'Nomor ' || v_ticket.queue_code || ' sedang dipanggil.',
    jsonb_build_object('ticket_id', v_ticket.id, 'queue_code', v_ticket.queue_code)
  );

  return v_ticket;
end;
$$;

grant execute on function public.call_next_queue(uuid) to authenticated;
