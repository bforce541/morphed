// morphed-backend/src/entitlementsStore.js
// Supabase-backed store for user entitlements (Apple IAP).
// Requires SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY in .env.

import { createClient } from "@supabase/supabase-js";

let supabaseClient = null;

function getSupabaseClient() {
    if (!supabaseClient) {
        const url = process.env.SUPABASE_URL;
        const key = process.env.SUPABASE_SERVICE_ROLE_KEY;
        if (!url || !key) {
            throw new Error(
                "ENTITLEMENTS_PERSISTENCE_NOT_CONFIGURED: SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY must be set in environment variables"
            );
        }
        supabaseClient = createClient(url, key);
    }
    return supabaseClient;
}

/**
 * @typedef {Object} EntitlementRow
 * @property {string} user_id
 * @property {string} plan - "free" | "proMonthly" | "premiumMonthly" (backward compat: accepts "weekly"/"monthlyPro")
 * @property {boolean} isPro
 * @property {number|null} expires_at - Unix seconds
 * @property {string|null} apple_original_transaction_id
 * @property {string|null} apple_product_id
 * @property {string|null} apple_environment
 * @property {string} updated_at - ISO string
 */

/**
 * Normalize plan tier string: map old names to new ones for consistency.
 * @param {string} plan
 * @returns {string} Normalized plan ("free" | "proMonthly" | "premiumMonthly")
 */
function normalizePlan(plan) {
    switch (plan) {
        case "free":
            return "free";
        case "proMonthly":
        case "weekly":  // Backward compatibility
            return "proMonthly";
        case "premiumMonthly":
        case "monthlyPro":  // Backward compatibility
            return "premiumMonthly";
        default:
            return "free";
    }
}

async function updateProfileSubscription(supabase, userId, plan, expires_at) {
    const updates = {
        subscription_status: plan,
        subscription_expires_at: expires_at,
        updated_at: new Date().toISOString()
    };

    const { error } = await supabase
        .from("profiles")
        .update(updates)
        .eq("id", userId);

    if (error) {
        console.error("Error updating profile subscription status:", error);
    }
}

/**
 * Upsert entitlement after Apple verification.
 * @param {string} userId
 * @param {{ plan: string, expiresDate: number | null, originalTransactionId: string, productId: string, environment: string }} verified
 * @returns {Promise<EntitlementRow>}
 */
export async function upsertEntitlement(userId, verified) {
    const plan = normalizePlan(verified.plan);
    const isPro = plan === "proMonthly" || plan === "premiumMonthly";
    const expires_at = verified.expiresDate ? new Date(verified.expiresDate).toISOString() : null;

    const row = {
        user_id: userId,
        plan,
        is_pro: isPro,
        expires_at,
        apple_original_transaction_id: verified.originalTransactionId || null,
        apple_product_id: verified.productId || null,
        apple_environment: verified.environment || null,
        updated_at: new Date().toISOString(),
    };

    const supabase = getSupabaseClient();
    const { data, error } = await supabase
        .from("user_entitlements")
        .upsert(row, { onConflict: "user_id" })
        .select()
        .single();

    if (error) {
        console.error("Error upserting entitlement:", error);
        throw new Error(`Failed to persist entitlement: ${error.message}`);
    }

    await updateProfileSubscription(supabase, userId, plan, row.expires_at);

    // Return in the format expected by callers (isPro instead of is_pro, expires_at as Unix seconds)
    return {
        user_id: data.user_id,
        plan: normalizePlan(data.plan),
        isPro: data.is_pro,
        expires_at: data.expires_at ? Math.floor(new Date(data.expires_at).getTime() / 1000) : null,
        apple_original_transaction_id: data.apple_original_transaction_id,
        apple_product_id: data.apple_product_id,
        apple_environment: data.apple_environment,
        updated_at: data.updated_at,
    };
}

/**
 * Get entitlement for user. Returns free tier if not found (migration-safe).
 * @param {string} userId
 * @returns {Promise<EntitlementRow>}
 */
export async function getEntitlement(userId) {
    const supabase = getSupabaseClient();
    const { data, error } = await supabase
        .from("user_entitlements")
        .select("*")
        .eq("user_id", userId)
        .single();

    if (error) {
        if (error.code === "PGRST116") {
            // No row found - return free tier default
            return {
                user_id: userId,
                plan: "free",
                isPro: false,
                expires_at: null,
                apple_original_transaction_id: null,
                apple_product_id: null,
                apple_environment: null,
                updated_at: new Date().toISOString(),
            };
        }
        console.error("Error fetching entitlement:", error);
        throw new Error(`Failed to fetch entitlement: ${error.message}`);
    }

    // Normalize plan if it's an old value
    let plan = normalizePlan(data.plan);
    let expires_at = data.expires_at ? Math.floor(new Date(data.expires_at).getTime() / 1000) : null;
    let isPro = data.is_pro;

    // Check expiry and downgrade to free if expired
    if (expires_at && expires_at < Math.floor(Date.now() / 1000)) {
        plan = "free";
        isPro = false;
        expires_at = null;
        // Update DB to reflect expiry
        await supabase
            .from("user_entitlements")
            .update({
                plan: "free",
                is_pro: false,
                expires_at: null,
                updated_at: new Date().toISOString(),
            })
            .eq("user_id", userId);
        await updateProfileSubscription(supabase, userId, "free", null);
    }

    return {
        user_id: data.user_id,
        plan,
        isPro,
        expires_at,
        apple_original_transaction_id: data.apple_original_transaction_id,
        apple_product_id: data.apple_product_id,
        apple_environment: data.apple_environment,
        updated_at: data.updated_at,
    };
}
