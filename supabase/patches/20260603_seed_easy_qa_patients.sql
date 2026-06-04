-- Seed easy-to-type QA patient accounts for manual queue testing.
-- These accounts are valid Supabase Auth users with completed public profiles.

begin;

insert into public.roles (code, name, description)
values ('patient', 'Patient', 'Pengguna aplikasi mobile pasien.')
on conflict (code) do update
set
  name = excluded.name,
  description = excluded.description;

with seed_patients(
  user_id,
  email,
  full_name,
  phone_number,
  birth_date,
  gender,
  avatar_url
) as (
  values
    (
      '71000000-0000-4000-8000-000000000001'::uuid,
      'pasien1@antrimedis.test',
      'Alya Ramadhani',
      '+6281388891001',
      '1999-02-14'::date,
      'female'::public.gender_type,
      'https://api.dicebear.com/9.x/initials/svg?seed=Alya%20Ramadhani'
    ),
    (
      '71000000-0000-4000-8000-000000000002'::uuid,
      'pasien2@antrimedis.test',
      'Rafi Mahendra',
      '+6281388891002',
      '1997-09-03'::date,
      'male'::public.gender_type,
      'https://api.dicebear.com/9.x/initials/svg?seed=Rafi%20Mahendra'
    ),
    (
      '71000000-0000-4000-8000-000000000003'::uuid,
      'pasien3@antrimedis.test',
      'Nabila Putri',
      '+6281388891003',
      '2001-05-21'::date,
      'female'::public.gender_type,
      'https://api.dicebear.com/9.x/initials/svg?seed=Nabila%20Putri'
    ),
    (
      '71000000-0000-4000-8000-000000000004'::uuid,
      'pasien4@antrimedis.test',
      'Dimas Pratama',
      '+6281388891004',
      '1995-12-08'::date,
      'male'::public.gender_type,
      'https://api.dicebear.com/9.x/initials/svg?seed=Dimas%20Pratama'
    ),
    (
      '71000000-0000-4000-8000-000000000005'::uuid,
      'pasien5@antrimedis.test',
      'Sekar Larasati',
      '+6281388891005',
      '1998-07-27'::date,
      'female'::public.gender_type,
      'https://api.dicebear.com/9.x/initials/svg?seed=Sekar%20Larasati'
    ),
    (
      '71000000-0000-4000-8000-000000000006'::uuid,
      'pasien6@antrimedis.test',
      'Bima Prakoso',
      '+6281388891006',
      '1996-04-11'::date,
      'male'::public.gender_type,
      'https://api.dicebear.com/9.x/initials/svg?seed=Bima%20Prakoso'
    ),
    (
      '71000000-0000-4000-8000-000000000007'::uuid,
      'pasien7@antrimedis.test',
      'Maya Safitri',
      '+6281388891007',
      '2000-10-18'::date,
      'female'::public.gender_type,
      'https://api.dicebear.com/9.x/initials/svg?seed=Maya%20Safitri'
    ),
    (
      '71000000-0000-4000-8000-000000000008'::uuid,
      'pasien8@antrimedis.test',
      'Ardi Nugroho',
      '+6281388891008',
      '1994-01-30'::date,
      'male'::public.gender_type,
      'https://api.dicebear.com/9.x/initials/svg?seed=Ardi%20Nugroho'
    ),
    (
      '71000000-0000-4000-8000-000000000009'::uuid,
      'pasien9@antrimedis.test',
      'Citra Lestari',
      '+6281388891009',
      '2002-06-09'::date,
      'female'::public.gender_type,
      'https://api.dicebear.com/9.x/initials/svg?seed=Citra%20Lestari'
    ),
    (
      '71000000-0000-4000-8000-000000000010'::uuid,
      'pasien10@antrimedis.test',
      'Fajar Hidayat',
      '+6281388891010',
      '1993-11-22'::date,
      'male'::public.gender_type,
      'https://api.dicebear.com/9.x/initials/svg?seed=Fajar%20Hidayat'
    )
)
insert into auth.users (
  instance_id,
  id,
  aud,
  role,
  email,
  encrypted_password,
  email_confirmed_at,
  confirmation_token,
  recovery_token,
  email_change_token_new,
  email_change,
  raw_app_meta_data,
  raw_user_meta_data,
  is_super_admin,
  created_at,
  updated_at,
  phone,
  is_sso_user,
  is_anonymous
)
select
  '00000000-0000-0000-0000-000000000000'::uuid,
  sp.user_id,
  'authenticated',
  'authenticated',
  sp.email,
  crypt('PatientMedis2026!', gen_salt('bf')),
  now(),
  '',
  '',
  '',
  '',
  '{"provider":"email","providers":["email"]}'::jsonb,
  jsonb_build_object(
    'sub', sp.user_id::text,
    'email', sp.email,
    'full_name', sp.full_name,
    'email_verified', true,
    'phone_verified', false
  ),
  false,
  now(),
  now(),
  null,
  false,
  false
from seed_patients sp
where not exists (
  select 1
  from auth.users u
  where lower(u.email) = sp.email
);

with seed_patients(email, full_name) as (
  values
    ('pasien1@antrimedis.test', 'Alya Ramadhani'),
    ('pasien2@antrimedis.test', 'Rafi Mahendra'),
    ('pasien3@antrimedis.test', 'Nabila Putri'),
    ('pasien4@antrimedis.test', 'Dimas Pratama'),
    ('pasien5@antrimedis.test', 'Sekar Larasati'),
    ('pasien6@antrimedis.test', 'Bima Prakoso'),
    ('pasien7@antrimedis.test', 'Maya Safitri'),
    ('pasien8@antrimedis.test', 'Ardi Nugroho'),
    ('pasien9@antrimedis.test', 'Citra Lestari'),
    ('pasien10@antrimedis.test', 'Fajar Hidayat')
)
update auth.users u
set
  encrypted_password = crypt('PatientMedis2026!', gen_salt('bf')),
  email_confirmed_at = coalesce(u.email_confirmed_at, now()),
  confirmation_token = '',
  confirmation_sent_at = null,
  recovery_token = '',
  email_change_token_new = '',
  email_change = '',
  raw_app_meta_data = '{"provider":"email","providers":["email"]}'::jsonb,
  raw_user_meta_data = jsonb_build_object(
    'sub', u.id::text,
    'email', u.email,
    'full_name', sp.full_name,
    'email_verified', true,
    'phone_verified', false
  ),
  updated_at = now()
from seed_patients sp
where lower(u.email) = sp.email;

with seed_patients(email, full_name) as (
  values
    ('pasien1@antrimedis.test', 'Alya Ramadhani'),
    ('pasien2@antrimedis.test', 'Rafi Mahendra'),
    ('pasien3@antrimedis.test', 'Nabila Putri'),
    ('pasien4@antrimedis.test', 'Dimas Pratama'),
    ('pasien5@antrimedis.test', 'Sekar Larasati'),
    ('pasien6@antrimedis.test', 'Bima Prakoso'),
    ('pasien7@antrimedis.test', 'Maya Safitri'),
    ('pasien8@antrimedis.test', 'Ardi Nugroho'),
    ('pasien9@antrimedis.test', 'Citra Lestari'),
    ('pasien10@antrimedis.test', 'Fajar Hidayat')
)
insert into auth.identities (
  id,
  provider_id,
  user_id,
  identity_data,
  provider,
  last_sign_in_at,
  created_at,
  updated_at
)
select
  gen_random_uuid(),
  u.id::text,
  u.id,
  jsonb_build_object(
    'sub', u.id::text,
    'email', u.email,
    'full_name', sp.full_name,
    'email_verified', true,
    'phone_verified', false
  ),
  'email',
  now(),
  now(),
  now()
from seed_patients sp
join auth.users u on lower(u.email) = sp.email
on conflict (provider_id, provider) do update
set
  identity_data = excluded.identity_data,
  updated_at = now();

with seed_patients(email, full_name, phone_number, birth_date, gender, avatar_url) as (
  values
    ('pasien1@antrimedis.test', 'Alya Ramadhani', '+6281388891001', '1999-02-14'::date, 'female'::public.gender_type, 'https://api.dicebear.com/9.x/initials/svg?seed=Alya%20Ramadhani'),
    ('pasien2@antrimedis.test', 'Rafi Mahendra', '+6281388891002', '1997-09-03'::date, 'male'::public.gender_type, 'https://api.dicebear.com/9.x/initials/svg?seed=Rafi%20Mahendra'),
    ('pasien3@antrimedis.test', 'Nabila Putri', '+6281388891003', '2001-05-21'::date, 'female'::public.gender_type, 'https://api.dicebear.com/9.x/initials/svg?seed=Nabila%20Putri'),
    ('pasien4@antrimedis.test', 'Dimas Pratama', '+6281388891004', '1995-12-08'::date, 'male'::public.gender_type, 'https://api.dicebear.com/9.x/initials/svg?seed=Dimas%20Pratama'),
    ('pasien5@antrimedis.test', 'Sekar Larasati', '+6281388891005', '1998-07-27'::date, 'female'::public.gender_type, 'https://api.dicebear.com/9.x/initials/svg?seed=Sekar%20Larasati'),
    ('pasien6@antrimedis.test', 'Bima Prakoso', '+6281388891006', '1996-04-11'::date, 'male'::public.gender_type, 'https://api.dicebear.com/9.x/initials/svg?seed=Bima%20Prakoso'),
    ('pasien7@antrimedis.test', 'Maya Safitri', '+6281388891007', '2000-10-18'::date, 'female'::public.gender_type, 'https://api.dicebear.com/9.x/initials/svg?seed=Maya%20Safitri'),
    ('pasien8@antrimedis.test', 'Ardi Nugroho', '+6281388891008', '1994-01-30'::date, 'male'::public.gender_type, 'https://api.dicebear.com/9.x/initials/svg?seed=Ardi%20Nugroho'),
    ('pasien9@antrimedis.test', 'Citra Lestari', '+6281388891009', '2002-06-09'::date, 'female'::public.gender_type, 'https://api.dicebear.com/9.x/initials/svg?seed=Citra%20Lestari'),
    ('pasien10@antrimedis.test', 'Fajar Hidayat', '+6281388891010', '1993-11-22'::date, 'male'::public.gender_type, 'https://api.dicebear.com/9.x/initials/svg?seed=Fajar%20Hidayat')
)
insert into public.profiles (
  id,
  full_name,
  phone_number,
  birth_date,
  gender,
  avatar_url,
  is_active
)
select
  u.id,
  sp.full_name,
  sp.phone_number,
  sp.birth_date,
  sp.gender,
  sp.avatar_url,
  true
from seed_patients sp
join auth.users u on lower(u.email) = sp.email
on conflict (id) do update
set
  full_name = excluded.full_name,
  phone_number = excluded.phone_number,
  birth_date = excluded.birth_date,
  gender = excluded.gender,
  avatar_url = excluded.avatar_url,
  is_active = true,
  updated_at = now();

with seed_patients(email) as (
  values
    ('pasien1@antrimedis.test'),
    ('pasien2@antrimedis.test'),
    ('pasien3@antrimedis.test'),
    ('pasien4@antrimedis.test'),
    ('pasien5@antrimedis.test'),
    ('pasien6@antrimedis.test'),
    ('pasien7@antrimedis.test'),
    ('pasien8@antrimedis.test'),
    ('pasien9@antrimedis.test'),
    ('pasien10@antrimedis.test')
)
insert into public.user_roles (user_id, role_id)
select u.id, r.id
from seed_patients sp
join auth.users u on lower(u.email) = sp.email
join public.roles r on r.code = 'patient'
on conflict (user_id, role_id) do nothing;

commit;
