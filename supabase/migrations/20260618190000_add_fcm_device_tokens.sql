create table if not exists public.user_device_tokens (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  fcm_token text not null,
  platform text not null check (platform in ('android', 'ios', 'web', 'unknown')),
  device_name text,
  is_active boolean not null default true,
  last_seen_at timestamptz not null default now(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (fcm_token)
);

create index if not exists user_device_tokens_user_id_idx
on public.user_device_tokens(user_id);

create index if not exists user_device_tokens_active_user_id_idx
on public.user_device_tokens(user_id)
where is_active;

create table if not exists public.push_delivery_logs (
  id uuid primary key default gen_random_uuid(),
  notification_id uuid references public.notifications(id) on delete set null,
  user_device_token_id uuid references public.user_device_tokens(id) on delete set null,
  fcm_token text,
  status text not null check (
    status in ('queued', 'sent', 'failed', 'invalid_token')
  ),
  provider_message_id text,
  error_code text,
  error_message text,
  sent_at timestamptz,
  failed_at timestamptz,
  created_at timestamptz not null default now()
);

create index if not exists push_delivery_logs_notification_id_idx
on public.push_delivery_logs(notification_id);

create index if not exists push_delivery_logs_user_device_token_id_idx
on public.push_delivery_logs(user_device_token_id);

drop trigger if exists user_device_tokens_touch_updated_at
on public.user_device_tokens;

create trigger user_device_tokens_touch_updated_at
before update on public.user_device_tokens
for each row execute function public.touch_updated_at();

alter table public.user_device_tokens enable row level security;
alter table public.push_delivery_logs enable row level security;

create policy "Users can read own device tokens"
on public.user_device_tokens for select to authenticated
using (user_id = auth.uid());

create policy "Users can insert own device tokens"
on public.user_device_tokens for insert to authenticated
with check (user_id = auth.uid());

create policy "Users can update own device tokens"
on public.user_device_tokens for update to authenticated
using (user_id = auth.uid())
with check (user_id = auth.uid());

create policy "Staff can read push delivery logs"
on public.push_delivery_logs for select to authenticated
using (public.is_staff());

create or replace function public.register_fcm_token(
  p_fcm_token text,
  p_platform text,
  p_seen_at timestamptz default now(),
  p_device_name text default null
)
returns public.user_device_tokens
language plpgsql
security definer
set search_path = public
as $$
declare
  v_token public.user_device_tokens;
  v_platform text;
begin
  if auth.uid() is null then
    raise exception 'Authentication required';
  end if;

  if nullif(trim(p_fcm_token), '') is null then
    raise exception 'FCM token is required';
  end if;

  v_platform := lower(coalesce(nullif(trim(p_platform), ''), 'unknown'));
  if v_platform not in ('android', 'ios', 'web', 'unknown') then
    v_platform := 'unknown';
  end if;

  insert into public.user_device_tokens (
    user_id,
    fcm_token,
    platform,
    device_name,
    is_active,
    last_seen_at
  )
  values (
    auth.uid(),
    trim(p_fcm_token),
    v_platform,
    nullif(trim(p_device_name), ''),
    true,
    coalesce(p_seen_at, now())
  )
  on conflict (fcm_token) do update
  set
    user_id = excluded.user_id,
    platform = excluded.platform,
    device_name = excluded.device_name,
    is_active = true,
    last_seen_at = excluded.last_seen_at,
    updated_at = now()
  returning * into v_token;

  return v_token;
end;
$$;

create or replace function public.deactivate_fcm_token(
  p_fcm_token text,
  p_seen_at timestamptz default now()
)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if auth.uid() is null then
    raise exception 'Authentication required';
  end if;

  update public.user_device_tokens
  set
    is_active = false,
    last_seen_at = coalesce(p_seen_at, now()),
    updated_at = now()
  where user_id = auth.uid()
    and fcm_token = trim(p_fcm_token);
end;
$$;

revoke all on function public.register_fcm_token(text, text, timestamptz, text)
from public, anon;
revoke all on function public.deactivate_fcm_token(text, timestamptz)
from public, anon;
grant execute on function public.register_fcm_token(text, text, timestamptz, text)
to authenticated;
grant execute on function public.deactivate_fcm_token(text, timestamptz)
to authenticated;
