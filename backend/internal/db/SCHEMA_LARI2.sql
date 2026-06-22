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
CREATE INDEX IF NOT EXISTS pending_trails_start_point_idx ON public.pending_trails USING GIST(start_point);
CREATE INDEX IF NOT EXISTS pending_trails_end_point_idx ON public.pending_trails USING GIST(end_point);
CREATE INDEX IF NOT EXISTS pending_trails_user_id_idx ON public.pending_trails(user_id);
CREATE INDEX IF NOT EXISTS pending_trails_expires_at_idx ON public.pending_trails(expires_at);

-- Spatial index for territory conquest queries (viewport filter + cookie-cutter)
CREATE INDEX IF NOT EXISTS user_territories_spatial_idx ON public.user_territories USING GIST(merged_boundary);
CREATE INDEX IF NOT EXISTS user_territories_user_id_idx ON public.user_territories(user_id);
CREATE INDEX IF NOT EXISTS user_territories_guild_id_idx ON public.user_territories(guild_id);
CREATE INDEX IF NOT EXISTS user_territories_sector_id_idx ON public.user_territories(sector_id);

-- Spatial index for run history path queries
CREATE INDEX IF NOT EXISTS runs_spatial_idx ON public.runs USING GIST(path_geometry);
CREATE INDEX IF NOT EXISTS runs_user_id_idx ON public.runs(user_id);
CREATE INDEX IF NOT EXISTS runs_status_idx ON public.runs(status);
CREATE INDEX IF NOT EXISTS runs_created_at_idx ON public.runs(created_at DESC);

-- 8. GRAFFITI
CREATE TABLE IF NOT EXISTS public.graffiti (
  id SERIAL PRIMARY KEY,
  user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
  location GEOMETRY(Point, 4326), -- spatial column for geo-querying nearby graffiti
  data JSONB NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS graffiti_spatial_idx ON public.graffiti USING GIST(location);
CREATE INDEX IF NOT EXISTS graffiti_user_id_idx ON public.graffiti(user_id);

-- 9. SEASON HISTORY (Hall of Fame)
CREATE TABLE IF NOT EXISTS public.season_history (
  id SERIAL PRIMARY KEY,
  season_id TEXT NOT NULL, -- e.g., '2026-W25'
  sector_id TEXT NOT NULL,
  winner_user_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
  guild_id UUID REFERENCES public.guilds(id) ON DELETE SET NULL,
  total_area_sqm FLOAT DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS season_history_season_idx ON public.season_history(season_id);
CREATE INDEX IF NOT EXISTS season_history_sector_idx ON public.season_history(sector_id);

-- 10. USER BADGES (Achievements)
CREATE TABLE IF NOT EXISTS public.user_badges (
  id SERIAL PRIMARY KEY,
  user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
  badge_id TEXT NOT NULL, -- e.g., 'RULER_SENAYAN_W25'
  badge_name TEXT NOT NULL,
  description TEXT,
  earned_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(user_id, badge_id)
);
CREATE INDEX IF NOT EXISTS user_badges_user_id_idx ON public.user_badges(user_id);

-- 11. SOCIAL (Friends / Followers)
CREATE TABLE IF NOT EXISTS public.friendships (
  user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
  friend_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
  status TEXT DEFAULT 'pending', -- 'pending', 'accepted', 'blocked'
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  PRIMARY KEY (user_id, friend_id)
);
CREATE INDEX IF NOT EXISTS friendships_user_id_idx ON public.friendships(user_id);
CREATE INDEX IF NOT EXISTS friendships_friend_id_idx ON public.friendships(friend_id);
