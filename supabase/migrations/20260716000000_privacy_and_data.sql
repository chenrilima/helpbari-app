CREATE TABLE public.privacy_consents (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    terms_version text NOT NULL,
    privacy_version text NOT NULL,
    accepted_at timestamptz NOT NULL,
    device_id text NOT NULL,
    timezone text NOT NULL,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    deleted_at timestamptz,
    sync_status public.sync_status NOT NULL DEFAULT 'synced',
    UNIQUE (user_id, terms_version, privacy_version)
);

CREATE INDEX privacy_consents_user_accepted_idx
ON public.privacy_consents (user_id, accepted_at DESC)
WHERE deleted_at IS NULL;

CREATE INDEX privacy_consents_user_updated_idx
ON public.privacy_consents (user_id, updated_at);

CREATE TRIGGER privacy_consents_set_updated_at
BEFORE UPDATE ON public.privacy_consents
FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

ALTER TABLE public.privacy_consents ENABLE ROW LEVEL SECURITY;
CREATE POLICY "privacy_consents select own" ON public.privacy_consents
FOR SELECT TO authenticated USING (user_id = auth.uid());
CREATE POLICY "privacy_consents insert own" ON public.privacy_consents
FOR INSERT TO authenticated WITH CHECK (user_id = auth.uid());
CREATE POLICY "privacy_consents update own" ON public.privacy_consents
FOR UPDATE TO authenticated USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

CREATE TABLE public.privacy_deletion_requests (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    status text NOT NULL DEFAULT 'requested'
        CHECK (status IN ('requested', 'processing', 'completed', 'rejected')),
    requested_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE UNIQUE INDEX privacy_deletion_requests_open_user_idx
ON public.privacy_deletion_requests (user_id)
WHERE status IN ('requested', 'processing');

CREATE TRIGGER privacy_deletion_requests_set_updated_at
BEFORE UPDATE ON public.privacy_deletion_requests
FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

ALTER TABLE public.privacy_deletion_requests ENABLE ROW LEVEL SECURITY;
CREATE POLICY "privacy_deletion_requests select own"
ON public.privacy_deletion_requests FOR SELECT TO authenticated
USING (user_id = auth.uid());

CREATE POLICY "medical-reports delete own"
ON storage.objects FOR DELETE TO authenticated
USING (
    bucket_id = 'medical-reports'
    AND auth.uid()::text = (storage.foldername(name))[1]
);

CREATE POLICY "report-attachments delete own"
ON storage.objects FOR DELETE TO authenticated
USING (
    bucket_id = 'report-attachments'
    AND auth.uid()::text = (storage.foldername(name))[1]
);

CREATE OR REPLACE FUNCTION public.request_my_account_deletion()
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
    current_user_id uuid := auth.uid();
    request_id uuid;
BEGIN
    IF current_user_id IS NULL THEN
        RAISE EXCEPTION 'authentication required';
    END IF;

    INSERT INTO public.privacy_deletion_requests (user_id)
    VALUES (current_user_id)
    ON CONFLICT (user_id) WHERE status IN ('requested', 'processing')
    DO UPDATE SET updated_at = now()
    RETURNING id INTO request_id;

    RETURN request_id;
END;
$$;

CREATE OR REPLACE FUNCTION public.delete_my_data()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth, storage
AS $$
DECLARE
    current_user_id uuid := auth.uid();
BEGIN
    IF current_user_id IS NULL THEN
        RAISE EXCEPTION 'authentication required';
    END IF;

    DELETE FROM public.report_attachments WHERE user_id = current_user_id;
    DELETE FROM public.medical_reports WHERE user_id = current_user_id;
    DELETE FROM public.medication_logs WHERE user_id = current_user_id;
    DELETE FROM public.vitamin_logs WHERE user_id = current_user_id;
    DELETE FROM public.notification_reminders WHERE user_id = current_user_id;
    DELETE FROM public.appointments WHERE user_id = current_user_id;
    DELETE FROM public.exams WHERE user_id = current_user_id;
    DELETE FROM public.meals WHERE user_id = current_user_id;
    DELETE FROM public.medications WHERE user_id = current_user_id;
    DELETE FROM public.vitamins WHERE user_id = current_user_id;
    DELETE FROM public.water_records WHERE user_id = current_user_id;
    DELETE FROM public.weight_records WHERE user_id = current_user_id;
    DELETE FROM public.settings WHERE user_id = current_user_id;
    DELETE FROM public.profiles WHERE user_id = current_user_id;
    DELETE FROM public.privacy_consents WHERE user_id = current_user_id;
    DELETE FROM public.privacy_deletion_requests WHERE user_id = current_user_id;
END;
$$;

CREATE OR REPLACE FUNCTION public.delete_my_account()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth, storage
AS $$
DECLARE
    current_user_id uuid := auth.uid();
BEGIN
    IF current_user_id IS NULL THEN
        RAISE EXCEPTION 'authentication required';
    END IF;

    PERFORM public.delete_my_data();
    DELETE FROM auth.users WHERE id = current_user_id;
END;
$$;

REVOKE ALL ON FUNCTION public.request_my_account_deletion() FROM PUBLIC;
REVOKE ALL ON FUNCTION public.delete_my_data() FROM PUBLIC;
REVOKE ALL ON FUNCTION public.delete_my_account() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.request_my_account_deletion() TO authenticated;
GRANT EXECUTE ON FUNCTION public.delete_my_data() TO authenticated;
GRANT EXECUTE ON FUNCTION public.delete_my_account() TO authenticated;
