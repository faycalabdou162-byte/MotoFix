CREATE TABLE IF NOT EXISTS "user".users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  account_id UUID NOT NULL UNIQUE REFERENCES auth.accounts(id) ON DELETE CASCADE,
  full_name TEXT NOT NULL,
  email_encrypted BYTEA,
  phone_encrypted BYTEA,
  reputation_score NUMERIC(5,2) NOT NULL DEFAULT 5.00,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS "user".user_preferences (
  user_id UUID PRIMARY KEY REFERENCES "user".users(id) ON DELETE CASCADE,
  low_bandwidth_mode BOOLEAN NOT NULL DEFAULT TRUE,
  sms_fallback_enabled BOOLEAN NOT NULL DEFAULT TRUE,
  preferred_payment_method TEXT NOT NULL DEFAULT 'cash',
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS "user".saved_addresses (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES "user".users(id) ON DELETE CASCADE,
  label TEXT NOT NULL,
  address_line TEXT NOT NULL,
  location GEOGRAPHY(POINT, 4326),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
