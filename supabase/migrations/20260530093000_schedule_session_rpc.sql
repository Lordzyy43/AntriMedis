-- Keep schedule and queue session writes atomic.
-- Admin panel should use these RPCs instead of separate doctor_schedules
-- and queue_sessions writes, so a failed session write rolls back the schedule.

create or replace function public.create_schedule_with_session(
  p_branch_id uuid,
  p_polyclinic_id uuid,
  p_doctor_id uuid,
  p_schedule_date date,
  p_start_time time,
  p_end_time time,
  p_quota_limit int,
  p_average_service_minutes int,
  p_status public.schedule_status default 'open',
  p_notes text default null
)
returns public.doctor_schedules
language plpgsql
security definer
set search_path = public
as $$
declare
  v_schedule public.doctor_schedules%rowtype;
  v_is_open boolean;
begin
  if not public.is_staff() then
    raise exception 'Forbidden';
  end if;

  if p_end_time <= p_start_time then
    raise exception 'Schedule end time must be after start time';
  end if;

  if p_quota_limit <= 0 then
    raise exception 'Schedule quota must be greater than zero';
  end if;

  if p_average_service_minutes <= 0 then
    raise exception 'Average service minutes must be greater than zero';
  end if;

  if not exists (
    select 1
    from public.clinic_branches
    where id = p_branch_id
      and is_active = true
  ) then
    raise exception 'Clinic branch is not active';
  end if;

  if not exists (
    select 1
    from public.polyclinics
    where id = p_polyclinic_id
      and branch_id = p_branch_id
      and is_active = true
  ) then
    raise exception 'Polyclinic is not active in this branch';
  end if;

  if not exists (
    select 1
    from public.doctors
    where id = p_doctor_id
      and is_active = true
  ) then
    raise exception 'Doctor is not active';
  end if;

  insert into public.doctor_schedules (
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
  ) values (
    p_branch_id,
    p_polyclinic_id,
    p_doctor_id,
    p_schedule_date,
    p_start_time,
    p_end_time,
    p_quota_limit,
    p_average_service_minutes,
    p_status,
    p_notes
  )
  returning * into v_schedule;

  v_is_open := p_status = 'open';

  insert into public.queue_sessions (
    schedule_id,
    is_open,
    started_at,
    closed_at
  ) values (
    v_schedule.id,
    v_is_open,
    case when v_is_open then now() else null end,
    case when v_is_open then null else now() end
  );

  return v_schedule;
end;
$$;

create or replace function public.update_schedule_with_session(
  p_schedule_id uuid,
  p_branch_id uuid,
  p_polyclinic_id uuid,
  p_doctor_id uuid,
  p_schedule_date date,
  p_start_time time,
  p_end_time time,
  p_quota_limit int,
  p_average_service_minutes int,
  p_status public.schedule_status,
  p_notes text default null
)
returns public.doctor_schedules
language plpgsql
security definer
set search_path = public
as $$
declare
  v_schedule public.doctor_schedules%rowtype;
  v_session public.queue_sessions%rowtype;
  v_is_open boolean;
begin
  if not public.is_staff() then
    raise exception 'Forbidden';
  end if;

  select * into v_session
  from public.queue_sessions
  where schedule_id = p_schedule_id
  for update;

  if not found then
    raise exception 'Queue session not found for schedule';
  end if;

  if p_end_time <= p_start_time then
    raise exception 'Schedule end time must be after start time';
  end if;

  if p_quota_limit <= 0 then
    raise exception 'Schedule quota must be greater than zero';
  end if;

  if p_average_service_minutes <= 0 then
    raise exception 'Average service minutes must be greater than zero';
  end if;

  if v_session.last_number > p_quota_limit then
    raise exception 'Schedule quota cannot be lower than existing taken queue count';
  end if;

  if not exists (
    select 1
    from public.clinic_branches
    where id = p_branch_id
      and is_active = true
  ) then
    raise exception 'Clinic branch is not active';
  end if;

  if not exists (
    select 1
    from public.polyclinics
    where id = p_polyclinic_id
      and branch_id = p_branch_id
      and is_active = true
  ) then
    raise exception 'Polyclinic is not active in this branch';
  end if;

  if not exists (
    select 1
    from public.doctors
    where id = p_doctor_id
      and is_active = true
  ) then
    raise exception 'Doctor is not active';
  end if;

  update public.doctor_schedules
  set branch_id = p_branch_id,
      polyclinic_id = p_polyclinic_id,
      doctor_id = p_doctor_id,
      schedule_date = p_schedule_date,
      start_time = p_start_time,
      end_time = p_end_time,
      quota_limit = p_quota_limit,
      average_service_minutes = p_average_service_minutes,
      status = p_status,
      notes = p_notes
  where id = p_schedule_id
  returning * into v_schedule;

  if not found then
    raise exception 'Schedule not found';
  end if;

  v_is_open := p_status = 'open';

  update public.queue_sessions
  set is_open = v_is_open,
      started_at = case
        when v_is_open and started_at is null then now()
        else started_at
      end,
      closed_at = case
        when v_is_open then null
        when closed_at is null then now()
        else closed_at
      end
  where id = v_session.id;

  perform public.refresh_queue_estimates(v_session.id);

  return v_schedule;
end;
$$;

grant execute on function public.create_schedule_with_session(
  uuid,
  uuid,
  uuid,
  date,
  time,
  time,
  int,
  int,
  public.schedule_status,
  text
) to authenticated;

grant execute on function public.update_schedule_with_session(
  uuid,
  uuid,
  uuid,
  uuid,
  date,
  time,
  time,
  int,
  int,
  public.schedule_status,
  text
) to authenticated;
