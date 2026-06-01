alter table public.queue_tickets
add column if not exists status_reason text;

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
  v_reason text;
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
  v_reason := nullif(trim(coalesce(p_message, '')), '');

  if v_old_status = p_new_status then
    return v_ticket;
  end if;

  if p_new_status in ('skipped', 'cancelled') and v_reason is null then
    raise exception 'Reason is required for skipped or cancelled queue';
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
      status_reason = case
        when p_new_status in ('skipped', 'cancelled', 'expired') then v_reason
        else status_reason
      end,
      cancel_reason = case when p_new_status = 'cancelled' then v_reason else cancel_reason end,
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
    coalesce(v_reason, p_message, 'Queue status updated')
  );

  if p_new_status in ('skipped', 'cancelled') then
    insert into public.notifications (user_id, type, title, body, data)
    values (
      v_ticket.patient_id,
      (case
        when p_new_status = 'skipped' then 'queue_skipped'
        else 'queue_cancelled'
      end)::public.notification_type,
      case when p_new_status = 'skipped' then 'Antrean dilewati' else 'Antrean dibatalkan' end,
      case when p_new_status = 'skipped'
        then 'Nomor ' || v_ticket.queue_code || ' dilewati oleh petugas. Alasan: ' || v_reason
        else 'Nomor ' || v_ticket.queue_code || ' dibatalkan. Alasan: ' || v_reason
      end,
      jsonb_build_object(
        'ticket_id', v_ticket.id,
        'queue_code', v_ticket.queue_code,
        'reason', v_reason
      )
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
  v_reason text;
begin
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

  v_reason := coalesce(nullif(trim(p_message), ''), 'Dibatalkan oleh pasien');

  update public.queue_tickets
  set status = 'cancelled',
      status_reason = v_reason,
      cancel_reason = v_reason,
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
    v_reason
  );

  insert into public.notifications (user_id, type, title, body, data)
  values (
    auth.uid(),
    'queue_cancelled',
    'Antrean dibatalkan',
    'Nomor ' || v_ticket.queue_code || ' berhasil dibatalkan.',
    jsonb_build_object('ticket_id', v_ticket.id, 'queue_code', v_ticket.queue_code, 'reason', v_reason)
  );

  perform public.refresh_queue_estimates(v_ticket.queue_session_id);

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
  qt.expired_at
from public.queue_tickets qt
join public.profiles p on p.id = qt.patient_id
join public.queue_sessions qs on qs.id = qt.queue_session_id
join public.doctor_schedules ds on ds.id = qs.schedule_id
join public.clinic_branches cb on cb.id = ds.branch_id
join public.polyclinics pc on pc.id = ds.polyclinic_id
join public.doctors d on d.id = ds.doctor_id;

grant execute on function public.update_queue_status(uuid, public.queue_status, text) to authenticated;
grant execute on function public.cancel_my_ticket(uuid, text) to authenticated;
