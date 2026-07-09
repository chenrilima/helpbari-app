# Plano Supabase-ready

Este documento mapeia as mudanças necessárias para preparar as features do HelpBari para persistência em Supabase. A auditoria não altera código de features; ela define campos de auditoria, repositórios a substituir e tabelas sugeridas.

## Diretrizes

- Todas as tabelas de dados do usuário devem ter `user_id uuid not null references auth.users(id)`.
- Todas as tabelas persistidas devem ter `created_at timestamptz not null default now()` e `updated_at timestamptz not null default now()`.
- `updated_at` deve ser mantido por trigger no Supabase.
- RLS deve filtrar por `auth.uid() = user_id`.
- No Dart, entidades devem receber `userId`, `createdAt` e `updatedAt` quando forem migradas para Supabase.
- Value objects continuam no domínio; repositories Supabase fazem mapping entre colunas primitivas e entidades/value objects.

## Resumo por Feature

| Feature | Entity atual | Precisa `userId` | Precisa `createdAt` | Precisa `updatedAt` | Tabela sugerida |
| --- | --- | --- | --- | --- | --- |
| Profile | `Profile` | Sim | Já tem `createdAt`; padronizar | Sim | `profiles` |
| Weight | `WeightRecord` | Sim | Sim | Sim | `weight_records` |
| Water | `WaterRecord` | Sim | Sim | Sim | `water_records` |
| Vitamins | `Vitamin` | Sim | Sim | Sim | `vitamins` |
| Medications | `Medication` | Sim | Sim | Sim | `medications` |
| Meals | `Meal` | Sim | Sim | Sim | `meals` |
| Appointments | `Appointment` | Sim | Sim | Sim | `appointments` |
| Exams | `Exam` | Sim | Sim | Sim | `exams` |
| Settings | `AppSettings` | Sim | Sim | Sim | `settings` |

## Repositórios a substituir por Supabase

| Feature | Interface | Fake atual | SupabaseRepository sugerido |
| --- | --- | --- | --- |
| Profile | `ProfileRepository` | `FakeProfileRepository` | `SupabaseProfileRepository` existente, ainda TODO |
| Weight | `WeightRepository` | `FakeWeightRepository` | `SupabaseWeightRepository` |
| Water | `WaterRepository` | `FakeWaterRepository` | `SupabaseWaterRepository` |
| Vitamins | `VitaminRepository` | `FakeVitaminRepository` | `SupabaseVitaminRepository` |
| Medications | `MedicationRepository` | `FakeMedicationRepository` | `SupabaseMedicationRepository` |
| Meals | `MealRepository` | `FakeMealRepository` | `SupabaseMealRepository` |
| Appointments | `AppointmentRepository` | `FakeAppointmentRepository` | `SupabaseAppointmentRepository` |
| Exams | `ExamRepository` | `FakeExamRepository` | `SupabaseExamRepository` |
| Settings | `SettingsRepository` | `FakeSettingRepository` | `SupabaseSettingsRepository` |

## Tabelas sugeridas

### `profiles`

Representa o perfil principal do usuário. Deve ter regra de unicidade por usuário.

Campos sugeridos:

- `id uuid primary key`
- `user_id uuid not null references auth.users(id) unique`
- `name text not null`
- `email text not null`
- `birth_date date not null`
- `height_cm integer not null`
- `initial_weight_kg numeric not null`
- `target_weight_kg numeric null`
- `surgery_date date not null`
- `surgery_type text not null`
- `photo_url text null`
- `created_at timestamptz not null default now()`
- `updated_at timestamptz not null default now()`

Entidade:

- Adicionar `userId`.
- Manter `createdAt`, mas padronizar como metadata de persistência.
- Adicionar `updatedAt`.

### `weight_records`

Histórico de pesagens.

Campos sugeridos:

- `id uuid primary key`
- `user_id uuid not null references auth.users(id)`
- `weight_kg numeric not null`
- `recorded_at timestamptz not null`
- `notes text null`
- `created_at timestamptz not null default now()`
- `updated_at timestamptz not null default now()`

Entidade:

- Adicionar `userId`.
- Adicionar `createdAt`.
- Adicionar `updatedAt`.
- `recordedAt` continua sendo a data informada pelo usuário para o peso.

### `water_records`

Registros de ingestão de água.

Campos sugeridos:

- `id uuid primary key`
- `user_id uuid not null references auth.users(id)`
- `amount_ml integer not null`
- `recorded_at timestamptz not null`
- `created_at timestamptz not null default now()`
- `updated_at timestamptz not null default now()`

Entidade:

- Adicionar `userId`.
- Adicionar `createdAt`.
- Adicionar `updatedAt`.
- `recordedAt` continua representando quando a água foi consumida.

### `vitamins`

Cadastro e status diário atual de vitaminas. Se o app evoluir para histórico diário, criar depois uma tabela separada `vitamin_logs`.

Campos sugeridos:

- `id uuid primary key`
- `user_id uuid not null references auth.users(id)`
- `name text not null`
- `schedule_hour integer not null`
- `schedule_minute integer not null`
- `status text not null`
- `created_at timestamptz not null default now()`
- `updated_at timestamptz not null default now()`

Entidade:

- Adicionar `userId`.
- Adicionar `createdAt`.
- Adicionar `updatedAt`.

### `medications`

Cadastro e status diário atual de medicamentos. Se precisar histórico por tomada, criar depois `medication_logs`.

Campos sugeridos:

- `id uuid primary key`
- `user_id uuid not null references auth.users(id)`
- `name text not null`
- `schedule_hour integer not null`
- `schedule_minute integer not null`
- `dosage text null`
- `notes text null`
- `status text not null`
- `created_at timestamptz not null default now()`
- `updated_at timestamptz not null default now()`

Entidade:

- Adicionar `userId`.
- Adicionar `createdAt`.
- Adicionar `updatedAt`.

### `meals`

Registros alimentares.

Campos sugeridos:

- `id uuid primary key`
- `user_id uuid not null references auth.users(id)`
- `name text not null`
- `type text not null`
- `meal_date timestamptz not null`
- `protein_grams integer null`
- `notes text null`
- `created_at timestamptz not null default now()`
- `updated_at timestamptz not null default now()`

Entidade:

- Adicionar `userId`.
- Adicionar `createdAt`.
- Adicionar `updatedAt`.
- `mealDate` continua representando a data/hora da refeição.

### `appointments`

Consultas e compromissos médicos.

Campos sugeridos:

- `id uuid primary key`
- `user_id uuid not null references auth.users(id)`
- `title text not null`
- `appointment_at timestamptz not null`
- `doctor_name text null`
- `location text null`
- `notes text null`
- `status text not null`
- `created_at timestamptz not null default now()`
- `updated_at timestamptz not null default now()`

Entidade:

- Adicionar `userId`.
- Adicionar `createdAt`.
- Adicionar `updatedAt`.
- `date` pode mapear para `appointment_at` no banco.

### `exams`

Exames cadastrados pelo usuário.

Campos sugeridos:

- `id uuid primary key`
- `user_id uuid not null references auth.users(id)`
- `name text not null`
- `exam_date date not null`
- `laboratory text null`
- `notes text null`
- `attachment_path text null`
- `created_at timestamptz not null default now()`
- `updated_at timestamptz not null default now()`

Entidade:

- Adicionar `userId`.
- Adicionar `createdAt`.
- Adicionar `updatedAt`.
- `attachmentPath` deve apontar para um path em Supabase Storage, não URL pública fixa.

### `settings`

Preferências do usuário. Deve ter um registro por usuário.

Campos sugeridos:

- `id uuid primary key`
- `user_id uuid not null references auth.users(id) unique`
- `daily_water_goal_ml integer not null default 2000`
- `vitamin_reminders_enabled boolean not null default true`
- `medication_reminders_enabled boolean not null default true`
- `appointment_reminders_enabled boolean not null default true`
- `meal_tracking_enabled boolean not null default true`
- `weight_unit text not null default 'kg'`
- `created_at timestamptz not null default now()`
- `updated_at timestamptz not null default now()`

Entidade:

- Adicionar `userId`.
- Adicionar `createdAt`.
- Adicionar `updatedAt`.

## Ordem sugerida de migração

1. Criar modelos de metadata comuns no domínio ou adicionar campos diretamente nas entidades.
2. Criar mappers por feature: `fromJson/fromMap` e `toJson/toMap`.
3. Implementar `SupabaseProfileRepository` primeiro, porque já existe stub.
4. Migrar `Settings`, pois deve ser carregado cedo e tem relação 1:1 com usuário.
5. Migrar registros simples: `Weight`, `Water`, `Meals`.
6. Migrar cadastros com status: `Vitamins`, `Medications`, `Appointments`.
7. Migrar `Exams` e depois tratar Supabase Storage para anexos.

## RLS sugerida

Cada tabela deve seguir a mesma base:

```sql
alter table <table_name> enable row level security;

create policy "Users can select own rows"
on <table_name> for select
using (auth.uid() = user_id);

create policy "Users can insert own rows"
on <table_name> for insert
with check (auth.uid() = user_id);

create policy "Users can update own rows"
on <table_name> for update
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

create policy "Users can delete own rows"
on <table_name> for delete
using (auth.uid() = user_id);
```

Para `profiles` e `settings`, adicionar índice único:

```sql
create unique index profiles_user_id_key on profiles(user_id);
create unique index settings_user_id_key on settings(user_id);
```

## Observações técnicas

- O projeto já possui `supabaseClientProvider`, então os providers de repository podem trocar fake por Supabase sem impactar a camada de domínio.
- `ProfileViewModel` ainda cria `id: 'local-profile'`; na migração Supabase isso deve virar UUID gerado via `UuidService` ou id derivado do usuário, conforme decisão de schema.
- `createdAt` de domínio não deve substituir datas de evento como `recordedAt`, `mealDate`, `appointment_at` ou `examDate`.
- Status devem ser persistidos como `text` inicialmente e validados no mapper contra os enums do domínio.
- Anexos de exames devem usar bucket dedicado, por exemplo `exam-attachments`, com path por usuário.
