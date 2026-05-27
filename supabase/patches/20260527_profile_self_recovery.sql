do $$
begin
  if not exists (
    select 1
    from pg_policies
    where schemaname = 'public'
      and tablename = 'profiles'
      and policyname = 'Users can create own profile'
  ) then
    create policy "Users can create own profile"
    on public.profiles for insert to authenticated
    with check (id = auth.uid());
  end if;
end $$;

create or replace function public.upsert_my_profile(
  p_full_name text,
  p_phone_number text,
  p_gender public.gender_type,
  p_birth_date date default null,
  p_avatar_url text default null
)
returns public.profiles
language plpgsql
security definer
set search_path = public
as $$
declare
  v_profile public.profiles%rowtype;
begin
  if auth.uid() is null then
    raise exception 'Unauthorized';
  end if;

  insert into public.profiles (
    id,
    full_name,
    phone_number,
    gender,
    birth_date,
    avatar_url
  )
  values (
    auth.uid(),
    p_full_name,
    p_phone_number,
    p_gender,
    p_birth_date,
    nullif(p_avatar_url, '')
  )
  on conflict (id) do update
  set full_name = excluded.full_name,
      phone_number = excluded.phone_number,
      gender = excluded.gender,
      birth_date = excluded.birth_date,
      avatar_url = coalesce(excluded.avatar_url, public.profiles.avatar_url)
  returning * into v_profile;

  return v_profile;
end;
$$;

grant execute on function public.upsert_my_profile(
  text,
  text,
  public.gender_type,
  date,
  text
) to authenticated;
