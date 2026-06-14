-- Seed Default Guilds based on Tactical Colors
INSERT INTO public.guilds (id, name, emblem_color)
VALUES 
  ('00000000-0000-0000-0000-000000000001', 'THE_VANGUARD', '#39FF14') ON CONFLICT (id) DO NOTHING; -- Neon Green

INSERT INTO public.guilds (id, name, emblem_color)
VALUES 
  ('00000000-0000-0000-0000-000000000002', 'SAPPHIRE_SYNDICATE', '#007FFF') ON CONFLICT (id) DO NOTHING; -- Azure Blue

INSERT INTO public.guilds (id, name, emblem_color)
VALUES 
  ('00000000-0000-0000-0000-000000000003', 'CYBER_CORE', '#FF5F1F') ON CONFLICT (id) DO NOTHING; -- Neon Orange

INSERT INTO public.guilds (id, name, emblem_color)
VALUES 
  ('00000000-0000-0000-0000-000000000004', 'RED_REBEL_CELL', '#FF3131') ON CONFLICT (id) DO NOTHING; -- Neon Red
