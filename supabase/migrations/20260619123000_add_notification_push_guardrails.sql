create or replace function public.should_dispatch_notification_push(
  p_type public.notification_type
)
returns boolean
language sql
stable
set search_path = public
as $$
  select case p_type
    when 'queue_near'::public.notification_type then false
    else true
  end;
$$;

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
  if not public.should_dispatch_notification_push(new.type) then
    return new;
  end if;

  v_function_url := nullif(
    current_setting('app.fcm_push_function_url', true),
    ''
  );
  v_webhook_secret := nullif(
    current_setting('app.fcm_push_webhook_secret', true),
    ''
  );

  if v_function_url is null then
    select arc.value into v_function_url
    from public.app_runtime_config arc
    where arc.key = 'fcm_push_function_url';
  end if;

  if v_webhook_secret is null then
    select arc.value into v_webhook_secret
    from public.app_runtime_config arc
    where arc.key = 'fcm_push_webhook_secret';
  end if;

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

revoke all on function public.should_dispatch_notification_push(public.notification_type)
from public, anon, authenticated;
revoke all on function public.dispatch_notification_push()
from public, anon, authenticated;
