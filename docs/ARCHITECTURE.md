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

- `Medication`, `Vitamin` e `Appointment`, para horário, data e estado;
- `Settings`, para habilitar ou desabilitar cada categoria de lembrete;
- Drift, como fonte local offline-first dessas entidades;
- Supabase e o Sync Engine, para sincronizar entidades e preferências.

O `NotificationScheduler` recebe projeções produzidas pelos serviços de cada
feature. Ele não é repositório de domínio e não participa do Sync Engine. A
chave local combina `userId`, tipo da entidade e `entityId`; o ID inteiro usado
pelo plugin é derivado dessa chave e nunca é sincronizado.

## Restore, dispositivo e timezone

Após login, sincronização inicial, retorno do app e alteração de configurações,
o app relê Settings e as entidades atuais, cancela as projeções anteriores e
reconstrói o conjunto local de forma idempotente. Logout e troca de usuário
cancelam todas as notificações pendentes antes de ativar a próxima conta. Taps
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

Smart Routines deverá introduzir `RoutinePlan` e `RoutineSchedule` como regras
sincronizáveis, incluindo múltiplos horários, vigência, pausas, PRN e offsets.
Notifications V2 deverá projetar localmente uma janela móvel de ocorrências a
partir desses schedules. Ocorrências, IDs do plugin, permissões e estado do
sistema operacional continuarão locais. A transição deve substituir os
projetores por feature gradualmente, sem reativar `notification_reminders`.
