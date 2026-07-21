-- Macro 2: immutable prescription versions, reviews and treatment proposals.
-- Notification manifests and action inboxes are intentionally device-local.

CREATE UNIQUE INDEX IF NOT EXISTS medical_prescription_items_owner_parent_id_uidx
  ON public.medical_prescription_items(user_id,prescription_id,id);
CREATE UNIQUE INDEX IF NOT EXISTS routine_plans_owner_routine_id_uidx
  ON public.routine_plans(user_id,routine_id,id);

CREATE TABLE IF NOT EXISTS public.prescription_versions (
  id uuid NOT NULL,
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  prescription_id uuid NOT NULL,
  revision integer NOT NULL CHECK (revision > 0),
  status text NOT NULL CHECK (status IN ('draft','requiresReview','confirmed','archived')),
  snapshot jsonb NOT NULL,
  source_processing_id uuid,
  submitted_at timestamptz,
  confirmed_at timestamptz,
  created_at timestamptz NOT NULL,
  updated_at timestamptz NOT NULL,
  deleted_at timestamptz,
  PRIMARY KEY (user_id,id),
  UNIQUE (user_id,prescription_id,revision),
  UNIQUE (user_id,id,prescription_id),
  UNIQUE (user_id,source_processing_id),
  FOREIGN KEY (user_id,prescription_id)
    REFERENCES public.medical_prescriptions(user_id,id) ON DELETE CASCADE,
  FOREIGN KEY (user_id,source_processing_id)
    REFERENCES public.document_processings(user_id,id)
);

CREATE TABLE IF NOT EXISTS public.prescription_reviews (
  id uuid NOT NULL,
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  prescription_id uuid NOT NULL,
  version_id uuid NOT NULL,
  decision text NOT NULL CHECK (decision IN ('submitted','confirmed','rejected')),
  actor text NOT NULL,
  field_decisions jsonb NOT NULL DEFAULT '{}'::jsonb,
  note text,
  created_at timestamptz NOT NULL,
  updated_at timestamptz NOT NULL,
  deleted_at timestamptz,
  PRIMARY KEY (user_id,id),
  FOREIGN KEY (user_id,version_id,prescription_id)
    REFERENCES public.prescription_versions(user_id,id,prescription_id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS public.treatment_proposals (
  id uuid NOT NULL,
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  prescription_id uuid NOT NULL,
  prescription_version_id uuid NOT NULL,
  prescription_item_id uuid NOT NULL,
  decision text NOT NULL CHECK (decision IN ('pending','createRoutine','linkExisting','createRevision','dismissed')),
  draft jsonb NOT NULL,
  target_routine_id uuid,
  resulting_plan_id uuid,
  confirmed_at timestamptz,
  created_at timestamptz NOT NULL,
  updated_at timestamptz NOT NULL,
  deleted_at timestamptz,
  PRIMARY KEY (user_id,id),
  UNIQUE (user_id,prescription_item_id,prescription_version_id),
  FOREIGN KEY (user_id,prescription_version_id,prescription_id)
    REFERENCES public.prescription_versions(user_id,id,prescription_id) ON DELETE CASCADE,
  FOREIGN KEY (user_id,prescription_id,prescription_item_id)
    REFERENCES public.medical_prescription_items(user_id,prescription_id,id),
  FOREIGN KEY (user_id,target_routine_id) REFERENCES public.smart_routines(user_id,id),
  FOREIGN KEY (user_id,target_routine_id,resulting_plan_id)
    REFERENCES public.routine_plans(user_id,routine_id,id),
  CHECK (
    (decision = 'pending' AND target_routine_id IS NULL AND resulting_plan_id IS NULL AND confirmed_at IS NULL)
    OR (decision = 'dismissed' AND resulting_plan_id IS NULL)
    OR (decision IN ('createRoutine','linkExisting','createRevision')
      AND target_routine_id IS NOT NULL AND resulting_plan_id IS NOT NULL AND confirmed_at IS NOT NULL)
  )
);

CREATE TABLE IF NOT EXISTS public.prescription_routine_links (
  id uuid NOT NULL,
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  prescription_id uuid NOT NULL,
  prescription_version_id uuid NOT NULL,
  prescription_item_id uuid NOT NULL,
  routine_id uuid NOT NULL,
  plan_id uuid NOT NULL,
  active boolean NOT NULL DEFAULT true,
  created_at timestamptz NOT NULL,
  updated_at timestamptz NOT NULL,
  deleted_at timestamptz,
  PRIMARY KEY (user_id,id),
  FOREIGN KEY (user_id,prescription_version_id,prescription_id)
    REFERENCES public.prescription_versions(user_id,id,prescription_id) ON DELETE CASCADE,
  FOREIGN KEY (user_id,prescription_id,prescription_item_id)
    REFERENCES public.medical_prescription_items(user_id,prescription_id,id),
  FOREIGN KEY (user_id,routine_id) REFERENCES public.smart_routines(user_id,id),
  FOREIGN KEY (user_id,routine_id,plan_id)
    REFERENCES public.routine_plans(user_id,routine_id,id)
);

CREATE INDEX IF NOT EXISTS prescription_versions_sync_idx
  ON public.prescription_versions(user_id,updated_at,id);
CREATE INDEX IF NOT EXISTS prescription_reviews_sync_idx
  ON public.prescription_reviews(user_id,updated_at,id);
CREATE INDEX IF NOT EXISTS treatment_proposals_sync_idx
  ON public.treatment_proposals(user_id,updated_at,id);
CREATE INDEX IF NOT EXISTS prescription_routine_links_sync_idx
  ON public.prescription_routine_links(user_id,updated_at,id);

CREATE OR REPLACE FUNCTION public.macro2_reject_immutable_mutation()
RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
  IF TG_OP = 'UPDATE' AND NEW IS NOT DISTINCT FROM OLD THEN RETURN NEW; END IF;
  IF TG_TABLE_NAME = 'prescription_versions'
    AND OLD.status = 'confirmed' AND NEW.status = 'archived'
    AND NEW.snapshot IS NOT DISTINCT FROM OLD.snapshot
    AND NEW.prescription_id = OLD.prescription_id
    AND NEW.revision = OLD.revision
    AND NEW.source_processing_id IS NOT DISTINCT FROM OLD.source_processing_id
    AND NEW.submitted_at IS NOT DISTINCT FROM OLD.submitted_at
    AND NEW.confirmed_at IS NOT DISTINCT FROM OLD.confirmed_at
    AND NEW.created_at = OLD.created_at
    AND NEW.deleted_at IS NOT DISTINCT FROM OLD.deleted_at
  THEN RETURN NEW; END IF;
  IF TG_OP = 'DELETE' AND current_setting('helpbari.lgpd_deletion', true) = 'on'
  THEN RETURN OLD; END IF;
  RAISE EXCEPTION 'immutable clinical record';
END; $$;

DROP TRIGGER IF EXISTS prescription_versions_no_update ON public.prescription_versions;
CREATE TRIGGER prescription_versions_no_update BEFORE UPDATE
  ON public.prescription_versions FOR EACH ROW
  WHEN (OLD.status IN ('confirmed','archived'))
  EXECUTE FUNCTION public.macro2_reject_immutable_mutation();
DROP TRIGGER IF EXISTS prescription_reviews_no_update ON public.prescription_reviews;
CREATE TRIGGER prescription_reviews_no_update BEFORE UPDATE
  ON public.prescription_reviews FOR EACH ROW
  EXECUTE FUNCTION public.macro2_reject_immutable_mutation();

DO $$ DECLARE table_name text; BEGIN
  FOREACH table_name IN ARRAY ARRAY[
    'prescription_versions','prescription_reviews',
    'treatment_proposals','prescription_routine_links'
  ] LOOP
    EXECUTE format('ALTER TABLE public.%I ENABLE ROW LEVEL SECURITY',table_name);
    EXECUTE format('DROP POLICY IF EXISTS %I ON public.%I',table_name || '_select_own',table_name);
    EXECUTE format('DROP POLICY IF EXISTS %I ON public.%I',table_name || '_insert_own',table_name);
    EXECUTE format('DROP POLICY IF EXISTS %I ON public.%I',table_name || '_update_own',table_name);
    EXECUTE format('CREATE POLICY %I ON public.%I FOR SELECT USING (user_id = auth.uid())',table_name || '_select_own',table_name);
    EXECUTE format('CREATE POLICY %I ON public.%I FOR INSERT WITH CHECK (user_id = auth.uid())',table_name || '_insert_own',table_name);
    EXECUTE format('CREATE POLICY %I ON public.%I FOR UPDATE USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid())',table_name || '_update_own',table_name);
  END LOOP;
END $$;

GRANT SELECT,INSERT,UPDATE ON public.prescription_versions,
  public.prescription_reviews,public.treatment_proposals,
  public.prescription_routine_links TO authenticated;
GRANT ALL ON public.prescription_versions,public.prescription_reviews,
  public.treatment_proposals,public.prescription_routine_links TO service_role;

CREATE OR REPLACE FUNCTION public.delete_macro2_data(current_user_id uuid)
RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path = '' AS $$
BEGIN
  IF current_user_id IS NULL OR current_user_id <> auth.uid()
  THEN RAISE EXCEPTION 'authentication required'; END IF;
  PERFORM set_config('helpbari.lgpd_deletion','on',true);
  DELETE FROM public.prescription_routine_links WHERE user_id=current_user_id;
  DELETE FROM public.treatment_proposals WHERE user_id=current_user_id;
  DELETE FROM public.prescription_reviews WHERE user_id=current_user_id;
  DELETE FROM public.prescription_versions WHERE user_id=current_user_id;
END; $$;

REVOKE ALL ON FUNCTION public.delete_macro2_data(uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.delete_macro2_data(uuid) TO authenticated;
