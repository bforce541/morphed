import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

serve(async (req) => {
  if (req.method !== "POST") {
    return new Response("Method Not Allowed", { status: 405 });
  }

  const supabaseUrl = Deno.env.get("SB_URL");
  const serviceRoleKey = Deno.env.get("SB_SERVICE_ROLE_KEY");

  if (!supabaseUrl || !serviceRoleKey) {
    return new Response("Missing SB_URL or SB_SERVICE_ROLE_KEY", {
      status: 500,
    });
  }

  const supabase = createClient(supabaseUrl, serviceRoleKey);

  const { data: profiles, error } = await supabase
    .from("profiles")
    .select("id, name")
    .not("name", "is", null);

  if (error) {
    return new Response(JSON.stringify(error), { status: 500 });
  }

  let updated = 0;
  const errors: Array<{ id: string; error: string }> = [];

  for (const profile of profiles ?? []) {
    if (!profile?.id || !profile?.name) continue;
    const res = await fetch(`${supabaseUrl}/auth/v1/admin/users/${profile.id}`, {
      method: "PUT",
      headers: {
        apikey: serviceRoleKey,
        Authorization: `Bearer ${serviceRoleKey}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({ user_metadata: { name: profile.name } }),
    });

    if (res.ok) {
      updated++;
    } else {
      const body = await res.text();
      errors.push({ id: profile.id, error: body || "Error updating user" });
    }
  }

  return new Response(
    JSON.stringify({ updated, total: profiles?.length ?? 0, errors }),
    { status: 200 }
  );
});
