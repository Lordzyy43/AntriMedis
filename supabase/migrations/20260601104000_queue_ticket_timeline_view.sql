create or replace view public.v_queue_ticket_timeline
with (security_invoker = true) as
select
  qe.id as event_id,
  qe.queue_ticket_id,
  qe.actor_id,
  actor.full_name as actor_name,
  case
    when qe.actor_id is null then 'system'
    when qe.actor_id = qtd.patient_id then 'patient'
    else 'staff'
  end as actor_type,
  qe.previous_status,
  qe.new_status,
  qe.message,
  qe.created_at,
  qtd.queue_code,
  qtd.patient_id
from public.queue_events qe
join public.v_queue_ticket_details qtd on qtd.ticket_id = qe.queue_ticket_id
left join public.profiles actor on actor.id = qe.actor_id;

grant select on public.v_queue_ticket_timeline to authenticated;
