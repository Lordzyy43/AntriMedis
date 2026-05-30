-- Operational event feed for admin dashboard.
-- This view keeps the dashboard tied to queue_events instead of deriving
-- activity from the latest ticket rows.

create or replace view public.v_queue_event_feed
with (security_invoker = true) as
select
  qe.id as event_id,
  qe.queue_ticket_id,
  qe.actor_id,
  qe.previous_status,
  qe.new_status,
  qe.message,
  qe.created_at,
  qtd.queue_code,
  qtd.patient_id,
  qtd.patient_name,
  qtd.polyclinic_name,
  qtd.doctor_name,
  qtd.branch_name,
  qtd.schedule_date,
  qtd.start_time,
  qtd.end_time
from public.queue_events qe
join public.v_queue_ticket_details qtd on qtd.ticket_id = qe.queue_ticket_id;

grant select on public.v_queue_event_feed to authenticated;
