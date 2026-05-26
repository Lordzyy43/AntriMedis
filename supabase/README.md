# Supabase Setup - AntriMedis

Project Supabase remote:

```txt
Name        : AntriMedis
Project ref : vicwdxxjaoekppembbvt
Region      : Southeast Asia (Singapore)
```

## Local CLI

The Supabase CLI is available through `npx` in this workspace:

```bash
npx supabase projects list
npx supabase migration list
npx supabase db push
```

Docker Desktop is required only for local Supabase services, local reset, and database dump workflows.

## Admin Bootstrap

The migration creates patient profiles automatically when a user signs up through Supabase Auth.

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

## Demo Queue Sessions

The first migration seeds one clinic, one branch, three polyclinics, three doctors, today's schedules, and queue sessions:

```txt
Klinik Sehat Sentosa
Cabang Utama
Poli Umum  -> U001, U002, ...
Poli Gigi  -> G001, G002, ...
Poli Anak  -> A001, A002, ...
```

Use `v_schedule_availability` to list available schedules in the mobile app.
