CREATE TABLE IF NOT EXISTS driver.drivers (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  account_id UUID NOT NULL UNIQUE REFERENCES auth.accounts(id) ON DELETE CASCADE,
  service_type TEXT NOT NULL,
  onboarding_status TEXT NOT NULL DEFAULT 'pending',
  availability_state TEXT NOT NULL DEFAULT 'offline',
  rating NUMERIC(3,2) NOT NULL DEFAULT 5.00,
  last_location_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS driver.vehicles (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  driver_id UUID NOT NULL REFERENCES driver.drivers(id) ON DELETE CASCADE,
  vehicle_type TEXT NOT NULL,
  plate_number TEXT NOT NULL,
  metadata JSONB NOT NULL DEFAULT '{}'::JSONB,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS driver.driver_location_snapshots (
  id BIGSERIAL PRIMARY KEY,
  driver_id UUID NOT NULL REFERENCES driver.drivers(id) ON DELETE CASCADE,
  city_code TEXT NOT NULL,
  position GEOGRAPHY(POINT, 4326) NOT NULL,
  heading NUMERIC(6,2),
  speed_kph NUMERIC(6,2),
  recorded_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_driver_locations_position
  ON driver.driver_location_snapshots USING GIST (position);
