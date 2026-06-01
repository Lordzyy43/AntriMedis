# Supabase Setup - AntriMedis

Project Supabase remote:

```txt
Name        : AntriMedis
Project ref : vicwdxxjaoekppembbvt
Region      : Southeast Asia (Singapore)
```

## Local CLI

The Supabase CLI is available on this machine after adding the npm global path to `PATH`:

```powershell
$env:Path += ";$env:APPDATA\npm"
supabase --version
```

If `supabase` is not recognized, use the direct executable:

```powershell
& "$env:APPDATA\npm\supabase.cmd" --version
```

Common commands:

```powershell
supabase link --project-ref vicwdxxjaoekppembbvt
supabase migration list
supabase db push
supabase db query --linked --file supabase/patches/20260528_clean_professional_demo_seed.sql
```

Docker Desktop is required only for local Supabase services, local reset, and database dump workflows.

## Admin Bootstrap

The migration creates patient profiles automatically when a user signs up through Supabase Auth. Passwords are managed by Supabase Auth in the `auth` schema and are not stored in public tables.

Current professional demo admin:

```txt
Email    : admin@antrimedis.test
Password : AdminMedis2026!
Name     : Nadia Prameswari
Role     : admin
Branch   : Cabang Utama Patrang
Title    : Koordinator Front Office
```

To reset operational data and reseed the professional demo clinic dataset, run:

```bash
supabase db query --linked --file supabase/patches/20260528_clean_professional_demo_seed.sql
```

To create an admin:

1. Create an auth user from Supabase Dashboard, or register normally from the app.
2. Run this SQL in Supabase SQL Editor:

```sql
select public.assign_role_by_email(
  'admin@example.com',
  'admin',
  '22222222-2222-2222-2222-222222222222',
  'Resepsionis'
);
```

The `assign_role_by_email` function is intentionally not executable from client apps.

## Smoke Test

Copy `.env.example` to `.env.local`, fill the Supabase anon key and test account credentials, then run:

```bash
npm run smoke:supabase
```

For a fresh project, you can let the script create confirmed test users and assign the admin role by temporarily providing `SUPABASE_SERVICE_ROLE_KEY` in `.env.local`:

```bash
npm run smoke:supabase:bootstrap
```

Remove `SUPABASE_SERVICE_ROLE_KEY` from `.env.local` after bootstrap. The file is ignored by Git.

## Professional Demo Dataset

The professional seed script creates a richer clinic demo dataset for mobile and admin testing:

```txt
Klinik Sehat Sentosa
Cabang Utama Patrang
6 poli aktif
8 dokter/tenaga layanan aktif
11 jadwal lintas kemarin, hari ini, besok, dan lusa
0 tiket antrean awal
0 queue events awal
0 notifications awal
```

Patient accounts are intentionally not seeded. Use the currently logged-in mobile user to take a queue number, so tracking/progress belongs to the real test account instead of a demo patient.

Use `v_schedule_availability` to list available schedules in the mobile app.

## Current Backend Notes

Important RPCs:

```txt
create_queue_ticket
cancel_my_ticket
call_next_queue
update_queue_status
create_schedule_with_session
update_schedule_with_session
delete_schedule_if_empty
delete_doctor_if_unused
delete_polyclinic_if_unused
```

Important views:

```txt
v_schedule_availability
v_queue_ticket_details
v_queue_event_feed
```

For the latest project status, see `../docs/prd_status_roadmap.md` and `../docs/current_project_snapshot.md`.
