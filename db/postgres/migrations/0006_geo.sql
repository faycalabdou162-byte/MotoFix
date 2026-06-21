CREATE TABLE IF NOT EXISTS geo.zones (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  city_code TEXT NOT NULL,
  zone_name TEXT NOT NULL,
  polygon GEOGRAPHY(POLYGON, 4326) NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS geo.demand_heatmap (
  id BIGSERIAL PRIMARY KEY,
  city_code TEXT NOT NULL,
  geohash TEXT NOT NULL,
  demand_score NUMERIC(8,4) NOT NULL,
  predicted_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_geo_zones_polygon
  ON geo.zones USING GIST (polygon);
