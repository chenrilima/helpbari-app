BEGIN;

INSERT INTO auth.users (id, aud, role, email, created_at, updated_at)
VALUES
  ('81000000-0000-4000-8000-000000000001', 'authenticated', 'authenticated', 'release-a@example.test', now(), now()),
  ('81000000-0000-4000-8000-000000000002', 'authenticated', 'authenticated', 'release-b@example.test', now(), now());

INSERT INTO public.water_records
  (id, user_id, amount_ml, recorded_at, updated_at)
VALUES
  ('82000000-0000-4000-8000-000000000001', '81000000-0000-4000-8000-000000000001', 250, now(), '2040-01-01 00:00:00+00'),
  ('82000000-0000-4000-8000-000000000002', '81000000-0000-4000-8000-000000000002', 300, now(), now());
INSERT INTO public.weight_records
  (id, user_id, weight_kg, recorded_at, updated_at)
VALUES
  ('82000000-0000-4000-8000-000000000011', '81000000-0000-4000-8000-000000000001', 90, now(), '2040-01-01 00:00:00+00');
INSERT INTO public.meals
  (id, user_id, name, type, meal_date, updated_at)
VALUES
  ('82000000-0000-4000-8000-000000000021', '81000000-0000-4000-8000-000000000001', 'Test meal', 'lunch', now(), '2040-01-01 00:00:00+00');
INSERT INTO public.appointments
  (id, user_id, title, appointment_at, updated_at)
VALUES
  ('82000000-0000-4000-8000-000000000031', '81000000-0000-4000-8000-000000000001', 'Test appointment', now(), '2040-01-01 00:00:00+00');
INSERT INTO public.exams
  (id, user_id, name, exam_date, updated_at)
VALUES
  ('82000000-0000-4000-8000-000000000041', '81000000-0000-4000-8000-000000000001', 'Test exam', now(), '2040-01-01 00:00:00+00');
INSERT INTO public.bioimpedance_records
  (id, user_id, measured_at, updated_at)
VALUES
  ('82000000-0000-4000-8000-000000000051', '81000000-0000-4000-8000-000000000001', now(), '2040-01-01 00:00:00+00');

INSERT INTO public.settings (id, user_id)
VALUES
  ('83000000-0000-4000-8000-000000000001', '81000000-0000-4000-8000-000000000001'),
  ('83000000-0000-4000-8000-000000000002', '81000000-0000-4000-8000-000000000002');
INSERT INTO public.onboarding_states
  (id, user_id, onboarding_version, status)
VALUES
  ('84000000-0000-4000-8000-000000000001', '81000000-0000-4000-8000-000000000001', 1, 'notStarted'),
  ('84000000-0000-4000-8000-000000000002', '81000000-0000-4000-8000-000000000002', 1, 'notStarted');
INSERT INTO public.smart_routines
  (id, user_id, category, display_name, status, source, created_at, updated_at)
VALUES
  ('85000000-0000-4000-8000-000000000001', '81000000-0000-4000-8000-000000000001', 'other', 'Routine A', 'active', 'manual', now(), now()),
  ('85000000-0000-4000-8000-000000000002', '81000000-0000-4000-8000-000000000002', 'other', 'Routine B', 'active', 'manual', now(), now());
INSERT INTO public.medical_prescriptions
  (id, user_id, prescribed_at, status)
VALUES
  ('86000000-0000-4000-8000-000000000001', '81000000-0000-4000-8000-000000000001', now(), 'draft'),
  ('86000000-0000-4000-8000-000000000002', '81000000-0000-4000-8000-000000000002', now(), 'draft');

INSERT INTO storage.objects (id, bucket_id, name, owner, owner_id)
VALUES
  ('87000000-0000-4000-8000-000000000001', 'clinical-documents', '81000000-0000-4000-8000-000000000001/release/a.pdf', '81000000-0000-4000-8000-000000000001', '81000000-0000-4000-8000-000000000001'),
  ('87000000-0000-4000-8000-000000000002', 'clinical-documents', '81000000-0000-4000-8000-000000000002/release/b.pdf', '81000000-0000-4000-8000-000000000002', '81000000-0000-4000-8000-000000000002');

SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub', '81000000-0000-4000-8000-000000000001', true);

DO $$
DECLARE
  visible_count integer;
  changed_count integer;
  table_name text;
  record_id uuid;
  revision_value bigint;
  server_updated_at timestamptz;
BEGIN
  SELECT count(*) INTO visible_count FROM public.water_records;
  IF visible_count <> 1 THEN
    RAISE EXCEPTION 'RLS SELECT/tombstone isolation failed for water_records';
  END IF;

  UPDATE public.water_records SET amount_ml = 999
  WHERE id = '82000000-0000-4000-8000-000000000002';
  GET DIAGNOSTICS changed_count = ROW_COUNT;
  IF changed_count <> 0 THEN
    RAISE EXCEPTION 'cross-user UPDATE unexpectedly succeeded';
  END IF;

  BEGIN
    INSERT INTO public.water_records (id, user_id, amount_ml, recorded_at)
    VALUES (
      '82000000-0000-4000-8000-000000000003',
      '81000000-0000-4000-8000-000000000002',
      100,
      now()
    );
    RAISE EXCEPTION 'cross-user INSERT unexpectedly succeeded';
  EXCEPTION WHEN insufficient_privilege THEN NULL;
  END;

  FOREACH table_name, record_id IN ARRAY ARRAY[
    ROW('water_records', '82000000-0000-4000-8000-000000000001'::uuid),
    ROW('weight_records', '82000000-0000-4000-8000-000000000011'::uuid),
    ROW('meals', '82000000-0000-4000-8000-000000000021'::uuid),
    ROW('appointments', '82000000-0000-4000-8000-000000000031'::uuid),
    ROW('exams', '82000000-0000-4000-8000-000000000041'::uuid),
    ROW('bioimpedance_records', '82000000-0000-4000-8000-000000000051'::uuid)
  ] LOOP
    EXECUTE format(
      'UPDATE public.%I SET updated_at = $1 WHERE id = $2 AND server_revision = 1 RETURNING server_revision, updated_at',
      table_name
    ) INTO revision_value, server_updated_at
      USING '2050-01-01 00:00:00+00'::timestamptz, record_id;
    IF revision_value <> 2 OR server_updated_at >= '2050-01-01 00:00:00+00' THEN
      RAISE EXCEPTION 'server revision/time authority failed for %', table_name;
    END IF;

    EXECUTE format(
      'UPDATE public.%I SET updated_at = updated_at WHERE id = $1 AND server_revision = 1',
      table_name
    ) USING record_id;
    GET DIAGNOSTICS changed_count = ROW_COUNT;
    IF changed_count <> 0 THEN
      RAISE EXCEPTION 'stale CAS unexpectedly succeeded for %', table_name;
    END IF;

    EXECUTE format(
      'UPDATE public.%I SET deleted_at = public.sync_server_now() WHERE id = $1 AND server_revision = 2 RETURNING server_revision',
      table_name
    ) INTO revision_value USING record_id;
    IF revision_value <> 3 THEN
      RAISE EXCEPTION 'tombstone revision failed for %', table_name;
    END IF;
  END LOOP;

  SELECT count(*) INTO visible_count FROM public.onboarding_states;
  IF visible_count <> 1 THEN RAISE EXCEPTION 'onboarding ownership failed'; END IF;
  SELECT count(*) INTO visible_count FROM public.settings;
  IF visible_count <> 1 THEN RAISE EXCEPTION 'notification settings ownership failed'; END IF;
  SELECT count(*) INTO visible_count FROM public.smart_routines;
  IF visible_count <> 1 THEN RAISE EXCEPTION 'Smart Routines ownership failed'; END IF;
  SELECT count(*) INTO visible_count FROM public.medical_prescriptions;
  IF visible_count <> 1 THEN RAISE EXCEPTION 'Prescription Platform ownership failed'; END IF;
  SELECT count(*) INTO visible_count FROM storage.objects
  WHERE bucket_id = 'clinical-documents';
  IF visible_count <> 1 THEN RAISE EXCEPTION 'Storage ownership failed'; END IF;

  BEGIN
    INSERT INTO storage.objects (id, bucket_id, name, owner, owner_id)
    VALUES (
      '87000000-0000-4000-8000-000000000003',
      'clinical-documents',
      '81000000-0000-4000-8000-000000000002/release/foreign.pdf',
      '81000000-0000-4000-8000-000000000002',
      '81000000-0000-4000-8000-000000000002'
    );
    RAISE EXCEPTION 'cross-user Storage INSERT unexpectedly succeeded';
  EXCEPTION WHEN insufficient_privilege THEN NULL;
  END;

  BEGIN
    PERFORM public.delete_macro2_data(
      '81000000-0000-4000-8000-000000000002'
    );
    RAISE EXCEPTION 'cross-user Macro 2 LGPD deletion unexpectedly succeeded';
  EXCEPTION WHEN raise_exception THEN
    IF SQLERRM <> 'authentication required' THEN RAISE; END IF;
  END;
END $$;

SELECT public.request_my_account_deletion();
SELECT public.delete_my_data();

RESET ROLE;

DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM public.water_records
    WHERE user_id = '81000000-0000-4000-8000-000000000001'
  ) THEN
    RAISE EXCEPTION 'delete_my_data left authenticated user data';
  END IF;
  IF NOT EXISTS (
    SELECT 1 FROM public.water_records
    WHERE user_id = '81000000-0000-4000-8000-000000000002'
  ) THEN
    RAISE EXCEPTION 'delete_my_data removed another user data';
  END IF;
END $$;

SET LOCAL ROLE anon;
SELECT set_config('request.jwt.claim.sub', '', true);

DO $$
DECLARE
  visible_count integer;
  table_name text;
BEGIN
  FOREACH table_name IN ARRAY ARRAY[
    'water_records', 'onboarding_states', 'settings', 'smart_routines',
    'medical_prescriptions'
  ] LOOP
    EXECUTE format('SELECT count(*) FROM public.%I', table_name)
      INTO visible_count;
    IF visible_count <> 0 THEN
      RAISE EXCEPTION 'anonymous access unexpectedly succeeded for %', table_name;
    END IF;
  END LOOP;

  SELECT count(*) INTO visible_count
  FROM storage.objects WHERE bucket_id = 'clinical-documents';
  IF visible_count <> 0 THEN
    RAISE EXCEPTION 'anonymous Storage access unexpectedly succeeded';
  END IF;

  BEGIN
    PERFORM public.request_my_account_deletion();
    RAISE EXCEPTION 'anonymous LGPD RPC unexpectedly succeeded';
  EXCEPTION
    WHEN insufficient_privilege THEN NULL;
    WHEN raise_exception THEN
      IF SQLERRM <> 'authentication required' THEN RAISE; END IF;
  END;
END $$;

RESET ROLE;
SELECT '1..1';
SELECT 'ok 1 - release remote validation passed';
ROLLBACK;
