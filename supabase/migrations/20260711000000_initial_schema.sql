


SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;


CREATE SCHEMA IF NOT EXISTS "public";


ALTER SCHEMA "public" OWNER TO "pg_database_owner";


COMMENT ON SCHEMA "public" IS 'standard public schema';



CREATE TYPE "public"."sync_status" AS ENUM (
    'synced',
    'pendingCreate',
    'pendingUpdate',
    'pendingDelete',
    'failed',
    'conflict'
);


ALTER TYPE "public"."sync_status" OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."set_updated_at"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
begin
  new.updated_at = now();
  return new;
end;
$$;


ALTER FUNCTION "public"."set_updated_at"() OWNER TO "postgres";

SET default_tablespace = '';

SET default_table_access_method = "heap";


CREATE TABLE IF NOT EXISTS "public"."appointments" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "user_id" "uuid" NOT NULL,
    "title" "text" NOT NULL,
    "appointment_at" timestamp with time zone NOT NULL,
    "doctor_name" "text",
    "location" "text",
    "notes" "text",
    "status" "text" DEFAULT 'scheduled'::"text" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "deleted_at" timestamp with time zone,
    "sync_status" "public"."sync_status" DEFAULT 'synced'::"public"."sync_status" NOT NULL,
    CONSTRAINT "appointments_status_check" CHECK (("status" = ANY (ARRAY['scheduled'::"text", 'completed'::"text", 'canceled'::"text"])))
);


ALTER TABLE "public"."appointments" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."exams" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "user_id" "uuid" NOT NULL,
    "name" "text" NOT NULL,
    "exam_date" timestamp with time zone NOT NULL,
    "laboratory" "text",
    "notes" "text",
    "attachment_path" "text",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "deleted_at" timestamp with time zone,
    "sync_status" "public"."sync_status" DEFAULT 'synced'::"public"."sync_status" NOT NULL
);


ALTER TABLE "public"."exams" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."meals" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "user_id" "uuid" NOT NULL,
    "name" "text" NOT NULL,
    "type" "text" NOT NULL,
    "meal_date" timestamp with time zone NOT NULL,
    "notes" "text",
    "protein_grams" integer,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "deleted_at" timestamp with time zone,
    "sync_status" "public"."sync_status" DEFAULT 'synced'::"public"."sync_status" NOT NULL,
    CONSTRAINT "meals_protein_grams_check" CHECK ((("protein_grams" IS NULL) OR ("protein_grams" >= 0))),
    CONSTRAINT "meals_type_check" CHECK (("type" = ANY (ARRAY['breakfast'::"text", 'lunch'::"text", 'dinner'::"text", 'snack'::"text"])))
);


ALTER TABLE "public"."meals" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."medical_reports" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "user_id" "uuid" NOT NULL,
    "file_name" "text" NOT NULL,
    "template_id" "text" NOT NULL,
    "template_name" "text" NOT NULL,
    "sections" "text"[] NOT NULL,
    "include_charts" boolean DEFAULT true NOT NULL,
    "generated_at" timestamp with time zone NOT NULL,
    "saved_path" "text",
    "storage_path" "text",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "deleted_at" timestamp with time zone,
    "sync_status" "public"."sync_status" DEFAULT 'synced'::"public"."sync_status" NOT NULL
);


ALTER TABLE "public"."medical_reports" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."medications" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "user_id" "uuid" NOT NULL,
    "name" "text" NOT NULL,
    "schedule_hour" smallint NOT NULL,
    "schedule_minute" smallint NOT NULL,
    "dosage" "text",
    "notes" "text",
    "status" "text" DEFAULT 'pending'::"text" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "deleted_at" timestamp with time zone,
    "sync_status" "public"."sync_status" DEFAULT 'synced'::"public"."sync_status" NOT NULL,
    CONSTRAINT "medications_schedule_hour_check" CHECK ((("schedule_hour" >= 0) AND ("schedule_hour" <= 23))),
    CONSTRAINT "medications_schedule_minute_check" CHECK ((("schedule_minute" >= 0) AND ("schedule_minute" <= 59))),
    CONSTRAINT "medications_status_check" CHECK (("status" = ANY (ARRAY['pending'::"text", 'taken'::"text", 'skipped'::"text"])))
);


ALTER TABLE "public"."medications" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."notification_reminders" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "user_id" "uuid" NOT NULL,
    "source" "text" NOT NULL,
    "entity_id" "uuid",
    "title" "text" NOT NULL,
    "body" "text" NOT NULL,
    "scheduled_at" timestamp with time zone NOT NULL,
    "recurrence" "text" DEFAULT 'none'::"text" NOT NULL,
    "enabled" boolean DEFAULT true NOT NULL,
    "payload" "jsonb" DEFAULT '{}'::"jsonb" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "deleted_at" timestamp with time zone,
    "sync_status" "public"."sync_status" DEFAULT 'synced'::"public"."sync_status" NOT NULL,
    CONSTRAINT "notification_reminders_recurrence_check" CHECK (("recurrence" = ANY (ARRAY['none'::"text", 'daily'::"text", 'weekly'::"text"]))),
    CONSTRAINT "notification_reminders_source_check" CHECK (("source" = ANY (ARRAY['vitamin'::"text", 'medication'::"text", 'appointment'::"text", 'push'::"text"])))
);


ALTER TABLE "public"."notification_reminders" OWNER TO "postgres";


COMMENT ON COLUMN "public"."notification_reminders"."entity_id" IS 'Polymorphic reference. Integrity is validated by the Flutter app/application service because source may point to vitamins, medications, appointments, or push.';



CREATE TABLE IF NOT EXISTS "public"."profiles" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "user_id" "uuid" NOT NULL,
    "name" "text" NOT NULL,
    "email" "text" NOT NULL,
    "birth_date" "date" NOT NULL,
    "height_cm" numeric(5,2) NOT NULL,
    "initial_weight_kg" numeric(5,2) NOT NULL,
    "target_weight_kg" numeric(5,2),
    "surgery_date" "date" NOT NULL,
    "surgery_type" "text" NOT NULL,
    "photo_url" "text",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "deleted_at" timestamp with time zone,
    "sync_status" "public"."sync_status" DEFAULT 'synced'::"public"."sync_status" NOT NULL,
    CONSTRAINT "profiles_height_cm_check" CHECK (("height_cm" > (0)::numeric)),
    CONSTRAINT "profiles_initial_weight_kg_check" CHECK (("initial_weight_kg" > (0)::numeric)),
    CONSTRAINT "profiles_target_weight_kg_check" CHECK ((("target_weight_kg" IS NULL) OR ("target_weight_kg" > (0)::numeric)))
);


ALTER TABLE "public"."profiles" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."report_attachments" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "user_id" "uuid" NOT NULL,
    "report_id" "uuid" NOT NULL,
    "name" "text" NOT NULL,
    "type" "text" NOT NULL,
    "path" "text" NOT NULL,
    "mime_type" "text",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "deleted_at" timestamp with time zone,
    "sync_status" "public"."sync_status" DEFAULT 'synced'::"public"."sync_status" NOT NULL,
    CONSTRAINT "report_attachments_type_check" CHECK (("type" = ANY (ARRAY['image'::"text", 'pdf'::"text"])))
);


ALTER TABLE "public"."report_attachments" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."settings" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "user_id" "uuid" NOT NULL,
    "daily_water_goal_ml" integer DEFAULT 2000 NOT NULL,
    "vitamin_reminders_enabled" boolean DEFAULT true NOT NULL,
    "medication_reminders_enabled" boolean DEFAULT true NOT NULL,
    "appointment_reminders_enabled" boolean DEFAULT true NOT NULL,
    "meal_tracking_enabled" boolean DEFAULT true NOT NULL,
    "weight_unit" "text" DEFAULT 'kg'::"text" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "deleted_at" timestamp with time zone,
    "sync_status" "public"."sync_status" DEFAULT 'synced'::"public"."sync_status" NOT NULL,
    CONSTRAINT "settings_daily_water_goal_ml_check" CHECK (("daily_water_goal_ml" > 0)),
    CONSTRAINT "settings_weight_unit_check" CHECK (("weight_unit" = 'kg'::"text"))
);


ALTER TABLE "public"."settings" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."vitamins" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "user_id" "uuid" NOT NULL,
    "name" "text" NOT NULL,
    "schedule_hour" smallint NOT NULL,
    "schedule_minute" smallint NOT NULL,
    "status" "text" DEFAULT 'pending'::"text" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "deleted_at" timestamp with time zone,
    "sync_status" "public"."sync_status" DEFAULT 'synced'::"public"."sync_status" NOT NULL,
    CONSTRAINT "vitamins_schedule_hour_check" CHECK ((("schedule_hour" >= 0) AND ("schedule_hour" <= 23))),
    CONSTRAINT "vitamins_schedule_minute_check" CHECK ((("schedule_minute" >= 0) AND ("schedule_minute" <= 59))),
    CONSTRAINT "vitamins_status_check" CHECK (("status" = ANY (ARRAY['pending'::"text", 'taken'::"text", 'skipped'::"text"])))
);


ALTER TABLE "public"."vitamins" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."water_records" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "user_id" "uuid" NOT NULL,
    "amount_ml" integer NOT NULL,
    "recorded_at" timestamp with time zone NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "deleted_at" timestamp with time zone,
    "sync_status" "public"."sync_status" DEFAULT 'synced'::"public"."sync_status" NOT NULL,
    CONSTRAINT "water_records_amount_ml_check" CHECK (("amount_ml" > 0))
);


ALTER TABLE "public"."water_records" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."weight_records" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "user_id" "uuid" NOT NULL,
    "weight_kg" numeric(5,2) NOT NULL,
    "recorded_at" timestamp with time zone NOT NULL,
    "notes" "text",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "deleted_at" timestamp with time zone,
    "sync_status" "public"."sync_status" DEFAULT 'synced'::"public"."sync_status" NOT NULL,
    CONSTRAINT "weight_records_weight_kg_check" CHECK (("weight_kg" > (0)::numeric))
);


ALTER TABLE "public"."weight_records" OWNER TO "postgres";


ALTER TABLE ONLY "public"."appointments"
    ADD CONSTRAINT "appointments_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."exams"
    ADD CONSTRAINT "exams_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."meals"
    ADD CONSTRAINT "meals_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."medical_reports"
    ADD CONSTRAINT "medical_reports_id_user_unique" UNIQUE ("id", "user_id");



ALTER TABLE ONLY "public"."medical_reports"
    ADD CONSTRAINT "medical_reports_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."medications"
    ADD CONSTRAINT "medications_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."notification_reminders"
    ADD CONSTRAINT "notification_reminders_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."profiles"
    ADD CONSTRAINT "profiles_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."profiles"
    ADD CONSTRAINT "profiles_user_unique" UNIQUE ("user_id");



ALTER TABLE ONLY "public"."report_attachments"
    ADD CONSTRAINT "report_attachments_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."settings"
    ADD CONSTRAINT "settings_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."settings"
    ADD CONSTRAINT "settings_user_unique" UNIQUE ("user_id");



ALTER TABLE ONLY "public"."vitamins"
    ADD CONSTRAINT "vitamins_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."water_records"
    ADD CONSTRAINT "water_records_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."weight_records"
    ADD CONSTRAINT "weight_records_pkey" PRIMARY KEY ("id");



CREATE INDEX "appointments_user_date_idx" ON "public"."appointments" USING "btree" ("user_id", "appointment_at");



CREATE INDEX "appointments_user_deleted_idx" ON "public"."appointments" USING "btree" ("user_id", "deleted_at");



CREATE INDEX "appointments_user_status_idx" ON "public"."appointments" USING "btree" ("user_id", "status");



CREATE INDEX "appointments_user_updated_at_idx" ON "public"."appointments" USING "btree" ("user_id", "updated_at");



CREATE INDEX "exams_user_deleted_idx" ON "public"."exams" USING "btree" ("user_id", "deleted_at");



CREATE INDEX "exams_user_exam_date_idx" ON "public"."exams" USING "btree" ("user_id", "exam_date" DESC);



CREATE INDEX "exams_user_updated_at_idx" ON "public"."exams" USING "btree" ("user_id", "updated_at");



CREATE INDEX "meals_user_deleted_idx" ON "public"."meals" USING "btree" ("user_id", "deleted_at");



CREATE INDEX "meals_user_meal_date_idx" ON "public"."meals" USING "btree" ("user_id", "meal_date" DESC);



CREATE INDEX "meals_user_type_idx" ON "public"."meals" USING "btree" ("user_id", "type");



CREATE INDEX "meals_user_updated_at_idx" ON "public"."meals" USING "btree" ("user_id", "updated_at");



CREATE INDEX "medical_reports_user_deleted_idx" ON "public"."medical_reports" USING "btree" ("user_id", "deleted_at");



CREATE INDEX "medical_reports_user_generated_idx" ON "public"."medical_reports" USING "btree" ("user_id", "generated_at" DESC);



CREATE INDEX "medical_reports_user_updated_at_idx" ON "public"."medical_reports" USING "btree" ("user_id", "updated_at");



CREATE INDEX "medications_user_deleted_idx" ON "public"."medications" USING "btree" ("user_id", "deleted_at");



CREATE INDEX "medications_user_schedule_idx" ON "public"."medications" USING "btree" ("user_id", "schedule_hour", "schedule_minute");



CREATE INDEX "medications_user_status_idx" ON "public"."medications" USING "btree" ("user_id", "status");



CREATE INDEX "medications_user_updated_at_idx" ON "public"."medications" USING "btree" ("user_id", "updated_at");



CREATE INDEX "notification_reminders_payload_gin_idx" ON "public"."notification_reminders" USING "gin" ("payload");



CREATE INDEX "notification_reminders_user_schedule_idx" ON "public"."notification_reminders" USING "btree" ("user_id", "scheduled_at");



CREATE INDEX "notification_reminders_user_source_idx" ON "public"."notification_reminders" USING "btree" ("user_id", "source", "entity_id");



CREATE INDEX "notification_reminders_user_updated_at_idx" ON "public"."notification_reminders" USING "btree" ("user_id", "updated_at");



CREATE INDEX "profiles_deleted_at_idx" ON "public"."profiles" USING "btree" ("deleted_at");



CREATE INDEX "profiles_user_id_idx" ON "public"."profiles" USING "btree" ("user_id");



CREATE INDEX "profiles_user_updated_at_idx" ON "public"."profiles" USING "btree" ("user_id", "updated_at");



CREATE INDEX "report_attachments_report_idx" ON "public"."report_attachments" USING "btree" ("report_id");



CREATE INDEX "report_attachments_user_idx" ON "public"."report_attachments" USING "btree" ("user_id");



CREATE INDEX "report_attachments_user_updated_at_idx" ON "public"."report_attachments" USING "btree" ("user_id", "updated_at");



CREATE INDEX "settings_user_id_idx" ON "public"."settings" USING "btree" ("user_id");



CREATE INDEX "settings_user_updated_at_idx" ON "public"."settings" USING "btree" ("user_id", "updated_at");



CREATE INDEX "vitamins_user_deleted_idx" ON "public"."vitamins" USING "btree" ("user_id", "deleted_at");



CREATE INDEX "vitamins_user_schedule_idx" ON "public"."vitamins" USING "btree" ("user_id", "schedule_hour", "schedule_minute");



CREATE INDEX "vitamins_user_status_idx" ON "public"."vitamins" USING "btree" ("user_id", "status");



CREATE INDEX "vitamins_user_updated_at_idx" ON "public"."vitamins" USING "btree" ("user_id", "updated_at");



CREATE INDEX "water_records_user_deleted_idx" ON "public"."water_records" USING "btree" ("user_id", "deleted_at");



CREATE INDEX "water_records_user_recorded_at_idx" ON "public"."water_records" USING "btree" ("user_id", "recorded_at" DESC);



CREATE INDEX "water_records_user_updated_at_idx" ON "public"."water_records" USING "btree" ("user_id", "updated_at");



CREATE INDEX "weight_records_user_deleted_idx" ON "public"."weight_records" USING "btree" ("user_id", "deleted_at");



CREATE INDEX "weight_records_user_recorded_at_idx" ON "public"."weight_records" USING "btree" ("user_id", "recorded_at" DESC);



CREATE INDEX "weight_records_user_updated_at_idx" ON "public"."weight_records" USING "btree" ("user_id", "updated_at");



CREATE OR REPLACE TRIGGER "appointments_set_updated_at" BEFORE UPDATE ON "public"."appointments" FOR EACH ROW EXECUTE FUNCTION "public"."set_updated_at"();



CREATE OR REPLACE TRIGGER "exams_set_updated_at" BEFORE UPDATE ON "public"."exams" FOR EACH ROW EXECUTE FUNCTION "public"."set_updated_at"();



CREATE OR REPLACE TRIGGER "meals_set_updated_at" BEFORE UPDATE ON "public"."meals" FOR EACH ROW EXECUTE FUNCTION "public"."set_updated_at"();



CREATE OR REPLACE TRIGGER "medical_reports_set_updated_at" BEFORE UPDATE ON "public"."medical_reports" FOR EACH ROW EXECUTE FUNCTION "public"."set_updated_at"();



CREATE OR REPLACE TRIGGER "medications_set_updated_at" BEFORE UPDATE ON "public"."medications" FOR EACH ROW EXECUTE FUNCTION "public"."set_updated_at"();



CREATE OR REPLACE TRIGGER "notification_reminders_set_updated_at" BEFORE UPDATE ON "public"."notification_reminders" FOR EACH ROW EXECUTE FUNCTION "public"."set_updated_at"();



CREATE OR REPLACE TRIGGER "profiles_set_updated_at" BEFORE UPDATE ON "public"."profiles" FOR EACH ROW EXECUTE FUNCTION "public"."set_updated_at"();



CREATE OR REPLACE TRIGGER "report_attachments_set_updated_at" BEFORE UPDATE ON "public"."report_attachments" FOR EACH ROW EXECUTE FUNCTION "public"."set_updated_at"();



CREATE OR REPLACE TRIGGER "settings_set_updated_at" BEFORE UPDATE ON "public"."settings" FOR EACH ROW EXECUTE FUNCTION "public"."set_updated_at"();



CREATE OR REPLACE TRIGGER "vitamins_set_updated_at" BEFORE UPDATE ON "public"."vitamins" FOR EACH ROW EXECUTE FUNCTION "public"."set_updated_at"();



CREATE OR REPLACE TRIGGER "water_records_set_updated_at" BEFORE UPDATE ON "public"."water_records" FOR EACH ROW EXECUTE FUNCTION "public"."set_updated_at"();



CREATE OR REPLACE TRIGGER "weight_records_set_updated_at" BEFORE UPDATE ON "public"."weight_records" FOR EACH ROW EXECUTE FUNCTION "public"."set_updated_at"();



ALTER TABLE ONLY "public"."appointments"
    ADD CONSTRAINT "appointments_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."exams"
    ADD CONSTRAINT "exams_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."meals"
    ADD CONSTRAINT "meals_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."medical_reports"
    ADD CONSTRAINT "medical_reports_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."medications"
    ADD CONSTRAINT "medications_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."notification_reminders"
    ADD CONSTRAINT "notification_reminders_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."profiles"
    ADD CONSTRAINT "profiles_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."report_attachments"
    ADD CONSTRAINT "report_attachments_report_user_fk" FOREIGN KEY ("report_id", "user_id") REFERENCES "public"."medical_reports"("id", "user_id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."report_attachments"
    ADD CONSTRAINT "report_attachments_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."settings"
    ADD CONSTRAINT "settings_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."vitamins"
    ADD CONSTRAINT "vitamins_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."water_records"
    ADD CONSTRAINT "water_records_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."weight_records"
    ADD CONSTRAINT "weight_records_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id") ON DELETE CASCADE;



ALTER TABLE "public"."appointments" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "appointments insert own" ON "public"."appointments" FOR INSERT WITH CHECK (("user_id" = "auth"."uid"()));



CREATE POLICY "appointments select own" ON "public"."appointments" FOR SELECT USING (("user_id" = "auth"."uid"()));



CREATE POLICY "appointments update own" ON "public"."appointments" FOR UPDATE USING (("user_id" = "auth"."uid"())) WITH CHECK (("user_id" = "auth"."uid"()));



ALTER TABLE "public"."exams" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "exams insert own" ON "public"."exams" FOR INSERT WITH CHECK (("user_id" = "auth"."uid"()));



CREATE POLICY "exams select own" ON "public"."exams" FOR SELECT USING (("user_id" = "auth"."uid"()));



CREATE POLICY "exams update own" ON "public"."exams" FOR UPDATE USING (("user_id" = "auth"."uid"())) WITH CHECK (("user_id" = "auth"."uid"()));



ALTER TABLE "public"."meals" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "meals insert own" ON "public"."meals" FOR INSERT WITH CHECK (("user_id" = "auth"."uid"()));



CREATE POLICY "meals select own" ON "public"."meals" FOR SELECT USING (("user_id" = "auth"."uid"()));



CREATE POLICY "meals update own" ON "public"."meals" FOR UPDATE USING (("user_id" = "auth"."uid"())) WITH CHECK (("user_id" = "auth"."uid"()));



ALTER TABLE "public"."medical_reports" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "medical_reports insert own" ON "public"."medical_reports" FOR INSERT WITH CHECK (("user_id" = "auth"."uid"()));



CREATE POLICY "medical_reports select own" ON "public"."medical_reports" FOR SELECT USING (("user_id" = "auth"."uid"()));



CREATE POLICY "medical_reports update own" ON "public"."medical_reports" FOR UPDATE USING (("user_id" = "auth"."uid"())) WITH CHECK (("user_id" = "auth"."uid"()));



ALTER TABLE "public"."medications" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "medications insert own" ON "public"."medications" FOR INSERT WITH CHECK (("user_id" = "auth"."uid"()));



CREATE POLICY "medications select own" ON "public"."medications" FOR SELECT USING (("user_id" = "auth"."uid"()));



CREATE POLICY "medications update own" ON "public"."medications" FOR UPDATE USING (("user_id" = "auth"."uid"())) WITH CHECK (("user_id" = "auth"."uid"()));



ALTER TABLE "public"."notification_reminders" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "notification_reminders insert own" ON "public"."notification_reminders" FOR INSERT WITH CHECK (("user_id" = "auth"."uid"()));



CREATE POLICY "notification_reminders select own" ON "public"."notification_reminders" FOR SELECT USING (("user_id" = "auth"."uid"()));



CREATE POLICY "notification_reminders update own" ON "public"."notification_reminders" FOR UPDATE USING (("user_id" = "auth"."uid"())) WITH CHECK (("user_id" = "auth"."uid"()));



ALTER TABLE "public"."profiles" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "profiles insert own" ON "public"."profiles" FOR INSERT WITH CHECK (("user_id" = "auth"."uid"()));



CREATE POLICY "profiles select own" ON "public"."profiles" FOR SELECT USING (("user_id" = "auth"."uid"()));



CREATE POLICY "profiles update own" ON "public"."profiles" FOR UPDATE USING (("user_id" = "auth"."uid"())) WITH CHECK (("user_id" = "auth"."uid"()));



ALTER TABLE "public"."report_attachments" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "report_attachments insert own" ON "public"."report_attachments" FOR INSERT WITH CHECK ((("user_id" = "auth"."uid"()) AND (EXISTS ( SELECT 1
   FROM "public"."medical_reports" "r"
  WHERE (("r"."id" = "report_attachments"."report_id") AND ("r"."user_id" = "auth"."uid"()))))));



CREATE POLICY "report_attachments select own" ON "public"."report_attachments" FOR SELECT USING (("user_id" = "auth"."uid"()));



CREATE POLICY "report_attachments update own" ON "public"."report_attachments" FOR UPDATE USING (("user_id" = "auth"."uid"())) WITH CHECK ((("user_id" = "auth"."uid"()) AND (EXISTS ( SELECT 1
   FROM "public"."medical_reports" "r"
  WHERE (("r"."id" = "report_attachments"."report_id") AND ("r"."user_id" = "auth"."uid"()))))));



ALTER TABLE "public"."settings" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "settings insert own" ON "public"."settings" FOR INSERT WITH CHECK (("user_id" = "auth"."uid"()));



CREATE POLICY "settings select own" ON "public"."settings" FOR SELECT USING (("user_id" = "auth"."uid"()));



CREATE POLICY "settings update own" ON "public"."settings" FOR UPDATE USING (("user_id" = "auth"."uid"())) WITH CHECK (("user_id" = "auth"."uid"()));



ALTER TABLE "public"."vitamins" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "vitamins insert own" ON "public"."vitamins" FOR INSERT WITH CHECK (("user_id" = "auth"."uid"()));



CREATE POLICY "vitamins select own" ON "public"."vitamins" FOR SELECT USING (("user_id" = "auth"."uid"()));



CREATE POLICY "vitamins update own" ON "public"."vitamins" FOR UPDATE USING (("user_id" = "auth"."uid"())) WITH CHECK (("user_id" = "auth"."uid"()));



ALTER TABLE "public"."water_records" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "water_records insert own" ON "public"."water_records" FOR INSERT WITH CHECK (("user_id" = "auth"."uid"()));



CREATE POLICY "water_records select own" ON "public"."water_records" FOR SELECT USING (("user_id" = "auth"."uid"()));



CREATE POLICY "water_records update own" ON "public"."water_records" FOR UPDATE USING (("user_id" = "auth"."uid"())) WITH CHECK (("user_id" = "auth"."uid"()));



ALTER TABLE "public"."weight_records" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "weight_records insert own" ON "public"."weight_records" FOR INSERT WITH CHECK (("user_id" = "auth"."uid"()));



CREATE POLICY "weight_records select own" ON "public"."weight_records" FOR SELECT USING (("user_id" = "auth"."uid"()));



CREATE POLICY "weight_records update own" ON "public"."weight_records" FOR UPDATE USING (("user_id" = "auth"."uid"())) WITH CHECK (("user_id" = "auth"."uid"()));


-- Storage buckets and object policies are application-owned configuration.
-- Supabase manages the storage schema itself, so only bucket rows and policies
-- are versioned here.

INSERT INTO "storage"."buckets" (
    "id",
    "name",
    "public",
    "file_size_limit",
    "allowed_mime_types"
) VALUES
    ('profile-photos', 'profile-photos', false, NULL, NULL),
    ('exam-attachments', 'exam-attachments', false, NULL, NULL),
    ('medical-reports', 'medical-reports', false, NULL, NULL),
    ('report-attachments', 'report-attachments', false, NULL, NULL)
ON CONFLICT ("id") DO NOTHING;


CREATE POLICY "exam-attachments insert own"
ON "storage"."objects"
FOR INSERT
WITH CHECK (
    "bucket_id" = 'exam-attachments'
    AND ("auth"."uid"())::"text" = ("storage"."foldername"("name"))[1]
);

CREATE POLICY "exam-attachments read own"
ON "storage"."objects"
FOR SELECT
USING (
    "bucket_id" = 'exam-attachments'
    AND ("auth"."uid"())::"text" = ("storage"."foldername"("name"))[1]
);

CREATE POLICY "exam-attachments update own"
ON "storage"."objects"
FOR UPDATE
USING (
    "bucket_id" = 'exam-attachments'
    AND ("auth"."uid"())::"text" = ("storage"."foldername"("name"))[1]
)
WITH CHECK (
    "bucket_id" = 'exam-attachments'
    AND ("auth"."uid"())::"text" = ("storage"."foldername"("name"))[1]
);

CREATE POLICY "medical-reports insert own"
ON "storage"."objects"
FOR INSERT
WITH CHECK (
    "bucket_id" = 'medical-reports'
    AND ("auth"."uid"())::"text" = ("storage"."foldername"("name"))[1]
);

CREATE POLICY "medical-reports read own"
ON "storage"."objects"
FOR SELECT
USING (
    "bucket_id" = 'medical-reports'
    AND ("auth"."uid"())::"text" = ("storage"."foldername"("name"))[1]
);

CREATE POLICY "medical-reports update own"
ON "storage"."objects"
FOR UPDATE
USING (
    "bucket_id" = 'medical-reports'
    AND ("auth"."uid"())::"text" = ("storage"."foldername"("name"))[1]
)
WITH CHECK (
    "bucket_id" = 'medical-reports'
    AND ("auth"."uid"())::"text" = ("storage"."foldername"("name"))[1]
);

CREATE POLICY "profile-photos insert own"
ON "storage"."objects"
FOR INSERT
WITH CHECK (
    "bucket_id" = 'profile-photos'
    AND ("auth"."uid"())::"text" = ("storage"."foldername"("name"))[1]
);

CREATE POLICY "profile-photos read own"
ON "storage"."objects"
FOR SELECT
USING (
    "bucket_id" = 'profile-photos'
    AND ("auth"."uid"())::"text" = ("storage"."foldername"("name"))[1]
);

CREATE POLICY "profile-photos update own"
ON "storage"."objects"
FOR UPDATE
USING (
    "bucket_id" = 'profile-photos'
    AND ("auth"."uid"())::"text" = ("storage"."foldername"("name"))[1]
)
WITH CHECK (
    "bucket_id" = 'profile-photos'
    AND ("auth"."uid"())::"text" = ("storage"."foldername"("name"))[1]
);

CREATE POLICY "report-attachments insert own"
ON "storage"."objects"
FOR INSERT
WITH CHECK (
    "bucket_id" = 'report-attachments'
    AND ("auth"."uid"())::"text" = ("storage"."foldername"("name"))[1]
);

CREATE POLICY "report-attachments read own"
ON "storage"."objects"
FOR SELECT
USING (
    "bucket_id" = 'report-attachments'
    AND ("auth"."uid"())::"text" = ("storage"."foldername"("name"))[1]
);

CREATE POLICY "report-attachments update own"
ON "storage"."objects"
FOR UPDATE
USING (
    "bucket_id" = 'report-attachments'
    AND ("auth"."uid"())::"text" = ("storage"."foldername"("name"))[1]
)
WITH CHECK (
    "bucket_id" = 'report-attachments'
    AND ("auth"."uid"())::"text" = ("storage"."foldername"("name"))[1]
);



GRANT USAGE ON SCHEMA "public" TO "postgres";
GRANT USAGE ON SCHEMA "public" TO "anon";
GRANT USAGE ON SCHEMA "public" TO "authenticated";
GRANT USAGE ON SCHEMA "public" TO "service_role";



GRANT ALL ON FUNCTION "public"."set_updated_at"() TO "anon";
GRANT ALL ON FUNCTION "public"."set_updated_at"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."set_updated_at"() TO "service_role";



GRANT ALL ON TABLE "public"."appointments" TO "anon";
GRANT ALL ON TABLE "public"."appointments" TO "authenticated";
GRANT ALL ON TABLE "public"."appointments" TO "service_role";



GRANT ALL ON TABLE "public"."exams" TO "anon";
GRANT ALL ON TABLE "public"."exams" TO "authenticated";
GRANT ALL ON TABLE "public"."exams" TO "service_role";



GRANT ALL ON TABLE "public"."meals" TO "anon";
GRANT ALL ON TABLE "public"."meals" TO "authenticated";
GRANT ALL ON TABLE "public"."meals" TO "service_role";



GRANT ALL ON TABLE "public"."medical_reports" TO "anon";
GRANT ALL ON TABLE "public"."medical_reports" TO "authenticated";
GRANT ALL ON TABLE "public"."medical_reports" TO "service_role";



GRANT ALL ON TABLE "public"."medications" TO "anon";
GRANT ALL ON TABLE "public"."medications" TO "authenticated";
GRANT ALL ON TABLE "public"."medications" TO "service_role";



GRANT ALL ON TABLE "public"."notification_reminders" TO "anon";
GRANT ALL ON TABLE "public"."notification_reminders" TO "authenticated";
GRANT ALL ON TABLE "public"."notification_reminders" TO "service_role";



GRANT ALL ON TABLE "public"."profiles" TO "anon";
GRANT ALL ON TABLE "public"."profiles" TO "authenticated";
GRANT ALL ON TABLE "public"."profiles" TO "service_role";



GRANT ALL ON TABLE "public"."report_attachments" TO "anon";
GRANT ALL ON TABLE "public"."report_attachments" TO "authenticated";
GRANT ALL ON TABLE "public"."report_attachments" TO "service_role";



GRANT ALL ON TABLE "public"."settings" TO "anon";
GRANT ALL ON TABLE "public"."settings" TO "authenticated";
GRANT ALL ON TABLE "public"."settings" TO "service_role";



GRANT ALL ON TABLE "public"."vitamins" TO "anon";
GRANT ALL ON TABLE "public"."vitamins" TO "authenticated";
GRANT ALL ON TABLE "public"."vitamins" TO "service_role";



GRANT ALL ON TABLE "public"."water_records" TO "anon";
GRANT ALL ON TABLE "public"."water_records" TO "authenticated";
GRANT ALL ON TABLE "public"."water_records" TO "service_role";



GRANT ALL ON TABLE "public"."weight_records" TO "anon";
GRANT ALL ON TABLE "public"."weight_records" TO "authenticated";
GRANT ALL ON TABLE "public"."weight_records" TO "service_role";



ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "service_role";






ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "service_role";






ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "service_role";






