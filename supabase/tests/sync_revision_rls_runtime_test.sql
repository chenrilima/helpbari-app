BEGIN;
SELECT plan(1);

INSERT INTO auth.users (id, aud, role, email, created_at, updated_at)
VALUES
  ('71000000-0000-4000-8000-000000000001', 'authenticated', 'authenticated', 'revision-one@example.test', now(), now()),
  ('71000000-0000-4000-8000-000000000002', 'authenticated', 'authenticated', 'revision-two@example.test', now(), now());

INSERT INTO public.water_records
  (id, user_id, amount_ml, recorded_at, created_at, updated_at)
VALUES
  ('72000000-0000-4000-8000-000000000001', '71000000-0000-4000-8000-000000000001', 250, now(), now(), '2040-01-01 00:00:00+00'),
  ('72000000-0000-4000-8000-000000000002', '71000000-0000-4000-8000-000000000002', 300, now(), now(), now());

SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub', '71000000-0000-4000-8000-000000000001', true);

DO $$
DECLARE
  visible_count integer;
  changed_count integer;
  revision_value bigint;
  server_updated_at timestamptz;
BEGIN
  SELECT count(*) INTO visible_count FROM public.water_records;
  IF visible_count <> 1 THEN
    RAISE EXCEPTION 'RLS SELECT isolation failed: % visible rows', visible_count;
  END IF;

  UPDATE public.water_records
  SET amount_ml = 275, updated_at = '2050-01-01 00:00:00+00'
  WHERE id = '72000000-0000-4000-8000-000000000001'
    AND user_id = '71000000-0000-4000-8000-000000000001'
    AND server_revision = 1
  RETURNING server_revision, updated_at
  INTO revision_value, server_updated_at;

  IF revision_value <> 2 THEN
    RAISE EXCEPTION 'revision did not advance atomically';
  END IF;
  IF server_updated_at >= '2050-01-01 00:00:00+00' THEN
    RAISE EXCEPTION 'client updated_at was not replaced by server time';
  END IF;

  UPDATE public.water_records
  SET amount_ml = 280
  WHERE id = '72000000-0000-4000-8000-000000000001'
    AND server_revision = 1;
  GET DIAGNOSTICS changed_count = ROW_COUNT;
  IF changed_count <> 0 THEN
    RAISE EXCEPTION 'stale optimistic update unexpectedly succeeded';
  END IF;

  UPDATE public.water_records
  SET amount_ml = 999
  WHERE id = '72000000-0000-4000-8000-000000000002';
  GET DIAGNOSTICS changed_count = ROW_COUNT;
  IF changed_count <> 0 THEN
    RAISE EXCEPTION 'cross-user UPDATE unexpectedly succeeded';
  END IF;

  BEGIN
    INSERT INTO public.water_records
      (id, user_id, amount_ml, recorded_at)
    VALUES
      ('72000000-0000-4000-8000-000000000003', '71000000-0000-4000-8000-000000000002', 100, now());
    RAISE EXCEPTION 'cross-user INSERT unexpectedly succeeded';
  EXCEPTION WHEN insufficient_privilege THEN NULL;
  END;

  UPDATE public.water_records
  SET deleted_at = public.sync_server_now()
  WHERE id = '72000000-0000-4000-8000-000000000001'
    AND server_revision = 2
  RETURNING server_revision INTO revision_value;
  IF revision_value <> 3 THEN
    RAISE EXCEPTION 'tombstone did not advance revision';
  END IF;
END $$;

RESET ROLE;
SELECT pass('server revisions, tombstones and two-user RLS checks passed');
ROLLBACK;
