-- Migration: Create user_entitlements table for Apple IAP subscription persistence
-- Run this in your Supabase SQL editor or via migration tool

CREATE TABLE IF NOT EXISTS user_entitlements (
    user_id TEXT PRIMARY KEY,
    plan TEXT NOT NULL DEFAULT 'free' CHECK (plan IN ('free', 'proMonthly', 'premiumMonthly', 'weekly', 'monthlyPro')),
    is_pro BOOLEAN NOT NULL DEFAULT false,
    expires_at TIMESTAMPTZ NULL,
    apple_original_transaction_id TEXT NULL,
    apple_product_id TEXT NULL,
    apple_environment TEXT NULL,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Index for expiry checks (useful for cleanup queries)
CREATE INDEX IF NOT EXISTS idx_user_entitlements_expires_at ON user_entitlements(expires_at) WHERE expires_at IS NOT NULL;

-- Index for updated_at (useful for audit queries)
CREATE INDEX IF NOT EXISTS idx_user_entitlements_updated_at ON user_entitlements(updated_at);

-- Comment on table
COMMENT ON TABLE user_entitlements IS 'Stores user subscription entitlements from Apple IAP. Backend source of truth for feature gating.';
