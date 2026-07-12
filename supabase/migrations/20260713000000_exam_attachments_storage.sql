ALTER TABLE "public"."exams"
    ADD CONSTRAINT "exams_attachment_path_owner_check"
    CHECK (
        "attachment_path" IS NULL
        OR "attachment_path" LIKE ("user_id")::text || '/' || ("id")::text || '/%'
    );

UPDATE "storage"."buckets"
SET
    "public" = false,
    "file_size_limit" = 12582912,
    "allowed_mime_types" = ARRAY[
        'image/jpeg', 'image/png', 'image/webp', 'application/pdf'
    ]::text[]
WHERE "id" = 'exam-attachments';

DROP POLICY IF EXISTS "exam-attachments delete own" ON "storage"."objects";

CREATE POLICY "exam-attachments delete own"
ON "storage"."objects" FOR DELETE TO authenticated
USING (
    "bucket_id" = 'exam-attachments'
    AND ("auth"."uid"())::text = ("storage"."foldername"("name"))[1]
);
