-- Unified Treatment Engine hardening and rollout contracts.
-- This migration is intentionally not applied by the client repository.

ALTER TABLE public.routine_plans
  ADD COLUMN category text,
  ADD COLUMN provenance_origin text NOT NULL DEFAULT 'manual',
  ADD COLUMN validation_status text NOT NULL DEFAULT 'confirmed',
  ADD COLUMN provenance_prescription_id uuid,
  ADD COLUMN provenance_prescription_item_id uuid,
  ADD COLUMN provenance_document_id uuid,
  ADD COLUMN provenance_professional_reference text,
  ADD COLUMN temporal_precision text NOT NULL DEFAULT 'exact';

UPDATE public.routine_plans AS plan
SET category = routine.category
FROM public.smart_routines AS routine
WHERE routine.user_id = plan.user_id AND routine.id = plan.routine_id;

UPDATE public.routine_plans SET duration_type = 'bounded'
WHERE duration_type = 'fixed';

ALTER TABLE public.routine_plans
  ALTER COLUMN category SET NOT NULL,
  DROP CONSTRAINT routine_plans_duration_type_check,
  ADD CONSTRAINT routine_plans_category_check
    CHECK (category IN ('medication','vitamin','supplement','other')),
  ADD CONSTRAINT routine_plans_duration_type_check
    CHECK (duration_type IN ('bounded','continuous','unknown','singleDose')),
  ADD CONSTRAINT routine_plans_provenance_origin_check
    CHECK (provenance_origin IN ('manual','migratedLegacy','prescriptionImport')),
  ADD CONSTRAINT routine_plans_validation_status_check
    CHECK (validation_status IN ('confirmed','estimated','validationRequired')),
  ADD CONSTRAINT routine_plans_temporal_precision_check
    CHECK (temporal_precision IN ('exact','inferredFromProfile','estimatedFromLegacyDate','unknown'));

COMMENT ON COLUMN public.smart_routines.category IS
  'Current category projection only. routine_plans.category is the historical clinical authority.';

CREATE OR REPLACE FUNCTION public.unified_treatment_preserve_plan_revision()
RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
  IF ROW(NEW.user_id,NEW.id,NEW.routine_id,NEW.revision,NEW.category,NEW.mode,
         NEW.duration_type,NEW.effective_from,NEW.effective_until,NEW.dose_value,
         NEW.dose_unit,NEW.dose_original_text,NEW.route,NEW.clinical_instructions,
         NEW.activated_at,NEW.previous_plan_id,
         NEW.provenance_origin,NEW.validation_status,
         NEW.provenance_prescription_id,NEW.provenance_prescription_item_id,
         NEW.provenance_document_id,NEW.provenance_professional_reference,
         NEW.temporal_precision,NEW.created_at)
     IS DISTINCT FROM
     ROW(OLD.user_id,OLD.id,OLD.routine_id,OLD.revision,OLD.category,OLD.mode,
         OLD.duration_type,OLD.effective_from,OLD.effective_until,OLD.dose_value,
         OLD.dose_unit,OLD.dose_original_text,OLD.route,OLD.clinical_instructions,
         OLD.activated_at,OLD.previous_plan_id,
         OLD.provenance_origin,OLD.validation_status,
         OLD.provenance_prescription_id,OLD.provenance_prescription_item_id,
         OLD.provenance_document_id,OLD.provenance_professional_reference,
         OLD.temporal_precision,OLD.created_at)
  THEN RAISE EXCEPTION 'immutable routine plan revision'; END IF;
  IF OLD.replaced_at IS NOT NULL AND NEW.replaced_at IS DISTINCT FROM OLD.replaced_at
  THEN RAISE EXCEPTION 'routine plan replacement is immutable'; END IF;
  IF OLD.replaced_at IS NULL AND NEW.replaced_at IS NOT NULL AND
     NEW.replaced_at < COALESCE(OLD.activated_at, OLD.created_at)
  THEN RAISE EXCEPTION 'invalid routine plan replacement'; END IF;
  RETURN NEW;
END; $$;

DROP TRIGGER IF EXISTS routine_plans_preserve_revision ON public.routine_plans;
CREATE TRIGGER routine_plans_preserve_revision
BEFORE UPDATE ON public.routine_plans FOR EACH ROW
EXECUTE FUNCTION public.unified_treatment_preserve_plan_revision();

DROP TRIGGER IF EXISTS routine_adherence_events_no_update
  ON public.routine_adherence_events;
DROP TRIGGER IF EXISTS routine_adherence_events_no_delete
  ON public.routine_adherence_events;
CREATE TRIGGER routine_adherence_events_no_update BEFORE UPDATE
  ON public.routine_adherence_events FOR EACH ROW
  EXECUTE FUNCTION public.smart_routine_reject_clinical_mutation();
CREATE TRIGGER routine_adherence_events_no_delete BEFORE DELETE
  ON public.routine_adherence_events FOR EACH ROW
  EXECUTE FUNCTION public.smart_routine_reject_clinical_mutation();

CREATE TABLE public.unified_treatment_legacy_mappings (
  id uuid NOT NULL, user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  source_type text NOT NULL CHECK (source_type IN ('medication','vitamin')),
  legacy_entity_id uuid NOT NULL, target_routine_id uuid NOT NULL,
  target_plan_id uuid NOT NULL, target_schedule_id uuid NOT NULL,
  migration_schema_version integer NOT NULL CHECK (migration_schema_version > 0),
  status text NOT NULL CHECK (status IN ('notStarted','detected','migrating','validationRequired','completed','failed','conflict')),
  started_at_utc timestamptz NOT NULL, completed_at_utc timestamptz,
  failure_code text, validation_summary jsonb NOT NULL DEFAULT '{}'::jsonb,
  time_zone text, temporal_precision text NOT NULL,
  has_new_clinical_writes boolean NOT NULL DEFAULT false,
  created_at timestamptz NOT NULL, updated_at timestamptz NOT NULL,
  PRIMARY KEY (user_id,id), UNIQUE (user_id,source_type,legacy_entity_id),
  UNIQUE (user_id,target_routine_id),
  FOREIGN KEY (user_id,target_routine_id) REFERENCES public.smart_routines(user_id,id),
  FOREIGN KEY (user_id,target_plan_id) REFERENCES public.routine_plans(user_id,id),
  FOREIGN KEY (user_id,target_schedule_id) REFERENCES public.routine_schedules(user_id,id)
);

CREATE TABLE public.unified_treatment_legacy_log_mappings (
  id uuid NOT NULL, user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  source_type text NOT NULL CHECK (source_type IN ('medication','vitamin')),
  legacy_log_id uuid NOT NULL, legacy_entity_id uuid NOT NULL,
  occurrence_id uuid NOT NULL, adherence_event_id uuid,
  temporal_precision text NOT NULL, created_at timestamptz NOT NULL,
  PRIMARY KEY (user_id,id), UNIQUE (user_id,source_type,legacy_log_id),
  FOREIGN KEY (user_id,occurrence_id) REFERENCES public.routine_occurrences(user_id,id),
  FOREIGN KEY (user_id,adherence_event_id) REFERENCES public.routine_adherence_events(user_id,id)
);

CREATE TABLE public.unified_treatment_cutover_states (
  user_id uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  state text NOT NULL, migration_schema_version integer NOT NULL,
  validated_at_utc timestamptz, read_new_at_utc timestamptz,
  write_new_at_utc timestamptz, recovery_code text,
  remote_schema_available boolean NOT NULL DEFAULT true,
  updated_at timestamptz NOT NULL
);

CREATE TABLE public.unified_treatment_rollout_flags (
  key text PRIMARY KEY, enabled boolean NOT NULL DEFAULT false,
  source text NOT NULL, updated_at timestamptz NOT NULL,
  expires_at timestamptz
);

INSERT INTO public.unified_treatment_rollout_flags(key,enabled,source,updated_at)
VALUES
 ('unified_treatment_migration_enabled',false,'migration',now()),
 ('unified_treatment_cutover_enabled',false,'migration',now()),
 ('unified_treatment_read_new_enabled',false,'migration',now()),
 ('unified_treatment_write_new_enabled',false,'migration',now()),
 ('unified_treatment_remote_sync_enabled',false,'migration',now())
ON CONFLICT (key) DO NOTHING;

ALTER TABLE public.unified_treatment_legacy_mappings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.unified_treatment_legacy_log_mappings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.unified_treatment_cutover_states ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.unified_treatment_rollout_flags ENABLE ROW LEVEL SECURITY;

CREATE POLICY unified_treatment_mapping_own ON public.unified_treatment_legacy_mappings
  FOR ALL USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());
CREATE POLICY unified_treatment_log_mapping_own ON public.unified_treatment_legacy_log_mappings
  FOR ALL USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());
CREATE POLICY unified_treatment_cutover_own ON public.unified_treatment_cutover_states
  FOR SELECT USING (user_id = auth.uid());
CREATE POLICY unified_treatment_flags_read ON public.unified_treatment_rollout_flags
  FOR SELECT USING (auth.uid() IS NOT NULL);

GRANT SELECT,INSERT,UPDATE ON public.unified_treatment_legacy_mappings,
  public.unified_treatment_legacy_log_mappings TO authenticated;
GRANT SELECT ON public.unified_treatment_cutover_states,
  public.unified_treatment_rollout_flags TO authenticated;
GRANT ALL ON public.unified_treatment_legacy_mappings,
  public.unified_treatment_legacy_log_mappings,
  public.unified_treatment_cutover_states,
  public.unified_treatment_rollout_flags TO service_role;

CREATE OR REPLACE FUNCTION public.delete_my_data()
RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path = '' AS $$
DECLARE current_user_id uuid := auth.uid();
BEGIN
  IF current_user_id IS NULL THEN RAISE EXCEPTION 'authentication required'; END IF;
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
  DELETE FROM public.settings WHERE user_id=current_user_id;
  DELETE FROM public.profiles WHERE user_id=current_user_id;
  DELETE FROM public.privacy_consents WHERE user_id=current_user_id;
  DELETE FROM public.privacy_deletion_requests WHERE user_id=current_user_id;
END; $$;

REVOKE ALL ON FUNCTION public.delete_my_data() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.delete_my_data() TO authenticated;
