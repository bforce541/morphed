// morphed-backend/src/appleVerify.js
// Verifies StoreKit 2 JWS transaction with Apple and returns decoded payload.
// Requires Apple root CA: set APPLE_ROOT_CA_PATH to path to AppleRootCA-G3.cer (download from https://www.apple.com/certificateauthority/)

import fs from "fs";
import path from "path";
import { fileURLToPath } from "url";
import { SignedDataVerifier, Environment } from "@apple/app-store-server-library";

const __dirname = path.dirname(fileURLToPath(import.meta.url));

const BUNDLE_ID = process.env.APP_BUNDLE_ID || "yoshua.Morphed";
const APP_APPLE_ID = process.env.APP_APPLE_ID ? parseInt(process.env.APP_APPLE_ID, 10) : undefined;

let verifierProduction = null;
let verifierSandbox = null;

function loadRootCAs() {
    const pathEnv = process.env.APPLE_ROOT_CA_PATH;
    if (pathEnv) {
        const paths = pathEnv.split(",").map((p) => p.trim());
        const buffers = [];
        for (const p of paths) {
            const resolved = path.isAbsolute(p) ? p : path.resolve(process.cwd(), p);
            if (fs.existsSync(resolved)) {
                buffers.push(fs.readFileSync(resolved));
            }
        }
        if (buffers.length > 0) return buffers;
    }
    const defaultPath = path.resolve(__dirname, "../certs/AppleRootCA-G3.cer");
    if (fs.existsSync(defaultPath)) {
        return [fs.readFileSync(defaultPath)];
    }
    return null;
}

function getVerifier(environment) {
    const rootCAs = loadRootCAs();
    if (!rootCAs || rootCAs.length === 0) {
        return null;
    }
    const enableOnlineChecks = false;
    if (environment === Environment.PRODUCTION) {
        if (!verifierProduction) {
            verifierProduction = new SignedDataVerifier(
                rootCAs,
                enableOnlineChecks,
                Environment.PRODUCTION,
                BUNDLE_ID,
                APP_APPLE_ID
            );
        }
        return verifierProduction;
    }
    if (!verifierSandbox) {
        verifierSandbox = new SignedDataVerifier(
            rootCAs,
            enableOnlineChecks,
            Environment.SANDBOX,
            BUNDLE_ID,
            undefined
        );
    }
    return verifierSandbox;
}

const VALID_PRODUCT_IDS = new Set([
    "morphed_pro_monthly",
    "morphed_premium_monthly",
]);

/**
 * Map Apple productId to internal plan tier (same as iOS SubscriptionTier).
 * Returns new tier names: "proMonthly" (Pro), "premiumMonthly" (Premium).
 * @param {string} productId
 * @returns {"proMonthly"|"premiumMonthly"|null}
 */
function productIdToPlan(productId) {
    switch (productId) {
        case "morphed_pro_monthly":
            return "proMonthly";
        case "morphed_premium_monthly":
            return "premiumMonthly";
        default:
            return null;
    }
}

/**
 * Verify JWS signed transaction and return decoded payload + plan.
 * Tries Production first, then Sandbox.
 * @param {string} signedTransactionInfo - JWS from StoreKit 2 (verification.jwsRepresentation)
 * @param {string} [environmentHint] - "Production" or "Sandbox" from client
 * @returns {Promise<{ productId: string, originalTransactionId: string, transactionId: string, plan: string, expiresDate: number | null, bundleId: string }>}
 */
export async function verifyTransaction(signedTransactionInfo, environmentHint) {
    const envOrder =
        environmentHint === "Sandbox"
            ? [Environment.SANDBOX, Environment.PRODUCTION]
            : [Environment.PRODUCTION, Environment.SANDBOX];

    let lastError = null;
    for (const env of envOrder) {
        const verifier = getVerifier(env);
        if (!verifier) {
            lastError = new Error(
                "Apple root CA not configured. Set APPLE_ROOT_CA_PATH or place AppleRootCA-G3.cer in backend/certs/. Download from https://www.apple.com/certificateauthority/"
            );
            continue;
        }
        try {
            const decoded = await verifier.verifyAndDecodeTransaction(signedTransactionInfo);
            const productId = decoded.productId || "";
            if (!VALID_PRODUCT_IDS.has(productId)) {
                throw new Error(`Invalid productId: ${productId}`);
            }
            const plan = productIdToPlan(productId);
            if (!plan) {
                throw new Error(`Unknown productId: ${productId}`);
            }
            return {
                productId,
                originalTransactionId: String(decoded.originalTransactionId ?? ""),
                transactionId: String(decoded.transactionId ?? ""),
                plan,
                expiresDate: decoded.expiresDate ?? null,
                bundleId: decoded.bundleId ?? "",
            };
        } catch (e) {
            lastError = e;
        }
    }
    throw lastError || new Error("Verification failed");
}
