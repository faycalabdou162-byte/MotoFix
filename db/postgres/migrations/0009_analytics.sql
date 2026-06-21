CREATE TABLE IF NOT EXISTS analytics.trip_fact_daily (
  fact_date DATE NOT NULL,
  city_code TEXT NOT NULL,
  completed_trips BIGINT NOT NULL DEFAULT 0,
  cancelled_trips BIGINT NOT NULL DEFAULT 0,
  gross_revenue NUMERIC(14,2) NOT NULL DEFAULT 0,
  PRIMARY KEY (fact_date, city_code)
);

CREATE TABLE IF NOT EXISTS analytics.driver_performance_daily (
  fact_date DATE NOT NULL,
  driver_id UUID NOT NULL,
  completed_trips BIGINT NOT NULL DEFAULT 0,
  acceptance_rate NUMERIC(5,4) NOT NULL DEFAULT 0,
  ontime_start_rate NUMERIC(5,4) NOT NULL DEFAULT 0,
  PRIMARY KEY (fact_date, driver_id)
);
