CREATE TABLE public.document_inputs (
  id uuid NOT NULL,
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  source_type text NOT NULL,
  remote_path text,
  mime_type text NOT NULL,
  file_name text NOT NULL,
  file_size integer NOT NULL CHECK (file_size >= 0),
  checksum text,
  captured_at timestamptz NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  deleted_at timestamptz,
  PRIMARY KEY (user_id, id)
);

CREATE TABLE public.document_processings (
  id uuid NOT NULL,
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  document_id uuid NOT NULL,
  status text NOT NULL,
  detected_type text NOT NULL,
  raw_text text,
  engine text NOT NULL,
  engine_version text,
  general_confidence double precision NOT NULL DEFAULT 0,
  error_code text,
  error_message text,
  started_at timestamptz,
  completed_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  deleted_at timestamptz,
  PRIMARY KEY (user_id, id),
  CONSTRAINT document_processings_document_fkey FOREIGN KEY (user_id, document_id)
    REFERENCES public.document_inputs(user_id, id) ON DELETE CASCADE
);

CREATE TABLE public.extracted_document_fields (
  id text NOT NULL,
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  processing_id uuid NOT NULL,
  key text NOT NULL,
  label text NOT NULL,
  raw_value text NOT NULL,
  normalized_value text,
  confirmed_value text,
  unit text,
  confidence double precision NOT NULL DEFAULT 0,
  status text NOT NULL,
  source text NOT NULL,
  original_bounding_box text,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  deleted_at timestamptz,
  PRIMARY KEY (user_id, id),
  CONSTRAINT extracted_document_fields_processing_fkey FOREIGN KEY (user_id, processing_id)
    REFERENCES public.document_processings(user_id, id) ON DELETE CASCADE
);

CREATE INDEX document_inputs_user_updated_at_idx
  ON public.document_inputs (user_id, updated_at);
CREATE INDEX document_processings_user_updated_at_idx
  ON public.document_processings (user_id, updated_at);
CREATE INDEX extracted_document_fields_user_processing_idx
  ON public.extracted_document_fields (user_id, processing_id, updated_at);

ALTER TABLE public.document_inputs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.document_processings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.extracted_document_fields ENABLE ROW LEVEL SECURITY;

CREATE POLICY "document_inputs select own"
  ON public.document_inputs FOR SELECT USING (user_id = auth.uid());
CREATE POLICY "document_inputs insert own"
  ON public.document_inputs FOR INSERT WITH CHECK (user_id = auth.uid());
CREATE POLICY "document_inputs update own"
  ON public.document_inputs FOR UPDATE USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());

CREATE POLICY "document_processings select own"
  ON public.document_processings FOR SELECT USING (user_id = auth.uid());
CREATE POLICY "document_processings insert own"
  ON public.document_processings FOR INSERT WITH CHECK (user_id = auth.uid());
CREATE POLICY "document_processings update own"
  ON public.document_processings FOR UPDATE USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());

CREATE POLICY "extracted_document_fields select own"
  ON public.extracted_document_fields FOR SELECT USING (user_id = auth.uid());
CREATE POLICY "extracted_document_fields insert own"
  ON public.extracted_document_fields FOR INSERT WITH CHECK (user_id = auth.uid());
CREATE POLICY "extracted_document_fields update own"
  ON public.extracted_document_fields FOR UPDATE USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());

GRANT SELECT, INSERT, UPDATE ON public.document_inputs TO authenticated;
GRANT SELECT, INSERT, UPDATE ON public.document_processings TO authenticated;
GRANT SELECT, INSERT, UPDATE ON public.extracted_document_fields TO authenticated;
GRANT ALL ON public.document_inputs TO service_role;
GRANT ALL ON public.document_processings TO service_role;
GRANT ALL ON public.extracted_document_fields TO service_role;

CREATE OR REPLACE FUNCTION public.document_intelligence_latest_updated_at_wins()
RETURNS trigger LANGUAGE plpgsql SET search_path = '' AS $$
BEGIN
  IF NEW.updated_at < OLD.updated_at THEN
    RETURN OLD;
  END IF;
  RETURN NEW;
END;
$$;

CREATE TRIGGER document_inputs_latest_updated_at_wins
  BEFORE UPDATE ON public.document_inputs
  FOR EACH ROW EXECUTE FUNCTION public.document_intelligence_latest_updated_at_wins();
CREATE TRIGGER document_processings_latest_updated_at_wins
  BEFORE UPDATE ON public.document_processings
  FOR EACH ROW EXECUTE FUNCTION public.document_intelligence_latest_updated_at_wins();
CREATE TRIGGER extracted_document_fields_latest_updated_at_wins
  BEFORE UPDATE ON public.extracted_document_fields
  FOR EACH ROW EXECUTE FUNCTION public.document_intelligence_latest_updated_at_wins();

INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'clinical-documents',
  'clinical-documents',
  false,
  12582912,
  ARRAY['image/jpeg', 'image/png', 'image/webp', 'application/pdf']
)
ON CONFLICT (id) DO UPDATE
SET public = false,
    file_size_limit = 12582912,
    allowed_mime_types = ARRAY['image/jpeg', 'image/png', 'image/webp', 'application/pdf'];

CREATE POLICY "clinical documents select own"
ON storage.objects FOR SELECT TO authenticated
USING (
  bucket_id = 'clinical-documents'
  AND split_part(name, '/', 1) = auth.uid()::text
);

CREATE POLICY "clinical documents insert own"
ON storage.objects FOR INSERT TO authenticated
WITH CHECK (
  bucket_id = 'clinical-documents'
  AND split_part(name, '/', 1) = auth.uid()::text
);

CREATE POLICY "clinical documents update own"
ON storage.objects FOR UPDATE TO authenticated
USING (
  bucket_id = 'clinical-documents'
  AND split_part(name, '/', 1) = auth.uid()::text
)
WITH CHECK (
  bucket_id = 'clinical-documents'
  AND split_part(name, '/', 1) = auth.uid()::text
);

CREATE POLICY "clinical documents delete own"
ON storage.objects FOR DELETE TO authenticated
USING (
  bucket_id = 'clinical-documents'
  AND split_part(name, '/', 1) = auth.uid()::text
);
