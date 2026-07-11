ALTER TABLE "public"."profiles"
    ADD COLUMN IF NOT EXISTS "photo_storage_path" text;

ALTER TABLE "public"."profiles"
    ADD CONSTRAINT "profiles_photo_storage_path_owner_check"
    CHECK (
        "photo_storage_path" IS NULL
        OR "photo_storage_path" LIKE ("user_id")::text || '/profile/%'
    );

UPDATE "storage"."buckets"
SET
    "public" = false,
    "file_size_limit" = 5242880,
    "allowed_mime_types" = ARRAY['image/jpeg', 'image/png', 'image/webp']::text[]
WHERE "id" = 'profile-photos';

DROP POLICY IF EXISTS "profile-photos insert own" ON "storage"."objects";
DROP POLICY IF EXISTS "profile-photos read own" ON "storage"."objects";
DROP POLICY IF EXISTS "profile-photos update own" ON "storage"."objects";
DROP POLICY IF EXISTS "profile-photos delete own" ON "storage"."objects";

CREATE POLICY "profile-photos insert own"
ON "storage"."objects" FOR INSERT TO authenticated
WITH CHECK (
    "bucket_id" = 'profile-photos'
    AND ("auth"."uid"())::text = ("storage"."foldername"("name"))[1]
    AND ("storage"."foldername"("name"))[2] = 'profile'
);

CREATE POLICY "profile-photos read own"
ON "storage"."objects" FOR SELECT TO authenticated
USING (
    "bucket_id" = 'profile-photos'
    AND ("auth"."uid"())::text = ("storage"."foldername"("name"))[1]
    AND ("storage"."foldername"("name"))[2] = 'profile'
);

CREATE POLICY "profile-photos update own"
ON "storage"."objects" FOR UPDATE TO authenticated
USING (
    "bucket_id" = 'profile-photos'
    AND ("auth"."uid"())::text = ("storage"."foldername"("name"))[1]
    AND ("storage"."foldername"("name"))[2] = 'profile'
)
WITH CHECK (
    "bucket_id" = 'profile-photos'
    AND ("auth"."uid"())::text = ("storage"."foldername"("name"))[1]
    AND ("storage"."foldername"("name"))[2] = 'profile'
);

CREATE POLICY "profile-photos delete own"
ON "storage"."objects" FOR DELETE TO authenticated
USING (
    "bucket_id" = 'profile-photos'
    AND ("auth"."uid"())::text = ("storage"."foldername"("name"))[1]
    AND ("storage"."foldername"("name"))[2] = 'profile'
);
