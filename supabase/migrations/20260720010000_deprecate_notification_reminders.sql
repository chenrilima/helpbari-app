-- This legacy table is intentionally retained for compatibility and privacy
-- deletion. Concrete OS notification schedules are local device projections;
-- synchronized reminder rules live in their owning business entities/settings.
COMMENT ON TABLE public.notification_reminders IS
  'LEGACY/DEPRECATED: not a functional source of truth for the Flutter app. '
  'Do not store plugin notification IDs or concrete device schedules here. '
  'Retained for compatibility and delete_my_data() coverage pending a separately approved removal.';
