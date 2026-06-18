create extension if not exists pg_net with schema extensions;

create or replace function public.dispatch_notification_push()
returns trigger
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_function_url text;
  v_webhook_secret text;
begin
  v_function_url := nullif(
    current_setting('app.fcm_push_function_url', true),
    ''
  );
  v_webhook_secret := nullif(
    current_setting('app.fcm_push_webhook_secret', true),
    ''
  );

  if v_function_url is null or v_webhook_secret is null then
    return new;
  end if;

  perform net.http_post(
    url := v_function_url,
    headers := jsonb_build_object(
      'Content-Type',
      'application/json',
      'x-push-webhook-secret',
      v_webhook_secret
    ),
    body := jsonb_build_object('notification_id', new.id),
    timeout_milliseconds := 5000
  );

  return new;
exception
  when others then
    return new;
end;
$$;

drop trigger if exists notifications_dispatch_push
on public.notifications;

create trigger notifications_dispatch_push
after insert on public.notifications
for each row execute function public.dispatch_notification_push();

revoke all on function public.dispatch_notification_push()
from public, anon, authenticated;
