-- Keep patient schedule cards realtime when ticket status changes affect quota.
-- Patients can subscribe to queue_sessions, so touching the session gives the
-- mobile app a safe realtime signal without exposing other patients' tickets.

create or replace function public.touch_queue_session_on_ticket_change()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  update public.queue_sessions
  set updated_at = now()
  where id = coalesce(new.queue_session_id, old.queue_session_id);

  return coalesce(new, old);
end;
$$;

drop trigger if exists queue_tickets_touch_queue_session on public.queue_tickets;

create trigger queue_tickets_touch_queue_session
after insert or update of status or delete on public.queue_tickets
for each row execute function public.touch_queue_session_on_ticket_change();
