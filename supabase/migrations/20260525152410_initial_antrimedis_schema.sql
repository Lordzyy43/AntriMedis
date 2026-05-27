-- AntriMedis initial database schema.
-- Focus: Flutter patient app, web admin, real-time queue tracking.

create extension if not exists "pgcrypto";
create extension if not exists "uuid-ossp";

create type public.gender_type as enum ('male', 'female', 'other');
create type public.queue_status as enum (
  'waiting',
  'called',
  'serving',
  'completed',
  'skipped',
  'cancelled',
  'expired'
);
create type public.schedule_status as enum ('open', 'closed', 'full', 'cancelled');
create type public.notification_type as enum (
  'queue_created',
  'queue_near',
  'queue_called',
  'queue_skipped',
  'queue_cancelled',
  'schedule_changed'
);

create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  full_name text not null,
  phone_number text,
  birth_date date,
  gender public.gender_type,
  avatar_url text,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.roles (
  id bigserial primary key,
  code text not null unique,
  name text not null,
  description text,
  created_at timestamptz not null default now()
);

create table public.user_roles (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  role_id bigint not null references public.roles(id) on delete cascade,
  created_at timestamptz not null default now(),
  unique(user_id, role_id)
);

create table public.clinics (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  description text,
  logo_url text,
  phone_number text,
  email text,
  website text,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.clinic_branches (
  id uuid primary key default gen_random_uuid(),
  clinic_id uuid not null references public.clinics(id) on delete cascade,
  name text not null,
  address text not null,
  city text,
  province text,
  latitude numeric(10, 7),
  longitude numeric(10, 7),
  phone_number text,
  open_time time,
  close_time time,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.clinic_staff (
  id uuid primary key default gen_random_uuid(),
  branch_id uuid not null references public.clinic_branches(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  staff_title text,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  unique(branch_id, user_id)
);

create table public.polyclinics (
  id uuid primary key default gen_random_uuid(),
  branch_id uuid not null references public.clinic_branches(id) on delete cascade,
  name text not null,
  code text not null,
  description text,
  queue_prefix text not null,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(branch_id, code),
  unique(branch_id, queue_prefix)
);

create table public.doctors (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users(id) on delete set null,
  full_name text not null,
  license_number text,
  specialization text,
  bio text,
  photo_url text,
  default_service_minutes int not null default 10 check (default_service_minutes > 0),
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(user_id)
);

create table public.doctor_polyclinics (
  id uuid primary key default gen_random_uuid(),
  doctor_id uuid not null references public.doctors(id) on delete cascade,
  polyclinic_id uuid not null references public.polyclinics(id) on delete cascade,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  unique(doctor_id, polyclinic_id)
);

create table public.doctor_schedules (
  id uuid primary key default gen_random_uuid(),
  branch_id uuid not null references public.clinic_branches(id) on delete cascade,
  polyclinic_id uuid not null references public.polyclinics(id) on delete restrict,
  doctor_id uuid not null references public.doctors(id) on delete restrict,
  schedule_date date not null,
  start_time time not null,
  end_time time not null,
  quota_limit int not null check (quota_limit > 0),
  average_service_minutes int not null default 10 check (average_service_minutes > 0),
  status public.schedule_status not null default 'open',
  notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check (end_time > start_time),
  unique(branch_id, polyclinic_id, doctor_id, schedule_date, start_time)
);

create table public.queue_sessions (
  id uuid primary key default gen_random_uuid(),
  schedule_id uuid not null references public.doctor_schedules(id) on delete cascade,
  current_number int not null default 0,
  last_number int not null default 0,
  is_open boolean not null default true,
  started_at timestamptz,
  closed_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(schedule_id),
  check (current_number >= 0),
  check (last_number >= 0),
  check (last_number >= current_number)
);

create table public.queue_tickets (
  id uuid primary key default gen_random_uuid(),
  queue_session_id uuid not null references public.queue_sessions(id) on delete cascade,
  patient_id uuid not null references public.profiles(id) on delete cascade,
  queue_number int not null,
  queue_code text not null,
  status public.queue_status not null default 'waiting',
  estimated_wait_minutes int not null default 0,
  checked_in_at timestamptz,
  called_at timestamptz,
  serving_started_at timestamptz,
  completed_at timestamptz,
  skipped_at timestamptz,
  cancelled_at timestamptz,
  expired_at timestamptz,
  cancel_reason text,
  notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(queue_session_id, queue_number),
  unique(queue_session_id, queue_code)
);

create table public.queue_events (
  id uuid primary key default gen_random_uuid(),
  queue_ticket_id uuid not null references public.queue_tickets(id) on delete cascade,
  actor_id uuid references public.profiles(id) on delete set null,
  previous_status public.queue_status,
  new_status public.queue_status not null,
  message text,
  created_at timestamptz not null default now()
);

create table public.notifications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  type public.notification_type not null,
  title text not null,
  body text not null,
  data jsonb,
  is_read boolean not null default false,
  created_at timestamptz not null default now(),
  read_at timestamptz
);

create index profiles_full_name_idx on public.profiles using gin (to_tsvector('simple', full_name));
create index user_roles_user_id_idx on public.user_roles(user_id);
create index user_roles_role_id_idx on public.user_roles(role_id);
create index clinic_branches_clinic_id_idx on public.clinic_branches(clinic_id);
create index clinic_staff_branch_id_idx on public.clinic_staff(branch_id);
create index clinic_staff_user_id_idx on public.clinic_staff(user_id);
create index polyclinics_branch_id_idx on public.polyclinics(branch_id);
create index doctors_user_id_idx on public.doctors(user_id);
create index doctors_full_name_idx on public.doctors using gin (to_tsvector('simple', full_name));
create index doctor_polyclinics_doctor_id_idx on public.doctor_polyclinics(doctor_id);
create index doctor_polyclinics_polyclinic_id_idx on public.doctor_polyclinics(polyclinic_id);
create index doctor_schedules_branch_id_idx on public.doctor_schedules(branch_id);
create index doctor_schedules_polyclinic_id_idx on public.doctor_schedules(polyclinic_id);
create index doctor_schedules_doctor_id_idx on public.doctor_schedules(doctor_id);
create index doctor_schedules_date_idx on public.doctor_schedules(schedule_date);
create index queue_sessions_schedule_id_idx on public.queue_sessions(schedule_id);
create index queue_tickets_session_id_idx on public.queue_tickets(queue_session_id);
create index queue_tickets_patient_id_idx on public.queue_tickets(patient_id);
create index queue_tickets_status_idx on public.queue_tickets(status);
create index queue_tickets_created_at_idx on public.queue_tickets(created_at);
create index queue_events_ticket_id_idx on public.queue_events(queue_ticket_id);
create index queue_events_actor_id_idx on public.queue_events(actor_id);
create index notifications_user_id_idx on public.notifications(user_id);
create index notifications_is_read_idx on public.notifications(is_read);

create or replace function public.touch_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create trigger profiles_touch_updated_at
before update on public.profiles
for each row execute function public.touch_updated_at();

create trigger clinics_touch_updated_at
before update on public.clinics
for each row execute function public.touch_updated_at();

create trigger clinic_branches_touch_updated_at
before update on public.clinic_branches
for each row execute function public.touch_updated_at();

create trigger polyclinics_touch_updated_at
before update on public.polyclinics
for each row execute function public.touch_updated_at();

create trigger doctors_touch_updated_at
before update on public.doctors
for each row execute function public.touch_updated_at();

create trigger doctor_schedules_touch_updated_at
before update on public.doctor_schedules
for each row execute function public.touch_updated_at();

create trigger queue_sessions_touch_updated_at
before update on public.queue_sessions
for each row execute function public.touch_updated_at();

create trigger queue_tickets_touch_updated_at
before update on public.queue_tickets
for each row execute function public.touch_updated_at();

insert into public.roles (code, name, description) values
  ('patient', 'Patient', 'Pengguna aplikasi mobile'),
  ('admin', 'Admin', 'Admin operasional klinik'),
  ('doctor', 'Doctor', 'Dokter atau petugas poli'),
  ('owner', 'Owner', 'Pemilik klinik'),
  ('super_admin', 'Super Admin', 'Pengelola seluruh sistem')
on conflict (code) do nothing;

create or replace function public.has_role(target_role text)
returns boolean
language sql
security definer
set search_path = public
stable
as $$
  select exists (
    select 1
    from public.user_roles ur
    join public.roles r on r.id = ur.role_id
    where ur.user_id = auth.uid()
      and r.code = target_role
  );
$$;

create or replace function public.is_staff()
returns boolean
language sql
security definer
set search_path = public
stable
as $$
  select public.has_role('admin')
    or public.has_role('doctor')
    or public.has_role('owner')
    or public.has_role('super_admin');
$$;

create or replace function public.get_my_roles()
returns table(role_code text)
language sql
security definer
set search_path = public
stable
as $$
  select r.code
  from public.user_roles ur
  join public.roles r on r.id = ur.role_id
  where ur.user_id = auth.uid();
$$;

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_patient_role_id bigint;
begin
  insert into public.profiles (id, full_name, phone_number, avatar_url)
  values (
    new.id,
    coalesce(
      nullif(new.raw_user_meta_data ->> 'full_name', ''),
      nullif(new.raw_user_meta_data ->> 'name', ''),
      split_part(new.email, '@', 1),
      'Pasien AntriMedis'
    ),
    nullif(new.raw_user_meta_data ->> 'phone_number', ''),
    coalesce(
      nullif(new.raw_user_meta_data ->> 'avatar_url', ''),
      nullif(new.raw_user_meta_data ->> 'picture', '')
    )
  )
  on conflict (id) do update
  set full_name = excluded.full_name,
      phone_number = excluded.phone_number,
      avatar_url = coalesce(excluded.avatar_url, public.profiles.avatar_url);

  select id into v_patient_role_id
  from public.roles
  where code = 'patient';

  if v_patient_role_id is not null then
    insert into public.user_roles (user_id, role_id)
    values (new.id, v_patient_role_id)
    on conflict (user_id, role_id) do nothing;
  end if;

  return new;
end;
$$;

create trigger on_auth_user_created
after insert on auth.users
for each row execute function public.handle_new_user();

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

create or replace function public.assign_role_by_email(
  p_email text,
  p_role_code text,
  p_branch_id uuid default null,
  p_staff_title text default null
)
returns void
language plpgsql
security definer
set search_path = public, auth
as $$
declare
  v_user_id uuid;
  v_role_id bigint;
begin
  select id into v_user_id
  from auth.users
  where lower(email) = lower(p_email);

  if v_user_id is null then
    raise exception 'User with email % not found', p_email;
  end if;

  select id into v_role_id
  from public.roles
  where code = p_role_code;

  if v_role_id is null then
    raise exception 'Role % not found', p_role_code;
  end if;

  insert into public.user_roles (user_id, role_id)
  values (v_user_id, v_role_id)
  on conflict (user_id, role_id) do nothing;

  if p_branch_id is not null and p_role_code in ('admin', 'doctor', 'owner') then
    insert into public.clinic_staff (branch_id, user_id, staff_title)
    values (p_branch_id, v_user_id, p_staff_title)
    on conflict (branch_id, user_id) do update
    set staff_title = excluded.staff_title,
        is_active = true;
  end if;
end;
$$;

create or replace function public.create_queue_ticket(p_queue_session_id uuid)
returns public.queue_tickets
language plpgsql
security definer
set search_path = public
as $$
declare
  v_session public.queue_sessions%rowtype;
  v_schedule public.doctor_schedules%rowtype;
  v_polyclinic public.polyclinics%rowtype;
  v_next_number int;
  v_queue_code text;
  v_ticket public.queue_tickets%rowtype;
  v_existing_active int;
  v_taken_count int;
begin
  if auth.uid() is null then
    raise exception 'Unauthorized';
  end if;

  select * into v_session
  from public.queue_sessions
  where id = p_queue_session_id
  for update;

  if not found then
    raise exception 'Queue session not found';
  end if;

  if v_session.is_open = false then
    raise exception 'Queue session is closed';
  end if;

  select * into v_schedule
  from public.doctor_schedules
  where id = v_session.schedule_id;

  if not found then
    raise exception 'Schedule not found';
  end if;

  if v_schedule.status <> 'open' then
    raise exception 'Schedule is not open';
  end if;

  select count(*) into v_taken_count
  from public.queue_tickets
  where queue_session_id = p_queue_session_id
    and status <> 'cancelled';

  if v_taken_count >= v_schedule.quota_limit then
    raise exception 'Queue quota is full';
  end if;

  select count(*) into v_existing_active
  from public.queue_tickets
  where queue_session_id = p_queue_session_id
    and patient_id = auth.uid()
    and status in ('waiting', 'called', 'serving');

  if v_existing_active > 0 then
    raise exception 'Patient already has active queue in this session';
  end if;

  select * into v_polyclinic
  from public.polyclinics
  where id = v_schedule.polyclinic_id;

  v_next_number := v_session.last_number + 1;
  v_queue_code := v_polyclinic.queue_prefix || lpad(v_next_number::text, 3, '0');

  update public.queue_sessions
  set last_number = v_next_number
  where id = p_queue_session_id;

  insert into public.queue_tickets (
    queue_session_id,
    patient_id,
    queue_number,
    queue_code,
    status,
    estimated_wait_minutes
  ) values (
    p_queue_session_id,
    auth.uid(),
    v_next_number,
    v_queue_code,
    'waiting',
    greatest((v_next_number - v_session.current_number - 1), 0) * v_schedule.average_service_minutes
  )
  returning * into v_ticket;

  insert into public.queue_events (
    queue_ticket_id,
    actor_id,
    previous_status,
    new_status,
    message
  ) values (
    v_ticket.id,
    auth.uid(),
    null,
    'waiting',
    'Queue ticket created'
  );

  insert into public.notifications (user_id, type, title, body, data)
  values (
    auth.uid(),
    'queue_created',
    'Nomor antrean berhasil dibuat',
    'Nomor antrean Anda adalah ' || v_ticket.queue_code,
    jsonb_build_object('ticket_id', v_ticket.id, 'queue_code', v_ticket.queue_code)
  );

  return v_ticket;
end;
$$;

create or replace function public.refresh_queue_estimates(p_queue_session_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_current_number int;
  v_average_minutes int;
begin
  select qs.current_number, ds.average_service_minutes
  into v_current_number, v_average_minutes
  from public.queue_sessions qs
  join public.doctor_schedules ds on ds.id = qs.schedule_id
  where qs.id = p_queue_session_id;

  update public.queue_tickets
  set estimated_wait_minutes = greatest(queue_number - v_current_number - 1, 0) * v_average_minutes
  where queue_session_id = p_queue_session_id
    and status in ('waiting', 'called', 'serving');
end;
$$;

create or replace function public.call_next_queue(p_queue_session_id uuid)
returns public.queue_tickets
language plpgsql
security definer
set search_path = public
as $$
declare
  v_ticket public.queue_tickets%rowtype;
begin
  if not public.is_staff() then
    raise exception 'Forbidden';
  end if;

  select * into v_ticket
  from public.queue_tickets
  where queue_session_id = p_queue_session_id
    and status = 'waiting'
  order by queue_number asc
  limit 1
  for update skip locked;

  if not found then
    raise exception 'No waiting queue found';
  end if;

  update public.queue_tickets
  set status = 'called',
      called_at = now()
  where id = v_ticket.id
  returning * into v_ticket;

  update public.queue_sessions
  set current_number = v_ticket.queue_number
  where id = p_queue_session_id;

  perform public.refresh_queue_estimates(p_queue_session_id);

  insert into public.queue_events (
    queue_ticket_id,
    actor_id,
    previous_status,
    new_status,
    message
  ) values (
    v_ticket.id,
    auth.uid(),
    'waiting',
    'called',
    'Queue called by staff'
  );

  insert into public.notifications (user_id, type, title, body, data)
  values (
    v_ticket.patient_id,
    'queue_called',
    'Nomor antrean dipanggil',
    'Nomor ' || v_ticket.queue_code || ' sedang dipanggil.',
    jsonb_build_object('ticket_id', v_ticket.id, 'queue_code', v_ticket.queue_code)
  );

  return v_ticket;
end;
$$;

create or replace function public.update_queue_status(
  p_ticket_id uuid,
  p_new_status public.queue_status,
  p_message text default null
)
returns public.queue_tickets
language plpgsql
security definer
set search_path = public
as $$
declare
  v_ticket public.queue_tickets%rowtype;
  v_old_status public.queue_status;
begin
  if not public.is_staff() then
    raise exception 'Forbidden';
  end if;

  select * into v_ticket
  from public.queue_tickets
  where id = p_ticket_id
  for update;

  if not found then
    raise exception 'Queue ticket not found';
  end if;

  v_old_status := v_ticket.status;

  update public.queue_tickets
  set status = p_new_status,
      serving_started_at = case when p_new_status = 'serving' then now() else serving_started_at end,
      completed_at = case when p_new_status = 'completed' then now() else completed_at end,
      skipped_at = case when p_new_status = 'skipped' then now() else skipped_at end,
      cancelled_at = case when p_new_status = 'cancelled' then now() else cancelled_at end,
      expired_at = case when p_new_status = 'expired' then now() else expired_at end
  where id = p_ticket_id
  returning * into v_ticket;

  insert into public.queue_events (
    queue_ticket_id,
    actor_id,
    previous_status,
    new_status,
    message
  ) values (
    p_ticket_id,
    auth.uid(),
    v_old_status,
    p_new_status,
    coalesce(p_message, 'Queue status updated')
  );

  if p_new_status in ('skipped', 'cancelled') then
    insert into public.notifications (user_id, type, title, body, data)
    values (
      v_ticket.patient_id,
      case when p_new_status = 'skipped' then 'queue_skipped' else 'queue_cancelled' end,
      case when p_new_status = 'skipped' then 'Antrean dilewati' else 'Antrean dibatalkan' end,
      case when p_new_status = 'skipped'
        then 'Nomor ' || v_ticket.queue_code || ' dilewati oleh petugas.'
        else 'Nomor ' || v_ticket.queue_code || ' dibatalkan.'
      end,
      jsonb_build_object('ticket_id', v_ticket.id, 'queue_code', v_ticket.queue_code)
    );
  end if;

  perform public.refresh_queue_estimates(v_ticket.queue_session_id);

  return v_ticket;
end;
$$;

create or replace view public.v_queue_ticket_details
with (security_invoker = true) as
select
  qt.id as ticket_id,
  qt.queue_session_id,
  qt.patient_id,
  p.full_name as patient_name,
  qt.queue_number,
  qt.queue_code,
  qt.status,
  qt.estimated_wait_minutes,
  qt.created_at,
  qt.called_at,
  qt.serving_started_at,
  qt.completed_at,
  qs.current_number,
  qs.last_number,
  ds.id as schedule_id,
  ds.schedule_date,
  ds.start_time,
  ds.end_time,
  ds.average_service_minutes,
  cb.id as branch_id,
  cb.name as branch_name,
  cb.address as branch_address,
  pc.id as polyclinic_id,
  pc.name as polyclinic_name,
  pc.queue_prefix,
  d.id as doctor_id,
  d.full_name as doctor_name,
  d.specialization
from public.queue_tickets qt
join public.profiles p on p.id = qt.patient_id
join public.queue_sessions qs on qs.id = qt.queue_session_id
join public.doctor_schedules ds on ds.id = qs.schedule_id
join public.clinic_branches cb on cb.id = ds.branch_id
join public.polyclinics pc on pc.id = ds.polyclinic_id
join public.doctors d on d.id = ds.doctor_id;

create or replace view public.v_schedule_availability
with (security_invoker = true) as
select
  ds.id as schedule_id,
  ds.branch_id,
  cb.name as branch_name,
  ds.polyclinic_id,
  pc.name as polyclinic_name,
  pc.queue_prefix,
  ds.doctor_id,
  d.full_name as doctor_name,
  d.specialization,
  ds.schedule_date,
  ds.start_time,
  ds.end_time,
  ds.quota_limit,
  ds.average_service_minutes,
  ds.status,
  coalesce(qs.id, null) as queue_session_id,
  coalesce(qs.current_number, 0) as current_number,
  coalesce(qs.last_number, 0) as last_number,
  count(qt.id) filter (where qt.status <> 'cancelled') as total_taken,
  ds.quota_limit - count(qt.id) filter (where qt.status <> 'cancelled') as remaining_quota
from public.doctor_schedules ds
join public.clinic_branches cb on cb.id = ds.branch_id
join public.polyclinics pc on pc.id = ds.polyclinic_id
join public.doctors d on d.id = ds.doctor_id
left join public.queue_sessions qs on qs.schedule_id = ds.id
left join public.queue_tickets qt on qt.queue_session_id = qs.id
group by ds.id, cb.name, pc.name, pc.queue_prefix, d.full_name, d.specialization, qs.id, qs.current_number, qs.last_number;

alter table public.profiles enable row level security;
alter table public.roles enable row level security;
alter table public.user_roles enable row level security;
alter table public.clinics enable row level security;
alter table public.clinic_branches enable row level security;
alter table public.clinic_staff enable row level security;
alter table public.polyclinics enable row level security;
alter table public.doctors enable row level security;
alter table public.doctor_polyclinics enable row level security;
alter table public.doctor_schedules enable row level security;
alter table public.queue_sessions enable row level security;
alter table public.queue_tickets enable row level security;
alter table public.queue_events enable row level security;
alter table public.notifications enable row level security;

create policy "Users can read own profile"
on public.profiles for select to authenticated
using (id = auth.uid());

create policy "Users can create own profile"
on public.profiles for insert to authenticated
with check (id = auth.uid());

create policy "Users can update own profile"
on public.profiles for update to authenticated
using (id = auth.uid())
with check (id = auth.uid());

create policy "Staff can read profiles"
on public.profiles for select to authenticated
using (public.is_staff());

create policy "Authenticated users can read roles"
on public.roles for select to authenticated
using (true);

create policy "Users can read own roles"
on public.user_roles for select to authenticated
using (user_id = auth.uid() or public.is_staff());

create policy "Authenticated users can read active clinics"
on public.clinics for select to authenticated
using (is_active = true or public.is_staff());

create policy "Staff can manage clinics"
on public.clinics for all to authenticated
using (public.is_staff())
with check (public.is_staff());

create policy "Authenticated users can read active branches"
on public.clinic_branches for select to authenticated
using (is_active = true or public.is_staff());

create policy "Staff can manage branches"
on public.clinic_branches for all to authenticated
using (public.is_staff())
with check (public.is_staff());

create policy "Staff can read clinic staff"
on public.clinic_staff for select to authenticated
using (public.is_staff());

create policy "Authenticated users can read active polyclinics"
on public.polyclinics for select to authenticated
using (is_active = true or public.is_staff());

create policy "Staff can manage polyclinics"
on public.polyclinics for all to authenticated
using (public.is_staff())
with check (public.is_staff());

create policy "Authenticated users can read active doctors"
on public.doctors for select to authenticated
using (is_active = true or public.is_staff());

create policy "Staff can manage doctors"
on public.doctors for all to authenticated
using (public.is_staff())
with check (public.is_staff());

create policy "Authenticated users can read doctor polyclinics"
on public.doctor_polyclinics for select to authenticated
using (is_active = true or public.is_staff());

create policy "Staff can manage doctor polyclinics"
on public.doctor_polyclinics for all to authenticated
using (public.is_staff())
with check (public.is_staff());

create policy "Authenticated users can read schedules"
on public.doctor_schedules for select to authenticated
using (status in ('open', 'full', 'closed') or public.is_staff());

create policy "Staff can manage schedules"
on public.doctor_schedules for all to authenticated
using (public.is_staff())
with check (public.is_staff());

create policy "Authenticated users can read queue sessions"
on public.queue_sessions for select to authenticated
using (true);

create policy "Staff can manage queue sessions"
on public.queue_sessions for all to authenticated
using (public.is_staff())
with check (public.is_staff());

create policy "Patients can read own queue tickets"
on public.queue_tickets for select to authenticated
using (patient_id = auth.uid());

create policy "Staff can read queue tickets"
on public.queue_tickets for select to authenticated
using (public.is_staff());

create policy "Patients can cancel own waiting queue tickets"
on public.queue_tickets for update to authenticated
using (patient_id = auth.uid() and status = 'waiting')
with check (patient_id = auth.uid() and status = 'cancelled');

create policy "Staff can update queue tickets"
on public.queue_tickets for update to authenticated
using (public.is_staff())
with check (public.is_staff());

create policy "Users can read own queue events"
on public.queue_events for select to authenticated
using (
  exists (
    select 1
    from public.queue_tickets qt
    where qt.id = queue_events.queue_ticket_id
      and qt.patient_id = auth.uid()
  )
  or public.is_staff()
);

create policy "Users can read own notifications"
on public.notifications for select to authenticated
using (user_id = auth.uid());

create policy "Users can update own notifications"
on public.notifications for update to authenticated
using (user_id = auth.uid())
with check (user_id = auth.uid());

revoke all on function public.assign_role_by_email(text, text, uuid, text) from public, anon, authenticated;
revoke all on function public.refresh_queue_estimates(uuid) from public, anon, authenticated;
grant execute on function public.has_role(text) to authenticated;
grant execute on function public.is_staff() to authenticated;
grant execute on function public.get_my_roles() to authenticated;
grant execute on function public.upsert_my_profile(text, text, public.gender_type, date, text) to authenticated;
grant execute on function public.create_queue_ticket(uuid) to authenticated;
grant execute on function public.call_next_queue(uuid) to authenticated;
grant execute on function public.update_queue_status(uuid, public.queue_status, text) to authenticated;

alter publication supabase_realtime add table public.queue_sessions;
alter publication supabase_realtime add table public.queue_tickets;
alter publication supabase_realtime add table public.notifications;

insert into public.clinics (id, name, description, phone_number, email)
values (
  '11111111-1111-1111-1111-111111111111',
  'Klinik Sehat Sentosa',
  'Klinik utama untuk operasional AntriMedis.',
  '0331-123456',
  null
);

insert into public.clinic_branches (id, clinic_id, name, address, city, province, phone_number, open_time, close_time)
values (
  '22222222-2222-2222-2222-222222222222',
  '11111111-1111-1111-1111-111111111111',
  'Cabang Utama',
  'Jl. Merdeka No. 10',
  'Jember',
  'Jawa Timur',
  '0331-123456',
  '08:00',
  '20:00'
);
