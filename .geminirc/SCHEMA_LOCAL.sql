-- LARI - Local Standalone Postgres Schema
-- Modified for Opsi 2 (No Supabase Auth schema)

-- NOTE: You must have PostGIS installed on your system!
-- e.g., sudo apt install postgresql-18-postgis-3
CREATE EXTENSION IF NOT EXISTS postgis;

-- 1. USERS & GUILDS
CREATE TABLE IF NOT EXISTS public.guilds (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  name TEXT UNIQUE NOT NULL,
  emblem_color TEXT DEFAULT '#38bdf8',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Standalone Users table (replacing Supabase Auth)
CREATE TABLE IF NOT EXISTS public.users (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  email TEXT UNIQUE NOT NULL,
  password_hash TEXT NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.profiles (
  id UUID REFERENCES public.users(id) ON DELETE CASCADE PRIMARY KEY,
  username TEXT UNIQUE,
  display_name TEXT,
  avatar_url TEXT,
  level INTEGER DEFAULT 1,
  xp INTEGER DEFAULT 0,
  guild_id UUID REFERENCES public.guilds(id) NULL,
  territory_color TEXT DEFAULT '#0ea5e9',
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 2. RUNNING HISTORY
CREATE TABLE IF NOT EXISTS public.runs (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
  distance_km FLOAT DEFAULT 0,
  duration_sec INTEGER DEFAULT 0,
  calories FLOAT DEFAULT 0,
  status TEXT DEFAULT 'pending',
  path_geometry GEOMETRY(LineString, 4326),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 3. TERRITORY DOMINION
CREATE TABLE IF NOT EXISTS public.user_territories (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
  district_code TEXT NOT NULL,
  merged_boundary GEOMETRY(MultiPolygon, 4326),
  total_area_sqm FLOAT DEFAULT 0,
  last_expanded_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(user_id, district_code)
);

-- 4. CACHED LEADERBOARD
CREATE TABLE IF NOT EXISTS public.leaderboard_cache (
  district_code TEXT NOT NULL,
  user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
  rank INTEGER NOT NULL,
  total_area_sqm FLOAT NOT NULL,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  PRIMARY KEY (district_code, user_id)
);

-- 5. PENDING TRAILS (Integrity Protocol)
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
