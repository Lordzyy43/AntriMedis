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

Current QA patient for mobile/web patient login:

```txt
Email    : pasien1@antrimedis.test
Password : PatientMedis2026!
Role     : patient
```

Easy QA patient pool:

```txt
pasien1@antrimedis.test
pasien2@antrimedis.test
pasien3@antrimedis.test
pasien4@antrimedis.test
pasien5@antrimedis.test
pasien6@antrimedis.test
pasien7@antrimedis.test
pasien8@antrimedis.test
pasien9@antrimedis.test
pasien10@antrimedis.test

Password for all: PatientMedis2026!
```

To reset operational data and reseed the professional demo clinic dataset, run:

```bash
supabase db query --linked --file supabase/patches/20260528_clean_professional_demo_seed.sql
```

To reset only operational queue data while keeping master data, run:

```bash
supabase db query --linked --file supabase/patches/20260604_reset_operational_data_keep_master.sql
```

This keeps:

```txt
clinics, branches, staff, roles, doctors, polyclinics, users, and patient profiles
```

It clears:

```txt
doctor_schedules, queue_sessions, queue_tickets, queue_events, and queue notifications
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

The professional clinic dataset itself starts with no queue tickets, events, or notifications. Use the QA patient above, or a freshly registered patient account, to take a queue number so tracking/progress belongs to the user currently under test.

Use `v_schedule_availability` to list available schedules in the mobile app.

## Operational Data Reset

To clear schedules, queue sessions, tickets, queue events, and queue notifications while keeping doctors, polyclinics, users, roles, clinic, and branch data, use the reset SQL documented in:

```txt
../docs/queue_business_flow.md
```

This is useful when the admin wants to create fresh schedules manually before testing the queue flow again.

The ready-to-run version is available at:

```txt
supabase/patches/20260604_reset_operational_data_keep_master.sql
```

## Current Backend Notes

Important RPCs:

```txt
create_queue_ticket
cancel_my_ticket
call_next_queue
recall_missed_queue
update_queue_status
close_queue_session
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

Realtime publication currently includes:

```txt
queue_tickets
queue_sessions
doctor_schedules
queue_events
notifications
```

Current queue business rules:

- AntriMedis is a same-day queue system, not future booking.
- Patients can take a number before schedule start time on the service date.
- Patients cannot take a number exactly at or after schedule end time.
- Staff cannot call before schedule start time.
- Staff can keep draining existing waiting queues at or after schedule end time.
- Missed queues are recalled with the same number after regular waiting queues are finished.
- Closing a session changes remaining `waiting` to `expired` and `missed` to `skipped`.
- Quota is based on tickets taken except `cancelled`; completed tickets do not restore quota.

For the latest project status, see `../docs/prd_status_roadmap.md` and `../docs/current_project_snapshot.md`.

For queue business rules, status lifecycle, realtime expectations, edge cases, and manual QA checklist, see:

```txt
../docs/queue_business_flow.md
```

## Heartbeat Function

If you want a very small keep-alive endpoint, use the `heartbeat` Edge Function:

```txt
supabase/functions/heartbeat/index.ts
```

It returns a simple JSON `ok` response.
It also pings the database with the project service role key, so the request is not just a no-op.

Recommended setup for the free plan:

1. Deploy the function.
2. Let GitHub Actions call it daily from:

```txt
.github/workflows/supabase-heartbeat.yml
```

The schedule runs once a day at `00:15 UTC`, which is enough to keep the project regularly active without being noisy.

Deployment command:

```bash
supabase functions deploy heartbeat
```
