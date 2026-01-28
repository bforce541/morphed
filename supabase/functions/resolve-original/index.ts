import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

serve(async (req) => {
  if (req.method !== "POST") {
    return new Response("Method Not Allowed", { status: 405 });
  }

  const supabaseUrl =
    Deno.env.get("SUPABASE_URL") ?? Deno.env.get("SB_URL");
  const serviceRoleKey =
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ??
    Deno.env.get("SB_SERVICE_ROLE_KEY");

  if (!supabaseUrl || !serviceRoleKey) {
    return new Response("Missing SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY", { status: 500 });
  }

  const authHeader = req.headers.get("Authorization") ?? "";
  const headerToken = authHeader.replace("Bearer ", "").trim();

  let body: { original_hash?: string; mode?: string } = {};
  try {
    body = await req.json();
  } catch {
    // Ignore body parse errors.
  }

  const accessToken = headerToken;
  if (!accessToken) {
    return new Response(JSON.stringify({ exists: false }), { status: 401 });
  }

  const supabase = createClient(supabaseUrl, serviceRoleKey, {
    auth: { persistSession: false },
    global: { headers: { Authorization: `Bearer ${accessToken}` } },
  });

  const {
    data: { user },
    error: userError,
  } = await supabase.auth.getUser(accessToken);

  if (userError || !user) {
    return new Response(JSON.stringify({ exists: false }), { status: 401 });
  }

  const originalHash = body.original_hash?.trim() ?? "";
  const mode = body.mode?.trim() ?? "";
  if (!originalHash || !mode) {
    return new Response(JSON.stringify({ exists: false }), { status: 400 });
  }

  const { data, error } = await supabase
    .from("created_images")
    .select("id")
    .eq("profile_id", user.id)
    .eq("original_hash", originalHash)
    .eq("mode", mode)
    .limit(1)
    .maybeSingle();

  if (error) {
    return new Response(JSON.stringify({ exists: false }), { status: 200 });
  }

  return new Response(
    JSON.stringify({ exists: !!data, pair_id: data?.id ?? null }),
    { status: 200 }
  );
});
