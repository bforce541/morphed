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
  let bodyToken = "";
  try {
    const body = await req.json();
    if (body?.access_token) {
      bodyToken = body.access_token;
    }
  } catch {
    // Ignore body parse errors.
  }

  const headerToken = authHeader.replace("Bearer ", "").trim();
  const accessToken = headerToken || bodyToken;
  const supabase = createClient(supabaseUrl, serviceRoleKey, {
    auth: { persistSession: false },
    global: accessToken ? { headers: { Authorization: `Bearer ${accessToken}` } } : undefined,
  });

  const {
    data: { user },
    error: userError,
  } = await supabase.auth.getUser(accessToken);

  if (userError || !user) {
    return new Response(JSON.stringify({ error: "Unauthorized" }), { status: 401 });
  }

  const results: Record<string, unknown> = {};

  const { error: createdImagesError } = await supabase
    .from("created_images")
    .delete()
    .eq("profile_id", user.id);
  if (createdImagesError) {
    results.createdImagesError = createdImagesError.message;
  }

  const { error: profileError } = await supabase
    .from("profiles")
    .delete()
    .eq("id", user.id);
  if (profileError) {
    results.profileError = profileError.message;
  }

  const { data: imageFolders, error: imageListError } = await supabase.storage
    .from("morphed-images")
    .list(user.id, { limit: 200 });

  if (imageListError) {
    results.imageListError = imageListError.message;
  } else if (imageFolders && imageFolders.length > 0) {
    const pathsToRemove: string[] = [];
    for (const folder of imageFolders) {
      const { data: imageFiles, error: imageFilesError } =
        await supabase.storage
          .from("morphed-images")
          .list(`${user.id}/${folder.name}`, { limit: 200 });
      if (imageFilesError) {
        results.imageFilesError = imageFilesError.message;
        continue;
      }
      for (const file of imageFiles ?? []) {
        pathsToRemove.push(`${user.id}/${folder.name}/${file.name}`);
      }
    }
    if (pathsToRemove.length > 0) {
      const { error: imagesRemoveError } = await supabase.storage
        .from("morphed-images")
        .remove(pathsToRemove);
      if (imagesRemoveError) {
        results.imagesRemoveError = imagesRemoveError.message;
      }
    }
  }

  const { data: files, error: listError } = await supabase.storage
    .from("avatars")
    .list(user.id, { limit: 100 });

  if (listError) {
    results.avatarListError = listError.message;
  } else if (files && files.length > 0) {
    const paths = files.map((file) => `${user.id}/${file.name}`);
    const { error: removeError } = await supabase.storage
      .from("avatars")
      .remove(paths);
    if (removeError) {
      results.avatarRemoveError = removeError.message;
    }
  }

  const adminRes = await fetch(`${supabaseUrl}/auth/v1/admin/users/${user.id}`, {
    method: "DELETE",
    headers: {
      apikey: serviceRoleKey,
      Authorization: `Bearer ${serviceRoleKey}`,
    },
  });
  if (!adminRes.ok) {
    const body = await adminRes.text();
    return new Response(JSON.stringify({ error: body || "User not allowed", results }), {
      status: 500,
    });
  }

  return new Response(JSON.stringify({ ok: true, results }), { status: 200 });
});
