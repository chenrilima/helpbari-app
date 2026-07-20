BEGIN;

INSERT INTO auth.users (id, aud, role, email, created_at, updated_at)
VALUES
  ('10000000-0000-4000-8000-000000000001', 'authenticated', 'authenticated', 'one@example.test', now(), now()),
  ('10000000-0000-4000-8000-000000000002', 'authenticated', 'authenticated', 'two@example.test', now(), now());

INSERT INTO public.smart_routines
  (id,user_id,category,display_name,status,source,created_at,updated_at)
VALUES
  ('20000000-0000-4000-8000-000000000001','10000000-0000-4000-8000-000000000001','vitamin','One','active','manual',now(),now()),
  ('20000000-0000-4000-8000-000000000002','10000000-0000-4000-8000-000000000002','vitamin','Two','active','manual',now(),now());

SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub', '10000000-0000-4000-8000-000000000001', true);

DO $$
DECLARE visible_count integer;
BEGIN
  SELECT count(*) INTO visible_count FROM public.smart_routines;
  IF visible_count <> 1 THEN RAISE EXCEPTION 'RLS select isolation failed'; END IF;

  INSERT INTO public.smart_routines
    (id,user_id,category,display_name,status,source,created_at,updated_at)
  VALUES
    ('20000000-0000-4000-8000-000000000003','10000000-0000-4000-8000-000000000001','other','Own','active','manual',now(),now());

  BEGIN
    INSERT INTO public.smart_routines
      (id,user_id,category,display_name,status,source,created_at,updated_at)
    VALUES
      ('20000000-0000-4000-8000-000000000004','10000000-0000-4000-8000-000000000002','other','Foreign','active','manual',now(),now());
    RAISE EXCEPTION 'RLS cross-owner insert unexpectedly succeeded';
  EXCEPTION WHEN insufficient_privilege THEN NULL;
  END;
END $$;

RESET ROLE;

INSERT INTO public.routine_plans
  (id,user_id,routine_id,revision,mode,duration_type,effective_from,created_at,updated_at)
VALUES
  ('30000000-0000-4000-8000-000000000001','10000000-0000-4000-8000-000000000001','20000000-0000-4000-8000-000000000001',1,'scheduled','continuous','2026-07-20',now(),now());

DO $$
BEGIN
  BEGIN
    INSERT INTO public.routine_plans
      (id,user_id,routine_id,revision,mode,duration_type,effective_from,created_at,updated_at)
    VALUES
      ('30000000-0000-4000-8000-000000000002','10000000-0000-4000-8000-000000000001','20000000-0000-4000-8000-000000000002',1,'scheduled','continuous','2026-07-20',now(),now());
    RAISE EXCEPTION 'cross-owner FK unexpectedly succeeded';
  EXCEPTION WHEN foreign_key_violation THEN NULL;
  END;
END $$;

INSERT INTO public.routine_schedules
  (id,user_id,routine_id,plan_id,rule,time_zone,reminder_preference,early_tolerance_seconds,on_time_tolerance_seconds,late_tolerance_seconds,is_enabled,display_order,created_at,updated_at)
VALUES
  ('40000000-0000-4000-8000-000000000001','10000000-0000-4000-8000-000000000001','20000000-0000-4000-8000-000000000001','30000000-0000-4000-8000-000000000001','{"schemaVersion":1,"type":"asNeeded"}','America/Sao_Paulo','enabled',0,1800,43200,true,0,now(),now());

INSERT INTO public.routine_occurrences
  (id,user_id,routine_id,plan_id,schedule_id,origin,status,original_clinical_date,original_local_hour,original_local_minute,original_time_zone,expectation_kind,sequence,original_scheduled_for,original_window_starts_at,original_on_time_ends_at,original_window_ends_at,scheduled_for,window_starts_at,on_time_ends_at,window_ends_at,created_at,updated_at)
VALUES
  ('50000000-0000-5000-8000-000000000001','10000000-0000-4000-8000-000000000001','20000000-0000-4000-8000-000000000001','30000000-0000-4000-8000-000000000001','40000000-0000-4000-8000-000000000001','generated','expected','2026-07-20',8,0,'America/Sao_Paulo','recurringExpectation',0,'2026-07-20 11:00:00+00','2026-07-20 11:00:00+00','2026-07-20 11:30:00+00','2026-07-20 23:00:00+00','2026-07-20 11:00:00+00','2026-07-20 11:00:00+00','2026-07-20 11:30:00+00','2026-07-20 23:00:00+00',now(),now());

INSERT INTO public.routine_adherence_events
  (id,user_id,occurrence_id,routine_id,plan_id,schedule_id,type,actor,occurred_at_utc,recorded_at_utc,created_at)
VALUES
  ('60000000-0000-4000-8000-000000000001','10000000-0000-4000-8000-000000000001','50000000-0000-5000-8000-000000000001','20000000-0000-4000-8000-000000000001','30000000-0000-4000-8000-000000000001','40000000-0000-4000-8000-000000000001','taken','user','2026-07-20 11:05:00+00','2026-07-20 11:06:00+00',now());

DO $$
BEGIN
  BEGIN
    UPDATE public.routine_adherence_events SET note='mutated'
    WHERE id='60000000-0000-4000-8000-000000000001';
    RAISE EXCEPTION 'event update unexpectedly succeeded';
  EXCEPTION WHEN raise_exception THEN NULL;
  END;
  BEGIN
    DELETE FROM public.routine_adherence_events
    WHERE id='60000000-0000-4000-8000-000000000001';
    RAISE EXCEPTION 'event delete unexpectedly succeeded';
  EXCEPTION WHEN raise_exception THEN NULL;
  END;
  BEGIN
    UPDATE public.routine_occurrences
    SET original_scheduled_for='2026-07-20 12:00:00+00', updated_at=now()+interval '1 second'
    WHERE id='50000000-0000-5000-8000-000000000001';
    RAISE EXCEPTION 'occurrence identity update unexpectedly succeeded';
  EXCEPTION WHEN raise_exception THEN NULL;
  END;
END $$;

ROLLBACK;
