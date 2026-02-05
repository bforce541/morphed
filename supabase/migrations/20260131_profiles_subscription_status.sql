ALTER TABLE profiles
    ADD COLUMN IF NOT EXISTS subscription_status text DEFAULT 'free',
    ADD COLUMN IF NOT EXISTS subscription_expires_at timestamptz;

UPDATE profiles
SET subscription_status = 'free'
WHERE subscription_status IS NULL;
