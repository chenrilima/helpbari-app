CREATE TABLE public.medical_prescriptions (
  id uuid NOT NULL,
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  professional_name text,
  professional_specialty text,
  professional_registration text,
  prescribed_at timestamptz NOT NULL,
  valid_until timestamptz,
  notes text,
  source_document_id uuid,
  status text NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  deleted_at timestamptz,
  PRIMARY KEY (user_id, id),
  CONSTRAINT medical_prescriptions_status_check CHECK (
    status IN ('draft', 'requiresReview', 'confirmed', 'archived', 'canceled')
  ),
  CONSTRAINT medical_prescriptions_document_fkey
    FOREIGN KEY (user_id, source_document_id)
    REFERENCES public.document_inputs(user_id, id)
);

CREATE TABLE public.medical_prescription_items (
  id uuid NOT NULL,
  prescription_id uuid NOT NULL,
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  item_type text NOT NULL,
  name text NOT NULL,
  dosage_value double precision,
  dosage_unit text,
  route text,
  frequency_type text,
  frequency_value integer,
  frequency_unit text,
  schedule_times jsonb NOT NULL DEFAULT '[]'::jsonb,
  days_of_week jsonb NOT NULL DEFAULT '[]'::jsonb,
  interval_days integer,
  start_date timestamptz,
  end_date timestamptz,
  duration_value integer,
  duration_unit text,
  instructions text,
  as_needed boolean NOT NULL DEFAULT false,
  notes text,
  confidence double precision,
  field_confidences jsonb NOT NULL DEFAULT '{}'::jsonb,
  provenance jsonb NOT NULL DEFAULT '{}'::jsonb,
  review_status text NOT NULL,
  linked_medication_id uuid,
  linked_vitamin_id uuid,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  deleted_at timestamptz,
  PRIMARY KEY (user_id, id),
  CONSTRAINT medical_prescription_items_parent_fkey
    FOREIGN KEY (user_id, prescription_id)
    REFERENCES public.medical_prescriptions(user_id, id),
  CONSTRAINT medical_prescription_items_type_check CHECK (
    item_type IN ('medication', 'vitamin', 'supplement', 'other')
  ),
  CONSTRAINT medical_prescription_items_review_check CHECK (
    review_status IN ('pending', 'reviewed', 'confirmed')
  ),
  CONSTRAINT medical_prescription_items_confidence_check CHECK (
    confidence IS NULL OR confidence BETWEEN 0 AND 1
  )
);

CREATE INDEX medical_prescriptions_user_date_idx
  ON public.medical_prescriptions (user_id, prescribed_at DESC)
  WHERE deleted_at IS NULL;
CREATE INDEX medical_prescriptions_user_status_idx
  ON public.medical_prescriptions (user_id, status)
  WHERE deleted_at IS NULL;
CREATE INDEX medical_prescriptions_user_document_idx
  ON public.medical_prescriptions (user_id, source_document_id)
  WHERE source_document_id IS NOT NULL;
CREATE INDEX medical_prescriptions_user_updated_idx
  ON public.medical_prescriptions (user_id, updated_at);
CREATE INDEX medical_prescription_items_parent_idx
  ON public.medical_prescription_items (user_id, prescription_id)
  WHERE deleted_at IS NULL;
CREATE INDEX medical_prescription_items_type_idx
  ON public.medical_prescription_items (user_id, item_type)
  WHERE deleted_at IS NULL;
CREATE INDEX medical_prescription_items_linked_medication_idx
  ON public.medical_prescription_items (user_id, linked_medication_id)
  WHERE linked_medication_id IS NOT NULL;
CREATE INDEX medical_prescription_items_linked_vitamin_idx
  ON public.medical_prescription_items (user_id, linked_vitamin_id)
  WHERE linked_vitamin_id IS NOT NULL;
CREATE INDEX medical_prescription_items_user_updated_idx
  ON public.medical_prescription_items (user_id, updated_at);

ALTER TABLE public.medical_prescriptions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.medical_prescription_items ENABLE ROW LEVEL SECURITY;

CREATE POLICY "medical_prescriptions select own"
  ON public.medical_prescriptions FOR SELECT USING (user_id = auth.uid());
CREATE POLICY "medical_prescriptions insert own"
  ON public.medical_prescriptions FOR INSERT WITH CHECK (user_id = auth.uid());
CREATE POLICY "medical_prescriptions update own"
  ON public.medical_prescriptions FOR UPDATE USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());
CREATE POLICY "medical_prescription_items select own"
  ON public.medical_prescription_items FOR SELECT USING (user_id = auth.uid());
CREATE POLICY "medical_prescription_items insert own"
  ON public.medical_prescription_items FOR INSERT WITH CHECK (
    user_id = auth.uid() AND EXISTS (
      SELECT 1 FROM public.medical_prescriptions prescription
      WHERE prescription.user_id = auth.uid()
        AND prescription.id = prescription_id
    )
  );
CREATE POLICY "medical_prescription_items update own"
  ON public.medical_prescription_items FOR UPDATE USING (user_id = auth.uid())
  WITH CHECK (
    user_id = auth.uid() AND EXISTS (
      SELECT 1 FROM public.medical_prescriptions prescription
      WHERE prescription.user_id = auth.uid()
        AND prescription.id = prescription_id
    )
  );

GRANT SELECT, INSERT, UPDATE ON public.medical_prescriptions TO authenticated;
GRANT SELECT, INSERT, UPDATE ON public.medical_prescription_items TO authenticated;
GRANT ALL ON public.medical_prescriptions TO service_role;
GRANT ALL ON public.medical_prescription_items TO service_role;

CREATE TRIGGER medical_prescriptions_latest_updated_at_wins
  BEFORE UPDATE ON public.medical_prescriptions
  FOR EACH ROW EXECUTE FUNCTION public.medical_exams_latest_updated_at_wins();
CREATE TRIGGER medical_prescription_items_latest_updated_at_wins
  BEFORE UPDATE ON public.medical_prescription_items
  FOR EACH ROW EXECUTE FUNCTION public.medical_exams_latest_updated_at_wins();
