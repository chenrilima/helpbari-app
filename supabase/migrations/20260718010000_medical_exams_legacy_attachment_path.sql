ALTER TABLE public.medical_exams
  ADD COLUMN IF NOT EXISTS legacy_attachment_path text;
