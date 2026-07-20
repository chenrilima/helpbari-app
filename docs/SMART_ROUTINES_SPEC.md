# Smart Routines — Contrato funcional e arquitetural

Status: proposta aprovada para orientar implementação incremental.  
Escopo: contrato de domínio; não representa implementação existente nem
orientação clínica.  
Última revisão: 2026-07-20.

## 1. Objetivo e princípios

Smart Routines unifica expectativas de tratamento sem confundir cadastro,
agenda, ocorrência e registro de adesão:

```text
SmartRoutine
  └─ RoutinePlan (revisão imutável e vigente)
       └─ RoutineSchedule (regra temporal)
            └─ RoutineOccurrence (expectativa determinística)
                 └─ RoutineAdherenceEvent (fato/auditoria)
```

Princípios obrigatórios:

- Drift continua sendo a fonte local de verdade e o Sync Engine existente é
  reutilizado.
- Expectativas clínicas históricas nunca são reinterpretadas pelo plano atual.
- Ausência de dados não equivale a baixa adesão.
- Notificações do sistema operacional são projeções locais descartáveis.
- Regras de acompanhamento não são recomendações clínicas.
- Toda conversão de prescrição exige revisão humana e vínculo por identidade.
- Eventos clínicos são minimizados, auditáveis e isolados por usuário.

## 2. Auditoria do comportamento atual

### 2.1 Medication e Vitamin

`Medication` e `Vitamin` possuem nome e exatamente um `scheduleTime`.
`Medication` também possui dose textual e observações. Seus logs usam a chave
funcional `userId + entityId + logDate` e os estados `pending`, `taken` e
`skipped`. Atualizar ou restaurar o estado sobrescreve o log diário, sem trilha
de correção, horário real da tomada, janela, atraso, pausa ou reagendamento.

`MedicationUseCases.adherence` e `VitaminUseCases.adherence` removem `pending`
do denominador e calculam `taken / resolvidos`. Não existe expectativa
persistida para um dia sem log; portanto o modelo atual não consegue distinguir
sem registro, futuro, missed, pausa ou período sem cobertura.

Evidências principais:

- `lib/features/medications/domain/entities/medication.dart`
- `lib/features/medications/domain/entities/medication_log.dart`
- `lib/features/medications/domain/usecases/medication_use_cases.dart`
- `lib/features/vitamins/domain/entities/vitamin.dart`
- `lib/features/vitamins/domain/entities/vitamin_log.dart`
- `lib/features/vitamins/domain/usecases/vitamin_use_cases.dart`
- datasources Drift de logs e seus índices únicos por usuário/entidade/data.

### 2.2 Prescrições e Document Intelligence

`MedicalPrescriptionItem` já preserva categoria, dose, unidade, via,
frequência estruturada, múltiplos horários, dias, intervalo, início, término,
duração, instruções, PRN, confidence, confidence por campo, provenance, revisão
e links legados. O parser determinístico reconhece, entre outros, `onceDaily`,
`timesDaily`, `everyHours`, semanal, mensal, contínuo, múltiplos horários,
duração e PRN. Campos de baixa confiança permanecem revisáveis.

A conversão atual em `AddPrescriptionToRoutinePage` é deliberadamente limitada:
usa apenas o primeiro horário, exige um horário para todo item, reduz suplemento
a Vitamin e procura rotina existente pelo nome normalizado. Ela não preserva a
estrutura completa da prescrição e não serve como contrato de Smart Routines.

### 2.3 Notificações e tempo

Medication e Vitamin projetam uma recorrência diária; Appointment projeta uma
notificação pontual. A chave local é `userId:source:entityId`; o ID do plugin é
derivado localmente. Login, sync, resume e Settings reconstroem as projeções;
logout/troca de usuário executa cancelamento global. Taps são filtrados pela
sessão. O timezone IANA do dispositivo é usado, com fallback UTC.

`public.notification_reminders` está descontinuada e não será reativada.

### 2.4 Home, Health Score, Reports e BarIA

Home agrega logs por dia. Sua adesão diária atual divide `taken` por todos os
logs daquele dia, enquanto os use cases e Reports removem `pending`; essa
diferença confirma a necessidade de um agregado único do domínio.

Health Score 2.0 recebe componentes opcionais, remove pesos indisponíveis do
denominador e declara não ser avaliação clínica. Ainda assim, vitaminas e
medicamentos chegam como razões calculadas diretamente de logs.

Reports alterna entre agregados da Home e cálculo próprio, sem conceito de
cobertura ou origem legacy/mixed. BarIA gera insights determinísticos e não
altera tratamentos, mas hoje conta cadastros sem log como “pendentes”, não
ocorrências elegíveis.

### 2.5 Sync e LGPD

O Sync Engine atual faz retry, tombstones e resolução LWW por `updatedAt`.
Medical Prescription sincroniza pai e itens como agregado. Exportação LGPD e
limpeza cobrem Medication, Vitamin, logs, prescrições e Document Intelligence.
Smart Routines deverá entrar nesses mesmos contratos antes de qualquer cutover.

## 3. Glossário normativo

| Conceito | Responsabilidade e representação | Não representa | Persistência | Exemplo |
|---|---|---|---|---|
| **SmartRoutine** | Identidade duradoura e intenção acompanhada ao longo de revisões. Possui proprietário e ciclo de vida. | Dose, frequência ou ocorrência específica. | Persistida. | “Vitamina B12” ao longo de mudanças de dose. |
| **RoutinePlan** | Snapshot imutável e versionado da expectativa: categoria, dose, via, instruções, vigência e schedules. | Estado atual do plugin ou edição mutável do passado. | Persistido. | Revisão 2: 1000 mcg a partir de 10/08. |
| **RoutineSchedule** | Regra temporal pertencente a uma revisão do plano, incluindo timezone, janela e preferências de lembrete. | Notificação concreta ou fato de tomada. | Persistido. | Diariamente às 08:00 em America/Sao_Paulo. |
| **OccurrenceBlueprint** | Intenção local intermediária produzida por rotina, plano e schedule elegíveis. Preserva LocalDate, horário e timezone IANA. | Ocorrência persistida, instante UTC ou ID. | Derivado e não persistido. | Intenção de 20/07 às 08:00 em America/Sao_Paulo. |
| **RoutineOccurrence** | Expectativa individual produzida por plan + schedule para um slot nominal. | Prova de tomada ou notificação. | Derivada por padrão; materializada quando possui evento, exceção ou snapshot. | Dose esperada em 20/07 às 08:00. |
| **RoutineAdherenceEvent** | Fato append-only ou correção referente a uma ocorrência. | Estado sobrescrito do dia ou recomendação clínica. | Persistido. | Taken às 08:12, registrado às 09:00. |
| **RoutinePause** | Intervalo explícito que suspende expectativas de uma rotina/plano. | Cancelamento, exclusão ou simples falta de uso. | Persistido. | Pausa de 20/07 a 25/07. |
| **RoutineCategory** | Classificação `medication`, `vitamin`, `supplement`, `other`, versionada no plano. | Forma da agenda ou inferência clínica. | Persistida no plano. | `supplement`. |
| **RoutineStatus** | Ciclo funcional da rotina: active, paused, completed, canceled, archived. | Tombstone ou status de uma ocorrência. | Persistido. | Tratamento concluído. |
| **ScheduleRule** | União tipada que descreve como slots são calculados. | Texto livre como única regra. | Persistida. | `specificWeekdays` seg/qua/sex às 08:00. |
| **OccurrenceWindow** | Intervalo de acompanhamento `[windowStartsAt, windowEndsAt)` associado ao alvo efetivo. | Janela clínica segura para uso do produto. | Regra persistida no schedule; instantes derivados/materializados. | 08:00–20:00, on-time até 08:30. |
| **Expected dose** | Quantidade/unidade esperada segundo a revisão do plano no slot. | Confirmação do que foi realmente tomado. | Snapshot na ocorrência materializada/evento. | 20 mg. |
| **Taken on time** | Ocorrência com evento taken cujo `occurredAt` está entre início da janela e limite on-time, inclusivos. | Garantia de eficácia clínica. | Derivado. | Alvo 08:00, tomada 08:20. |
| **Taken late** | Taken após o limite on-time e antes de `windowEndsAt`. | Missed ou orientação para tomar atrasado. | Derivado. | Tomada 09:10 dentro da janela. |
| **Skipped** | Decisão explícita do usuário de não cumprir uma ocorrência elegível. | Ausência de registro. | Evento persistido. | “Ignorar esta ocorrência”. |
| **Missed** | Janela encerrada sem evento resolutivo em ocorrência elegível. | Evento automático ou skipped. | Derivado; opcional em snapshot agregado. | 20:00 passou sem taken/skipped. |
| **Rescheduled** | Exceção auditável que mantém o alvo original e define novo alvo/janela para a mesma obrigação. | Edição destrutiva do schedule. | Evento/exceção persistida. | 08:00 reagendado para 10:00. |
| **Canceled occurrence** | Exclusão explícita e excepcional de uma obrigação individual. | Cancelar a rotina inteira. | Evento persistido; fora do denominador. | Dose cancelada por erro de agenda. |
| **Paused occurrence** | Slot que cairia integralmente em pausa efetiva. | Missed ou canceled. | Derivado da pausa; materializado se necessário para auditoria. | Slot de 22/07 durante pausa. |
| **Not applicable** | Ocorrência excluída explicitamente por correção de aplicabilidade, com motivo auditável. | Falta de dados. | Evento persistido; fora do denominador. | Expectativa criada por erro de importação. |
| **PRN / as needed** | Plano sem obrigação recorrente; cada uso cria ocorrência ad hoc. | Frequência obrigatória, missed ou denominador. | Regra persistida; ocorrência/evento quando usado. | Analgésico usado às 14:00 quando necessário. |
| **Continuous use** | Declaração explícita de uso sem término planejado. | Ausência acidental de `effectiveUntil`. | Persistida como modo de duração. | Uso contínuo confirmado na revisão. |
| **Unknown duration** | O término não foi informado ou não pôde ser confirmado. | Uso contínuo. | Persistida como modo distinto. | Receita sem duração legível. |
| **Adherence** | Proporção de taken válido entre ocorrências elegíveis encerradas. | Avaliação médica, cobertura ou qualidade do tratamento. | Derivada/agregada. | 8 taken de 10 elegíveis = 80%. |
| **On-time adherence** | Taken on time sobre ocorrências elegíveis encerradas. | Adesão geral. | Derivada/agregada. | 6 no horário de 10 = 60%. |
| **Data coverage** | Confiança de que as expectativas do período são conhecidas e avaliáveis. | Adesão. | Derivada, com snapshots opcionais. | Período mixed com 40% conhecido. |
| **Plan revision** | Número monotônico e identidade imutável de um RoutinePlan. | `updatedAt` ou edição in-place. | Persistida. | planId P2, revision 2. |
| **Business timestamp** | Momento do fato no domínio (`occurredAt`, `scheduledFor`, início da pausa). | Momento de upload. | Persistido quando o fato existe. | Tomada às 08:12 offline. |
| **Sync timestamp** | Momento técnico (`createdAt`, `updatedAt`, cursor, tentativa) usado por sync. | Prova do momento clínico. | Persistido tecnicamente. | Upload às 15:00. |

## 4. Contrato funcional

### 4.1 Categoria

Categorias iniciais: `medication`, `vitamin`, `supplement`, `other`. A categoria
nunca seleciona a estrutura de agenda. Alterá-la após início cria nova revisão
de plano, porque relatórios históricos devem manter a classificação vigente em
cada ocorrência. Correção antes de qualquer ocorrência/evento pode substituir
um draft ainda não ativado.

### 4.2 Status da rotina

| Status | Novas ocorrências | Reversibilidade e efeito |
|---|---|---|
| active | Sim, dentro do plano vigente. | Pode pausar, concluir, cancelar ou arquivar. |
| paused | Não durante pausas efetivas. | Retomada explícita volta a active; passado não é recalculado. |
| completed | Não após `completedAt`. | Reinício cria nova revisão/plano; histórico permanece concluído. |
| canceled | Não após `canceledAt`. | Reativação excepcional cria nova revisão e registra motivo. |
| archived | Não. | Estado terminal de organização no V1; retomada futura exige duplicação ou nova rotina. |

`completed` significa fim esperado do tratamento; `canceled`, interrupção antes
do fim; `archived`, ocultação organizacional terminal no V1. Arquivar preserva
todo o histórico e não permite restauração funcional. `deletedAt` é apenas
tombstone e nunca substitui status funcional.

### 4.3 Vigência e duração

- `effectiveFrom` é uma data clínica local obrigatória para ativar um plano. Se desconhecido na
  importação, usa-se o início de cobertura conhecido, marcado como estimado; o
  período anterior permanece desconhecido.
- `effectiveUntil` é uma data clínica local inclusiva e opcional conforme
  `durationMode`. Não representa meia-noite nem um instante absoluto.
- `activatedAt` e `replacedAt` são instantes operacionais e delimitam o
  intervalo semiaberto `[activatedAt, replacedAt)`. A futura resolução IANA
  converterá o dia posterior a `effectiveUntil` no limite operacional exclusivo.
- `durationMode` é `bounded`, `continuous`, `unknown` ou `singleDose`.
- Ausência de término com `unknown` não pode ser inferida como continuous.
- Plano futuro não produz ocorrências antes de `effectiveFrom`.
- Encerrar antecipadamente fecha a revisão no instante explícito e não apaga
  ocorrências encerradas.

### 4.4 Versionamento

Criam nova revisão: categoria, dose, unidade, via, frequência, horários, dias,
intervalos, timezone, janela, início/término, duração, instruções clínicas, PRN,
expected dose e regras de aplicabilidade. A revisão anterior recebe fim de
vigência sem ser reescrita.

Podem atualizar SmartRoutine sem nova revisão: nome de exibição não clínico,
observações pessoais, ícone, cor, ordem e preferências puramente visuais.

Revisões ativadas são imutáveis. Correções retroativas criam revisão corretiva
com motivo e faixa explícita; nunca reinterpretam silenciosamente eventos.

### 4.5 Frequências

`ScheduleRule` é uma união tipada:

- `dailyAtTimes`: um ou mais horários diários;
- `specificWeekdaysAtTimes`: dias ISO 1–7 e horários;
- `singleDose`: um instante;
- `timesPerDay`: quantidade, exigindo horários confirmados antes de ativar;
- `everyHours`, `everyDays`, `weekly`, `monthly`: estruturadas, inicialmente
  desabilitáveis por capability;
- `freeTextUnstructured`: preserva instrução, mas não gera obrigação até revisão;
- `prn`: não gera slots recorrentes.

Horários são normalizados, ordenados e únicos. Regras inválidas ou parcialmente
extraídas permanecem draft/requiresReview.

`everyDays` possui `anchorDate` clínica obrigatória e persistida na própria
regra. Para `monthly`, um mês sem o dia configurado não produz slot; o V1 não
antecipa para o último dia nem posterga para o mês seguinte.

### 4.6 Ocorrências e identidade

Uma ocorrência existe logicamente quando um schedule ativo produz um slot
dentro da vigência, fora de pausa e respeitando status/revisão. Por padrão ela
é derivada sob demanda.

Antes da resolução de timezone e identidade, o domínio produz um
`OccurrenceBlueprint` não persistido. Ele contém `routineId`, `planId`,
`scheduleId`, data clínica, horário local, timezone IANA, tipo da regra e uma
`sequence` baseada em zero, atribuída após ordenar e deduplicar os horários do
schedule na data. Não contém UUID, `RoutineOccurrenceId`, instante UTC, janela,
status de adesão ou metadados de sync.

Blueprints são ordenados por data clínica, horário local, `displayOrder`,
`scheduleId` e `sequence`. A deduplicação usa a identidade lógica do mesmo
schedule/data/horário/sequence; schedules distintos no mesmo horário continuam
produzindo expectativas distintas. `everyHours` não participa da geração por
data até existir resolução temporal por instante. Intervalos clínicos usam
`[startDateInclusive, endDateExclusive)` e limite máximo explícito do chamador.

ID determinístico: UUIDv5 de namespace versionado e chave canônica
`userId|planId|planRevision|scheduleId|localDate|slotKey`. O algoritmo e sua
versão fazem parte do contrato. `slotKey` distingue horários do mesmo dia; PRN
usa UUID próprio criado no dispositivo e preservado no sync.

Materializar somente quando houver evento, reagendamento, cancelamento,
notApplicable, snapshot fechado ou necessidade explícita de auditoria. A
projeção de notificações não materializa ocorrências no domínio.

Consultas podem derivar no máximo 366 dias por chamada. A janela operacional
recomendada é 31 dias passados e 31 futuros; notificações usam no máximo 14 dias
futuros. Ocorrências já materializadas/eventos não expiram.

Uma mudança de plano afeta apenas slots a partir da nova vigência. Ocorrências
do plano anterior com evento ou janela encerrada continuam ligadas à revisão
original.

### 4.7 Janela de tomada

A janela é configuração de acompanhamento copiada para cada schedule:

- `windowStartsAt = scheduledFor - earlyTolerance`;
- `onTimeEndsAt = scheduledFor + onTimeTolerance`;
- `windowEndsAt = min(scheduledFor + lateTolerance, próximo slot)`;
- intervalo operacional: `[windowStartsAt, windowEndsAt)`;
- V1 padrão: `earlyTolerance = 0`, `onTimeTolerance = 30 minutos`,
  `lateTolerance = 12 horas`, sempre limitado pelo próximo slot.

Esses padrões não indicam segurança ou eficácia clínica. A interface deve usar
“janela de acompanhamento” e permitir configuração por schedule; mudanças
criam revisão. `takenOnTime` inclui os limites inicial e on-time. `takenLate` é
posterior ao limite on-time e anterior ao fim. Após o fim, sem resolução, o
estado é missed.

### 4.8 Missed e clock

Missed é derivado quando `now` confiável está em ou após `windowEndsAt` e não há
evento resolutivo. Não cria evento automático nem writes diários. Agregados
podem materializar contagens com versão da regra e instante de cálculo.

Derivação usa instantes UTC calculados a partir do timezone IANA do schedule.
Clock injetável é obrigatório nos serviços de domínio. Mudança no relógio do
cliente não altera eventos já sincronizados; discrepâncias relevantes reduzem
confiança/cobertura em vez de inventar missed.

### 4.9 Taken e correções

- `occurredAt`: momento declarado da tomada; business timestamp.
- `recordedAt`: momento em que o app recebeu o registro; imutável.
- `createdAt/updatedAt`: timestamps técnicos de sync.
- Registro retroativo é permitido dentro do período conhecido, marcado como
  retroativo quando `recordedAt > occurredAt` por tolerância configurada.
- `occurredAt` futuro além de pequena tolerância técnica de relógio é inválido.
- Uma ocorrência possui no máximo uma resolução efetiva, mas todos os eventos
  conflitantes permanecem auditáveis.
- Alterar horário cria evento `correction` que referencia o evento anterior;
  não sobrescreve o original.
- Dois taken independentes para a mesma ocorrência produzem conflito explícito
  para revisão, não duplicidade silenciosa.
- Dose real e tomada parcial ficam modeladas, mas desabilitadas no V1; quando
  habilitadas não podem transformar automaticamente parcial em aderente.

### 4.10 Skipped

Skipped exige ação explícita, pode ter motivo opcional e conta como ocorrência
elegível não tomada. Missed é ausência após o fim da janela. Desfazer skipped
cria correction/reversal referenciando o evento anterior. Toda correção preserva
autor, deviceId, business timestamp e recordedAt.

### 4.11 Reagendamento

Reagendar cria evento com `originalScheduledFor`, `rescheduledFor`, janela nova,
motivo opcional e referência ao reagendamento anterior. A obrigação e o
denominador continuam únicos. Adesão on-time é julgada contra o alvo efetivo
mais recente, enquanto Reports preserva e sinaliza o alvo original.

V1 permite até três reagendamentos efetivos por ocorrência para evitar cadeias
acidentais; correções não contam nesse limite. Não é permitido reagendar após o
fim da janela efetiva: usa-se registro retroativo/correção ou cancelamento
auditável. Offline, todos os eventos são preservados; cadeias concorrentes são
marcadas para revisão, sem LWW destrutivo. A notificação original é cancelada e
a projeção local usa a chave da ocorrência com revisão da projeção.

### 4.12 Pausas

Pausa possui `startsAt`, `endsAt?`, motivo opcional e escopo de rotina/plano.
Sem término, permanece aberta. Retomada fecha a pausa; não apaga o intervalo.
Pausas sobrepostas do mesmo escopo são normalizadas como união para derivação,
mas os registros originais permanecem auditáveis.

Slots integralmente dentro da pausa são `pausedOccurrence`, não notificam e não
entram no denominador. Ocorrência já iniciada quando a pausa começa mantém sua
expectativa, salvo cancelamento explícito. Edição retroativa que afetaria
ocorrências encerradas exige motivo e recalcula agregados com nova versão, sem
apagar eventos.

### 4.13 PRN

PRN não exige horário, não produz obrigação recorrente, missed ou denominador.
Uso espontâneo cria ocorrência ad hoc e evento taken em uma transação lógica.
Lembrete opcional é apenas um prompt local e não cria expectativa. Motivo ou
sintoma é opcional, sensível e inicialmente texto minimizado; o app não sugere
quando usar, dose, limite ou interrupção.

### 4.14 Cancelamento, conclusão, arquivo e exclusão

- Cancelar ocorrência: exceção individual, fora do denominador.
- Cancelar rotina: encerra novas expectativas por interrupção antecipada.
- Concluir: registra término esperado do tratamento.
- Arquivar: oculta sem alterar fatos clínicos.
- Tombstone: exclusão técnica sincronizável; preserva apenas o necessário até
  propagação e não deve ser usado como status.

Histórico encerrado e eventos permanecem até exclusão LGPD.

### 4.15 Adesão e cobertura

Ocorrências elegíveis encerradas incluem taken on time, taken late, skipped e
missed. Excluem futuras, janela aberta, canceled, paused, notApplicable e PRN.

```text
adherence = (takenOnTime + takenLate) / eligibleClosedOccurrences
onTimeAdherence = takenOnTime / eligibleClosedOccurrences
```

Skipped e missed permanecem no denominador; taken late conta apenas na adesão
geral. Resultado sem denominador é `unavailable`, nunca 0%. Período anterior à
vigência não entra. Plano com início desconhecido só participa no intervalo de
cobertura comprovada. Logs legados só contribuem onde uma expectativa migrada
foi materializada; não se inventam obrigações anteriores.

Adesão deve carregar contagens, período, cobertura, versão do cálculo e aviso
“indicador de acompanhamento, não avaliação médica”.

Data coverage é métrica separada:

```text
coverage = evaluableExpectedSlots / potentiallyExpectedSlots
```

Ela possui estados `complete`, `partial`, `unknown`, `notApplicable`. Quando o
denominador potencial não puder ser estabelecido (por exemplo, legado sem
início), coverage é unknown, não 0%. Agregados mixed informam separadamente
intervalos smart, legacy conhecido e lacunas.

### 4.16 Timezone e DST

V1 usa timezone IANA fixo no schedule, capturado e confirmado na ativação. O
dispositivo pode estar em outra zona; UI mostra horário local convertido e a
zona do plano quando diferirem. Viagem não muda silenciosamente a expectativa;
alterar a zona exige nova revisão.

Regras determinísticas:

- horários persistidos como hora/minuto local + `timeZoneId`; instantes de
  ocorrência/evento são persistidos em UTC;
- horário inexistente no avanço DST move para o primeiro instante válido após
  o gap e marca `dstAdjusted`;
- horário ambíguo no retorno DST escolhe o primeiro offset e gera um único slot;
- horários duplicados normalizados geram um único slot;
- eventos preservam também offset/timezone observado para auditoria;
- notification restore recalcula somente projeções futuras não materializadas.

Modo `floatingLocal` fica modelado, mas desabilitado até regras de viagem e UX
serem validadas.

### 4.17 Contrato de notificações futuras

Preferências (`enabled`, offsets permitidos, snooze/follow-up capabilities)
pertencem ao RoutineSchedule. Projeções concretas permanecem locais. Chaves:
schedule para prompts recorrentes sem ocorrência e occurrence para obrigações
na janela móvel. Nenhum ID de plugin sincroniza.

Restore ocorre após login/sync/resume/configuração, deriva até 14 dias futuros,
deduplica, cancela projeções obsoletas e respeita sessão, permissões e timezone.
Snooze é exceção local auditável quando tiver impacto na expectativa; follow-up
não cria evento de adesão. Lock screen usa texto genérico por padrão. A tabela
`notification_reminders` continua descontinuada.

### 4.18 Prescriptions → Smart Routines

- Um item confirmado pode originar no máximo uma SmartRoutine por vínculo.
- Vínculo usa `prescriptionItemId`/`routineId`; nome serve apenas para sugerir
  possível duplicata, nunca vincular ou atualizar automaticamente.
- Revisão humana confirma categoria, dose, via, frequência, todos os horários,
  dias, vigência, PRN, timezone e campos incertos.
- Provenance e confidence são copiados por campo para o draft do plano.
- Campo não reconhecido permanece em instruções/provenance e bloqueia ativação
  apenas quando necessário para gerar expectativa segura.
- PRN não exige horário. Múltiplos horários são preservados integralmente.
- Item com possível rotina existente oferece: vincular sem alterar, criar nova,
  ou criar nova revisão; nenhuma opção é automática.
- Alterar a prescrição depois não altera a rotina: cria proposta de revisão que
  exige confirmação.

### 4.19 Migração de Medication e Vitamin

Migração é local-first, idempotente, por usuário e sem apagar legado:

- `routineId`, `planId` e `scheduleId` determinísticos por namespace + tipo + ID
  legado; IDs originais ficam em `legacySourceId`.
- categoria vem da feature de origem; suplemento legado em Vitamin exige revisão
  se não puder ser distinguido.
- plan revision 1 usa a data clínica local de `createdAt` quando confiável; caso
  contrário, a primeira data de cobertura conhecida, marcada estimada.
- uma regra `dailyAtTimes` recebe o único horário atual.
- ausência de endDate vira `durationMode = unknown`, nunca continuous.
- cada log existente materializa somente a ocorrência daquele dia e seu evento;
  `pending` vira cobertura conhecida sem resolução, não missed automático.
- dias sem log anteriores ao cutover permanecem coverage unknown e não geram
  ocorrências/missed retroativos.
- logs válidos preservam identidade/provenance; deduplicação usa usuário + origem
  + entityId + data e nunca somente nome.
- tombstones migram como tombstones e não reativam rotinas.
- durante coexistência, uma origem é dona de cada período/evento para impedir
  dupla contagem.

### 4.20 Sync e conflitos

- SmartRoutine, RoutineSchedule, Pause e metadados mutáveis podem usar LWW pelo
  `updatedAt` existente, com isolamento por usuário.
- RoutinePlan ativado é imutável/versionado; revisão nova não disputa via LWW
  com revisão anterior.
- AdherenceEvent é append-only, UUID estável, idempotente e sincronizado pelo
  Sync Engine atual. Correction referencia `supersedesEventId`.
- Reschedule preserva original; cadeias concorrentes não são achatadas.
- Tombstones propagam normalmente.
- Filho recebido sem pai é adiado/quarentenado para retry; nunca reassociado por
  nome ou usuário diferente.
- Eventos offline simultâneos para a mesma occurrence são todos preservados. Se
  forem semanticamente incompatíveis, o agregado marca conflict/requiresReview.
- Duplicata exata por eventId é idempotente; duas IDs diferentes não são
  silenciosamente mescladas.
- Business timestamp não é substituído por `updatedAt`; clock suspeito reduz
  confiança e exige revisão.

### 4.21 LGPD

Antes do release, exportação, `delete_my_data()`, limpeza Drift e testes devem
cobrir routines, todas as revisões, schedules, pausas, ocorrências materializadas,
eventos, provenance e vínculos com prescriptions. Ordem de exclusão: eventos e
ocorrências, schedules/pausas/planos, routine.

Notificações locais são canceladas no logout/exclusão; não há arquivo de
notificação a exportar. Campos de motivo/sintoma, dose real, instruções,
provenance e timestamps são dados de saúde. Logs técnicos não incluem nomes,
doses, motivos, IDs de entidade, payloads ou documentos. Retenção de tombstone
deve ser mínima e compatível com propagação da exclusão.

### 4.22 Contratos de consumo

- **Home:** recebe ocorrências atuais agregadas (`due`, `open`, `resolved`), não
  conta cadastros. PRN sem uso não aparece como pendência.
- **Health Score:** recebe agregado versionado de adesão + cobertura do domínio;
  não consulta eventos/logs crus. Cobertura insuficiente remove/reduz o
  componente conforme política explícita, nunca vira zero automático.
- **Reports:** declara `legacy`, `smartRoutines` ou `mixed`, mostra contagens,
  fórmulas, coverage e não duplica eventos migrados.
- **BarIA:** consome apenas agregados determinísticos. Pode apontar ocorrência
  aberta ou padrão com cobertura suficiente; não altera dose, recomenda tomar,
  interromper ou compensar. Falta de dados gera insight de cobertura, não baixa
  adesão.

## 5. Matriz de capacidades

| Capacidade | V1 | Estado | Justificativa |
|---|---:|---|---|
| Categorias iniciais | Sim | Suportada | Necessária para coexistência e Reports. |
| Planos versionados | Sim | Suportada | Evita reinterpretar histórico. |
| Diário com horários | Sim | Suportada | Cobre legado e maior valor inicial. |
| Múltiplos horários | Sim | Suportada | Prescriptions já preserva essa informação. |
| Dias específicos | Sim | Suportada | Determinístico e comum. |
| Dose única | Sim | Suportada | Regra simples e necessária. |
| Início/término | Sim | Suportada | Base de elegibilidade. |
| Continuous explícito/unknown | Sim | Suportada | Evita inferência perigosa. |
| Pausas | Sim | Suportada | Necessária para denominador correto. |
| PRN ad hoc | Sim | Suportada | Não pode ser forçado ao modelo diário. |
| Taken/skipped/corrections | Sim | Suportada | Núcleo auditável de adesão. |
| TakenLate/missed derivados | Sim | Suportada | Evita writes automáticos. |
| Reagendamento auditável | Sim | Suportada | Preserva expectativa original. |
| Adesão + cobertura | Sim | Suportada | Consumidores dependem da distinção. |
| Integração Prescriptions | Sim | Suportada | Sem perda e com revisão humana. |
| `timesPerDay` sem horários | Não | Modelada/desabilitada | Não gera slots determinísticos; revisão deve fornecer horários. |
| A cada N horas | Não | Modelada/desabilitada | Exige âncora e regras DST validadas. |
| A cada N dias | Não | Modelada/desabilitada | Exige âncora/ciclo bem definido. |
| Semanal simples | Não | Modelada/desabilitada | Pode ser representada por weekdays no V1. |
| Mensal | Não | Modelada/desabilitada | Dias inexistentes e fim de mês elevam risco. |
| Frequência livre | Parcial | Preservada sem ativação | Informação não é descartada, mas não gera expectativa. |
| Floating local timezone | Não | Modelada/desabilitada | Viagem precisa de UX específica. |
| Offsets avançados | Não | Adiada | Notifications V2. |
| Snooze/follow-up | Não | Adiada | Exigem contrato de exceção e UX. |
| Dose realmente tomada | Não | Modelada/desabilitada | Campo sensível e sem uso analítico inicial. |
| Tomada parcial | Não | Modelada/desabilitada | Semântica clínica exige validação. |
| Motivo/sintoma estruturado | Não | Modelado/desabilitado | Minimização e segurança. |

## 6. Cenários conceituais Given/When/Then

| # | Given | When | Then |
|---:|---|---|---|
| 1 | Dose diária às 08:00, janela aberta | Taken às 08:20 | Resolvida como takenOnTime; entra no numerador geral e on-time. |
| 2 | Mesma dose | Taken às 09:00 dentro da janela | Resolvida como takenLate; só numerador geral. |
| 3 | Ocorrência elegível sem evento | Clock alcança windowEndsAt | Missed derivado, sem write automático. |
| 4 | Ocorrência aberta | Usuário escolhe skipped | Evento explícito; permanece no denominador e fora dos numeradores. |
| 5 | Dois slots 08:00 e 20:00 | Ambos taken | Duas occurrences/IDs e duas resoluções, sem colisão diária. |
| 6 | Regra seg/qua/sex | Data é terça | Nenhuma ocorrência é gerada. |
| 7 | Plano inicia amanhã | Consulta hoje | Nenhuma pendência ou denominador hoje. |
| 8 | Plano terminou ontem | Consulta hoje | Nenhuma ocorrência nova; histórico permanece. |
| 9 | Pausa cobre o slot | Agregado é calculado | pausedOccurrence, sem notificação e fora do denominador. |
| 10 | Plano PRN | Usuário registra uso | Cria occurrence ad hoc + taken, fora da adesão recorrente. |
| 11 | Plano PRN sem uso | Período encerra | Não cria occurrence, missed ou denominador. |
| 12 | Slot 08:00 aberto | Reagendado para 10:00 e tomado 10:10 | Original preservado; uma obrigação, on-time contra alvo efetivo. |
| 13 | Plano ativo 20 mg | Dose muda para 40 mg amanhã | Nova revisão; ocorrências antigas mantêm 20 mg. |
| 14 | Schedule America/Sao_Paulo; usuário viaja | Device muda de zona | Expectativa mantém zona do plano; UI exibe conversão. |
| 15 | Horário cai em gap DST | Ocorrência é derivada | Move ao primeiro instante válido e marca dstAdjusted. |
| 16 | Device offline | Taken é registrado e depois sincroniza | Business timestamp/ID permanecem; Sync Engine envia depois. |
| 17 | Dois devices registram taken diferente | Sync converge | Ambos eventos preservados; conflito explícito para revisão. |
| 18 | Medication legado com um horário/logs | Migração roda duas vezes | IDs determinísticos, uma rotina/plano/schedule; sem duplicação. |
| 19 | Vitamin legado | Migração roda | Categoria vitamin, horário único, duration unknown. |
| 20 | Período legado sem logs | Relatório mixed é gerado | Coverage unknown; não produz missed nem adesão baixa. |
| 21 | Item prescrito com 08:00 e 16:00 | Usuário confirma conversão | Ambos horários viram schedules/slots; nenhum é descartado. |
| 22 | Item PRN sem horário | Usuário confirma | Rotina PRN é válida sem selecionar horário. |
| 23 | Usuário solicita exclusão LGPD | Fluxo conclui | Eventos/occurrences/schedules/plans/routine removidos e projeções locais canceladas. |
| 24 | Período contém legado e Smart Routines | Report é gerado | Origem `mixed`, períodos/coverage separados, eventos migrados contados uma vez. |
| 25 | BarIA recebe coverage insuficiente | Insights são calculados | Não afirma baixa adesão; pode informar dados insuficientes. |

## 7. Revisão de segurança

Podem parecer orientação clínica e exigem linguagem de acompanhamento:

- janelas on-time/late, missed, alertas, limites de reagendamento e padrões de
  adesão;
- nunca escrever “é seguro tomar”, “tome agora”, “compense”, “interrompa” ou
  “ajuste a dose” sem conteúdo clínico aprovado fora deste domínio;
- telas e relatórios exibem disclaimer de que adesão/Health Score não são
  avaliação médica.

Dados sensíveis: nome, dose, via, instruções, profissional, motivo/sintoma,
occurredAt, skipped, PRN, provenance e vínculo de prescrição. Lock screen deve
usar “Você tem um lembrete do HelpBari” por padrão; conteúdo detalhado exige
opt-in local. Logs técnicos não incluem esses campos, IDs, payload completo,
OCR, documento ou métricas individuais.

## 8. Decisões abertas

| ID | Decisão aberta | Bloqueia |
|---|---|---|
| OPEN-001 | Confirmar com produto se lateTolerance padrão de 12h deve variar por categoria sem sugerir regra clínica. | UX final da janela, não o modelo. |
| OPEN-002 | Definir UX de conflito entre eventos simultâneos e quem pode resolvê-lo. | Sync de events em produção. |
| OPEN-003 | Validar namespace/algoritmo UUIDv5 e versão canônica com testes multiplataforma. | Persistência de occurrences. |
| OPEN-004 | Definir política de retenção mínima de tombstones após exclusão propagada. | LGPD/go-live. |
| OPEN-005 | Definir limiar mínimo de coverage para Health Score/BarIA com produto e segurança clínica. | Integração analítica. |
| OPEN-006 | Auditar qualidade real de `createdAt` legado antes de escolher effectiveFrom em massa. | Cutover. |
| OPEN-007 | Decidir se limite de três reagendamentos é UX rígida ou aviso com confirmação. | Reagendamento V1. |

## 9. Alternativas rejeitadas

- Um único modelo mutável sem RoutinePlan: reinterpreta histórico.
- Um log diário por rotina: não representa múltiplos horários.
- Missed como write automático: amplifica sync e transforma ausência de dados em
  fatos artificiais.
- PRN recorrente: cria obrigações inexistentes.
- Vincular prescrição somente por nome: risco de alterar rotina errada.
- Sincronizar IDs/notificações concretas: mistura estado específico do device
  com regra de negócio e reativa uma segunda fonte da verdade.
- LWW para adherence events incompatíveis: perde fatos e auditoria.
- Ausência de endDate igual a continuous: inferência não sustentada.
- Migrar todos os dias passados como missed: fabrica baixa adesão.
- Usar string livre como única frequência: impede geração determinística.

## 10. Impacto técnico esperado

Novas camadas futuras deverão incluir domínio puro para geração de slots,
elegibilidade, resolução de eventos, adesão e coverage; persistência Drift;
repositórios sync no mecanismo existente; export/cleanup LGPD; projetor de
notificações; adaptadores de consumo. Medication/Vitamin permanecerão em
coexistência até cutover idempotente e observável.

Principais riscos: explosão combinatória de regras, DST, concorrência de events,
perda de provenance, dupla contagem mixed, inferência clínica na UX e migração
com cobertura falsa. Cada etapa deve permanecer atrás de capability/feature
flag até invariantes e métricas de cutover serem verificadas.

## 11. Ordem recomendada de implementação

1. Value objects/enums puros, clock e canonicalização de timezone/UUID, sem IO.
2. Routine + Plan versionado e máquina de status, com testes de invariantes.
3. ScheduleRule V1 e gerador determinístico de occurrences.
4. Pausas, janelas e resolução derivada on-time/late/missed.
5. Eventos append-only, corrections, skipped, PRN e reschedule.
6. Agregador único de adesão/coverage.
7. Drift, DAOs e migrations locais em shadow mode.
8. Supabase/RLS/migrations e integração ao Sync Engine existente.
9. LGPD export/delete/cleanup antes de dados reais.
10. Adaptador Prescriptions com revisão humana e provenance.
11. Migração Medication/Vitamin idempotente e coexistência `mixed`.
12. Notifications V2 como projeção local em janela móvel.
13. Home sobre occurrences; depois Reports; depois Health Score; por fim BarIA.
14. Cutover gradual por flag, auditoria de duplicação/cobertura e retirada
    separada do legado.

## 12. Decision Log

| ID | Contexto | Decisão | Justificativa / consequências | Status |
|---|---|---|---|---|
| SR-001 | Histórico muda ao editar tratamento. | Plano ativado é imutável e versionado. | Mais entidades, porém histórico estável. | Aceita |
| SR-002 | Agenda e fatos se sobrepunham no legado. | Separar Routine, Plan, Schedule, Occurrence e Event. | Permite múltiplos slots e auditoria. | Aceita |
| SR-003 | Missed poderia gerar writes em massa. | Missed é derivado. | Menos sync; cálculo precisa de clock/regra versionada. | Aceita |
| SR-004 | PRN não é obrigação. | PRN não gera denominador/missed; uso é ad hoc. | Exige fluxo próprio sem horário obrigatório. | Aceita |
| SR-005 | Pausas distorcem adesão. | Slots pausados ficam fora do denominador. | Pausas precisam ser persistidas/auditadas. | Aceita |
| SR-006 | Ausência de dados parecia baixa adesão. | Coverage é métrica separada; sem denominador = unavailable. | Consumidores devem exibir incerteza. | Aceita |
| SR-007 | Alteração de horário/dose poderia mudar passado. | Alterações de expectativa criam plan revision. | Revisões adicionais e cutover explícito. | Aceita |
| SR-008 | Notificações variam por dispositivo. | Concretas são projeções locais; regras no schedule. | Restore obrigatório; sem `notification_reminders`. | Aceita |
| SR-009 | Identidade de slots deve convergir offline. | UUIDv5 canônico para recorrentes; UUID estável para PRN. | Algoritmo vira contrato versionado. | Aceita |
| SR-010 | DST/viagem podem duplicar slots. | V1 usa timezone IANA fixo, gap avança e overlap escolhe primeiro offset. | Determinístico; floating local adiado. | Aceita |
| SR-011 | Reagendamento apagava expectativa. | Preservar original e cadeia de exceções. | Relatórios distinguem alvo original/efetivo. | Aceita |
| SR-012 | Eventos concorrentes não cabem em LWW. | Events append-only; incompatibilidade requer revisão. | Convergência sem perda, UX de conflito pendente. | Aceita |
| SR-013 | Prescrição contém estrutura mais rica que legado. | Conversão 1 item→1 routine, revisão humana, vínculo por ID e provenance. | Tela atual não é reutilizável como regra final. | Aceita |
| SR-014 | Legado não conhece expectativas ausentes. | Migrar apenas cobertura comprovada; nunca missed retroativo. | Métricas mixed/unknown durante transição. | Aceita |
| SR-015 | Consumidores calculam adesão de modos diferentes. | Domínio fornece agregado único versionado. | Home/Score/Reports/BarIA deixam de ler logs crus. | Aceita |
| SR-016 | Categoria pode mudar relatórios passados. | Categoria faz parte da revisão do plano. | Mudança pós-ativação cria revisão. | Aceita |
| SR-017 | Janela pode parecer orientação clínica. | É configuração de acompanhamento com disclaimer e defaults copiáveis por schedule. | UX deve evitar linguagem prescritiva. | Aceita |
| SR-018 | Exclusão técnica era confundida com estado. | Tombstone nunca substitui status funcional. | Sync e domínio mantêm semânticas separadas. | Aceita |
