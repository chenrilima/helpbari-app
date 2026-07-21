-- V1 distributed consistency: server-owned revisions for optimistic updates.
-- Business timestamps remain in their domain columns. `updated_at` is a sync
-- timestamp and is assigned by Postgres for every mutable remote update.

CREATE OR REPLACE FUNCTION public.sync_server_now()
RETURNS timestamptz
LANGUAGE sql
STABLE
SECURITY INVOKER
SET search_path = ''
AS $$ SELECT clock_timestamp(); $$;

REVOKE ALL ON FUNCTION public.sync_server_now() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.sync_server_now() TO authenticated;
GRANT EXECUTE ON FUNCTION public.sync_server_now() TO service_role;

DO $$
DECLARE table_name text;
BEGIN
  FOREACH table_name IN ARRAY ARRAY[
    'appointments', 'exams', 'meals', 'medical_reports', 'medications',
    'notification_reminders', 'profiles', 'report_attachments', 'settings',
    'vitamins', 'water_records', 'weight_records', 'vitamin_logs',
    'medication_logs', 'privacy_consents', 'document_inputs',
    'document_processings', 'extracted_document_fields',
    'bioimpedance_records', 'medical_exams', 'medical_exam_results',
    'medical_prescriptions', 'medical_prescription_items', 'smart_routines',
    'routine_plans', 'routine_schedules', 'routine_pauses',
    'routine_occurrences', 'routine_adherence_events',
    'prescription_versions', 'prescription_reviews',
    'treatment_proposals', 'prescription_routine_links', 'onboarding_states'
  ] LOOP
    EXECUTE format(
      'ALTER TABLE public.%I ADD COLUMN IF NOT EXISTS server_revision bigint NOT NULL DEFAULT 1 CHECK (server_revision > 0)',
      table_name
    );
  END LOOP;
END $$;

CREATE OR REPLACE FUNCTION public.bump_sync_server_revision()
RETURNS trigger
LANGUAGE plpgsql
SET search_path = ''
AS $$
BEGIN
  NEW.server_revision := OLD.server_revision + 1;
  NEW.updated_at := clock_timestamp();
  RETURN NEW;
END;
$$;

-- Remove device-clock LWW triggers. The new trigger owns the remote ordering.
DROP TRIGGER IF EXISTS vitamins_latest_updated_at_wins ON public.vitamins;
DROP TRIGGER IF EXISTS vitamin_logs_latest_updated_at_wins ON public.vitamin_logs;
DROP TRIGGER IF EXISTS medications_latest_updated_at_wins ON public.medications;
DROP TRIGGER IF EXISTS medication_logs_latest_updated_at_wins ON public.medication_logs;
DROP TRIGGER IF EXISTS document_inputs_latest_updated_at_wins ON public.document_inputs;
DROP TRIGGER IF EXISTS document_processings_latest_updated_at_wins ON public.document_processings;
DROP TRIGGER IF EXISTS extracted_document_fields_latest_updated_at_wins ON public.extracted_document_fields;
DROP TRIGGER IF EXISTS bioimpedance_records_latest_updated_at_wins ON public.bioimpedance_records;
DROP TRIGGER IF EXISTS medical_exams_latest_updated_at_wins ON public.medical_exams;
DROP TRIGGER IF EXISTS medical_exam_results_latest_updated_at_wins ON public.medical_exam_results;
DROP TRIGGER IF EXISTS medical_prescriptions_latest_updated_at_wins ON public.medical_prescriptions;
DROP TRIGGER IF EXISTS medical_prescription_items_latest_updated_at_wins ON public.medical_prescription_items;
DROP TRIGGER IF EXISTS smart_routines_latest_wins ON public.smart_routines;
DROP TRIGGER IF EXISTS routine_plans_latest_wins ON public.routine_plans;
DROP TRIGGER IF EXISTS routine_schedules_latest_wins ON public.routine_schedules;
DROP TRIGGER IF EXISTS routine_pauses_latest_wins ON public.routine_pauses;
DROP TRIGGER IF EXISTS routine_occurrences_latest_wins ON public.routine_occurrences;

DO $$
DECLARE table_name text;
BEGIN
  FOREACH table_name IN ARRAY ARRAY[
    'appointments', 'exams', 'meals', 'medical_reports', 'medications',
    'notification_reminders', 'profiles', 'report_attachments', 'settings',
    'vitamins', 'water_records', 'weight_records', 'vitamin_logs',
    'medication_logs', 'privacy_consents', 'document_inputs',
    'document_processings', 'extracted_document_fields',
    'bioimpedance_records', 'medical_exams', 'medical_exam_results',
    'medical_prescriptions', 'medical_prescription_items', 'smart_routines',
    'routine_plans', 'routine_schedules', 'routine_pauses',
    'routine_occurrences', 'treatment_proposals',
    'prescription_routine_links', 'onboarding_states'
  ] LOOP
    EXECUTE format(
      'DROP TRIGGER IF EXISTS %I ON public.%I',
      table_name || '_bump_sync_revision', table_name
    );
    EXECUTE format(
      'CREATE TRIGGER %I BEFORE UPDATE ON public.%I FOR EACH ROW EXECUTE FUNCTION public.bump_sync_server_revision()',
      table_name || '_bump_sync_revision', table_name
    );
    EXECUTE format(
      'CREATE INDEX IF NOT EXISTS %I ON public.%I (user_id, updated_at, id)',
      table_name || '_sync_page_idx', table_name
    );
  END LOOP;
END $$;

-- Immutable/append-only rows never bump. Their insert revision is always 1,
-- but the composite index still gives deterministic owner-scoped pagination.
CREATE INDEX IF NOT EXISTS prescription_versions_sync_page_idx
  ON public.prescription_versions (user_id, updated_at, id);
CREATE INDEX IF NOT EXISTS prescription_reviews_sync_page_idx
  ON public.prescription_reviews (user_id, updated_at, id);
CREATE INDEX IF NOT EXISTS routine_adherence_events_sync_page_idx
  ON public.routine_adherence_events (user_id, created_at, id);
