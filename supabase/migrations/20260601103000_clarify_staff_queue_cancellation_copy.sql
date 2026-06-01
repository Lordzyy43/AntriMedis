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
      case when p_new_status = 'skipped' then 'Antrean dilewati petugas' else 'Antrean dibatalkan petugas' end,
      case when p_new_status = 'skipped'
        then 'Nomor ' || v_ticket.queue_code || ' dilewati oleh petugas. Alasan: ' || v_reason
        else 'Nomor ' || v_ticket.queue_code || ' dibatalkan oleh petugas. Alasan: ' || v_reason
      end,
      jsonb_build_object(
        'ticket_id', v_ticket.id,
        'queue_code', v_ticket.queue_code,
        'reason', v_reason,
        'source', 'staff'
      )
    );
  end if;

  perform public.refresh_queue_estimates(v_ticket.queue_session_id);

  return v_ticket;
end;
$$;

grant execute on function public.update_queue_status(uuid, public.queue_status, text) to authenticated;
