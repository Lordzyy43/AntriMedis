create unique index if not exists push_delivery_logs_notification_device_once_idx
on public.push_delivery_logs(notification_id, user_device_token_id)
where notification_id is not null
  and user_device_token_id is not null
  and status in ('sent', 'invalid_token');
