import fs from 'node:fs';
import path from 'node:path';

const rootDir = process.cwd();
loadEnvFile(path.join(rootDir, '.env.local'));
loadEnvFile(path.join(rootDir, '.env'));

const env = {
  url: requiredEnv('SUPABASE_URL'),
  anonKey: requiredEnv('SUPABASE_ANON_KEY'),
};

const args = new Set(process.argv.slice(2));
const verifyOnly = args.has('--verify-only');
const password = process.env.ANTRIMEDIS_SEED_PATIENT_PASSWORD || 'PatientMedis2026!';

const patients = [
  {
    email: 'patient.antrimedis+qa1@gmail.com',
    fullName: 'Alya Ramadhani',
    phoneNumber: '+6281388883001',
    gender: 'female',
    birthDate: '1999-02-14',
  },
  {
    email: 'patient.antrimedis+qa2@gmail.com',
    fullName: 'Rafi Mahendra',
    phoneNumber: '+6281388883002',
    gender: 'male',
    birthDate: '1997-09-03',
  },
  {
    email: 'patient.antrimedis+qa3@gmail.com',
    fullName: 'Nabila Putri',
    phoneNumber: '+6281388883003',
    gender: 'female',
    birthDate: '2001-05-21',
  },
  {
    email: 'patient.antrimedis+qa4@gmail.com',
    fullName: 'Dimas Pratama',
    phoneNumber: '+6281388883004',
    gender: 'male',
    birthDate: '1995-12-08',
  },
  {
    email: 'patient.antrimedis+qa5@gmail.com',
    fullName: 'Sekar Larasati',
    phoneNumber: '+6281388883005',
    gender: 'female',
    birthDate: '1998-07-27',
  },
];

try {
  console.log('\nSeeding valid QA patient accounts...\n');

  const pendingConfirmation = [];

  for (const patient of patients) {
    if (!verifyOnly) await signUpIfNeeded(patient);
    const session = await signIn(patient.email, password);
    if (session?.needsConfirmation) {
      pendingConfirmation.push(patient.email);
      console.log(`PENDING ${patient.email} needs email confirmation`);
      continue;
    }
    const profile = await upsertProfile(session.access_token, patient);
    assert(profile?.id === session.user.id, `Profile mismatch for ${patient.email}`);
    await verifyPatientRole(session.access_token);
    console.log(`OK ${patient.email} | ${patient.fullName}`);
  }

  if (pendingConfirmation.length > 0) {
    console.log('\nThese accounts were created but still need confirmation:');
    for (const email of pendingConfirmation) console.log(`- ${email}`);
    console.log(
      '\nRun: supabase db query --linked --file supabase/patches/20260602_seed_valid_qa_patients.sql',
    );
    process.exitCode = 2;
    process.exit();
  }

  console.log('\nSeeded patients ready for queue testing:');
  for (const patient of patients) {
    console.log(`- ${patient.email} / ${password}`);
  }
} catch (error) {
  console.error('\nSeed valid patients failed.');
  console.error(error.message || error);
  if (error.cause) console.error(error.cause);
  process.exitCode = 1;
}

async function signUpIfNeeded(patient) {
  const response = await fetch(`${env.url}/auth/v1/signup`, {
    method: 'POST',
    headers: {
      apikey: env.anonKey,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      email: patient.email,
      password,
      data: {
        full_name: patient.fullName,
        phone_number: patient.phoneNumber,
      },
    }),
  });

  if (response.ok) return readJson(response);

  const body = await readJson(response);
  const message = JSON.stringify(body).toLowerCase();
  if (message.includes('already') || message.includes('registered')) return null;
  throw new Error(`Failed to sign up ${patient.email}: ${formatError(response, body)}`);
}

async function signIn(email, passwordValue) {
  const response = await fetch(`${env.url}/auth/v1/token?grant_type=password`, {
    method: 'POST',
    headers: {
      apikey: env.anonKey,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({ email, password: passwordValue }),
  });

  const body = await readJson(response);
  if (!response.ok) {
    if (body?.error_code === 'email_not_confirmed') {
      return { needsConfirmation: true };
    }
    throw new Error(`Failed to sign in ${email}: ${formatError(response, body)}`);
  }
  return body;
}

async function upsertProfile(accessToken, patient) {
  const response = await fetch(`${env.url}/rest/v1/rpc/upsert_my_profile`, {
    method: 'POST',
    headers: {
      apikey: env.anonKey,
      Authorization: `Bearer ${accessToken}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      p_full_name: patient.fullName,
      p_phone_number: patient.phoneNumber,
      p_gender: patient.gender,
      p_birth_date: patient.birthDate,
      p_avatar_url: `https://api.dicebear.com/9.x/initials/svg?seed=${encodeURIComponent(
        patient.fullName,
      )}`,
    }),
  });

  const body = await readJson(response);
  if (!response.ok) {
    throw new Error(`Failed to upsert profile ${patient.email}: ${formatError(response, body)}`);
  }
  return body;
}

async function verifyPatientRole(accessToken) {
  const response = await fetch(`${env.url}/rest/v1/rpc/get_my_roles`, {
    method: 'POST',
    headers: {
      apikey: env.anonKey,
      Authorization: `Bearer ${accessToken}`,
      'Content-Type': 'application/json',
    },
    body: '{}',
  });

  const body = await readJson(response);
  if (!response.ok) {
    throw new Error(`Failed to verify patient role: ${formatError(response, body)}`);
  }

  const hasPatientRole = Array.isArray(body) && body.some((role) => role.role_code === 'patient');
  assert(hasPatientRole, 'Signed-in account does not have patient role.');
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
