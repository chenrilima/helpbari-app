-- Product Freeze V1, Block A: versioned onboarding and tracking preferences.
-- Additive and compatible with clients that only know the legacy settings fields.

ALTER TABLE public.settings
  ADD COLUMN IF NOT EXISTS treatment_tracking_enabled boolean NOT NULL DEFAULT true,
  ADD COLUMN IF NOT EXISTS water_tracking_enabled boolean NOT NULL DEFAULT true,
  ADD COLUMN IF NOT EXISTS weight_tracking_enabled boolean NOT NULL DEFAULT true;

CREATE TABLE IF NOT EXISTS public.onboarding_states (
  id uuid PRIMARY KEY,
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  onboarding_version integer NOT NULL CHECK (onboarding_version > 0),
  status text NOT NULL CHECK (
    status IN ('notStarted', 'inProgress', 'completed', 'needsReview')
  ),
  current_step_id text NULL CHECK (
    current_step_id IS NULL OR current_step_id IN (
      'welcome', 'legalConsents', 'basicProfile', 'bariatricJourney',
      'weightAndGoals', 'trackingPreferences', 'trackingConfiguration',
      'reminderPreference', 'completion'
    )
  ),
  completed_step_ids jsonb NOT NULL DEFAULT '[]'::jsonb
    CHECK (jsonb_typeof(completed_step_ids) = 'array'),
  started_at timestamptz NULL,
  completed_at timestamptz NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  deleted_at timestamptz NULL,
  CONSTRAINT onboarding_states_user_key UNIQUE (user_id),
  CONSTRAINT onboarding_states_completed_at_check CHECK (
    status <> 'completed' OR completed_at IS NOT NULL
  )
);

CREATE INDEX IF NOT EXISTS onboarding_states_user_sync_idx
  ON public.onboarding_states (user_id, updated_at);

DROP TRIGGER IF EXISTS onboarding_states_set_updated_at
  ON public.onboarding_states;
CREATE TRIGGER onboarding_states_set_updated_at
BEFORE UPDATE ON public.onboarding_states
FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

ALTER TABLE public.onboarding_states ENABLE ROW LEVEL SECURITY;

CREATE POLICY "onboarding_states select own"
  ON public.onboarding_states FOR SELECT
  USING (auth.uid() = user_id);
CREATE POLICY "onboarding_states insert own"
  ON public.onboarding_states FOR INSERT
  WITH CHECK (auth.uid() = user_id);
CREATE POLICY "onboarding_states update own"
  ON public.onboarding_states FOR UPDATE
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

GRANT SELECT, INSERT, UPDATE ON public.onboarding_states TO authenticated;
GRANT ALL ON public.onboarding_states TO service_role;

CREATE OR REPLACE FUNCTION public.delete_my_data()
RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path = '' AS $$
DECLARE current_user_id uuid := auth.uid();
BEGIN
  IF current_user_id IS NULL THEN RAISE EXCEPTION 'authentication required'; END IF;
  PERFORM set_config('helpbari.lgpd_deletion','on',true);
  DELETE FROM public.prescription_routine_links WHERE user_id=current_user_id;
  DELETE FROM public.treatment_proposals WHERE user_id=current_user_id;
  DELETE FROM public.prescription_reviews WHERE user_id=current_user_id;
  DELETE FROM public.prescription_versions WHERE user_id=current_user_id;
  DELETE FROM public.unified_treatment_legacy_log_mappings WHERE user_id=current_user_id;
  DELETE FROM public.unified_treatment_legacy_mappings WHERE user_id=current_user_id;
  DELETE FROM public.unified_treatment_cutover_states WHERE user_id=current_user_id;
  DELETE FROM public.routine_adherence_events WHERE user_id=current_user_id;
  DELETE FROM public.routine_occurrences WHERE user_id=current_user_id;
  DELETE FROM public.routine_pauses WHERE user_id=current_user_id;
  DELETE FROM public.routine_schedules WHERE user_id=current_user_id;
  DELETE FROM public.routine_plans WHERE user_id=current_user_id;
  DELETE FROM public.smart_routines WHERE user_id=current_user_id;
  DELETE FROM public.medical_prescription_items WHERE user_id=current_user_id;
  DELETE FROM public.medical_exam_results WHERE user_id=current_user_id;
  DELETE FROM public.medical_prescriptions WHERE user_id=current_user_id;
  DELETE FROM public.medical_exams WHERE user_id=current_user_id;
  DELETE FROM public.bioimpedance_records WHERE user_id=current_user_id;
  DELETE FROM public.extracted_document_fields WHERE user_id=current_user_id;
  DELETE FROM public.document_processings WHERE user_id=current_user_id;
  DELETE FROM public.document_inputs WHERE user_id=current_user_id;
  DELETE FROM public.report_attachments WHERE user_id=current_user_id;
  DELETE FROM public.medical_reports WHERE user_id=current_user_id;
  DELETE FROM public.medication_logs WHERE user_id=current_user_id;
  DELETE FROM public.vitamin_logs WHERE user_id=current_user_id;
  DELETE FROM public.notification_reminders WHERE user_id=current_user_id;
  DELETE FROM public.appointments WHERE user_id=current_user_id;
  DELETE FROM public.exams WHERE user_id=current_user_id;
  DELETE FROM public.meals WHERE user_id=current_user_id;
  DELETE FROM public.medications WHERE user_id=current_user_id;
  DELETE FROM public.vitamins WHERE user_id=current_user_id;
  DELETE FROM public.water_records WHERE user_id=current_user_id;
  DELETE FROM public.weight_records WHERE user_id=current_user_id;
  DELETE FROM public.onboarding_states WHERE user_id=current_user_id;
  DELETE FROM public.settings WHERE user_id=current_user_id;
  DELETE FROM public.profiles WHERE user_id=current_user_id;
  DELETE FROM public.privacy_consents WHERE user_id=current_user_id;
  DELETE FROM public.privacy_deletion_requests WHERE user_id=current_user_id;
END; $$;

REVOKE ALL ON FUNCTION public.delete_my_data() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.delete_my_data() TO authenticated;
