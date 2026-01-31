// morphed-backend/src/server.js

import express from "express";
import cors from "cors";
import dotenv from "dotenv";
import { editImageWithGemini } from "./geminiClient.js";
import { validateEditRequest } from "./validate.js";
import { createCheckoutSession, verifyWebhookSignature } from "./stripeClient.js";
import { verifyTransaction } from "./appleVerify.js";
import { upsertEntitlement, getEntitlement } from "./entitlementsStore.js";
import { checkPresenceWithOpenRouter } from "./openrouterClient.js";

dotenv.config();

const app = express();
const PORT = process.env.PORT || 3000;

app.use(cors());
app.use(express.json({ limit: "10mb" }));

// Stripe webhook endpoint needs raw body for signature verification
app.use("/stripe/webhook", express.raw({ type: "application/json" }));

app.use((req, res, next) => {
    const requestId = Math.random().toString(36).substring(7);
    req.requestId = requestId;
    console.log(`[${requestId}] ${req.method} ${req.path}`);
    next();
});

app.post("/edit", async (req, res) => {
    const { requestId } = req;

    try {
        const validation = validateEditRequest(req.body);
        if (!validation.valid) {
            console.error(`[${requestId}] Validation failed:`, validation.error);
            return res.status(400).json({
                error: {
                    code: "BAD_REQUEST",
                    message: validation.error,
                    details: validation.details
                }
            });
        }

        const { mode, imageBase64, mimeType } = req.body;

        // Feature flag: Gemini API must be explicitly enabled
        const geminiEnabled = process.env.GEMINI_ENABLED === "true";
        if (!geminiEnabled) {
            console.error(`[${requestId}] Gemini API is disabled (GEMINI_ENABLED=false)`);
            return res.status(503).json({
                error: {
                    code: "SERVICE_UNAVAILABLE",
                    message: "Gemini API is currently disabled",
                    details: "Set GEMINI_ENABLED=true in your .env file to enable image processing"
                }
            });
        }

        if (!process.env.GEMINI_API_KEY) {
            console.error(`[${requestId}] GEMINI_API_KEY not configured`);
            return res.status(500).json({
                error: {
                    code: "INTERNAL",
                    message: "Server configuration error: GEMINI_API_KEY is not set",
                    details: "Please configure GEMINI_API_KEY in your .env file"
                }
            });
        }

        console.log(`[${requestId}] Processing ${mode} mode request`);

        const result = await Promise.race([
            editImageWithGemini(imageBase64, mode, process.env.GEMINI_API_KEY),
            new Promise((_, reject) =>
                setTimeout(() => reject(new Error("Request timeout")), 120000)
            )
        ]);

        console.log(`[${requestId}] Successfully processed image`);

        res.json({
            editedImageBase64: result.imageBase64,
            mimeType: result.mimeType || "image/jpeg"
        });
    } catch (error) {
        console.error(`[${requestId}] Error:`, error.message);

        if (error.message.includes("timeout")) {
            return res.status(504).json({
                error: {
                    code: "INTERNAL",
                    message: "Request timeout",
                    details: "The image processing took too long. Please try again."
                }
            });
        }

        if (error.message.includes("MODEL_ERROR") || error.message.includes("did not return an image")) {
            return res.status(500).json({
                error: {
                    code: "MODEL_ERROR",
                    message: error.message,
                    details: "The AI model did not return a valid image. Please try again."
                }
            });
        }

        res.status(500).json({
            error: {
                code: "INTERNAL",
                message: error.message || "Internal server error",
                details: "An unexpected error occurred while processing your image"
            }
        });
    }
});

app.post("/precheck", async (req, res) => {
    const { requestId } = req;
    try {
        const { imageBase64, mimeType } = req.body || {};

        if (!imageBase64 || typeof imageBase64 !== "string") {
            return res.status(400).json({
                error: {
                    code: "BAD_REQUEST",
                    message: "imageBase64 is required"
                }
            });
        }

        if (!mimeType || (mimeType !== "image/jpeg" && mimeType !== "image/png")) {
            return res.status(400).json({
                error: {
                    code: "BAD_REQUEST",
                    message: "mimeType must be 'image/jpeg' or 'image/png'"
                }
            });
        }

        if (!process.env.OPENROUTER_API_KEY) {
            return res.status(500).json({
                error: {
                    code: "INTERNAL",
                    message: "Server configuration error: OPENROUTER_API_KEY is not set"
                }
            });
        }

        const models = buildOpenRouterModels(
            process.env.OPENROUTER_MODEL,
            process.env.OPENROUTER_MODEL_FALLBACKS
        );

        const result = await checkPresenceWithOpenRouter(
            imageBase64,
            mimeType,
            process.env.OPENROUTER_API_KEY,
            models,
            process.env.OPENROUTER_BASE_URL
        );

        return res.json({
            pass: !!result.pass,
            blockingMessage: result.blockingMessage ?? null,
            warnings: Array.isArray(result.warnings) ? result.warnings : [],
            debug: appendModelDebug(result.debug, result.modelUsed)
        });
    } catch (error) {
        console.error(`[${requestId}] /precheck error:`, error.message);
        return res.status(500).json({
            error: {
                code: "INTERNAL",
                message: error.message || "Precheck failed"
            }
        });
    }
});

function buildOpenRouterModels(primary, fallbacks) {
    const list = [];
    if (primary && primary.trim().length > 0) {
        list.push(primary.trim());
    }
    if (fallbacks && fallbacks.trim().length > 0) {
        const parts = fallbacks.split(",").map((v) => v.trim()).filter(Boolean);
        list.push(...parts);
    }
    return list.length > 0 ? list : undefined;
}

function appendModelDebug(debug, modelUsed) {
    if (!modelUsed) return debug ?? null;
    if (!debug || debug.trim().length === 0) {
        return `model=${modelUsed}`;
    }
    return `${debug} | model=${modelUsed}`;
}

// Lightweight usage tracking endpoint (stub – no persistence yet).
app.post("/usage", (req, res) => {
    const { requestId } = req;
    const payload = req.body || {};
    console.log(`[${requestId}] /usage event`, payload);
    return res.json({ ok: true });
});

// Credits decrement endpoint (stub – does not actually enforce credits).
app.post("/credits/decrement", (req, res) => {
    const { requestId } = req;
    const { userId, amount } = req.body || {};
    console.log(`[${requestId}] /credits/decrement userId=${userId} amount=${amount}`);
    return res.json({
        ok: true,
        remainingCredits: 0
    });
});

// Referral tracking endpoint (stub).
app.post("/referral", (req, res) => {
    const { requestId } = req;
    const { code } = req.body || {};
    console.log(`[${requestId}] /referral code=${code}`);
    return res.json({ ok: true });
});

// Entitlements endpoint – source of truth for gating. Reads from store (Apple IAP or legacy).
// Query: user_id (required, must be UUID). Returns free tier if invalid/missing.
app.get("/entitlements", async (req, res) => {
    const { requestId } = req;
    const userId = req.query.user_id || req.body?.user_id || "";
    // Validate UUID format
    const uuidRegex = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
    if (!userId || !uuidRegex.test(userId)) {
        console.log(`[${requestId}] /entitlements (invalid/missing user_id – free tier)`);
        return res.json({
            tier: "free",
            canUseMaxMode: false,
            canExportHD: false,
            remainingPremiumRenders: 0,
            isPro: false
        });
    }
    const ent = await getEntitlement(userId);
    const isPro = ent.isPro && (!ent.expires_at || ent.expires_at > Math.floor(Date.now() / 1000));
    console.log(`[${requestId}] /entitlements user_id=${userId} tier=${ent.plan} isPro=${isPro}`);
    return res.json({
        tier: ent.plan,
        canUseMaxMode: isPro,
        canExportHD: isPro,
        remainingPremiumRenders: isPro ? 999999 : 0,
        isPro,
        expiresAt: ent.expires_at || null
    });
});

// Apple IAP: verify JWS and update entitlements. Do NOT trust client isPro – only Apple verification.
app.post("/iap/apple/verify", async (req, res) => {
    const { requestId } = req;
    try {
        const { user_id, signed_transaction_info, environment } = req.body || {};
        if (!user_id) {
            return res.status(400).json({
                error: { code: "BAD_REQUEST", message: "user_id is required" }
            });
        }
        // Validate user_id is UUID format (Supabase UUIDs are standard UUIDs)
        const uuidRegex = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
        if (!uuidRegex.test(user_id)) {
            return res.status(400).json({
                error: { code: "BAD_REQUEST", message: "user_id must be a valid UUID" }
            });
        }
        if (!signed_transaction_info) {
            return res.status(400).json({
                error: { code: "BAD_REQUEST", message: "signed_transaction_info (JWS) is required" }
            });
        }
        console.log(`[${requestId}] IAP verify user_id=${user_id} env=${environment || "auto"}`);
        const verified = await verifyTransaction(signed_transaction_info, environment);
        const row = await upsertEntitlement(user_id, {
            plan: verified.plan,
            expiresDate: verified.expiresDate,
            originalTransactionId: verified.originalTransactionId,
            productId: verified.productId,
            environment: environment || "Production"
        });
        console.log(`[${requestId}] IAP verified plan=${verified.plan} originalTxId=${verified.originalTransactionId}`);
        const isPro = row.isPro && (!row.expires_at || row.expires_at > Math.floor(Date.now() / 1000));
        return res.json({
            tier: row.plan,
            isPro,
            canUseMaxMode: isPro,
            canExportHD: isPro,
            remainingPremiumRenders: isPro ? 999999 : 0,
            expiresAt: row.expires_at,
            appleOriginalTransactionId: row.apple_original_transaction_id,
            appleProductId: row.apple_product_id
        });
    } catch (error) {
        console.error(`[${requestId}] IAP verify error:`, error.message);
        return res.status(400).json({
            error: {
                code: "VERIFICATION_FAILED",
                message: error.message || "Apple transaction verification failed"
            }
        });
    }
});

// Stripe Checkout Session Creation
app.post("/stripe/create-checkout-session", async (req, res) => {
    const { requestId } = req;

    try {
        const { priceId, userId } = req.body;

        if (!priceId) {
            return res.status(400).json({
                error: {
                    code: "BAD_REQUEST",
                    message: "priceId is required"
                }
            });
        }

        if (!userId) {
            return res.status(400).json({
                error: {
                    code: "BAD_REQUEST",
                    message: "userId is required"
                }
            });
        }

        // Validate price IDs
        const validPriceIds = [
            process.env.STRIPE_PRICE_ID_PRO,
            process.env.STRIPE_PRICE_ID_PREMIUM
        ];

        if (!validPriceIds.includes(priceId)) {
            return res.status(400).json({
                error: {
                    code: "BAD_REQUEST",
                    message: "Invalid priceId"
                }
            });
        }

        // Deep link URLs for iOS app
        const successUrl = "morphed://stripe-success?session_id={CHECKOUT_SESSION_ID}";
        const cancelUrl = "morphed://stripe-cancel";

        console.log(`[${requestId}] Creating checkout session for priceId=${priceId}, userId=${userId}`);

        const session = await createCheckoutSession(priceId, userId, successUrl, cancelUrl);

        res.json({
            url: session.url
        });
    } catch (error) {
        console.error(`[${requestId}] Error creating checkout session:`, error);
        res.status(500).json({
            error: {
                code: "INTERNAL",
                message: error.message || "Failed to create checkout session"
            }
        });
    }
});

// Stripe Webhook Handler
app.post("/stripe/webhook", async (req, res) => {
    const { requestId } = req;
    const sig = req.headers["stripe-signature"];

    try {
        if (!sig) {
            return res.status(400).json({ error: "Missing stripe-signature header" });
        }

        const event = verifyWebhookSignature(req.body, sig);

        console.log(`[${requestId}] Webhook received: ${event.type}`);

        // Handle subscription events
        switch (event.type) {
            case "checkout.session.completed":
                const session = event.data.object;
                console.log(`[${requestId}] Checkout completed for session: ${session.id}`);
                // Here you would update your database with the subscription
                break;

            case "customer.subscription.created":
            case "customer.subscription.updated":
                const subscription = event.data.object;
                console.log(`[${requestId}] Subscription ${event.type}: ${subscription.id}`);
                // Update subscription status in your database
                break;

            case "customer.subscription.deleted":
                const deletedSubscription = event.data.object;
                console.log(`[${requestId}] Subscription cancelled: ${deletedSubscription.id}`);
                // Update subscription status in your database
                break;

            default:
                console.log(`[${requestId}] Unhandled event type: ${event.type}`);
        }

        res.json({ received: true });
    } catch (error) {
        console.error(`[${requestId}] Webhook error:`, error.message);
        res.status(400).json({ error: `Webhook Error: ${error.message}` });
    }
});

// Apple App Store Server Notifications (optional, for subscription lifecycle).
// When configured in App Store Connect, Apple sends server-to-server notifications (renewal, cancel, etc.).
// POST /iap/apple/notifications — verify signedPayload with appleVerify, then update entitlementsStore.
// Placeholder: rely on app verification on purchase/restore/open + periodic entitlement refresh for now.
// See: https://developer.apple.com/documentation/appstoreservernotifications

app.get("/health", (req, res) => {
    res.json({
        status: "ok",
        timestamp: new Date().toISOString()
    });
});

app.listen(PORT, () => {
    console.log(`Morphed backend server running on http://localhost:${PORT}`);
    console.log(`Environment: ${process.env.NODE_ENV || "development"}`);
});
