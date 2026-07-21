-- Product Freeze V1, Block B: synchronized business preferences only.
-- OS permission, plugin IDs, concrete schedules and local manifest stay local.

ALTER TABLE public.settings
  ADD COLUMN IF NOT EXISTS notification_preferences jsonb;

UPDATE public.settings
SET notification_preferences = jsonb_build_object(
  'version', 1,
  'globalEnabled',
    vitamin_reminders_enabled OR medication_reminders_enabled OR appointment_reminders_enabled,
  'categories', jsonb_build_object(
    'treatment', vitamin_reminders_enabled OR medication_reminders_enabled,
    'appointments', appointment_reminders_enabled,
    'water', false,
    'meals', false,
    'weight', false
  ),
  'items', '{}'::jsonb,
  'times', '[]'::jsonb
)
WHERE notification_preferences IS NULL;

ALTER TABLE public.settings
  ALTER COLUMN notification_preferences SET DEFAULT
    '{"version":1,"globalEnabled":false,"categories":{"treatment":false,"appointments":false,"water":false,"meals":false,"weight":false},"items":{},"times":[]}'::jsonb;

ALTER TABLE public.settings
  ALTER COLUMN notification_preferences SET NOT NULL;
