CREATE TABLE IF NOT EXISTS analytics.audit_logs (
  id BIGSERIAL PRIMARY KEY,
  actor_id UUID,
  actor_role TEXT NOT NULL,
  action_name TEXT NOT NULL,
  resource_type TEXT NOT NULL,
  resource_id TEXT NOT NULL,
  metadata JSONB NOT NULL DEFAULT '{}'::JSONB,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS analytics.fraud_signals (
  id BIGSERIAL PRIMARY KEY,
  signal_type TEXT NOT NULL,
  severity TEXT NOT NULL,
  account_id UUID,
  trip_id UUID,
  payment_id UUID,
  metadata JSONB NOT NULL DEFAULT '{}'::JSONB,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_fraud_signal_created
  ON analytics.fraud_signals (signal_type, created_at DESC);
