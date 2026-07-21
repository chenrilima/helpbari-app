# HelpBari Architecture

## Objetivo

HelpBari é um aplicativo Flutter voltado para o acompanhamento da jornada de pacientes bariátricos.

O projeto foi desenvolvido para ser escalável, modular e de fácil manutenção, permitindo no futuro a evolução para uma plataforma utilizada também por clínicas e profissionais da saúde.

---

# Stack

- Flutter
- Riverpod
- MVVM
- Supabase
- GoRouter

---

# Organização

lib/

app/
core/
shared/
features/

---

# Features

Cada feature possui sua própria estrutura.

feature/

data/
domain/
presentation/

---

# Camadas

## Domain

Contém regras de negócio.

Não conhece Flutter.

Não conhece Supabase.

Não conhece UI.

---

## Data

Contém implementações.

Supabase

REST

Storage

Cache

Modelos

---

## Presentation

Contém:

Pages

Widgets

ViewModels

States

---

# Shared

Widgets reutilizáveis.

---

# Core

Utilitários globais.

Validators

Extensions

Result

Errors

Logger

Formatter

Config

---

# Princípios

- Clean Code
- SOLID
- Baixo acoplamento
- Alta coesão
- Componentização
- Testabilidade
- Reutilização

---

# Arquitetura de notificações e lembretes

## Decisão

As regras que determinam um lembrete pertencem às entidades de negócio e às
configurações sincronizadas. As notificações concretas registradas no sistema
operacional são projeções locais e descartáveis de cada dispositivo.

Atualmente, as fontes da verdade são:

- `SmartRoutine`, `RoutinePlan` e `RoutineSchedule`, para as regras de
  tratamento expostas pelas fachadas Medication/Vitamin;
- `Appointment`, para data, horário e estado de consultas;
- `Settings`, para habilitar ou desabilitar cada categoria de lembrete;
- Drift, como fonte local offline-first dessas entidades;
- Supabase e o Sync Engine, para sincronizar entidades e preferências.

O `NotificationScheduler` recebe atualmente apenas a projeção de Appointment.
As projeções de tratamento serão retomadas por Notifications V2 a partir de
ocorrências canônicas. Ele não é repositório de domínio e não participa do Sync Engine. A
chave local combina `userId`, tipo da entidade e `entityId`; o ID inteiro usado
pelo plugin é derivado dessa chave e nunca é sincronizado.

## Restore, dispositivo e timezone

Após login, sincronização inicial, retorno do app e alteração de configurações,
o app relê Settings e as entidades atuais e reconcilia incrementalmente o
manifest local. Logout, troca de usuário e exclusão LGPD são os únicos fluxos
que cancelam globalmente as notificações antes de ativar a próxima conta. Taps
são aceitos somente quando o `userId` do payload corresponde à sessão ativa.

Horários recorrentes preservam a hora de parede informada pelo usuário e são
projetados no timezone atual do dispositivo. Se o timezone não puder ser
resolvido, o serviço usa UTC e registra somente uma advertência técnica.

Cada dispositivo pode ter permissões, timezone e projeções diferentes. O que é
sincronizado são as regras de negócio e preferências, não o estado interno do
plugin nem a ocorrência concreta agendada no sistema operacional.

## Privacidade do payload

O payload local contém apenas `source`, `entityId`, `userId`, ação técnica e um
mapa técnico opcional. Nome de medicamento, vitamina, consulta ou outros dados
clínicos não devem ser acrescentados ao payload. Logs não devem registrar IDs,
conteúdo clínico ou o payload completo.

## `public.notification_reminders`

Decisão arquitetural: opção C, tabela legada descontinuada como fonte
funcional. Não existe entity, DTO, tabela Drift, DAO, datasource, repository,
use case, provider ou `SyncableRepository` Dart associado a ela. O app atual
não lê nem escreve nessa tabela e seu funcionamento não depende dela.

A tabela permanece fisicamente no schema para compatibilidade e preservação de
eventuais dados históricos. Ela não deve receber novas integrações, não deve ser
usada como segunda fonte da verdade e continua coberta por `delete_my_data()`
enquanto existir. Sua presença no schema não significa que notificações
concretas sejam sincronizadas entre dispositivos.

Uma remoção futura exige auditoria dos dados no ambiente remoto, confirmação de
que nenhuma versão externa ainda escreve na tabela, período de observação e uma
migration destrutiva aprovada separadamente.

## Smart Routines e Notifications V2

Smart Routines mantém `RoutinePlan` e `RoutineSchedule` como regras clínicas
sincronizáveis, incluindo múltiplos horários, vigência, pausas, PRN e offsets.
Notifications V2 projeta uma janela móvel limitada por meio do Occurrence
Engine canônico, mantém manifest e action inbox locais e reconcilia o plugin
por diff incremental. IDs do plugin, permissões, manifest e estado do sistema
operacional não entram no sync. Ações são persistidas antes do processamento e
somente Unified Treatment Commands criam eventos de adesão. A tabela legada
`notification_reminders` permanece descontinuada.

## Unified Treatment Engine

Medication e Vitamin são fachadas de apresentação sobre Smart Routines. Novas
escritas criam ou revisam `SmartRoutine + RoutinePlan + RoutineSchedule`; ações
diárias materializam a occurrence necessária e acrescentam um adherence event.
As tabelas legadas são preservadas somente para migração auditável e rollback
lógico anterior a novas escritas.

O rollout usa flags persistidas e cutover por usuário. Sync remoto de Smart
Routines permanece independente do cutover local e começa desabilitado até a
migration remota ser confirmada. Consulte `docs/UNIFIED_TREATMENT_ENGINE.md`.

A experiência V1 escreve por uma única intenção de aplicação,
`TreatmentWriteCommand`. O comando cria ou revisa o agregado canônico e nunca
expõe tabelas à apresentação. Mudanças de programação geram revisão futura;
pausa, retomada, conclusão e tombstone preservam planos, ocorrências e eventos
anteriores. As fachadas Medication/Vitamin permanecem apenas como
compatibilidade.

## Home Intelligence Platform

A Home é uma projeção local, read-only e reconstruível. Ela compõe read models
canônicos por meio de `HomeIntelligenceQueryFacade`, sem criar nova fonte
clínica, tabela remota ou mecanismo de sync. Smart Routines permanece a
autoridade de tratamento; Notifications são projeções e não são fonte da
agenda.

Home, Reports, Health Score e BarIA compartilham coverage, freshness, origem e
fórmulas versionadas. BarIA recebe contexto minimizado e o motor de insights é
determinístico, com linguagem não prescritiva. Consulte
`docs/HOME_INTELLIGENCE_PLATFORM.md`.

Feature Flags não fazem parte da Macro 3 e permanecem reservadas à Macro 6.

## Onboarding V1 e entrada canônica

O onboarding possui estado versionado offline-first em Drift, sincronizado pelo
Sync Engine existente e espelhado em `onboarding_states` no Supabase. A entrada
do app é decidida por uma única máquina de estados que combina sessão, perfil,
consentimento legal e progresso canônico. Preferências de acompanhamento ficam
em Settings e a permissão de notificações só é solicitada após opt-in explícito.
Consulte `docs/ONBOARDING_V1_FOUNDATION.md` e `docs/PRODUCT_FREEZE_V1.md`.

## Plataforma de Notificações V1

Preferências globais, por categoria, item e horário são parte sincronizável de
Settings. Permissão do SO, manifest, action inbox e IDs do plugin permanecem
locais ao dispositivo. Smart Routines fornece exclusivamente as projeções de
Tratamento; Appointments e horários explicitamente configurados fornecem as
demais categorias. Um único reconciliador deduplica, atualiza e cancela as
notificações concretas. Consulte `docs/NOTIFICATIONS_V1.md`.

## Fechamento de Tratamento V1

Detalhe, registro PRN e revisão de conflitos reutilizam
`UnifiedTreatmentStore`. PRN cria occurrence `adHocAsNeeded` e event append-only
sem schedule recorrente. Conflitos preservam os events e só são resolvidos por
corrections explícitas que invalidam a versão rejeitada.

## Confiabilidade do Sync — auditoria de 21/07/2026

`SyncManager` captura uma geração de sessão por execução. `SyncEngine` verifica
essa geração antes e depois de cada efeito relevante; respostas, retries e
cursores da conta revogada tornam-se inofensivos. Um novo usuário recebe um
passe serializado próprio, sem compartilhar o Future antigo.

Recuperação de transporte em foreground é um gatilho com debounce, não prova de
internet. Timeout, retry e backoff continuam centralizados no mesmo engine.
Water, Weight, Meals, Appointments, Exams e Bioimpedance usam pull keyset
`(updated_at,id)` em páginas. Os agregados restantes ainda precisam aderir ao
contrato; consulte `docs/SYNC_RELIABILITY_V1.md`.

Não há worker Android periódico nem versão monotônica confirmada pelo servidor.
Esses limites são explícitos e impedem promover o candidato enquanto conflito
por clock e paginação transversal não forem concluídos.
