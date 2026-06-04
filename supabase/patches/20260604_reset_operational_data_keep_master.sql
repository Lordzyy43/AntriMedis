-- Reset operational queue data only.
-- Keeps clinics, branches, staff, roles, doctors, polyclinics, and patient/admin accounts.
-- Use this before demo or manual QA when you want a clean queue state.

begin;

with deleted_notifications as (
  delete from public.notifications
  where type::text like 'queue_%'
  returning 1
),
deleted_events as (
  delete from public.queue_events
  returning 1
),
deleted_tickets as (
  delete from public.queue_tickets
  returning 1
),
deleted_sessions as (
  delete from public.queue_sessions
  returning 1
),
deleted_schedules as (
  delete from public.doctor_schedules
  returning 1
)
select
  (select count(*) from deleted_notifications) as notifications_deleted,
  (select count(*) from deleted_events) as events_deleted,
  (select count(*) from deleted_tickets) as tickets_deleted,
  (select count(*) from deleted_sessions) as sessions_deleted,
  (select count(*) from deleted_schedules) as schedules_deleted;

commit;
