import { createClient } from "https://esm.sh/@supabase/supabase-js@2.87.1";

type NotificationRow = {
  id: string;
  user_id: string;
  type: string;
  title: string;
  body: string;
  data: Record<string, unknown> | null;
  created_at: string;
};

type DeviceTokenRow = {
  id: string;
  fcm_token: string;
  platform: string;
};

type PushRequest = {
  notification_id?: string;
  user_id?: string;
  title?: string;
  body?: string;
  data?: Record<string, unknown>;
};

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

Deno.serve(async (request) => {
  if (request.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  if (request.method !== "POST") {
    return json({ error: "Method not allowed" }, 405);
  }

  const supabaseUrl = requireEnv("SUPABASE_URL");
  const anonKey = requireEnv("SUPABASE_ANON_KEY");
  const serviceRoleKey = requireEnv("SUPABASE_SERVICE_ROLE_KEY");
  const authorization = request.headers.get("Authorization") ?? "";
  const webhookSecret = request.headers.get("x-push-webhook-secret") ?? "";

  const authedClient = createClient(supabaseUrl, anonKey, {
    global: { headers: { Authorization: authorization } },
  });
  const serviceClient = createClient(supabaseUrl, serviceRoleKey);

  if (!(await canSendPush(authorization, webhookSecret, authedClient))) {
    return json({ error: "Forbidden" }, 403);
  }

  const payload = await request.json() as PushRequest;
  const notification = await resolveNotification(serviceClient, payload);
  const userId = notification?.user_id ?? payload.user_id;
  const title = notification?.title ?? payload.title;
  const body = notification?.body ?? payload.body;

  if (!userId || !title || !body) {
    return json(
      { error: "notification_id or user_id/title/body is required" },
      400,
    );
  }

  const { data: tokens, error: tokenError } = await serviceClient
    .from("user_device_tokens")
    .select("id, fcm_token, platform")
    .eq("user_id", userId)
    .eq("is_active", true)
    .returns<DeviceTokenRow[]>();

  if (tokenError) throw tokenError;
  if (!tokens?.length) {
    return json({ delivered: 0, failed: 0, invalid: 0, reason: "no_tokens" });
  }

  const firebase = await getFirebaseClient();
  let delivered = 0;
  let failed = 0;
  let invalid = 0;

  for (const token of tokens) {
    if (
      notification?.id &&
      await hasFinalDeliveryLog(serviceClient, notification.id, token.id)
    ) {
      continue;
    }

    const result = await firebase.send({
      token: token.fcm_token,
      notification: { title, body },
      data: stringifyData({
        ...notification?.data,
        ...payload.data,
        notification_id: notification?.id ?? payload.notification_id ?? "",
        type: notification?.type ?? payload.data?.type ?? "",
        created_at: notification?.created_at ?? new Date().toISOString(),
      }),
      android: {
        priority: "HIGH",
        notification: { channel_id: "queue_updates" },
      },
      apns: {
        payload: {
          aps: {
            sound: "default",
          },
        },
      },
    });

    if (result.ok) {
      delivered += 1;
      await logDelivery(serviceClient, {
        notificationId: notification?.id,
        deviceTokenId: token.id,
        fcmToken: token.fcm_token,
        status: "sent",
        providerMessageId: result.messageId,
      });
      continue;
    }

    const status = isInvalidTokenError(result.errorCode)
      ? "invalid_token"
      : "failed";
    if (status === "invalid_token") invalid += 1;
    else failed += 1;

    await logDelivery(serviceClient, {
      notificationId: notification?.id,
      deviceTokenId: token.id,
      fcmToken: token.fcm_token,
      status,
      errorCode: result.errorCode,
      errorMessage: result.errorMessage,
    });

    if (status === "invalid_token") {
      await serviceClient
        .from("user_device_tokens")
        .update({ is_active: false, updated_at: new Date().toISOString() })
        .eq("id", token.id);
    }
  }

  return json({ delivered, failed, invalid });
});

async function hasFinalDeliveryLog(
  serviceClient: ReturnType<typeof createClient>,
  notificationId: string,
  deviceTokenId: string,
) {
  const { data, error } = await serviceClient
    .from("push_delivery_logs")
    .select("id")
    .eq("notification_id", notificationId)
    .eq("user_device_token_id", deviceTokenId)
    .in("status", ["sent", "invalid_token"])
    .maybeSingle();

  if (error) throw error;
  return data !== null;
}

async function resolveNotification(
  serviceClient: ReturnType<typeof createClient>,
  payload: PushRequest,
) {
  if (!payload.notification_id) return null;

  const { data, error } = await serviceClient
    .from("notifications")
    .select("id, user_id, type, title, body, data, created_at")
    .eq("id", payload.notification_id)
    .single<NotificationRow>();

  if (error) throw error;
  return data;
}

async function canSendPush(
  authorization: string,
  webhookSecret: string,
  authedClient: ReturnType<typeof createClient>,
) {
  const expectedWebhookSecret = Deno.env.get("PUSH_WEBHOOK_SECRET");
  if (expectedWebhookSecret && webhookSecret === expectedWebhookSecret) {
    return true;
  }

  const role = parseJwtPayload(authorization.replace(/^Bearer\s+/i, ""))?.role;
  if (role === "service_role") return true;

  const { data, error } = await authedClient.rpc("is_staff");
  return !error && data === true;
}

async function logDelivery(
  serviceClient: ReturnType<typeof createClient>,
  params: {
    notificationId?: string;
    deviceTokenId: string;
    fcmToken: string;
    status: "sent" | "failed" | "invalid_token";
    providerMessageId?: string;
    errorCode?: string;
    errorMessage?: string;
  },
) {
  const now = new Date().toISOString();
  await serviceClient.from("push_delivery_logs").insert({
    notification_id: params.notificationId,
    user_device_token_id: params.deviceTokenId,
    fcm_token: params.fcmToken,
    status: params.status,
    provider_message_id: params.providerMessageId,
    error_code: params.errorCode,
    error_message: params.errorMessage,
    sent_at: params.status === "sent" ? now : null,
    failed_at: params.status === "sent" ? null : now,
  });
}

async function getFirebaseClient() {
  const serviceAccount = JSON.parse(requireEnv("FIREBASE_SERVICE_ACCOUNT_JSON"));
  const projectId = serviceAccount.project_id;
  const accessToken = await getAccessToken(serviceAccount);

  return {
    send: async (message: Record<string, unknown>) => {
      const response = await fetch(
        `https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`,
        {
          method: "POST",
          headers: {
            Authorization: `Bearer ${accessToken}`,
            "Content-Type": "application/json",
          },
          body: JSON.stringify({ message }),
        },
      );

      const data = await response.json().catch(() => ({}));
      if (response.ok) {
        return { ok: true, messageId: data.name as string };
      }

      return {
        ok: false,
        errorCode: data.error?.status as string | undefined,
        errorMessage: data.error?.message as string | undefined,
      };
    },
  };
}

async function getAccessToken(serviceAccount: Record<string, string>) {
  const now = Math.floor(Date.now() / 1000);
  const jwtHeader = base64UrlEncode(JSON.stringify({ alg: "RS256", typ: "JWT" }));
  const jwtClaim = base64UrlEncode(JSON.stringify({
    iss: serviceAccount.client_email,
    scope: "https://www.googleapis.com/auth/firebase.messaging",
    aud: "https://oauth2.googleapis.com/token",
    iat: now,
    exp: now + 3600,
  }));
  const unsignedJwt = `${jwtHeader}.${jwtClaim}`;
  const key = await importPrivateKey(serviceAccount.private_key);
  const signature = await crypto.subtle.sign(
    "RSASSA-PKCS1-v1_5",
    key,
    new TextEncoder().encode(unsignedJwt),
  );
  const signedJwt = `${unsignedJwt}.${base64UrlEncode(signature)}`;

  const response = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({
      grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
      assertion: signedJwt,
    }),
  });

  const data = await response.json();
  if (!response.ok) {
    throw new Error(data.error_description ?? "Failed to get Firebase token");
  }
  return data.access_token as string;
}

async function importPrivateKey(pem: string) {
  const keyData = pem
    .replace("-----BEGIN PRIVATE KEY-----", "")
    .replace("-----END PRIVATE KEY-----", "")
    .replaceAll(/\s/g, "");
  const binary = Uint8Array.from(atob(keyData), (char) => char.charCodeAt(0));

  return await crypto.subtle.importKey(
    "pkcs8",
    binary,
    { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
    false,
    ["sign"],
  );
}

function stringifyData(data: Record<string, unknown>) {
  return Object.fromEntries(
    Object.entries(data)
      .filter(([, value]) => value !== null && value !== undefined)
      .map(([key, value]) => [key, String(value)]),
  );
}

function isInvalidTokenError(errorCode?: string) {
  return errorCode === "INVALID_ARGUMENT" || errorCode === "NOT_FOUND";
}

function parseJwtPayload(token: string) {
  try {
    const [, payload] = token.split(".");
    return JSON.parse(atob(toBase64(payload)));
  } catch (_) {
    return null;
  }
}

function base64UrlEncode(input: string | ArrayBuffer) {
  const bytes = typeof input === "string"
    ? new TextEncoder().encode(input)
    : new Uint8Array(input);
  const binary = Array.from(bytes, (byte) => String.fromCharCode(byte)).join("");
  return btoa(binary).replaceAll("+", "-").replaceAll("/", "_").replaceAll("=", "");
}

function toBase64(input: string) {
  const base64 = input.replaceAll("-", "+").replaceAll("_", "/");
  return base64.padEnd(base64.length + (4 - base64.length % 4) % 4, "=");
}

function requireEnv(name: string) {
  const value = Deno.env.get(name);
  if (!value) throw new Error(`${name} is not configured`);
  return value;
}

function json(body: Record<string, unknown>, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}
