CREATE TABLE public.medical_exams (
  id uuid NOT NULL,
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  performed_at timestamptz NOT NULL,
  collected_at timestamptz,
  received_at timestamptz,
  title text,
  category text,
  laboratory_name text,
  professional_name text,
  request_professional_name text,
  document_number text,
  notes text,
  source text NOT NULL DEFAULT 'manual',
  source_document_id uuid,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  deleted_at timestamptz,
  PRIMARY KEY (user_id, id),
  CONSTRAINT medical_exams_source_check
    CHECK (source IN ('manual', 'document', 'imported', 'professionalPortal', 'unknown')),
  CONSTRAINT medical_exams_document_fkey
    FOREIGN KEY (user_id, source_document_id)
    REFERENCES public.document_inputs(user_id, id)
);

CREATE TABLE public.medical_exam_results (
  id uuid NOT NULL,
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  medical_exam_id uuid NOT NULL,
  canonical_code text,
  canonical_name text NOT NULL,
  display_name text NOT NULL,
  normalized_name text NOT NULL,
  category text,
  value_type text NOT NULL,
  numeric_value double precision,
  text_value text,
  boolean_value boolean,
  qualitative_value text,
  unit text,
  normalized_unit text,
  reference_range_text text,
  reference_min double precision,
  reference_max double precision,
  reference_comparator text,
  reference_context text,
  status text,
  method text,
  specimen text,
  notes text,
  original_text text,
  source text NOT NULL DEFAULT 'unknown',
  confidence double precision,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  deleted_at timestamptz,
  PRIMARY KEY (user_id, id),
  CONSTRAINT medical_exam_results_exam_fkey
    FOREIGN KEY (user_id, medical_exam_id)
    REFERENCES public.medical_exams(user_id, id)
    ON DELETE CASCADE
);

CREATE INDEX medical_exams_user_performed_at_idx
  ON public.medical_exams (user_id, performed_at DESC);
CREATE INDEX medical_exams_user_updated_at_idx
  ON public.medical_exams (user_id, updated_at);
CREATE INDEX medical_exams_user_deleted_at_idx
  ON public.medical_exams (user_id, deleted_at);
CREATE INDEX medical_exams_user_source_document_id_idx
  ON public.medical_exams (user_id, source_document_id);

CREATE INDEX medical_exam_results_exam_id_idx
  ON public.medical_exam_results (user_id, medical_exam_id, sort_order);
CREATE INDEX medical_exam_results_user_canonical_code_idx
  ON public.medical_exam_results (user_id, canonical_code);
CREATE INDEX medical_exam_results_user_normalized_name_idx
  ON public.medical_exam_results (user_id, normalized_name);
CREATE INDEX medical_exam_results_user_updated_at_idx
  ON public.medical_exam_results (user_id, updated_at);
CREATE INDEX medical_exam_results_user_deleted_at_idx
  ON public.medical_exam_results (user_id, deleted_at);

ALTER TABLE public.medical_exams ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.medical_exam_results ENABLE ROW LEVEL SECURITY;

CREATE POLICY "medical_exams select own"
  ON public.medical_exams FOR SELECT USING (user_id = auth.uid());
CREATE POLICY "medical_exams insert own"
  ON public.medical_exams FOR INSERT WITH CHECK (user_id = auth.uid());
CREATE POLICY "medical_exams update own"
  ON public.medical_exams FOR UPDATE USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());

CREATE POLICY "medical_exam_results select own"
  ON public.medical_exam_results FOR SELECT USING (user_id = auth.uid());
CREATE POLICY "medical_exam_results insert own"
  ON public.medical_exam_results FOR INSERT WITH CHECK (user_id = auth.uid());
CREATE POLICY "medical_exam_results update own"
  ON public.medical_exam_results FOR UPDATE USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());

GRANT SELECT, INSERT, UPDATE ON public.medical_exams TO authenticated;
GRANT SELECT, INSERT, UPDATE ON public.medical_exam_results TO authenticated;
GRANT ALL ON public.medical_exams TO service_role;
GRANT ALL ON public.medical_exam_results TO service_role;

CREATE OR REPLACE FUNCTION public.medical_exams_latest_updated_at_wins()
RETURNS trigger LANGUAGE plpgsql SET search_path = '' AS $$
BEGIN
  IF NEW.updated_at < OLD.updated_at THEN
    RETURN OLD;
  END IF;
  RETURN NEW;
END;
$$;

CREATE TRIGGER medical_exams_latest_updated_at_wins
  BEFORE UPDATE ON public.medical_exams
  FOR EACH ROW EXECUTE FUNCTION public.medical_exams_latest_updated_at_wins();

CREATE TRIGGER medical_exam_results_latest_updated_at_wins
  BEFORE UPDATE ON public.medical_exam_results
  FOR EACH ROW EXECUTE FUNCTION public.medical_exams_latest_updated_at_wins();
