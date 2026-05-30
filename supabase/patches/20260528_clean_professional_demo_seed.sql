-- Clean operational data and reseed a professional AntriMedis demo dataset.
-- Safe to run multiple times on the linked Supabase project.

begin;

create extension if not exists "pgcrypto";

do $$
declare
  v_admin_email text := 'admin@antrimedis.test';
  v_admin_password text := 'AdminMedis2026!';
  v_admin_user_id uuid;
  v_admin_role_id bigint;
  v_patient_role_id bigint;
begin
  select id into v_admin_user_id
  from auth.users
  where lower(email) = lower(v_admin_email)
  limit 1;

  if v_admin_user_id is null then
    v_admin_user_id := 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa';

    insert into auth.users (
      id,
      instance_id,
      aud,
      role,
      email,
      encrypted_password,
      email_confirmed_at,
      raw_app_meta_data,
      raw_user_meta_data,
      created_at,
      updated_at
    )
    values (
      v_admin_user_id,
      '00000000-0000-0000-0000-000000000000',
      'authenticated',
      'authenticated',
      v_admin_email,
      crypt(v_admin_password, gen_salt('bf')),
      now(),
      '{"provider":"email","providers":["email"]}'::jsonb,
      jsonb_build_object(
        'full_name', 'Nadia Prameswari',
        'email_verified', true,
        'phone_verified', false
      ),
      now(),
      now()
    );
  else
    update auth.users
    set
      aud = 'authenticated',
      role = 'authenticated',
      encrypted_password = crypt(v_admin_password, gen_salt('bf')),
      email_confirmed_at = coalesce(email_confirmed_at, now()),
      raw_app_meta_data = '{"provider":"email","providers":["email"]}'::jsonb,
      raw_user_meta_data = jsonb_build_object(
        'full_name', 'Nadia Prameswari',
        'email_verified', true,
        'phone_verified', false
      ),
      updated_at = now()
    where id = v_admin_user_id;
  end if;

  insert into auth.identities (
    id,
    user_id,
    identity_data,
    provider,
    provider_id,
    last_sign_in_at,
    created_at,
    updated_at
  )
  values (
    v_admin_user_id,
    v_admin_user_id,
    jsonb_build_object(
      'sub', v_admin_user_id::text,
      'email', v_admin_email,
      'email_verified', true,
      'phone_verified', false
    ),
    'email',
    v_admin_email,
    now(),
    now(),
    now()
  )
  on conflict (provider, provider_id) do update
  set
    user_id = excluded.user_id,
    identity_data = excluded.identity_data,
    updated_at = now();

  insert into public.roles (code, name, description) values
    ('patient', 'Patient', 'Pengguna aplikasi mobile pasien.'),
    ('admin', 'Admin Klinik', 'Petugas administrasi klinik yang mengelola jadwal, master data, dan antrean.'),
    ('doctor', 'Dokter', 'Dokter atau petugas poli yang memantau antrean pelayanan.'),
    ('owner', 'Owner Klinik', 'Pemilik klinik yang memantau performa operasional.'),
    ('super_admin', 'Super Admin', 'Pengelola seluruh sistem AntriMedis.')
  on conflict (code) do update
  set
    name = excluded.name,
    description = excluded.description;

  select id into v_admin_role_id from public.roles where code = 'admin';
  select id into v_patient_role_id from public.roles where code = 'patient';

  insert into public.profiles (
    id,
    full_name,
    phone_number,
    birth_date,
    gender,
    avatar_url,
    is_active
  )
  values (
    v_admin_user_id,
    'Nadia Prameswari',
    '+6281234567801',
    '1994-08-17',
    'female',
    'https://api.dicebear.com/9.x/initials/svg?seed=Nadia%20Prameswari',
    true
  )
  on conflict (id) do update
  set
    full_name = excluded.full_name,
    phone_number = excluded.phone_number,
    birth_date = excluded.birth_date,
    gender = excluded.gender,
    avatar_url = excluded.avatar_url,
    is_active = true,
    updated_at = now();

  if v_patient_role_id is not null then
    delete from public.user_roles
    where user_id = v_admin_user_id
      and role_id = v_patient_role_id;
  end if;

  if v_admin_role_id is not null then
    insert into public.user_roles (user_id, role_id)
    values (v_admin_user_id, v_admin_role_id)
    on conflict (user_id, role_id) do nothing;
  end if;

end $$;

-- Remove demo/smoke-test patient accounts only. Real Google/user accounts are preserved.
delete from auth.users
where lower(email) = 'patient@antrimedis.test'
   or lower(email) like 'patient.%@antrimedis.test';

-- Clean operational and demo master data before reseeding.
delete from public.notifications;
delete from public.queue_events;
delete from public.queue_tickets;
delete from public.queue_sessions;
delete from public.doctor_schedules;
delete from public.doctor_polyclinics;
delete from public.doctors;
delete from public.polyclinics;
delete from public.clinic_staff;
delete from public.clinic_branches;
delete from public.clinics;

insert into public.clinics (
  id,
  name,
  description,
  logo_url,
  phone_number,
  email,
  website,
  is_active
)
values (
  '11111111-1111-1111-1111-111111111111',
  'Klinik Sehat Sentosa',
  'Klinik pratama modern yang menyediakan layanan poli umum, anak, gigi, dan kulit dengan sistem antrean digital real-time.',
  'https://api.dicebear.com/9.x/shapes/svg?seed=AntriMedis',
  '+62331123456',
  'halo@kliniksehatsentosa.test',
  'https://kliniksehatsentosa.test',
  true
);

insert into public.clinic_branches (
  id,
  clinic_id,
  name,
  address,
  city,
  province,
  latitude,
  longitude,
  phone_number,
  open_time,
  close_time,
  is_active
)
values (
  '22222222-2222-2222-2222-222222222222',
  '11111111-1111-1111-1111-111111111111',
  'Cabang Utama Patrang',
  'Jl. Merdeka No. 10, Patrang',
  'Jember',
  'Jawa Timur',
  -8.1723570,
  113.7003020,
  '+62331123456',
  '08:00',
  '20:00',
  true
);

insert into public.clinic_staff (
  id,
  branch_id,
  user_id,
  staff_title,
  is_active
)
select
  '33333333-3333-3333-3333-333333333333',
  '22222222-2222-2222-2222-222222222222',
  u.id,
  'Koordinator Front Office',
  true
from auth.users u
where lower(u.email) = 'admin@antrimedis.test'
on conflict (branch_id, user_id) do update
set
  staff_title = excluded.staff_title,
  is_active = true;

insert into public.polyclinics (
  id,
  branch_id,
  name,
  code,
  description,
  queue_prefix,
  is_active
)
values
  (
    '44444444-4444-4444-4444-444444444441',
    '22222222-2222-2222-2222-222222222222',
    'Poli Umum',
    'POLI-UMUM',
    'Layanan pemeriksaan umum, konsultasi keluhan harian, dan tindak lanjut kesehatan keluarga.',
    'U',
    true
  ),
  (
    '44444444-4444-4444-4444-444444444442',
    '22222222-2222-2222-2222-222222222222',
    'Poli Gigi',
    'POLI-GIGI',
    'Layanan konsultasi kesehatan gigi, pembersihan karang gigi, tambal, dan perawatan dasar gigi.',
    'G',
    true
  ),
  (
    '44444444-4444-4444-4444-444444444443',
    '22222222-2222-2222-2222-222222222222',
    'Poli Anak',
    'POLI-ANAK',
    'Layanan konsultasi tumbuh kembang, imunisasi, dan pemeriksaan kesehatan anak.',
    'A',
    true
  ),
  (
    '44444444-4444-4444-4444-444444444444',
    '22222222-2222-2222-2222-222222222222',
    'Poli Kulit',
    'POLI-KULIT',
    'Layanan konsultasi kulit, jerawat, alergi, dan perawatan dermatologi dasar.',
    'K',
    true
  ),
  (
    '44444444-4444-4444-4444-444444444445',
    '22222222-2222-2222-2222-222222222222',
    'Poli Kandungan',
    'POLI-KANDUNGAN',
    'Layanan konsultasi kesehatan ibu, kontrol kehamilan dasar, dan edukasi kesehatan reproduksi.',
    'B',
    true
  ),
  (
    '44444444-4444-4444-4444-444444444446',
    '22222222-2222-2222-2222-222222222222',
    'Fisioterapi',
    'POLI-FISIO',
    'Layanan terapi gerak, pemulihan cedera ringan, dan edukasi latihan mandiri pasien.',
    'F',
    true
  );

insert into public.doctors (
  id,
  user_id,
  full_name,
  license_number,
  specialization,
  bio,
  photo_url,
  default_service_minutes,
  is_active
)
values
  (
    '55555555-5555-5555-5555-555555555551',
    null,
    'dr. Raka Adhitama',
    'SIP.503/DRU/2026/001',
    'Dokter Umum',
    'Dokter umum dengan fokus pada layanan primer, skrining kesehatan keluarga, dan edukasi gaya hidup sehat.',
    'https://api.dicebear.com/9.x/initials/svg?seed=Raka%20Adhitama',
    10,
    true
  ),
  (
    '55555555-5555-5555-5555-555555555552',
    null,
    'drg. Mira Lestari',
    'SIP.503/DRG/2026/002',
    'Dokter Gigi',
    'Dokter gigi yang menangani konsultasi, perawatan gigi dasar, dan edukasi kebersihan mulut.',
    'https://api.dicebear.com/9.x/initials/svg?seed=Mira%20Lestari',
    15,
    true
  ),
  (
    '55555555-5555-5555-5555-555555555553',
    null,
    'dr. Salsabila Kirana, Sp.A',
    'SIP.503/SPA/2026/003',
    'Spesialis Anak',
    'Dokter spesialis anak untuk pemeriksaan tumbuh kembang, imunisasi, dan konsultasi kesehatan anak.',
    'https://api.dicebear.com/9.x/initials/svg?seed=Salsabila%20Kirana',
    12,
    true
  ),
  (
    '55555555-5555-5555-5555-555555555554',
    null,
    'dr. Kevin Mahendra, Sp.KK',
    'SIP.503/SPKK/2026/004',
    'Spesialis Kulit dan Kelamin',
    'Dokter spesialis kulit untuk konsultasi jerawat, alergi, infeksi kulit, dan perawatan dermatologi dasar.',
    'https://api.dicebear.com/9.x/initials/svg?seed=Kevin%20Mahendra',
    15,
    true
  ),
  (
    '55555555-5555-5555-5555-555555555555',
    null,
    'dr. Anindya Putri',
    'SIP.503/DRU/2026/005',
    'Dokter Umum',
    'Dokter umum untuk layanan sore, kontrol keluhan ringan, dan konsultasi kesehatan preventif.',
    'https://api.dicebear.com/9.x/initials/svg?seed=Anindya%20Putri',
    10,
    true
  ),
  (
    '55555555-5555-5555-5555-555555555556',
    null,
    'dr. Ratih Paramita, Sp.OG',
    'SIP.503/SPOG/2026/006',
    'Spesialis Obstetri dan Ginekologi',
    'Dokter spesialis kandungan untuk kontrol kehamilan dasar, konsultasi kesehatan ibu, dan edukasi reproduksi.',
    'https://api.dicebear.com/9.x/initials/svg?seed=Ratih%20Paramita',
    18,
    true
  ),
  (
    '55555555-5555-5555-5555-555555555557',
    null,
    'Rizky Pratama, Ftr.',
    'STR.FTR/2026/007',
    'Fisioterapis',
    'Fisioterapis untuk pemulihan nyeri otot, cedera ringan, latihan postur, dan mobilitas dasar.',
    'https://api.dicebear.com/9.x/initials/svg?seed=Rizky%20Pratama',
    20,
    true
  ),
  (
    '55555555-5555-5555-5555-555555555558',
    null,
    'dr. Maulana Yusuf',
    'SIP.503/DRU/2026/008',
    'Dokter Umum',
    'Dokter umum untuk layanan konsultasi cepat, pemeriksaan tekanan darah, dan kontrol obat rutin.',
    'https://api.dicebear.com/9.x/initials/svg?seed=Maulana%20Yusuf',
    8,
    true
  );

insert into public.doctor_polyclinics (
  id,
  doctor_id,
  polyclinic_id,
  is_active
)
values
  ('66666666-6666-6666-6666-666666666661', '55555555-5555-5555-5555-555555555551', '44444444-4444-4444-4444-444444444441', true),
  ('66666666-6666-6666-6666-666666666662', '55555555-5555-5555-5555-555555555552', '44444444-4444-4444-4444-444444444442', true),
  ('66666666-6666-6666-6666-666666666663', '55555555-5555-5555-5555-555555555553', '44444444-4444-4444-4444-444444444443', true),
  ('66666666-6666-6666-6666-666666666664', '55555555-5555-5555-5555-555555555554', '44444444-4444-4444-4444-444444444444', true),
  ('66666666-6666-6666-6666-666666666665', '55555555-5555-5555-5555-555555555555', '44444444-4444-4444-4444-444444444441', true),
  ('66666666-6666-6666-6666-666666666666', '55555555-5555-5555-5555-555555555556', '44444444-4444-4444-4444-444444444445', true),
  ('66666666-6666-6666-6666-666666666667', '55555555-5555-5555-5555-555555555557', '44444444-4444-4444-4444-444444444446', true),
  ('66666666-6666-6666-6666-666666666668', '55555555-5555-5555-5555-555555555558', '44444444-4444-4444-4444-444444444441', true);

insert into public.doctor_schedules (
  id,
  branch_id,
  polyclinic_id,
  doctor_id,
  schedule_date,
  start_time,
  end_time,
  quota_limit,
  average_service_minutes,
  status,
  notes
)
values
  (
    '77777777-7777-7777-7777-777777777771',
    '22222222-2222-2222-2222-222222222222',
    '44444444-4444-4444-4444-444444444441',
    '55555555-5555-5555-5555-555555555551',
    current_date,
    '08:00',
    '11:30',
    24,
    10,
    'open',
    'Sesi pagi untuk konsultasi umum dan kontrol ringan.'
  ),
  (
    '77777777-7777-7777-7777-777777777772',
    '22222222-2222-2222-2222-222222222222',
    '44444444-4444-4444-4444-444444444442',
    '55555555-5555-5555-5555-555555555552',
    current_date,
    '09:00',
    '13:00',
    16,
    15,
    'open',
    'Sesi konsultasi dan tindakan gigi dasar.'
  ),
  (
    '77777777-7777-7777-7777-777777777773',
    '22222222-2222-2222-2222-222222222222',
    '44444444-4444-4444-4444-444444444443',
    '55555555-5555-5555-5555-555555555553',
    current_date,
    '13:00',
    '16:30',
    18,
    12,
    'open',
    'Sesi siang untuk anak dan imunisasi.'
  ),
  (
    '77777777-7777-7777-7777-777777777774',
    '22222222-2222-2222-2222-222222222222',
    '44444444-4444-4444-4444-444444444444',
    '55555555-5555-5555-5555-555555555554',
    current_date,
    '15:00',
    '19:00',
    14,
    15,
    'open',
    'Sesi sore untuk konsultasi kulit dan alergi.'
  ),
  (
    '77777777-7777-7777-7777-777777777775',
    '22222222-2222-2222-2222-222222222222',
    '44444444-4444-4444-4444-444444444441',
    '55555555-5555-5555-5555-555555555555',
    current_date + 1,
    '16:00',
    '20:00',
    22,
    10,
    'open',
    'Sesi besok untuk layanan umum sore.'
  ),
  (
    '77777777-7777-7777-7777-777777777776',
    '22222222-2222-2222-2222-222222222222',
    '44444444-4444-4444-4444-444444444445',
    '55555555-5555-5555-5555-555555555556',
    current_date,
    '10:00',
    '14:00',
    12,
    18,
    'open',
    'Sesi kontrol kehamilan dan konsultasi kesehatan ibu.'
  ),
  (
    '77777777-7777-7777-7777-777777777777',
    '22222222-2222-2222-2222-222222222222',
    '44444444-4444-4444-4444-444444444446',
    '55555555-5555-5555-5555-555555555557',
    current_date,
    '11:00',
    '17:00',
    10,
    20,
    'open',
    'Sesi fisioterapi dengan slot terbatas untuk evaluasi dan latihan.'
  ),
  (
    '77777777-7777-7777-7777-777777777778',
    '22222222-2222-2222-2222-222222222222',
    '44444444-4444-4444-4444-444444444441',
    '55555555-5555-5555-5555-555555555558',
    current_date + 1,
    '08:00',
    '12:00',
    26,
    8,
    'open',
    'Sesi besok untuk layanan umum cepat.'
  ),
  (
    '77777777-7777-7777-7777-777777777779',
    '22222222-2222-2222-2222-222222222222',
    '44444444-4444-4444-4444-444444444442',
    '55555555-5555-5555-5555-555555555552',
    current_date + 1,
    '13:30',
    '17:30',
    14,
    15,
    'open',
    'Sesi besok untuk tindakan gigi dasar.'
  ),
  (
    '77777777-7777-7777-7777-777777777780',
    '22222222-2222-2222-2222-222222222222',
    '44444444-4444-4444-4444-444444444443',
    '55555555-5555-5555-5555-555555555553',
    current_date - 1,
    '09:00',
    '12:00',
    16,
    12,
    'closed',
    'Sesi kemarin sudah ditutup untuk arsip operasional.'
  ),
  (
    '77777777-7777-7777-7777-777777777781',
    '22222222-2222-2222-2222-222222222222',
    '44444444-4444-4444-4444-444444444444',
    '55555555-5555-5555-5555-555555555554',
    current_date + 2,
    '15:00',
    '18:00',
    12,
    15,
    'open',
    'Sesi lusa untuk konsultasi kulit lanjutan.'
  );

insert into public.queue_sessions (
  id,
  schedule_id,
  current_number,
  last_number,
  is_open,
  started_at,
  closed_at
)
values
  ('88888888-8888-8888-8888-888888888881', '77777777-7777-7777-7777-777777777771', 0, 0, true, now(), null),
  ('88888888-8888-8888-8888-888888888882', '77777777-7777-7777-7777-777777777772', 0, 0, true, now(), null),
  ('88888888-8888-8888-8888-888888888883', '77777777-7777-7777-7777-777777777773', 0, 0, true, now(), null),
  ('88888888-8888-8888-8888-888888888884', '77777777-7777-7777-7777-777777777774', 0, 0, true, now(), null),
  ('88888888-8888-8888-8888-888888888885', '77777777-7777-7777-7777-777777777775', 0, 0, true, now(), null),
  ('88888888-8888-8888-8888-888888888886', '77777777-7777-7777-7777-777777777776', 0, 0, true, now(), null),
  ('88888888-8888-8888-8888-888888888887', '77777777-7777-7777-7777-777777777777', 0, 0, true, now(), null),
  ('88888888-8888-8888-8888-888888888888', '77777777-7777-7777-7777-777777777778', 0, 0, true, now(), null),
  ('88888888-8888-8888-8888-888888888889', '77777777-7777-7777-7777-777777777779', 0, 0, true, now(), null),
  ('88888888-8888-8888-8888-888888888890', '77777777-7777-7777-7777-777777777780', 0, 0, false, now() - interval '1 day', now() - interval '20 hours'),
  ('88888888-8888-8888-8888-888888888891', '77777777-7777-7777-7777-777777777781', 0, 0, true, now(), null);

-- Patient, ticket, event, and notification rows are intentionally left empty.
-- This keeps mobile testing tied to the currently logged-in user account.

commit;
