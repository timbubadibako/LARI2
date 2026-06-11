# Lari-Lari — Supabase Integration Guide & Schema (Reference for agents)

Dokumen ini menggabungkan semua kebutuhan Supabase: checklist setup, DDL (SQL) untuk tables & indexes, RLS example, example RPC `claim_hexes`, contoh query client (Dart/Flutter + supabase_flutter), storage & background job notes, dan langkah operasi. Tujuannya: jadi sumber kebenaran yang bisa dipakai agent atau engineer ketika mengintegrasikan backend.

---
## Ringkasan singkat
Lari-Lari membutuhkan:
- Penyimpanan workout summary + encoded polyline
- Penyimpanan raw GPS points (workout_points)
- Hex ownership + claims (H3 indices)
- Presence simplified lines
- Party/party_members (social)
- Sync queue + storage bucket untuk raw point files
- RPC server-authoritative untuk klaim hex (`claim_hexes`)

Dokumen ini berisi SQL siap-paste ke Supabase SQL editor, plus client snippets.

---

## 1) Checklist setup (quick)
1. Enable extensions:
   - postgis
   - (optional) h3 extension (if DB supports)
2. Create tables:
   - user_profiles (mirror auth.users)
   - workouts
   - workout_points
   - hex_ownership
   - hex_claims
   - presence
   - parties, party_members
   - sync_queue
3. Indexes:
   - GiST on geography/geometry columns
   - Composite index on (workout_id, ts)
4. RLS: enable row-level security on user-scoped tables (workouts, workout_points, presence)
5. RPC: create `claim_hexes(p_workout_id uuid, p_user_id uuid, p_candidates jsonb)`
6. Storage buckets:
   - `raw_points` (private)
   - `exports` (optional, protected)
7. Realtime: allow subscriptions on `hex_ownership` & `presence` (with filters)
8. Background worker: process `sync_queue` and storage imports

---

## 2) SQL (DDL + RPC + RLS examples)
Salin dan jalankan di Supabase → SQL editor. Sesuaikan otorisasi/role bila perlu.

```sql
-- 1) Extensions
CREATE EXTENSION IF NOT EXISTS postgis;

-- 2) user_profiles
create table if not exists user_profiles (
  user_id uuid primary key references auth.users(id) on delete cascade,
  display_name text,
  avatar_url text,
  faction_id uuid null,
  level integer default 1 not null,
  xp bigint default 0 not null,
  bio text,
  public_profile boolean default false,
  ghost_mode boolean default false,
  created_at timestamptz default now()
);
create index if not exists idx_user_profiles_faction on user_profiles(faction_id);

-- 3) workouts (summary)
create table if not exists workouts (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  title text,
  notes text,
  started_at timestamptz not null,
  ended_at timestamptz,
  duration_s integer,
  distance_m double precision,
  avg_pace_spk integer,
  calories integer,
  ghost_mode boolean default false,
  source text,
  polyline text,
  polyline_simplified text,
  polygon_geom geometry,
  created_at timestamptz default now()
);
create index if not exists idx_workouts_userid_created on workouts(user_id, created_at desc);

-- 4) workout_points (raw)
create table if not exists workout_points (
  id bigserial primary key,
  workout_id uuid not null references workouts(id) on delete cascade,
  ts timestamptz not null,
  lat double precision not null,
  lng double precision not null,
  pos geography(Point, 4326) GENERATED ALWAYS AS (ST_SetSRID(ST_MakePoint(lng, lat), 4326)::geography) STORED,
  accuracy_m real,
  speed_mps real,
  bearing_deg real,
  provider text,
  created_at timestamptz default now()
);
create index if not exists idx_workout_points_workout_ts on workout_points(workout_id, ts);
create index if not exists idx_workout_points_pos on workout_points using gist(pos);

-- 5) hex_ownership & hex_claims
create table if not exists hex_ownership (
  h3_index text primary key,
  owner_faction_id uuid null,
  owner_user_id uuid null references auth.users(id),
  updated_at timestamptz default now(),
  geom geography(Polygon,4326) null
);

create table if not exists hex_claims (
  id uuid primary key default gen_random_uuid(),
  workout_id uuid null references workouts(id),
  user_id uuid not null references auth.users(id),
  h3_index text not null,
  created_at timestamptz default now(),
  metadata jsonb default '{}'::jsonb
);
create index if not exists idx_hex_claims_user on hex_claims(user_id);
create index if not exists idx_hex_claims_h3 on hex_claims(h3_index);

-- 6) presence (coarse)
create table if not exists presence (
  user_id uuid primary key references auth.users(id),
  faction_id uuid,
  public_enabled boolean default false,
  ghost_mode boolean default false,
  line_simplified text,
  last_seen timestamptz default now(),
  updated_at timestamptz default now()
);
create index if not exists idx_presence_public on presence(public_enabled) where public_enabled;

-- 7) parties and party_members
create table if not exists parties (
  id uuid primary key default gen_random_uuid(),
  name text,
  host_user_id uuid not null references auth.users(id),
  share_code text,
  public boolean default true,
  created_at timestamptz default now()
);
create table if not exists party_members (
  party_id uuid not null references parties(id) on delete cascade,
  user_id uuid not null references auth.users(id),
  joined_at timestamptz default now(),
  primary key(party_id, user_id)
);
create index if not exists idx_parties_host on parties(host_user_id);

-- 8) sync_queue
create table if not exists sync_queue (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users(id),
  workout_id uuid references workouts(id),
  status text default 'pending',
  payload jsonb,
  created_at timestamptz default now(),
  updated_at timestamptz default now(),
  attempts int default 0
);
create index if not exists idx_sync_queue_status on sync_queue(status);

-- 9) RPC: claim_hexes (basic authoritative example)
create or replace function claim_hexes(p_workout_id uuid, p_user_id uuid, p_candidates jsonb)
returns jsonb
language plpgsql
as $$
declare
  rec jsonb;
  candidate text;
  result jsonb := '[]'::jsonb;
begin
  if not exists(select 1 from workouts w where w.id = p_workout_id and w.user_id = p_user_id) then
    raise exception 'Unauthorized or invalid workout';
  end if;

  perform pg_advisory_xact_lock((hashtext(p_user_id::text) % 2147483647)::int);

  for rec in select * from jsonb_array_elements(p_candidates) loop
    candidate := (rec ->> 'h3_index')::text;
    insert into hex_ownership(h3_index, owner_faction_id, owner_user_id, updated_at)
      values (candidate, null, p_user_id, now())
      on conflict (h3_index) do update set owner_user_id = excluded.owner_user_id, updated_at = now();
    insert into hex_claims(workout_id, user_id, h3_index, metadata)
      values (p_workout_id, p_user_id, candidate, rec);
    result := result || jsonb_build_object('h3_index', candidate, 'claimed', true);
  end loop;

  return jsonb_build_object('status','ok','claimed', result);
end;
$$;

-- 10) Example RLS policies (workouts)
alter table workouts enable row level security;

create policy "workouts_insert_owner" on workouts
  for insert
  with check (user_id = auth.uid());

create policy "workouts_select_owner" on workouts
  for select
  using (user_id = auth.uid());

create policy "workouts_update_owner" on workouts
  for update
  using (user_id = auth.uid())
  with check (user_id = auth.uid());

-- 11) user_profiles policies
alter table user_profiles enable row level security;

create policy "user_profiles_select_owner" on user_profiles
  for select
  using (user_id = auth.uid());

create policy "user_profiles_insert_owner" on user_profiles
  for insert
  with check (user_id = auth.uid());

create policy "user_profiles_update_owner" on user_profiles
  for update
  using (user_id = auth.uid())
  with check (user_id = auth.uid());

-- 12) workout_points policies
alter table workout_points enable row level security;

create policy "workout_points_select_owner" on workout_points
  for select
  using (exists (
    select 1 from workouts w
    where w.id = workout_points.workout_id and w.user_id = auth.uid()
  ));

create policy "workout_points_insert_owner" on workout_points
  for insert
  with check (exists (
    select 1 from workouts w
    where w.id = workout_points.workout_id and w.user_id = auth.uid()
  ));

-- 13) presence policies
alter table presence enable row level security;

create policy "presence_select_owner_or_public" on presence
  for select
  using (user_id = auth.uid() or public_enabled = true);

create policy "presence_insert_owner" on presence
  for insert
  with check (user_id = auth.uid());

create policy "presence_update_owner" on presence
  for update
  using (user_id = auth.uid())
  with check (user_id = auth.uid());

-- 14) sync_queue policies
alter table sync_queue enable row level security;

create policy "sync_queue_select_owner" on sync_queue
  for select
  using (user_id = auth.uid());

create policy "sync_queue_insert_owner" on sync_queue
  for insert
  with check (user_id = auth.uid());

create policy "sync_queue_update_owner" on sync_queue
  for update
  using (user_id = auth.uid())
  with check (user_id = auth.uid());

-- 15) Hex ownership: make writes server-only (example: allow only service role)
-- Keep SELECT public but restrict INSERT/UPDATE via RPC or service role in production.

-- If you see 403 on POST /rest/v1/user_profiles, the most common cause is:
-- - row level security is enabled, but insert/update policies are missing
-- - or the authenticated user_id does not match auth.uid()
-- Apply the policies above before testing profile/presence/workout sync flows.