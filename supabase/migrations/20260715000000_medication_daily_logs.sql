CREATE UNIQUE INDEX IF NOT EXISTS medications_user_id_id_key ON public.medications (user_id, id);
CREATE TABLE public.medication_logs (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(), user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  medication_id uuid NOT NULL, log_date date NOT NULL,
  status text NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'taken', 'skipped')),
  created_at timestamptz NOT NULL DEFAULT now(), updated_at timestamptz NOT NULL DEFAULT now(), deleted_at timestamptz,
  CONSTRAINT medication_logs_medication_owner_fkey FOREIGN KEY (user_id, medication_id) REFERENCES public.medications(user_id, id) ON DELETE CASCADE,
  CONSTRAINT medication_logs_user_medication_date_key UNIQUE (user_id, medication_id, log_date)
);
CREATE INDEX medication_logs_user_date_idx ON public.medication_logs (user_id, log_date, deleted_at);
CREATE INDEX medication_logs_user_updated_at_idx ON public.medication_logs (user_id, updated_at);
ALTER TABLE public.medication_logs ENABLE ROW LEVEL SECURITY;
CREATE POLICY "medication_logs select own" ON public.medication_logs FOR SELECT USING (user_id = auth.uid());
CREATE POLICY "medication_logs insert own" ON public.medication_logs FOR INSERT WITH CHECK (user_id = auth.uid());
CREATE POLICY "medication_logs update own" ON public.medication_logs FOR UPDATE USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());
GRANT SELECT, INSERT, UPDATE ON public.medication_logs TO authenticated;
GRANT ALL ON public.medication_logs TO service_role;
CREATE OR REPLACE FUNCTION public.medication_latest_updated_at_wins() RETURNS trigger LANGUAGE plpgsql SET search_path = '' AS $$
BEGIN IF NEW.updated_at < OLD.updated_at THEN RETURN OLD; END IF; RETURN NEW; END; $$;
DROP TRIGGER IF EXISTS medications_set_updated_at ON public.medications;
CREATE TRIGGER medications_latest_updated_at_wins BEFORE UPDATE ON public.medications FOR EACH ROW EXECUTE FUNCTION public.medication_latest_updated_at_wins();
CREATE TRIGGER medication_logs_latest_updated_at_wins BEFORE UPDATE ON public.medication_logs FOR EACH ROW EXECUTE FUNCTION public.medication_latest_updated_at_wins();
INSERT INTO public.medication_logs (user_id, medication_id, log_date, status, created_at, updated_at)
SELECT user_id, id, updated_at::date, status, created_at, updated_at FROM public.medications WHERE deleted_at IS NULL
ON CONFLICT (user_id, medication_id, log_date) DO NOTHING;
