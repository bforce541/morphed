import dotenv from "dotenv";
import { createClient } from "@supabase/supabase-js";
import { fileURLToPath } from "node:url";

dotenv.config({
    path: fileURLToPath(new URL("../.env", import.meta.url))
});

const supabaseUrl = process.env.SUPABASE_URL;
const supabaseKey = process.env.SUPABASE_SERVICE_ROLE_KEY;

if (!supabaseUrl || !supabaseKey) {
    console.error("SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY are required.");
    process.exit(1);
}

const supabase = createClient(supabaseUrl, supabaseKey);
const now = Date.now();

function normalizePlan(plan) {
    switch (plan) {
        case "free":
            return "free";
        case "proMonthly":
        case "weekly":
            return "proMonthly";
        case "premiumMonthly":
        case "monthlyPro":
            return "premiumMonthly";
        default:
            return "free";
    }
}

async function updateProfileSubscription(userId, plan, expiresAt) {
    const { error } = await supabase
        .from("profiles")
        .update({
            subscription_status: plan,
            subscription_expires_at: expiresAt,
            updated_at: new Date().toISOString()
        })
        .eq("id", userId);

    if (error) {
        console.error(`Failed to update profile ${userId}:`, error.message);
        return false;
    }
    return true;
}

async function syncEntitlementsToProfiles() {
    const { data, error } = await supabase
        .from("user_entitlements")
        .select("user_id, plan, expires_at");

    if (error) {
        console.error("Failed to fetch entitlements:", error.message);
        process.exit(1);
    }

    let updated = 0;
    for (const row of data || []) {
        const normalizedPlan = normalizePlan(row.plan);
        const expiresAt = row.expires_at ? new Date(row.expires_at).getTime() : null;
        const isExpired = expiresAt && expiresAt < now;
        const plan = isExpired ? "free" : normalizedPlan;
        const effectiveExpiresAt = isExpired ? null : row.expires_at;

        if (await updateProfileSubscription(row.user_id, plan, effectiveExpiresAt)) {
            updated += 1;
        }
    }

    return updated;
}

async function syncBypassProfiles() {
    const bypassList = (process.env.PRO_BYPASS_USER_IDS || "")
        .split(",")
        .map((id) => id.trim().toLowerCase())
        .filter(Boolean);

    let updated = 0;
    for (const userId of bypassList) {
        if (await updateProfileSubscription(userId, "proMonthly", null)) {
            updated += 1;
        }
    }

    return updated;
}

const entitlementsUpdated = await syncEntitlementsToProfiles();
const bypassUpdated = await syncBypassProfiles();

console.log(
    `Profile sync complete. Entitlements updated: ${entitlementsUpdated}. Bypass updated: ${bypassUpdated}.`
);
