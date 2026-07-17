CREATE TABLE public.bioimpedance_records (
  id uuid NOT NULL,
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  measured_at timestamptz NOT NULL,
  weight_kg double precision,
  muscle_mass_kg double precision,
  body_fat_mass_kg double precision,
  body_water_percentage double precision,
  body_fat_percentage double precision,
  skeletal_muscle_mass_kg double precision,
  lean_body_mass_kg double precision,
  fat_free_mass_kg double precision,
  visceral_fat_level double precision,
  visceral_fat_area_cm2 double precision,
  subcutaneous_fat_percentage double precision,
  protein_percentage double precision,
  mineral_mass_kg double precision,
  bone_mass_kg double precision,
  bmi double precision,
  basal_metabolic_rate_kcal double precision,
  metabolic_age integer,
  waist_hip_ratio double precision,
  waist_circumference_cm double precision,
  hip_circumference_cm double precision,
  body_cell_mass_kg double precision,
  intracellular_water_liters double precision,
  extracellular_water_liters double precision,
  total_body_water_liters double precision,
  phase_angle_degrees double precision,
  body_score double precision,
  recommended_weight_kg double precision,
  weight_control_kg double precision,
  fat_control_kg double precision,
  muscle_control_kg double precision,
  device_name text,
  clinic_name text,
  professional_name text,
  notes text,
  source_document_id uuid,
  source text NOT NULL DEFAULT 'manual',
  additional_metrics jsonb NOT NULL DEFAULT '{}'::jsonb,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  deleted_at timestamptz,
  PRIMARY KEY (user_id, id),
  CONSTRAINT bioimpedance_source_check CHECK (source IN ('manual', 'document'))
);

CREATE INDEX bioimpedance_records_user_measured_at_idx
  ON public.bioimpedance_records (user_id, measured_at DESC);
CREATE INDEX bioimpedance_records_user_updated_at_idx
  ON public.bioimpedance_records (user_id, updated_at);

ALTER TABLE public.bioimpedance_records ENABLE ROW LEVEL SECURITY;

CREATE POLICY "bioimpedance_records select own"
  ON public.bioimpedance_records
  FOR SELECT
  USING (user_id = auth.uid());

CREATE POLICY "bioimpedance_records insert own"
  ON public.bioimpedance_records
  FOR INSERT
  WITH CHECK (user_id = auth.uid());

CREATE POLICY "bioimpedance_records update own"
  ON public.bioimpedance_records
  FOR UPDATE
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

GRANT SELECT, INSERT, UPDATE ON public.bioimpedance_records TO authenticated;
GRANT ALL ON public.bioimpedance_records TO service_role;

CREATE OR REPLACE FUNCTION public.bioimpedance_latest_updated_at_wins()
RETURNS trigger LANGUAGE plpgsql SET search_path = '' AS $$
BEGIN
  IF NEW.updated_at < OLD.updated_at THEN
    RETURN OLD;
  END IF;
  RETURN NEW;
END;
$$;

CREATE TRIGGER bioimpedance_records_latest_updated_at_wins
  BEFORE UPDATE ON public.bioimpedance_records
  FOR EACH ROW
  EXECUTE FUNCTION public.bioimpedance_latest_updated_at_wins();
