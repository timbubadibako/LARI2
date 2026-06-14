-- LARI2 - Pure PostgreSQL Schema (Self-Managed Auth)
-- Focus: Optimized Storage for PostGIS without Supabase dependencies

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS postgis;

-- 1. AUTH & USERS (Replacing Supabase Auth)
CREATE TABLE IF NOT EXISTS public.users (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  email TEXT UNIQUE NOT NULL,
  password_hash TEXT NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 2. GUILDS
CREATE TABLE IF NOT EXISTS public.guilds (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  name TEXT UNIQUE NOT NULL,
  emblem_color TEXT DEFAULT '#38bdf8',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 3. PROFILES
CREATE TABLE IF NOT EXISTS public.profiles (
  id UUID REFERENCES public.users(id) ON DELETE CASCADE PRIMARY KEY,
  username TEXT UNIQUE,
  display_name TEXT,
  avatar_url TEXT,
  level INTEGER DEFAULT 1,
  xp INTEGER DEFAULT 0,
  guild_id UUID REFERENCES public.guilds(id) NULL,
  territory_color TEXT DEFAULT '#0ea5e9',
  bio TEXT,
  public_profile BOOLEAN DEFAULT FALSE,
  ghost_mode BOOLEAN DEFAULT FALSE,
  signature_data TEXT, -- Added for Graffiti Signature
  total_distance_km FLOAT DEFAULT 0,
  total_sectors_held INTEGER DEFAULT 0,
  global_rank INTEGER DEFAULT 0,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 4. RUNNING HISTORY
CREATE TABLE IF NOT EXISTS public.runs (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
  guild_id UUID REFERENCES public.guilds(id) ON DELETE SET NULL NULL,
  distance_km FLOAT DEFAULT 0,
  duration_sec INTEGER DEFAULT 0,
  calories FLOAT DEFAULT 0,
  status TEXT DEFAULT 'pending',
  path_geometry GEOMETRY(LineString, 4326),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 5. TERRITORY DOMINION
CREATE TABLE IF NOT EXISTS public.user_territories (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
  guild_id UUID REFERENCES public.guilds(id) NULL,
  sector_id TEXT NOT NULL,
  merged_boundary GEOMETRY(MultiPolygon, 4326),
  total_area_sqm FLOAT DEFAULT 0,
  last_expanded_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(user_id, sector_id)
);

-- 6. CACHED LEADERBOARD
CREATE TABLE IF NOT EXISTS public.leaderboard_cache (
  sector_id TEXT NOT NULL,
  user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
  rank INTEGER NOT NULL,
  total_area_sqm FLOAT NOT NULL,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  PRIMARY KEY (sector_id, user_id)
);

-- 7. PENDING TRAILS
CREATE TABLE IF NOT EXISTS public.pending_trails (
  id SERIAL PRIMARY KEY,
  user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
  geom GEOMETRY(LineString, 4326) NOT NULL,
  start_point GEOMETRY(Point, 4326) NOT NULL,
  end_point GEOMETRY(Point, 4326) NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  expires_at TIMESTAMP WITH TIME ZONE DEFAULT (NOW() + INTERVAL '72 hours'),
  is_active BOOLEAN DEFAULT TRUE
);
CREATE INDEX IF NOT EXISTS pending_trails_spatial_idx ON public.pending_trails USING GIST(geom);

-- 8. GRAFFITI
CREATE TABLE IF NOT EXISTS public.graffiti (
  id SERIAL PRIMARY KEY,
  user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
  data JSONB NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
