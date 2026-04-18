-- Dawn Run Apple Health Direct MVP schema
create table if not exists run_sessions (
  id uuid primary key default gen_random_uuid(),
  external_run_id text unique,
  source text not null default 'apple_health',
  started_at timestamptz not null,
  ended_at timestamptz not null,
  distance_m numeric not null,
  moving_time_s integer not null,
  elevation_gain_m numeric,
  avg_hr numeric,
  max_hr numeric,
  cadence_avg numeric,
  splits_json jsonb,
  raw_payload jsonb,
  created_at timestamptz not null default now()
);

create index if not exists idx_run_sessions_started_at on run_sessions (started_at desc);
create index if not exists idx_run_sessions_source on run_sessions (source);
