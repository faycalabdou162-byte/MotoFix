CREATE TABLE IF NOT EXISTS trip.trips (
  id UUID NOT NULL DEFAULT gen_random_uuid(),
  city_code TEXT NOT NULL,
  service_type TEXT NOT NULL,
  user_id UUID NOT NULL,
  driver_id UUID,
  status TEXT NOT NULL,
  pickup_location GEOGRAPHY(POINT, 4326) NOT NULL,
  destination_location GEOGRAPHY(POINT, 4326),
  quoted_amount NUMERIC(12,2),
  final_amount NUMERIC(12,2),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  PRIMARY KEY (id, city_code)
) PARTITION BY LIST (city_code);

CREATE TABLE IF NOT EXISTS trip.trips_niamey PARTITION OF trip.trips
  FOR VALUES IN ('niamey');

CREATE TABLE IF NOT EXISTS trip.trip_offers (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  trip_id UUID NOT NULL,
  driver_id UUID NOT NULL,
  offer_status TEXT NOT NULL,
  offered_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  expires_at TIMESTAMPTZ NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_trip_city_created
  ON trip.trips (city_code, created_at DESC);
