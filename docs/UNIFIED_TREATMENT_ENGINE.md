# Unified Treatment Engine

## Autoridade clínica

Smart Routines é a única autoridade funcional para Medication e Vitamin.
`smart_routines.category` é apenas a projeção da categoria atual; a autoridade
histórica é `routine_plans.category`. Alterações clínicas criam uma revisão e o
plano anterior pode receber somente o fechamento único `replacedAt`.

Os valores oficiais de duração são `bounded`, `continuous`, `unknown` e
`singleDose`. A migration 19 converte somente `fixed` para `bounded`.

## Migração e identidade

`UnifiedTreatmentMigrator` executa uma transação por entidade legada. IDs são
UUIDv5 de `version + userId + source + legacyId + targetType`. Mappings de
entidade e log tornam retry idempotente e registram apenas estado, contagens e
provenance não clínico.

O timezone vem do consentimento mais recente que contenha IANA válido. Sem ele,
o mapping fica `validationRequired`. Logs não têm horário real: taken/skipped
usam o horário nominal e precisão `estimatedFromLegacyDate`. Pending materializa
somente a expectativa e nunca cria evento. Dias sem log não são inventados.

## Cutover e rollback

O fluxo persistido é Detect → Migrate → Validate → Read New → Write New. O
cutover exige mappings completos, relações válidas e flags de read/cutover.
Rollback para leitura legada só é permitido antes de qualquer escrita clínica
nova; dados migrados nunca são apagados. Depois de Write New, recuperação mantém
Smart Routines como autoridade.

As flags persistidas são migration, cutover, read, write e remote sync. Desligar
uma flag impede novas transições, mas não reverte nem remove dados. Remote sync
inicia desabilitado até confirmação operacional da migration Supabase.

## Sync, LGPD e notificações

Medication/Vitamin e seus logs não são mais registrados no Sync Manager. A
ordem Smart Routines permanece routine, plan, schedule, pause, occurrence,
event. Eventos são insert-only; correções são eventos novos.

Export e exclusão incluem toda a família Smart Routines e os mappings. A
exclusão administrativa LGPD pode apagar eventos append-only.

Notifications 2.0 consumirá `RoutineNotificationProjection`, produzida de uma
occurrence. Nenhuma nova recorrência de Medication/Vitamin é agendada pelas
fachadas legadas. O payload técnico contém apenas occurrenceId, userId e source.
