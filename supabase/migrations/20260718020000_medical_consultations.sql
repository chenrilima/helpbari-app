CREATE TABLE public.medical_consultations (
  id uuid NOT NULL,
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  consultation_at timestamptz NOT NULL,
  title text,
  specialty text,
  consultation_type text NOT NULL DEFAULT 'unknown',
  professional_name text,
  professional_registration text,
  clinic_name text,
  location text,
  appointment_id uuid,
  source text NOT NULL DEFAULT 'manual',
  source_document_id uuid,
  reason text,
  symptoms text,
  patient_notes text,
  professional_guidance text,
  dietary_guidance text,
  physical_activity_guidance text,
  supplement_guidance text,
  medication_guidance text,
  requested_exams_notes text,
  follow_up_notes text,
  next_appointment_at timestamptz,
  general_notes text,
  weight_kg double precision,
  height_cm double precision,
  bmi double precision,
  blood_pressure_systolic integer,
  blood_pressure_diastolic integer,
  heart_rate_bpm integer,
  waist_circumference_cm double precision,
  additional_fields_json text,
  metadata_json text,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  deleted_at timestamptz,
  PRIMARY KEY (user_id, id),
  CONSTRAINT medical_consultations_source_check
    CHECK (source IN ('manual', 'appointment', 'document', 'imported', 'professionalPortal', 'unknown')),
  CONSTRAINT medical_consultations_document_fkey
    FOREIGN KEY (user_id, source_document_id)
    REFERENCES public.document_inputs(user_id, id)
);

CREATE TABLE public.medical_consultation_exams (
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  medical_consultation_id uuid NOT NULL,
  medical_exam_id uuid NOT NULL,
  PRIMARY KEY (user_id, medical_consultation_id, medical_exam_id),
  CONSTRAINT medical_consultation_exams_consultation_fkey
    FOREIGN KEY (user_id, medical_consultation_id)
    REFERENCES public.medical_consultations(user_id, id)
    ON DELETE CASCADE,
  CONSTRAINT medical_consultation_exams_exam_fkey
    FOREIGN KEY (user_id, medical_exam_id)
    REFERENCES public.medical_exams(user_id, id)
    ON DELETE CASCADE
);

CREATE TABLE public.medical_consultation_body_compositions (
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  medical_consultation_id uuid NOT NULL,
  bioimpedance_record_id uuid NOT NULL,
  PRIMARY KEY (user_id, medical_consultation_id, bioimpedance_record_id),
  CONSTRAINT medical_consultation_body_consultation_fkey
    FOREIGN KEY (user_id, medical_consultation_id)
    REFERENCES public.medical_consultations(user_id, id)
    ON DELETE CASCADE,
  CONSTRAINT medical_consultation_body_bio_fkey
    FOREIGN KEY (user_id, bioimpedance_record_id)
    REFERENCES public.bioimpedance_records(user_id, id)
    ON DELETE CASCADE
);

CREATE INDEX medical_consultations_user_consultation_at_idx
  ON public.medical_consultations (user_id, consultation_at DESC);
CREATE INDEX medical_consultations_user_updated_at_idx
  ON public.medical_consultations (user_id, updated_at);
CREATE INDEX medical_consultations_user_deleted_at_idx
  ON public.medical_consultations (user_id, deleted_at);
CREATE INDEX medical_consultations_user_appointment_id_idx
  ON public.medical_consultations (user_id, appointment_id);
CREATE INDEX medical_consultations_user_source_document_id_idx
  ON public.medical_consultations (user_id, source_document_id);
CREATE INDEX medical_consultation_exams_lookup_idx
  ON public.medical_consultation_exams (user_id, medical_consultation_id, medical_exam_id);
CREATE INDEX medical_consultation_body_lookup_idx
  ON public.medical_consultation_body_compositions (user_id, medical_consultation_id, bioimpedance_record_id);

ALTER TABLE public.medical_consultations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.medical_consultation_exams ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.medical_consultation_body_compositions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "medical_consultations select own"
  ON public.medical_consultations FOR SELECT USING (user_id = auth.uid());
CREATE POLICY "medical_consultations insert own"
  ON public.medical_consultations FOR INSERT WITH CHECK (user_id = auth.uid());
CREATE POLICY "medical_consultations update own"
  ON public.medical_consultations FOR UPDATE USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());

CREATE POLICY "medical_consultation_exams select own"
  ON public.medical_consultation_exams FOR SELECT USING (user_id = auth.uid());
CREATE POLICY "medical_consultation_exams insert own"
  ON public.medical_consultation_exams FOR INSERT WITH CHECK (user_id = auth.uid());
CREATE POLICY "medical_consultation_exams update own"
  ON public.medical_consultation_exams FOR UPDATE USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());

CREATE POLICY "medical_consultation_body select own"
  ON public.medical_consultation_body_compositions FOR SELECT USING (user_id = auth.uid());
CREATE POLICY "medical_consultation_body insert own"
  ON public.medical_consultation_body_compositions FOR INSERT WITH CHECK (user_id = auth.uid());
CREATE POLICY "medical_consultation_body update own"
  ON public.medical_consultation_body_compositions FOR UPDATE USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());

GRANT SELECT, INSERT, UPDATE ON public.medical_consultations TO authenticated;
GRANT SELECT, INSERT, UPDATE ON public.medical_consultation_exams TO authenticated;
GRANT SELECT, INSERT, UPDATE ON public.medical_consultation_body_compositions TO authenticated;
GRANT ALL ON public.medical_consultations TO service_role;
GRANT ALL ON public.medical_consultation_exams TO service_role;
GRANT ALL ON public.medical_consultation_body_compositions TO service_role;

CREATE OR REPLACE FUNCTION public.medical_consultations_latest_updated_at_wins()
RETURNS trigger LANGUAGE plpgsql SET search_path = '' AS $$
BEGIN
  IF NEW.updated_at < OLD.updated_at THEN
    RETURN OLD;
  END IF;
  RETURN NEW;
END;
$$;

CREATE TRIGGER medical_consultations_latest_updated_at_wins
  BEFORE UPDATE ON public.medical_consultations
  FOR EACH ROW EXECUTE FUNCTION public.medical_consultations_latest_updated_at_wins();
