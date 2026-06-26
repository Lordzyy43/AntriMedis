import { createClient } from "https://esm.sh/@supabase/supabase-js@2.87.1";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "content-type",
};

Deno.serve(async (request) => {
  if (request.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  if (request.method !== "GET" && request.method !== "POST") {
    return json({ error: "Method not allowed" }, 405);
  }

  const pingResult = await pingDatabase();
  if (!pingResult.ok) {
    console.warn("heartbeat database ping failed", pingResult.error);
  }

  return json({
    ok: true,
    service: "heartbeat",
    timestamp: new Date().toISOString(),
  });
});

function json(body: Record<string, unknown>, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

async function pingDatabase() {
  const supabaseUrl = Deno.env.get("SUPABASE_URL");
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  if (!supabaseUrl || !serviceRoleKey) {
    return { ok: false as const, error: "missing Supabase runtime config" };
  }

  const client = createClient(supabaseUrl, serviceRoleKey, {
    auth: { persistSession: false, autoRefreshToken: false },
  });

  const { error } = await client
    .from("doctor_schedules")
    .select("id", { head: true, count: "exact" })
    .limit(1);

  if (error) {
    return { ok: false as const, error: error.message };
  }

  return { ok: true as const };
}
