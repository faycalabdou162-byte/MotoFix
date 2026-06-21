CREATE TABLE IF NOT EXISTS payment.payments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  trip_id UUID NOT NULL,
  user_id UUID NOT NULL,
  driver_id UUID,
  provider TEXT NOT NULL,
  payment_method TEXT NOT NULL,
  amount NUMERIC(12,2) NOT NULL,
  currency_code TEXT NOT NULL DEFAULT 'XOF',
  status TEXT NOT NULL DEFAULT 'pending',
  idempotency_key TEXT NOT NULL UNIQUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS payment.payment_attempts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  payment_id UUID NOT NULL REFERENCES payment.payments(id) ON DELETE CASCADE,
  external_reference TEXT,
  attempt_status TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_payment_user_created
  ON payment.payments (user_id, created_at DESC);
