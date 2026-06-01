drop function if exists public.delete_doctor_if_unused(uuid);
drop function if exists public.delete_polyclinic_if_unused(uuid);

create or replace function public.delete_doctor_if_unused(p_doctor_id uuid)
returns text
language plpgsql
security definer
set search_path = public
as $$
begin
  if not public.is_staff() then
    raise exception 'Only clinic staff can delete doctors';
  end if;

  if not exists (
    select 1
    from public.doctors
    where id = p_doctor_id
  ) then
    raise exception 'Doctor not found';
  end if;

  if exists (
    select 1
    from public.doctor_schedules
    where doctor_id = p_doctor_id
  ) then
    update public.doctors
    set is_active = false
    where id = p_doctor_id;

    return 'archived';
  end if;

  delete from public.doctors
  where id = p_doctor_id;

  return 'deleted';
end;
$$;

create or replace function public.delete_polyclinic_if_unused(p_polyclinic_id uuid)
returns text
language plpgsql
security definer
set search_path = public
as $$
begin
  if not public.is_staff() then
    raise exception 'Only clinic staff can delete polyclinics';
  end if;

  if not exists (
    select 1
    from public.polyclinics
    where id = p_polyclinic_id
  ) then
    raise exception 'Polyclinic not found';
  end if;

  if exists (
    select 1
    from public.doctor_schedules
    where polyclinic_id = p_polyclinic_id
  ) then
    update public.polyclinics
    set is_active = false
    where id = p_polyclinic_id;

    return 'archived';
  end if;

  delete from public.polyclinics
  where id = p_polyclinic_id;

  return 'deleted';
end;
$$;

grant execute on function public.delete_doctor_if_unused(uuid) to authenticated;
grant execute on function public.delete_polyclinic_if_unused(uuid) to authenticated;
