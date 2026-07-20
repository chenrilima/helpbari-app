-- Completes the centralized LGPD deletion flow for every user-owned table
-- introduced after 20260716000000_privacy_and_data.sql.
-- Storage objects remain the responsibility of the authenticated Storage API
-- flow in the client; deleting storage.objects directly would not guarantee
-- removal of the underlying object.

CREATE OR REPLACE FUNCTION public.delete_my_data()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
    current_user_id uuid := auth.uid();
BEGIN
    IF current_user_id IS NULL THEN
        RAISE EXCEPTION 'authentication required';
    END IF;

    -- Children without a cascading parent relationship.
    DELETE FROM public.medical_prescription_items
    WHERE user_id = current_user_id;
    DELETE FROM public.medical_exam_results
    WHERE user_id = current_user_id;

    -- Clinical parents that reference document_inputs without ON DELETE CASCADE.
    DELETE FROM public.medical_prescriptions
    WHERE user_id = current_user_id;
    DELETE FROM public.medical_exams
    WHERE user_id = current_user_id;
    DELETE FROM public.bioimpedance_records
    WHERE user_id = current_user_id;

    -- Document Intelligence children and parents.
    DELETE FROM public.extracted_document_fields
    WHERE user_id = current_user_id;
    DELETE FROM public.document_processings
    WHERE user_id = current_user_id;
    DELETE FROM public.document_inputs
    WHERE user_id = current_user_id;

    -- Existing clinical and operational data.
    DELETE FROM public.report_attachments
    WHERE user_id = current_user_id;
    DELETE FROM public.medical_reports
    WHERE user_id = current_user_id;
    DELETE FROM public.medication_logs
    WHERE user_id = current_user_id;
    DELETE FROM public.vitamin_logs
    WHERE user_id = current_user_id;
    DELETE FROM public.notification_reminders
    WHERE user_id = current_user_id;
    DELETE FROM public.appointments
    WHERE user_id = current_user_id;
    DELETE FROM public.exams
    WHERE user_id = current_user_id;
    DELETE FROM public.meals
    WHERE user_id = current_user_id;
    DELETE FROM public.medications
    WHERE user_id = current_user_id;
    DELETE FROM public.vitamins
    WHERE user_id = current_user_id;
    DELETE FROM public.water_records
    WHERE user_id = current_user_id;
    DELETE FROM public.weight_records
    WHERE user_id = current_user_id;
    DELETE FROM public.settings
    WHERE user_id = current_user_id;
    DELETE FROM public.profiles
    WHERE user_id = current_user_id;

    -- Legal records are removed last so a failed earlier statement rolls back
    -- the transaction without losing the deletion request/consent trail.
    DELETE FROM public.privacy_consents
    WHERE user_id = current_user_id;
    DELETE FROM public.privacy_deletion_requests
    WHERE user_id = current_user_id;
END;
$$;

CREATE OR REPLACE FUNCTION public.delete_my_account()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
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

REVOKE ALL ON FUNCTION public.delete_my_data() FROM PUBLIC;
REVOKE ALL ON FUNCTION public.delete_my_account() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.delete_my_data() TO authenticated;
GRANT EXECUTE ON FUNCTION public.delete_my_account() TO authenticated;
