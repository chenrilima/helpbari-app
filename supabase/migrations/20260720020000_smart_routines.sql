-- Smart Routines V1. This migration is intentionally not applied remotely here.

CREATE TABLE public.smart_routines (
  id uuid NOT NULL, user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  category text NOT NULL CHECK (category IN ('medication','vitamin','supplement','other')),
  display_name text NOT NULL CHECK (length(trim(display_name)) > 0),
  status text NOT NULL CHECK (status IN ('active','paused','completed','canceled','archived')),
  source text NOT NULL CHECK (source IN ('manual','prescription','legacyMedication','legacyVitamin','imported','unknown')),
  prescription_id uuid, prescription_item_id uuid,
  personal_notes text, icon_key text, created_at timestamptz NOT NULL,
  updated_at timestamptz NOT NULL, deleted_at timestamptz,
  PRIMARY KEY (user_id,id),
  FOREIGN KEY (user_id,prescription_id) REFERENCES public.medical_prescriptions(user_id,id),
  FOREIGN KEY (user_id,prescription_item_id) REFERENCES public.medical_prescription_items(user_id,id)
);

CREATE TABLE public.routine_plans (
  id uuid NOT NULL, user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  routine_id uuid NOT NULL, revision integer NOT NULL CHECK (revision > 0),
  mode text NOT NULL CHECK (mode IN ('scheduled','asNeeded')),
  duration_type text NOT NULL CHECK (duration_type IN ('fixed','continuous','unknown')),
  effective_from date NOT NULL, effective_until date,
  dose_value text, dose_unit text, dose_original_text text, route text,
  clinical_instructions text, activated_at timestamptz, replaced_at timestamptz,
  previous_plan_id uuid, created_at timestamptz NOT NULL,
  updated_at timestamptz NOT NULL, deleted_at timestamptz,
  PRIMARY KEY (user_id,id), UNIQUE (user_id,routine_id,revision),
  FOREIGN KEY (user_id,routine_id) REFERENCES public.smart_routines(user_id,id),
  FOREIGN KEY (user_id,previous_plan_id) REFERENCES public.routine_plans(user_id,id),
  CHECK (effective_until IS NULL OR effective_until >= effective_from)
);

CREATE TABLE public.routine_schedules (
  id uuid NOT NULL, user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  routine_id uuid NOT NULL, plan_id uuid NOT NULL, rule jsonb NOT NULL,
  time_zone text NOT NULL CHECK (length(trim(time_zone)) > 0),
  reminder_preference text NOT NULL CHECK (reminder_preference IN ('disabled','enabled')),
  early_tolerance_seconds integer NOT NULL CHECK (early_tolerance_seconds >= 0),
  on_time_tolerance_seconds integer NOT NULL CHECK (on_time_tolerance_seconds >= 0),
  late_tolerance_seconds integer NOT NULL CHECK (late_tolerance_seconds >= 0),
  is_enabled boolean NOT NULL, display_order integer NOT NULL CHECK (display_order >= 0),
  created_at timestamptz NOT NULL, updated_at timestamptz NOT NULL, deleted_at timestamptz,
  PRIMARY KEY (user_id,id),
  FOREIGN KEY (user_id,routine_id) REFERENCES public.smart_routines(user_id,id),
  FOREIGN KEY (user_id,plan_id) REFERENCES public.routine_plans(user_id,id),
  CHECK ((rule->>'schemaVersion')::integer = 1),
  CHECK (rule->>'type' IN ('dailyAtTimes','specificWeekdaysAtTimes','everyNHours','everyNDays','weekly','monthly','singleDose','freeForm','asNeeded')),
  CHECK (rule->>'type' <> 'everyNHours' OR (rule ? 'anchorAtUtc' AND (rule->>'intervalHours')::integer > 0)),
  CHECK (rule->>'type' <> 'everyNDays' OR (rule ? 'anchorDate' AND (rule->>'intervalDays')::integer > 0))
);

CREATE TABLE public.routine_pauses (
  id uuid NOT NULL, user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  routine_id uuid NOT NULL, plan_id uuid, scope text NOT NULL CHECK (scope IN ('routine','plan')),
  starts_at timestamptz NOT NULL, ends_at timestamptz, reason text,
  created_at timestamptz NOT NULL, updated_at timestamptz NOT NULL, deleted_at timestamptz,
  PRIMARY KEY (user_id,id),
  FOREIGN KEY (user_id,routine_id) REFERENCES public.smart_routines(user_id,id),
  FOREIGN KEY (user_id,plan_id) REFERENCES public.routine_plans(user_id,id),
  CHECK (ends_at IS NULL OR ends_at > starts_at),
  CHECK ((scope = 'routine' AND plan_id IS NULL) OR (scope = 'plan' AND plan_id IS NOT NULL))
);

CREATE TABLE public.routine_occurrences (
  id uuid NOT NULL, user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  routine_id uuid NOT NULL, plan_id uuid NOT NULL, schedule_id uuid,
  origin text NOT NULL CHECK (origin IN ('generated','adHocAsNeeded','migrated')),
  status text NOT NULL CHECK (status IN ('expected','rescheduled','canceled','paused','notApplicable')),
  original_clinical_date date NOT NULL, original_local_hour integer NOT NULL CHECK (original_local_hour BETWEEN 0 AND 23),
  original_local_minute integer NOT NULL CHECK (original_local_minute BETWEEN 0 AND 59),
  original_time_zone text NOT NULL,
  expectation_kind text NOT NULL CHECK (expectation_kind IN ('recurringExpectation','singleExpectation','asNeeded','unstructured','unsupported','none')),
  sequence integer NOT NULL CHECK (sequence >= 0), original_scheduled_for timestamptz NOT NULL,
  original_window_starts_at timestamptz NOT NULL, original_on_time_ends_at timestamptz NOT NULL,
  original_window_ends_at timestamptz NOT NULL, scheduled_for timestamptz NOT NULL,
  window_starts_at timestamptz NOT NULL, on_time_ends_at timestamptz NOT NULL,
  window_ends_at timestamptz NOT NULL, created_at timestamptz NOT NULL,
  updated_at timestamptz NOT NULL, deleted_at timestamptz,
  PRIMARY KEY (user_id,id),
  FOREIGN KEY (user_id,routine_id) REFERENCES public.smart_routines(user_id,id),
  FOREIGN KEY (user_id,plan_id) REFERENCES public.routine_plans(user_id,id),
  FOREIGN KEY (user_id,schedule_id) REFERENCES public.routine_schedules(user_id,id),
  CHECK (original_window_starts_at <= original_scheduled_for AND original_scheduled_for <= original_on_time_ends_at AND original_on_time_ends_at <= original_window_ends_at),
  CHECK (window_starts_at <= scheduled_for AND scheduled_for <= on_time_ends_at AND on_time_ends_at <= window_ends_at)
);

CREATE TABLE public.routine_adherence_events (
  id uuid NOT NULL, user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  occurrence_id uuid NOT NULL, routine_id uuid NOT NULL, plan_id uuid NOT NULL, schedule_id uuid,
  type text NOT NULL CHECK (type IN ('taken','skipped','rescheduled','canceled','correction')),
  actor text NOT NULL CHECK (actor IN ('user','caregiver','system','imported')),
  occurred_at_utc timestamptz NOT NULL, recorded_at_utc timestamptz NOT NULL,
  referenced_event_id uuid, correction_action text, replacement_type text,
  replacement_occurred_at_utc timestamptz, rescheduled_for_utc timestamptz,
  rescheduled_window_starts_at_utc timestamptz, rescheduled_on_time_ends_at_utc timestamptz,
  rescheduled_window_ends_at_utc timestamptz, note text, actual_dose_value text,
  actual_dose_unit text, actual_dose_original_text text, created_at timestamptz NOT NULL,
  PRIMARY KEY (user_id,id),
  FOREIGN KEY (user_id,occurrence_id) REFERENCES public.routine_occurrences(user_id,id),
  FOREIGN KEY (user_id,routine_id) REFERENCES public.smart_routines(user_id,id),
  FOREIGN KEY (user_id,plan_id) REFERENCES public.routine_plans(user_id,id),
  FOREIGN KEY (user_id,schedule_id) REFERENCES public.routine_schedules(user_id,id),
  FOREIGN KEY (user_id,referenced_event_id) REFERENCES public.routine_adherence_events(user_id,id),
  CHECK ((type = 'correction') = (referenced_event_id IS NOT NULL AND correction_action IS NOT NULL)),
  CHECK (correction_action IS NULL OR correction_action IN ('invalidate','replace')),
  CHECK (replacement_type IS NULL OR replacement_type IN ('taken','skipped','rescheduled','canceled')),
  CHECK ((rescheduled_for_utc IS NULL AND rescheduled_window_starts_at_utc IS NULL AND rescheduled_on_time_ends_at_utc IS NULL AND rescheduled_window_ends_at_utc IS NULL) OR
    (rescheduled_window_starts_at_utc <= rescheduled_for_utc AND rescheduled_for_utc <= rescheduled_on_time_ends_at_utc AND rescheduled_on_time_ends_at_utc <= rescheduled_window_ends_at_utc))
);

CREATE INDEX smart_routines_sync_idx ON public.smart_routines(user_id,updated_at,id);
CREATE INDEX routine_plans_parent_idx ON public.routine_plans(user_id,routine_id,revision);
CREATE INDEX routine_plans_sync_idx ON public.routine_plans(user_id,updated_at,id);
CREATE INDEX routine_schedules_parent_idx ON public.routine_schedules(user_id,plan_id,display_order);
CREATE INDEX routine_schedules_sync_idx ON public.routine_schedules(user_id,updated_at,id);
CREATE INDEX routine_pauses_parent_idx ON public.routine_pauses(user_id,routine_id,starts_at);
CREATE INDEX routine_pauses_sync_idx ON public.routine_pauses(user_id,updated_at,id);
CREATE INDEX routine_occurrences_interval_idx ON public.routine_occurrences(user_id,original_scheduled_for,id);
CREATE INDEX routine_occurrences_sync_idx ON public.routine_occurrences(user_id,updated_at,id);
CREATE INDEX routine_adherence_events_occurrence_idx ON public.routine_adherence_events(user_id,occurrence_id,recorded_at_utc,id);
CREATE INDEX routine_adherence_events_cursor_idx ON public.routine_adherence_events(user_id,created_at,id);

CREATE FUNCTION public.smart_routine_reject_clinical_mutation() RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN RAISE EXCEPTION 'append-only clinical record'; END; $$;
CREATE FUNCTION public.smart_routine_preserve_occurrence_identity() RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
  IF ROW(NEW.routine_id,NEW.plan_id,NEW.schedule_id,NEW.origin,NEW.original_clinical_date,NEW.original_local_hour,NEW.original_local_minute,NEW.original_time_zone,NEW.expectation_kind,NEW.sequence,NEW.original_scheduled_for,NEW.original_window_starts_at,NEW.original_on_time_ends_at,NEW.original_window_ends_at)
    IS DISTINCT FROM ROW(OLD.routine_id,OLD.plan_id,OLD.schedule_id,OLD.origin,OLD.original_clinical_date,OLD.original_local_hour,OLD.original_local_minute,OLD.original_time_zone,OLD.expectation_kind,OLD.sequence,OLD.original_scheduled_for,OLD.original_window_starts_at,OLD.original_on_time_ends_at,OLD.original_window_ends_at)
  THEN RAISE EXCEPTION 'immutable occurrence identity'; END IF;
  RETURN NEW;
END; $$;
CREATE TRIGGER routine_occurrences_preserve_identity BEFORE UPDATE ON public.routine_occurrences FOR EACH ROW EXECUTE FUNCTION public.smart_routine_preserve_occurrence_identity();
CREATE TRIGGER routine_adherence_events_no_update BEFORE UPDATE ON public.routine_adherence_events FOR EACH ROW EXECUTE FUNCTION public.smart_routine_reject_clinical_mutation();
CREATE TRIGGER routine_adherence_events_no_delete BEFORE DELETE ON public.routine_adherence_events FOR EACH ROW EXECUTE FUNCTION public.smart_routine_reject_clinical_mutation();

DO $$ DECLARE table_name text; BEGIN
  FOREACH table_name IN ARRAY ARRAY['smart_routines','routine_plans','routine_schedules','routine_pauses','routine_occurrences','routine_adherence_events'] LOOP
    EXECUTE format('ALTER TABLE public.%I ENABLE ROW LEVEL SECURITY',table_name);
    EXECUTE format('CREATE POLICY %I ON public.%I FOR SELECT USING (user_id = auth.uid())',table_name || '_select_own',table_name);
    EXECUTE format('CREATE POLICY %I ON public.%I FOR INSERT WITH CHECK (user_id = auth.uid())',table_name || '_insert_own',table_name);
  END LOOP;
  FOREACH table_name IN ARRAY ARRAY['smart_routines','routine_plans','routine_schedules','routine_pauses','routine_occurrences'] LOOP
    EXECUTE format('CREATE POLICY %I ON public.%I FOR UPDATE USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid())',table_name || '_update_own',table_name);
  END LOOP;
END $$;

GRANT SELECT,INSERT,UPDATE ON public.smart_routines,public.routine_plans,public.routine_schedules,public.routine_pauses,public.routine_occurrences TO authenticated;
GRANT SELECT,INSERT ON public.routine_adherence_events TO authenticated;
GRANT ALL ON public.smart_routines,public.routine_plans,public.routine_schedules,public.routine_pauses,public.routine_occurrences,public.routine_adherence_events TO service_role;

CREATE TRIGGER smart_routines_latest_wins BEFORE UPDATE ON public.smart_routines FOR EACH ROW EXECUTE FUNCTION public.medical_exams_latest_updated_at_wins();
CREATE TRIGGER routine_plans_latest_wins BEFORE UPDATE ON public.routine_plans FOR EACH ROW EXECUTE FUNCTION public.medical_exams_latest_updated_at_wins();
CREATE TRIGGER routine_schedules_latest_wins BEFORE UPDATE ON public.routine_schedules FOR EACH ROW EXECUTE FUNCTION public.medical_exams_latest_updated_at_wins();
CREATE TRIGGER routine_pauses_latest_wins BEFORE UPDATE ON public.routine_pauses FOR EACH ROW EXECUTE FUNCTION public.medical_exams_latest_updated_at_wins();
CREATE TRIGGER routine_occurrences_latest_wins BEFORE UPDATE ON public.routine_occurrences FOR EACH ROW EXECUTE FUNCTION public.medical_exams_latest_updated_at_wins();
