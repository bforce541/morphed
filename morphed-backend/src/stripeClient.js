// morphed-backend/src/stripeClient.js

import Stripe from "stripe";

let stripeInstance = null;

function getStripe() {
    if (!stripeInstance) {
        if (!process.env.STRIPE_SECRET_KEY) {
            throw new Error("STRIPE_SECRET_KEY is not set in environment variables");
        }
        stripeInstance = new Stripe(process.env.STRIPE_SECRET_KEY, {
            apiVersion: "2024-11-20.acacia",
        });
    }
    return stripeInstance;
}

// Export a proxy that lazily initializes Stripe
export const stripe = new Proxy({}, {
    get(target, prop) {
        return getStripe()[prop];
    }
});

/**
 * Create a checkout session for a subscription
 * @param {string} priceId - Stripe Price ID
 * @param {string} userId - User identifier (can be email or user ID)
 * @param {string} successUrl - URL to redirect after successful payment
 * @param {string} cancelUrl - URL to redirect after cancelled payment
 * @returns {Promise<Stripe.Checkout.Session>}
 */
export async function createCheckoutSession(priceId, userId, successUrl, cancelUrl) {
    try {
        const session = await stripe.checkout.sessions.create({
            mode: "subscription",
            payment_method_types: ["card"],
            line_items: [
                {
                    price: priceId,
                    quantity: 1,
                },
            ],
            customer_email: userId.includes("@") ? userId : undefined,
            metadata: {
                userId: userId,
            },
            success_url: successUrl,
            cancel_url: cancelUrl,
            subscription_data: {
                metadata: {
                    userId: userId,
                },
            },
            allow_promotion_codes: true, // Enable promo code field in Stripe checkout
            payment_method_collection: "if_required", // Only require payment method if total > $0 (handles $0 totals and 100% discount promo codes)
        });

        return session;
    } catch (error) {
        console.error("Error creating checkout session:", error);
        throw error;
    }
}

/**
 * Get customer's active subscriptions
 * @param {string} userId - User identifier
 * @returns {Promise<Stripe.Subscription[]>}
 */
export async function getCustomerSubscriptions(userId) {
    try {
        // First, find the customer by email or metadata
        const customers = await stripe.customers.list({
            email: userId.includes("@") ? userId : undefined,
            limit: 100,
        });

        const subscriptions = [];
        for (const customer of customers.data) {
            const customerSubscriptions = await stripe.subscriptions.list({
                customer: customer.id,
                status: "active",
                limit: 10,
            });
            subscriptions.push(...customerSubscriptions.data);
        }

        return subscriptions;
    } catch (error) {
        console.error("Error getting customer subscriptions:", error);
        throw error;
    }
}

/**
 * Verify webhook signature
 * @param {string} payload - Raw request body
 * @param {string} signature - Stripe signature header
 * @returns {Stripe.Event}
 */
export function verifyWebhookSignature(payload, signature) {
    const webhookSecret = process.env.STRIPE_WEBHOOK_SECRET;
    if (!webhookSecret) {
        console.warn("STRIPE_WEBHOOK_SECRET is not set - skipping signature verification");
        try {
            return JSON.parse(payload.toString());
        } catch {
            throw new Error("Invalid webhook payload");
        }
    }

    try {
        return stripe.webhooks.constructEvent(payload, signature, webhookSecret);
    } catch (error) {
        console.error("Webhook signature verification failed:", error.message);
        throw error;
    }
}
