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
  v_reason text := 'Sesi ditutup petugas sebelum nomor dipanggil';
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
        status_reason = v_reason,
        expired_at = now()
    where queue_session_id = p_queue_session_id
      and status = 'waiting'
    returning id, patient_id, queue_code
  ),
  inserted_events as (
    insert into public.queue_events (
      queue_ticket_id,
      actor_id,
      previous_status,
      new_status,
      message
    )
    select
      id,
      auth.uid(),
      'waiting',
      'expired',
      v_reason
    from expired_tickets
    returning queue_ticket_id
  ),
  inserted_notifications as (
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

  update public.queue_sessions
  set is_open = false,
      closed_at = coalesce(closed_at, now())
  where id = p_queue_session_id;

  perform public.refresh_queue_estimates(p_queue_session_id);

  return jsonb_build_object(
    'queue_session_id', p_queue_session_id,
    'expired_count', v_expired_count,
    'closed_at', now()
  );
end;
$$;

grant execute on function public.close_queue_session(uuid) to authenticated;
