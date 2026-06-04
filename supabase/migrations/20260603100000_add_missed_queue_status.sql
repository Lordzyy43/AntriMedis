alter type public.queue_status add value if not exists 'missed';
alter type public.notification_type add value if not exists 'queue_missed';

alter table public.queue_tickets
add column if not exists missed_count int not null default 0;
