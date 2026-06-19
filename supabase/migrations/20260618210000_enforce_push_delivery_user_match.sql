create or replace function public.ensure_push_delivery_user_match()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_notification_user_id uuid;
  v_token_user_id uuid;
begin
  if new.notification_id is null or new.user_device_token_id is null then
    return new;
  end if;

  select n.user_id into v_notification_user_id
  from public.notifications n
  where n.id = new.notification_id;

  select udt.user_id into v_token_user_id
  from public.user_device_tokens udt
  where udt.id = new.user_device_token_id;

  if v_notification_user_id is distinct from v_token_user_id then
    raise exception 'Push delivery user mismatch';
  end if;

  return new;
end;
$$;

drop trigger if exists push_delivery_logs_user_match
on public.push_delivery_logs;

create trigger push_delivery_logs_user_match
before insert or update of notification_id, user_device_token_id
on public.push_delivery_logs
for each row execute function public.ensure_push_delivery_user_match();

revoke all on function public.ensure_push_delivery_user_match()
from public, anon, authenticated;
