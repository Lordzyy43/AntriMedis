do $$
begin
  if not exists (
    select 1
    from pg_publication_tables
    where pubname = 'supabase_realtime'
      and schemaname = 'public'
      and tablename = 'doctor_schedules'
  ) then
    alter publication supabase_realtime add table public.doctor_schedules;
  end if;
end $$;
