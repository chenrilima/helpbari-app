-- Daily vitamin adherence. The legacy vitamins.status column is intentionally
-- retained for backward compatibility but is no longer the adherence source.
CREATE UNIQUE INDEX IF NOT EXISTS vitamins_user_id_id_key
  ON public.vitamins (user_id, id);

CREATE TABLE public.vitamin_logs (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  vitamin_id uuid NOT NULL,
  log_date date NOT NULL,
  status text NOT NULL DEFAULT 'pending'
    CHECK (status IN ('pending', 'taken', 'skipped')),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  deleted_at timestamptz,
  CONSTRAINT vitamin_logs_vitamin_owner_fkey
    FOREIGN KEY (user_id, vitamin_id)
    REFERENCES public.vitamins(user_id, id) ON DELETE CASCADE,
  CONSTRAINT vitamin_logs_user_vitamin_date_key
    UNIQUE (user_id, vitamin_id, log_date)
);

CREATE INDEX vitamin_logs_user_date_idx
  ON public.vitamin_logs (user_id, log_date, deleted_at);
CREATE INDEX vitamin_logs_user_updated_at_idx
  ON public.vitamin_logs (user_id, updated_at);

CREATE TRIGGER vitamin_logs_set_updated_at
  BEFORE UPDATE ON public.vitamin_logs
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

-- Client timestamps are authoritative for offline-first conflict resolution.
CREATE OR REPLACE FUNCTION public.vitamin_latest_updated_at_wins()
RETURNS trigger LANGUAGE plpgsql SET search_path = '' AS $$
BEGIN
  IF NEW.updated_at < OLD.updated_at THEN
    RETURN OLD;
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS vitamins_set_updated_at ON public.vitamins;
DROP TRIGGER IF EXISTS vitamin_logs_set_updated_at ON public.vitamin_logs;
CREATE TRIGGER vitamins_latest_updated_at_wins
  BEFORE UPDATE ON public.vitamins FOR EACH ROW
  EXECUTE FUNCTION public.vitamin_latest_updated_at_wins();
CREATE TRIGGER vitamin_logs_latest_updated_at_wins
  BEFORE UPDATE ON public.vitamin_logs FOR EACH ROW
  EXECUTE FUNCTION public.vitamin_latest_updated_at_wins();

ALTER TABLE public.vitamin_logs ENABLE ROW LEVEL SECURITY;
CREATE POLICY "vitamin_logs select own" ON public.vitamin_logs
  FOR SELECT USING (user_id = auth.uid());
CREATE POLICY "vitamin_logs insert own" ON public.vitamin_logs
  FOR INSERT WITH CHECK (user_id = auth.uid());
CREATE POLICY "vitamin_logs update own" ON public.vitamin_logs
  FOR UPDATE USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());

GRANT SELECT, INSERT, UPDATE ON public.vitamin_logs TO authenticated;
GRANT ALL ON public.vitamin_logs TO service_role;

-- Preserve the only adherence snapshot available in the legacy model.
INSERT INTO public.vitamin_logs (user_id, vitamin_id, log_date, status, created_at, updated_at)
SELECT user_id, id, updated_at::date, status, created_at, updated_at
FROM public.vitamins
WHERE deleted_at IS NULL
ON CONFLICT (user_id, vitamin_id, log_date) DO NOTHING;
