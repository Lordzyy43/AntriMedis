create or replace function public.delete_doctor_if_unused(p_doctor_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if not public.is_staff() then
    raise exception 'Only clinic staff can delete doctors';
  end if;

  if exists (
    select 1
    from public.doctor_schedules
    where doctor_id = p_doctor_id
  ) then
    raise exception 'Doctor is used by schedules. Deactivate instead.';
  end if;

  delete from public.doctors
  where id = p_doctor_id;

  if not found then
    raise exception 'Doctor not found';
  end if;
end;
$$;

create or replace function public.delete_polyclinic_if_unused(p_polyclinic_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if not public.is_staff() then
    raise exception 'Only clinic staff can delete polyclinics';
  end if;

  if exists (
    select 1
    from public.doctor_schedules
    where polyclinic_id = p_polyclinic_id
  ) then
    raise exception 'Polyclinic is used by schedules. Deactivate instead.';
  end if;

  delete from public.polyclinics
  where id = p_polyclinic_id;

  if not found then
    raise exception 'Polyclinic not found';
  end if;
end;
$$;

create or replace function public.delete_schedule_if_empty(p_schedule_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if not public.is_staff() then
    raise exception 'Only clinic staff can delete schedules';
  end if;

  if exists (
    select 1
    from public.queue_sessions qs
    join public.queue_tickets qt on qt.queue_session_id = qs.id
    where qs.schedule_id = p_schedule_id
  ) then
    raise exception 'Schedule already has queue tickets. Cancel or close instead.';
  end if;

  delete from public.doctor_schedules
  where id = p_schedule_id;

  if not found then
    raise exception 'Schedule not found';
  end if;
end;
$$;

grant execute on function public.delete_doctor_if_unused(uuid) to authenticated;
grant execute on function public.delete_polyclinic_if_unused(uuid) to authenticated;
grant execute on function public.delete_schedule_if_empty(uuid) to authenticated;
