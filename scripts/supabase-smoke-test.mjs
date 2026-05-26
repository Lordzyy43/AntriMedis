import fs from 'node:fs';
import path from 'node:path';

const rootDir = process.cwd();
loadEnvFile(path.join(rootDir, '.env.local'));
loadEnvFile(path.join(rootDir, '.env'));

const args = new Set(process.argv.slice(2));
const shouldBootstrap = args.has('--bootstrap');

const env = {
  url: requiredEnv('SUPABASE_URL'),
  anonKey: requiredEnv('SUPABASE_ANON_KEY'),
  serviceRoleKey: process.env.SUPABASE_SERVICE_ROLE_KEY,
  adminEmail: requiredEnv('ANTRIMEDIS_ADMIN_EMAIL'),
  adminPassword: requiredEnv('ANTRIMEDIS_ADMIN_PASSWORD'),
  patientEmail:
    process.env.ANTRIMEDIS_PATIENT_EMAIL ||
    `patient.${Date.now()}@antrimedis.test`,
  patientPassword: process.env.ANTRIMEDIS_PATIENT_PASSWORD || 'Patient123!',
};

const demoBranchId = '22222222-2222-2222-2222-222222222222';

try {
  if (shouldBootstrap) {
    assert(env.serviceRoleKey, 'SUPABASE_SERVICE_ROLE_KEY is required for --bootstrap.');
    logStep('Bootstrapping test accounts');
    await ensureUser(env.adminEmail, env.adminPassword, 'Admin AntriMedis');
    await ensureUser(env.patientEmail, env.patientPassword, 'Pasien Smoke Test');
    await grantAdminRole(env.adminEmail);
    logOk('Admin and patient accounts are ready');
  }

  logStep('Signing in patient');
  await signUpIfNeeded(env.patientEmail, env.patientPassword, 'Pasien Smoke Test');
  const patientSession = await signIn(env.patientEmail, env.patientPassword);
  logOk(`Patient signed in: ${patientSession.user.email}`);

  logStep('Checking schedule availability as patient');
  const availableSchedules = await restGet(
    env.anonKey,
    patientSession.access_token,
    '/v_schedule_availability?select=*&status=eq.open&remaining_quota=gt.0&order=start_time.asc&limit=1',
  );

  assert(Array.isArray(availableSchedules) && availableSchedules.length > 0, 'No open schedule found.');
  const schedule = availableSchedules[0];
  assert(schedule.queue_session_id, 'Open schedule has no queue_session_id.');
  logOk(`Using ${schedule.polyclinic_name} / ${schedule.doctor_name} (${schedule.queue_session_id})`);

  logStep('Creating queue ticket as patient');
  const createdTicket = await rpc(
    env.anonKey,
    patientSession.access_token,
    'create_queue_ticket',
    { p_queue_session_id: schedule.queue_session_id },
  );
  assert(createdTicket?.id, 'create_queue_ticket did not return a ticket.');
  logOk(`Created ticket ${createdTicket.queue_code} with status ${createdTicket.status}`);

  logStep('Signing in admin');
  const adminSession = await signIn(env.adminEmail, env.adminPassword);
  logOk(`Admin signed in: ${adminSession.user.email}`);

  logStep('Calling next queue as admin');
  const calledTicket = await rpc(
    env.anonKey,
    adminSession.access_token,
    'call_next_queue',
    { p_queue_session_id: schedule.queue_session_id },
  );
  assert(calledTicket?.id, 'call_next_queue did not return a ticket.');
  logOk(`Called ticket ${calledTicket.queue_code}`);

  logStep('Updating queue to serving');
  const servingTicket = await rpc(
    env.anonKey,
    adminSession.access_token,
    'update_queue_status',
    {
      p_ticket_id: calledTicket.id,
      p_new_status: 'serving',
      p_message: 'Smoke test: serving',
    },
  );
  assert(servingTicket.status === 'serving', 'Ticket did not enter serving status.');
  logOk(`Ticket ${servingTicket.queue_code} is serving`);

  logStep('Updating queue to completed');
  const completedTicket = await rpc(
    env.anonKey,
    adminSession.access_token,
    'update_queue_status',
    {
      p_ticket_id: calledTicket.id,
      p_new_status: 'completed',
      p_message: 'Smoke test: completed',
    },
  );
  assert(completedTicket.status === 'completed', 'Ticket did not enter completed status.');
  logOk(`Ticket ${completedTicket.queue_code} is completed`);

  logStep('Verifying patient can read ticket detail');
  const detail = await restGet(
    env.anonKey,
    patientSession.access_token,
    `/v_queue_ticket_details?ticket_id=eq.${createdTicket.id}&select=*`,
  );
  assert(detail.length === 1, 'Patient cannot read created ticket detail.');
  logOk(`Verified ticket detail for ${detail[0].queue_code}`);

  console.log('\nSupabase smoke test passed.');
} catch (error) {
  console.error('\nSupabase smoke test failed.');
  console.error(error.message || error);
  process.exitCode = 1;
}

async function ensureUser(email, password, fullName) {
  const response = await fetch(`${env.url}/auth/v1/admin/users`, {
    method: 'POST',
    headers: {
      apikey: env.serviceRoleKey,
      Authorization: `Bearer ${env.serviceRoleKey}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      email,
      password,
      email_confirm: true,
      user_metadata: { full_name: fullName },
    }),
  });

  if (response.ok) return response.json();

  const body = await readJson(response);
  const message = JSON.stringify(body).toLowerCase();
  if (response.status === 422 && message.includes('already')) return null;
  throw new Error(`Failed to create ${email}: ${formatError(response, body)}`);
}

async function grantAdminRole(email) {
  const adminLogin = await signIn(email, env.adminPassword);
  const roles = await restGet(
    env.serviceRoleKey,
    env.serviceRoleKey,
    '/roles?code=eq.admin&select=id&limit=1',
  );
  assert(roles.length === 1, 'Admin role not found.');

  await restPost(
    env.serviceRoleKey,
    env.serviceRoleKey,
    '/user_roles?on_conflict=user_id,role_id',
    {
      user_id: adminLogin.user.id,
      role_id: roles[0].id,
    },
    { prefer: 'resolution=merge-duplicates' },
  );

  await restPost(
    env.serviceRoleKey,
    env.serviceRoleKey,
    '/clinic_staff?on_conflict=branch_id,user_id',
    {
      branch_id: demoBranchId,
      user_id: adminLogin.user.id,
      staff_title: 'Resepsionis',
    },
    { prefer: 'resolution=merge-duplicates' },
  );
}

async function signUpIfNeeded(email, password, fullName) {
  const response = await fetch(`${env.url}/auth/v1/signup`, {
    method: 'POST',
    headers: {
      apikey: env.anonKey,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      email,
      password,
      data: { full_name: fullName },
    }),
  });

  if (response.ok) return response.json();
  const body = await readJson(response);
  const message = JSON.stringify(body).toLowerCase();
  if (message.includes('already') || message.includes('registered')) return null;
  throw new Error(`Failed to sign up ${email}: ${formatError(response, body)}`);
}

async function signIn(email, password) {
  const response = await fetch(`${env.url}/auth/v1/token?grant_type=password`, {
    method: 'POST',
    headers: {
      apikey: env.anonKey,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({ email, password }),
  });

  const body = await readJson(response);
  if (!response.ok) {
    throw new Error(`Failed to sign in ${email}: ${formatError(response, body)}`);
  }
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
    headers: {
      apikey: apiKey,
      Authorization: `Bearer ${accessToken}`,
    },
  });

  const body = await readJson(response);
  if (!response.ok) throw new Error(`GET ${pathName} failed: ${formatError(response, body)}`);
  return body;
}

async function restPost(apiKey, accessToken, pathName, payload, options = {}) {
  const response = await fetch(`${env.url}/rest/v1${pathName}`, {
    method: 'POST',
    headers: {
      apikey: apiKey,
      Authorization: `Bearer ${accessToken}`,
      'Content-Type': 'application/json',
      Prefer: options.prefer || 'return=representation',
    },
    body: JSON.stringify(payload),
  });

  const body = await readJson(response);
  if (!response.ok) throw new Error(`POST ${pathName} failed: ${formatError(response, body)}`);
  return body;
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

function requiredEnv(name) {
  const value = process.env[name];
  if (!value || value.startsWith('replace_with_')) {
    throw new Error(`Missing required env: ${name}`);
  }
  return value;
}

function assert(condition, message) {
  if (!condition) throw new Error(message);
}

function formatError(response, body) {
  return `${response.status} ${response.statusText} ${JSON.stringify(body)}`;
}

function logStep(message) {
  console.log(`\n> ${message}`);
}

function logOk(message) {
  console.log(`  OK ${message}`);
}
