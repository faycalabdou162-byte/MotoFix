create extension if not exists postgis;

create table if not exists cities (
  id text primary key,
  name text not null,
  country_code text not null,
  timezone text not null,
  created_at timestamptz not null default now()
);

create table if not exists users (
  city_id text not null references cities(id),
  id text not null,
  phone_e164_hash bytea,
  phone_ciphertext bytea,
  email_hash bytea,
  email_ciphertext bytea,
  name text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  primary key (city_id, id)
);

create table if not exists drivers (
  city_id text not null references cities(id),
  id text not null,
  status text not null,
  rating numeric(3,2) not null default 4.50,
  trips_completed int not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  primary key (city_id, id)
);

create table if not exists vehicles (
  city_id text not null references cities(id),
  id text not null,
  driver_id text not null,
  type text not null,
  plate text,
  meta jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  primary key (city_id, id)
);

create table if not exists trips (
  city_id text not null references cities(id),
  id text not null,
  user_id text not null,
  driver_id text,
  vehicle_type text not null,
  status text not null,
  pickup_lat double precision not null,
  pickup_lng double precision not null,
  dropoff_lat double precision not null,
  dropoff_lng double precision not null,
  surge_factor double precision not null default 1.0,
  quoted_currency text not null,
  quoted_amount bigint not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  primary key (city_id, id)
) partition by list (city_id);

create table if not exists trips_niger_niamey partition of trips for values in ('ne_niamey');

create index if not exists trips_city_user_status_idx on trips (city_id, user_id, status, created_at desc);
create index if not exists trips_city_driver_status_idx on trips (city_id, driver_id, status, created_at desc);

create table if not exists payments (
  city_id text not null references cities(id),
  id text not null,
  trip_id text not null,
  method text not null,
  currency text not null,
  amount bigint not null,
  status text not null,
  provider_ref text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  primary key (city_id, id)
);

create index if not exists payments_city_trip_idx on payments (city_id, trip_id, created_at desc);

create table if not exists zones (
  city_id text not null references cities(id),
  id text not null,
  name text not null,
  centroid geography(point, 4326) not null,
  radius_m int not null default 800,
  created_at timestamptz not null default now(),
  primary key (city_id, id)
);

create index if not exists zones_centroid_gix on zones using gist (centroid);

create table if not exists demand_heatmap (
  city_id text not null references cities(id),
  zone_id text not null,
  bucket_start timestamptz not null,
  demand double precision not null,
  updated_at timestamptz not null default now(),
  primary key (city_id, zone_id, bucket_start)
);

create table if not exists audit_logs (
  city_id text not null references cities(id),
  id text not null,
  actor_id text not null,
  actor_role text not null,
  action text not null,
  ip inet,
  user_agent text,
  meta jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  primary key (city_id, id)
);

create index if not exists audit_logs_city_actor_idx on audit_logs (city_id, actor_id, created_at desc);

create table if not exists fraud_signals (
  city_id text not null references cities(id),
  id text not null,
  subject_type text not null,
  subject_id text not null,
  signal_type text not null,
  score double precision not null,
  meta jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  primary key (city_id, id)
);

create index if not exists fraud_city_subject_idx on fraud_signals (city_id, subject_type, subject_id, created_at desc);

