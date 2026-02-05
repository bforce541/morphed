// morphed-backend/src/appleVerify.js

export async function verifyTransaction(signedTransactionInfo, environment) {
    if (!signedTransactionInfo) {
        throw new Error("signed_transaction_info is required");
    }

    // Stub: return a deterministic Pro plan for local dev only.
    // Replace with real Apple JWS verification for production.
    return {
        plan: "pro",
        expiresDate: null,
        originalTransactionId: "local-dev-original-transaction",
        productId: "local-dev-product",
        environment: environment || "Local"
    };
}
