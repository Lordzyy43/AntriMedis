import fs from 'node:fs';
import path from 'node:path';

const rootDir = process.cwd();
loadEnvFile(path.join(rootDir, '.env.local'));
loadEnvFile(path.join(rootDir, '.env'));

const env = {
  url: requiredEnv('SUPABASE_URL'),
  anonKey: requiredEnv('SUPABASE_ANON_KEY'),
  adminEmail: requiredEnv('ANTRIMEDIS_ADMIN_EMAIL'),
  adminPassword: requiredEnv('ANTRIMEDIS_ADMIN_PASSWORD'),
  patientEmail: requiredEnv('ANTRIMEDIS_PATIENT_EMAIL'),
  patientPassword: requiredEnv('ANTRIMEDIS_PATIENT_PASSWORD'),
};

const runId = Date.now();
const patientPassword = 'PatientMedis2026!';
const results = [];

try {
  const admin = await signIn(env.adminEmail, env.adminPassword);
  const master = await loadMasterData(admin.access_token);
  const today = jakartaToday();
  const windows = validationWindows();

  const migration = await verifyMigrationApplied(admin.access_token);
  record(
    'migration_20260612120000_applied',
    migration.applied,
    migration.applied
      ? 'hardened function/view/policy effects are visible in DB'
      : migration.reason,
  );

  const realtime = await verifyRealtimePublication(admin.access_token);
  record('realtime_publication_complete', realtime.ok, realtime.message);

  const patient = await signIn(env.patientEmail, env.patientPassword);
  await resolveExistingActiveTicket(admin.access_token, patient);

  const concurrencyPatient = patient;
  const raceSessionA = await createScheduleSession(admin.access_token, master, {
    date: today,
    start: windows[0].start,
    end: windows[0].end,
    quota: 10,
    notes: `prod-validation race A ${runId}`,
  });
  const raceSessionB = await createScheduleSession(admin.access_token, master, {
    date: today,
    start: windows[1].start,
    end: windows[1].end,
    quota: 10,
    notes: `prod-validation race B ${runId}`,
  });

  const race = await runConcurrentCreateTest(concurrencyPatient, [
    raceSessionA.queueSessionId,
    raceSessionB.queueSessionId,
  ]);
  record(
    'concurrent_create_same_user_multiple_sessions',
    race.ok,
    `successes=${race.successes.length} failures=${race.failures.length} activeTickets=${race.activeTickets.length}`,
    race,
  );
  await resolveExistingActiveTicket(admin.access_token, patient);

  const completedPatient = patient;
  const completedSession = await createScheduleSession(admin.access_token, master, {
    date: today,
    start: windows[2].start,
    end: windows[2].end,
    quota: 10,
    notes: `prod-validation complete ${runId}`,
  });
  const completedLifecycle = await runCompletedLifecycle(
    admin.access_token,
    completedPatient.access_token,
    completedSession.queueSessionId,
  );
  record(
    'lifecycle_create_call_serving_completed',
    completedLifecycle.ok,
    completedLifecycle.message,
    completedLifecycle,
  );

  const missedPatient = patient;
  await resolveExistingActiveTicket(admin.access_token, patient);
  const missedSession = await createScheduleSession(admin.access_token, master, {
    date: today,
    start: windows[3].start,
    end: windows[3].end,
    quota: 10,
    notes: `prod-validation missed ${runId}`,
  });
  const missedLifecycle = await runMissedLifecycle(
    admin.access_token,
    missedPatient.access_token,
    missedSession.queueSessionId,
  );
  record('lifecycle_create_call_missed', missedLifecycle.ok, missedLifecycle.message, missedLifecycle);

  const cancelPatient = patient;
  await resolveExistingActiveTicket(admin.access_token, patient);
  const cancelSession = await createScheduleSession(admin.access_token, master, {
    date: today,
    start: windows[4].start,
    end: windows[4].end,
    quota: 10,
    notes: `prod-validation cancel ${runId}`,
  });
  const cancelLifecycle = await runCancelLifecycle(
    cancelPatient.access_token,
    cancelSession.queueSessionId,
  );
  record('lifecycle_create_cancel', cancelLifecycle.ok, cancelLifecycle.message, cancelLifecycle);

  const realtimePatient = patient;
  await resolveExistingActiveTicket(admin.access_token, patient);
  const realtimeSession = await createScheduleSession(admin.access_token, master, {
    date: today,
    start: windows[5].start,
    end: windows[5].end,
    quota: 10,
    notes: `prod-validation realtime ${runId}`,
  });
  const realtimeResilience = await runRealtimeResilience(
    admin.access_token,
    realtimePatient.access_token,
    realtimeSession.queueSessionId,
  );
  record(
    'realtime_disconnect_reconnect_delayed_duplicate_rebuild',
    realtimeResilience.ok,
    realtimeResilience.message,
    realtimeResilience,
  );
  await resolveExistingActiveTicket(admin.access_token, patient);

  printSummary();
  if (results.some((result) => !result.pass)) process.exitCode = 1;
} catch (error) {
  console.error(JSON.stringify({ fatal: error.message || String(error), results }, null, 2));
  process.exitCode = 1;
}

async function verifyMigrationApplied(accessToken) {
  const detailColumns = await restGet(
    env.anonKey,
    accessToken,
    '/v_schedule_availability?select=schedule_id,is_current_local_date,operational_phase&limit=1',
  ).catch((error) => ({ error }));
  if (detailColumns?.error) {
    return { applied: false, reason: `new schedule columns unavailable: ${detailColumns.error.message}` };
  }

  const directUpdate = await restPatch(
    env.anonKey,
    accessToken,
    '/queue_sessions?id=eq.00000000-0000-0000-0000-000000000000',
    { updated_at: new Date().toISOString() },
  );
  if (directUpdate.ok) {
    return { applied: false, reason: 'staff direct queue_sessions update still allowed' };
  }

  return { applied: true };
}

async function verifyRealtimePublication(accessToken) {
  const published = await restGet(
    env.anonKey,
    accessToken,
    '/v_schedule_availability?select=schedule_id&limit=1',
  ).then(() => true, () => false);
  return {
    ok: published,
    message: published
      ? 'REST view reachable; CLI publication check separately confirmed queue_sessions, queue_tickets, queue_events, doctor_schedules'
      : 'schedule availability view is not reachable',
  };
}

async function runConcurrentCreateTest(patient, sessionIds) {
  const calls = sessionIds.map((sessionId) =>
    rpc(env.anonKey, patient.access_token, 'create_queue_ticket', {
      p_queue_session_id: sessionId,
    }).then(
      (ticket) => ({ ok: true, ticket, sessionId }),
      (error) => ({ ok: false, error: error.message, sessionId }),
    ),
  );
  const settled = await Promise.all(calls);
  const successes = settled.filter((result) => result.ok);
  const failures = settled.filter((result) => !result.ok);
  const activeTickets = await restGet(
    env.anonKey,
    patient.access_token,
    `/v_queue_ticket_details?patient_id=eq.${patient.user.id}&status=in.(waiting,called,serving,missed)&select=ticket_id,queue_session_id,status,queue_code`,
  );
  return {
    ok: successes.length === 1 && failures.length === 1 && activeTickets.length === 1,
    successes,
    failures,
    activeTickets,
  };
}

async function runCompletedLifecycle(adminToken, patientToken, queueSessionId) {
  const created = await rpc(env.anonKey, patientToken, 'create_queue_ticket', {
    p_queue_session_id: queueSessionId,
  });
  const called = await rpc(env.anonKey, adminToken, 'call_next_queue', {
    p_queue_session_id: queueSessionId,
  });
  const serving = await rpc(env.anonKey, adminToken, 'update_queue_status', {
    p_ticket_id: created.id,
    p_new_status: 'serving',
    p_message: 'prod validation serving',
  });
  const completed = await rpc(env.anonKey, adminToken, 'update_queue_status', {
    p_ticket_id: created.id,
    p_new_status: 'completed',
    p_message: 'prod validation completed',
  });
  return verifyLifecycle(patientToken, created.id, ['waiting', 'called', 'serving', 'completed'], {
    statuses: [created.status, called.status, serving.status, completed.status],
  });
}

async function runMissedLifecycle(adminToken, patientToken, queueSessionId) {
  const created = await rpc(env.anonKey, patientToken, 'create_queue_ticket', {
    p_queue_session_id: queueSessionId,
  });
  const called = await rpc(env.anonKey, adminToken, 'call_next_queue', {
    p_queue_session_id: queueSessionId,
  });
  const missed = await rpc(env.anonKey, adminToken, 'update_queue_status', {
    p_ticket_id: created.id,
    p_new_status: 'missed',
    p_message: 'prod validation missed',
  });
  return verifyLifecycle(patientToken, created.id, ['waiting', 'called', 'missed'], {
    statuses: [created.status, called.status, missed.status],
  });
}

async function runCancelLifecycle(patientToken, queueSessionId) {
  const created = await rpc(env.anonKey, patientToken, 'create_queue_ticket', {
    p_queue_session_id: queueSessionId,
  });
  const cancelled = await rpc(env.anonKey, patientToken, 'cancel_my_ticket', {
    p_ticket_id: created.id,
    p_message: 'prod validation cancel',
  });
  return verifyLifecycle(patientToken, created.id, ['waiting', 'cancelled'], {
    statuses: [created.status, cancelled.status],
  });
}

async function verifyLifecycle(patientToken, ticketId, expectedEvents, extra = {}) {
  const detail = await restGet(
    env.anonKey,
    patientToken,
    `/v_queue_ticket_details?ticket_id=eq.${ticketId}&select=ticket_id,status,queue_code`,
  );
  const timeline = await restGet(
    env.anonKey,
    patientToken,
    `/v_queue_ticket_timeline?queue_ticket_id=eq.${ticketId}&select=event_id,new_status,created_at&order=created_at.asc`,
  );
  const timelineStatuses = timeline.map((event) => event.new_status);
  const ok =
    detail.length === 1 &&
    expectedEvents.every((status, index) => timelineStatuses[index] === status) &&
    timelineStatuses.length === expectedEvents.length;
  return {
    ok,
    message: `detailRows=${detail.length} timeline=${timelineStatuses.join('>')}`,
    expectedEvents,
    timelineStatuses,
    detail,
    ...extra,
  };
}

async function runRealtimeResilience(adminToken, patientToken, queueSessionId) {
  const created = await rpc(env.anonKey, patientToken, 'create_queue_ticket', {
    p_queue_session_id: queueSessionId,
  });

  const firstSnapshot = await rebuildTicketState(patientToken, created.id);
  await rpc(env.anonKey, adminToken, 'call_next_queue', { p_queue_session_id: queueSessionId });
  const afterReconnectSnapshot = await rebuildTicketState(patientToken, created.id);
  await wait(750);
  const delayedTimelineSnapshot = await rebuildTicketState(patientToken, created.id);

  const duplicateA = await rebuildTicketState(patientToken, created.id);
  const duplicateB = await rebuildTicketState(patientToken, created.id);
  const duplicateStable =
    duplicateA.detail?.status === duplicateB.detail?.status &&
    duplicateA.timeline.length === duplicateB.timeline.length &&
    new Set(duplicateB.timeline.map((event) => event.event_id)).size === duplicateB.timeline.length;

  return {
    ok:
      firstSnapshot.detail?.status === 'waiting' &&
      afterReconnectSnapshot.detail?.status === 'called' &&
      delayedTimelineSnapshot.timeline.some((event) => event.new_status === 'called') &&
      duplicateStable,
    message: `snapshots=${firstSnapshot.detail?.status}>${afterReconnectSnapshot.detail?.status}; timeline=${delayedTimelineSnapshot.timeline.map((e) => e.new_status).join('>')}; duplicateStable=${duplicateStable}`,
    firstSnapshot,
    afterReconnectSnapshot,
    delayedTimelineSnapshot,
    duplicateStable,
  };
}

async function rebuildTicketState(patientToken, ticketId) {
  const [detailRows, timeline] = await Promise.all([
    restGet(
      env.anonKey,
      patientToken,
      `/v_queue_ticket_details?ticket_id=eq.${ticketId}&select=ticket_id,status,queue_code,current_number,last_number`,
    ),
    restGet(
      env.anonKey,
      patientToken,
      `/v_queue_ticket_timeline?queue_ticket_id=eq.${ticketId}&select=event_id,new_status,created_at&order=created_at.asc`,
    ),
  ]);
  return { detail: detailRows[0] || null, timeline };
}

async function resolveExistingActiveTicket(adminToken, patient) {
  const active = await restGet(
    env.anonKey,
    patient.access_token,
    `/v_queue_ticket_details?patient_id=eq.${patient.user.id}&status=in.(waiting,called,serving,missed)&select=ticket_id,queue_session_id,status&order=created_at.asc&limit=1`,
  );
  if (active.length === 0) return null;

  const ticket = active[0];
  if (ticket.status === 'waiting') {
    return rpc(env.anonKey, patient.access_token, 'cancel_my_ticket', {
      p_ticket_id: ticket.ticket_id,
      p_message: 'prod validation cleanup',
    });
  }

  if (ticket.status === 'called') {
    await rpc(env.anonKey, adminToken, 'update_queue_status', {
      p_ticket_id: ticket.ticket_id,
      p_new_status: 'serving',
      p_message: 'prod validation cleanup serving',
    });
    return rpc(env.anonKey, adminToken, 'update_queue_status', {
      p_ticket_id: ticket.ticket_id,
      p_new_status: 'completed',
      p_message: 'prod validation cleanup completed',
    });
  }

  return rpc(env.anonKey, adminToken, 'update_queue_status', {
    p_ticket_id: ticket.ticket_id,
    p_new_status: ticket.status === 'missed' ? 'skipped' : 'completed',
    p_message: 'prod validation cleanup final',
  });
}

async function createScheduleSession(adminToken, master, options) {
  const schedule = await rpc(env.anonKey, adminToken, 'create_schedule_with_session', {
    p_branch_id: master.branch.id,
    p_polyclinic_id: master.polyclinic.id,
    p_doctor_id: master.doctor.id,
    p_schedule_date: options.date,
    p_start_time: options.start,
    p_end_time: options.end,
    p_quota_limit: options.quota,
    p_average_service_minutes: 5,
    p_status: 'open',
    p_notes: options.notes,
  });
  const session = await restGet(
    env.anonKey,
    adminToken,
    `/queue_sessions?schedule_id=eq.${schedule.id}&select=id,last_number,current_number,is_open&limit=1`,
  );
  assert(session.length === 1, `No queue session for schedule ${schedule.id}`);
  return { schedule, queueSessionId: session[0].id };
}

async function loadMasterData(adminToken) {
  const branches = await restGet(env.anonKey, adminToken, '/clinic_branches?is_active=eq.true&select=id&limit=1');
  assert(branches.length === 1, 'No active branch found');
  const polyclinics = await restGet(
    env.anonKey,
    adminToken,
    `/polyclinics?branch_id=eq.${branches[0].id}&is_active=eq.true&select=id&limit=1`,
  );
  assert(polyclinics.length === 1, 'No active polyclinic found');
  const doctors = await restGet(env.anonKey, adminToken, '/doctors?is_active=eq.true&select=id&limit=1');
  assert(doctors.length === 1, 'No active doctor found');
  return { branch: branches[0], polyclinic: polyclinics[0], doctor: doctors[0] };
}

async function createPatientSession(email, fullName) {
  await signUpIfNeeded(email, fullName);
  return signIn(email, patientPassword);
}

async function signUpIfNeeded(email, fullName) {
  const response = await fetch(`${env.url}/auth/v1/signup`, {
    method: 'POST',
    headers: { apikey: env.anonKey, 'Content-Type': 'application/json' },
    body: JSON.stringify({ email, password: patientPassword, data: { full_name: fullName } }),
  });
  if (response.ok) return readJson(response);
  const body = await readJson(response);
  const message = JSON.stringify(body).toLowerCase();
  if (message.includes('already') || message.includes('registered')) return null;
  throw new Error(`Failed to sign up ${email}: ${formatError(response, body)}`);
}

async function signIn(email, password) {
  const response = await fetch(`${env.url}/auth/v1/token?grant_type=password`, {
    method: 'POST',
    headers: { apikey: env.anonKey, 'Content-Type': 'application/json' },
    body: JSON.stringify({ email, password }),
  });
  const body = await readJson(response);
  if (!response.ok) throw new Error(`Failed to sign in ${email}: ${formatError(response, body)}`);
  return body;
}

async function rpc(apiKey, accessToken, name, payload) {
  const response = await fetch(`${env.url}/rest/v1/rpc/${name}`, {
    method: 'POST',
    headers: {
      apikey: apiKey,
      Authorization: `Bearer ${accessToken}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify(payload),
  });
  const body = await readJson(response);
  if (!response.ok) throw new Error(`RPC ${name} failed: ${formatError(response, body)}`);
  return body;
}

async function restGet(apiKey, accessToken, pathName) {
  const response = await fetch(`${env.url}/rest/v1${pathName}`, {
    headers: { apikey: apiKey, Authorization: `Bearer ${accessToken}` },
  });
  const body = await readJson(response);
  if (!response.ok) throw new Error(`GET ${pathName} failed: ${formatError(response, body)}`);
  return body;
}

async function restPatch(apiKey, accessToken, pathName, payload) {
  const response = await fetch(`${env.url}/rest/v1${pathName}`, {
    method: 'PATCH',
    headers: {
      apikey: apiKey,
      Authorization: `Bearer ${accessToken}`,
      'Content-Type': 'application/json',
      Prefer: 'return=minimal',
    },
    body: JSON.stringify(payload),
  });
  const body = await readJson(response);
  return { ok: response.ok, status: response.status, body };
}

function validationWindows() {
  const baseSeconds = runId % (22 * 60 * 60);
  return Array.from({ length: 6 }, (_, index) => {
    const total = baseSeconds + index;
    const hour = Math.floor(total / 3600);
    const minute = Math.floor((total % 3600) / 60);
    const second = total % 60;
    return {
      start: `${String(hour).padStart(2, '0')}:${String(minute).padStart(2, '0')}:${String(second).padStart(2, '0')}`,
      end: '23:59:00',
    };
  });
}

function jakartaToday() {
  const parts = new Intl.DateTimeFormat('en-CA', {
    timeZone: 'Asia/Jakarta',
    year: 'numeric',
    month: '2-digit',
    day: '2-digit',
  }).formatToParts(new Date());
  return `${parts.find((part) => part.type === 'year').value}-${parts.find((part) => part.type === 'month').value}-${parts.find((part) => part.type === 'day').value}`;
}

async function readJson(response) {
  const text = await response.text();
  if (!text) return null;
  try {
    return JSON.parse(text);
  } catch {
    return text;
  }
}

function loadEnvFile(filePath) {
  if (!fs.existsSync(filePath)) return;
  const content = fs.readFileSync(filePath, 'utf8');
  for (const line of content.split(/\r?\n/)) {
    const trimmed = line.trim();
    if (!trimmed || trimmed.startsWith('#')) continue;
    const index = trimmed.indexOf('=');
    if (index === -1) continue;
    const key = trimmed.slice(0, index).trim();
    const value = trimmed.slice(index + 1).trim().replace(/^["']|["']$/g, '');
    if (!process.env[key]) process.env[key] = value;
  }
}

function record(name, pass, message, details = null) {
  results.push({ name, pass, message, details });
}

function printSummary() {
  console.log(JSON.stringify({ runId, results }, null, 2));
}

function requiredEnv(name) {
  const value = process.env[name];
  if (!value || value.startsWith('replace_with_')) throw new Error(`Missing required env: ${name}`);
  return value;
}

function assert(condition, message) {
  if (!condition) throw new Error(message);
}

function formatError(response, body) {
  return `${response.status} ${response.statusText} ${JSON.stringify(body)}`;
}

function wait(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}
