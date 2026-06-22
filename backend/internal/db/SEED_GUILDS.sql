-- Seed Default Guilds based on Tactical Colors
INSERT INTO public.guilds (name, emblem_color) VALUES ('THE_VANGUARD', '#CCFF00') ON CONFLICT (name) DO NOTHING;
INSERT INTO public.guilds (name, emblem_color) VALUES ('SAPPHIRE_SYNDICATE', '#00F0FF') ON CONFLICT (name) DO NOTHING;
INSERT INTO public.guilds (name, emblem_color) VALUES ('CYBER_CORE', '#FF5F00') ON CONFLICT (name) DO NOTHING;
INSERT INTO public.guilds (name, emblem_color) VALUES ('RED_REBEL_CELL', '#FF0000') ON CONFLICT (name) DO NOTHING;
