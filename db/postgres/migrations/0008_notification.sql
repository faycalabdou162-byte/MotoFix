CREATE TABLE IF NOT EXISTS notification.outbox (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  aggregate_type TEXT NOT NULL,
  aggregate_id UUID NOT NULL,
  channel TEXT NOT NULL,
  template_code TEXT NOT NULL,
  payload JSONB NOT NULL,
  delivery_status TEXT NOT NULL DEFAULT 'pending',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_notification_status_created
  ON notification.outbox (delivery_status, created_at DESC);
