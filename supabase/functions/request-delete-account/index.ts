import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const RESEND_ENDPOINT = "https://api.resend.com/emails";

serve(async (req) => {
  if (req.method !== "POST") {
    return new Response("Method Not Allowed", { status: 405 });
  }

  const supabaseUrl = Deno.env.get("SB_URL");
  const serviceRoleKey = Deno.env.get("SB_SERVICE_ROLE_KEY");
  const resendApiKey = Deno.env.get("RESEND_API_KEY");
  const resendFrom = Deno.env.get("RESEND_FROM");

  if (!supabaseUrl || !serviceRoleKey) {
    return new Response("Missing SB_URL or SB_SERVICE_ROLE_KEY", {
      status: 500,
    });
  }

  if (!resendApiKey || !resendFrom) {
    return new Response("Missing RESEND_API_KEY or RESEND_FROM", {
      status: 500,
    });
  }

  const authHeader = req.headers.get("Authorization") ?? "";
  const token = authHeader.replace("Bearer ", "").trim();

  if (!token) {
    return new Response("Missing Authorization token", { status: 401 });
  }

  const supabase = createClient(supabaseUrl, serviceRoleKey);
  const { data: userData, error: userError } = await supabase.auth.getUser(
    token
  );

  if (userError || !userData?.user?.email) {
    return new Response("Invalid user token", { status: 401 });
  }

  const redirectTo = `morphed://login-callback?delete_account=true`;
  const { data, error } = await supabase.auth.admin.generateLink({
    type: "magiclink",
    email: userData.user.email,
    options: { redirectTo },
  });

  if (error || !data?.properties?.action_link) {
    return new Response("Failed to generate delete link", { status: 500 });
  }

  const actionLink = data.properties.action_link;
  const html = `
    <div style="font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif; color: #111;">
      <h2>Confirm account deletion</h2>
      <p>Click the button below to confirm deletion of your Morphed account.</p>
      <p><a href="${actionLink}" style="display:inline-block;padding:12px 18px;background:#22C7FF;color:#061A2E;text-decoration:none;border-radius:999px;font-weight:600;">Confirm deletion</a></p>
      <p>If you did not request this, you can ignore this email.</p>
    </div>
  `;

  const resendRes = await fetch(RESEND_ENDPOINT, {
    method: "POST",
    headers: {
      Authorization: `Bearer ${resendApiKey}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      from: resendFrom,
      to: userData.user.email,
      subject: "Confirm your Morphed account deletion",
      html,
    }),
  });

  if (!resendRes.ok) {
    const body = await resendRes.text();
    return new Response(body || "Failed to send email", { status: 500 });
  }

  return new Response(JSON.stringify({ sent: true }), {
    status: 200,
    headers: { "Content-Type": "application/json" },
  });
});
