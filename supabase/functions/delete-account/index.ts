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

  const authHeader = req.headers.get("Authorization") ?? "";
  const token = authHeader.replace("Bearer ", "").trim();

  if (!token) {
    return new Response("Missing Authorization token", { status: 401 });
  }

  const supabase = createClient(supabaseUrl, serviceRoleKey);
  const { data, error } = await supabase.auth.getUser(token);

  if (error || !data?.user) {
    return new Response("Invalid user token", { status: 401 });
  }

  const userId = data.user.id;

  await supabase.from("profiles").delete().eq("id", userId);

  const res = await fetch(`${supabaseUrl}/auth/v1/admin/users/${userId}`, {
    method: "DELETE",
    headers: {
      apikey: serviceRoleKey,
      Authorization: `Bearer ${serviceRoleKey}`,
    },
  });

  if (!res.ok) {
    const body = await res.text();
    return new Response(body || "Error deleting user", { status: 500 });
  }

  return new Response(JSON.stringify({ deleted: true, userId }), {
    status: 200,
    headers: { "Content-Type": "application/json" },
  });
});
