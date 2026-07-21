# Home Intelligence Platform — Macro 3

## Papel arquitetural

A Home é uma projeção operacional local e reconstruível. Ela não é fonte
clínica, não possui persistência remota própria e não escreve diretamente em
Drift, Supabase, logs de tratamento ou plugins de notification.

`HomeIntelligenceQueryFacade` compõe read models a partir dos contratos dos
domínios. Drift continua como fonte local de verdade e Smart Routines continua
como autoridade de tratamento. Notifications são projeções de occurrences e
nunca são consultadas para descobrir itens da agenda.

## Read models

O snapshot raiz é `TodayDashboardReadModel`. Seus blocos independentes são:

- `NextActionsReadModel`;
- `AgendaReadModel` e `AgendaItemReadModel`;
- `TreatmentSummaryReadModel`;
- `ProgressSummaryReadModel`;
- `QuickStatsReadModel`;
- `QuickActionsReadModel`;
- `InsightFeedReadModel`;
- `ProgressTrendReadModel`.

Todo bloco declara `HomeSectionStatus`, `FreshnessReadModel` e, quando
aplicável, `CoverageReadModel`. Os modelos não carregam históricos completos,
DAOs, DTOs ou serviços de apresentação.

## Coverage

Coverage é calculada por componente. Ausência de denominador, conflito ou dado
insuficiente resulta em `insufficient`, `unavailable` ou `notApplicable`; nunca
em taxa zero fabricada. Adesão de medicamentos e vitaminas é obtida por
categoria no agregado de Smart Routines. A fórmula informa sua versão.

## Agenda

A agenda reúne occurrences e appointments dentro de um intervalo limitado.
Exames realizados não são convertidos em compromissos. Como não existe contrato
temporal próprio para exames programados, esse tipo não participa da Macro 3.
PRN sem uso não produz occurrence nem pendência.

Conflitos append-only são exibidos como `requiresReview`. A apresentação nunca
escolhe um evento vencedor. Ordenação usa instante efetivo, estado operacional,
tipo e ID estável.

## Insights e linguagem segura

`DeterministicInsightEngine` é o único motor canônico. Regras declaram ID,
versão, fontes, coverage, deduplicação, cooldown, expiração, prioridade, ação e
disclaimer. Home e BarIA consomem o mesmo feed.

Mensagens são informativas, acolhedoras e não prescritivas. Não orientam dose,
compensação, interrupção, diagnóstico ou segurança clínica. Dados insuficientes
geram uma explicação de coverage, não uma classificação negativa.

## Offline-first e freshness

A Home consulta o snapshot local imediatamente e inicia o bootstrap de sync em
paralelo. O snapshot anterior permanece durante navegação e atualizações. Após
sync, os providers canônicos são invalidados. Falhas técnicas ou filas
pendentes não são apresentadas como falha clínica.

Cada seção distingue `loading`, `ready`, `empty`, `stale`, `unavailable` e
`error`. Falha de um source não bloqueia os demais blocos.

## Consumers

- Reports recebe o snapshot canônico junto do histórico exigido pelo PDF e usa
  adesão versionada por categoria.
- Health Score consome componentes opcionais e remove dados indisponíveis do
  denominador.
- BarIA recebe contexto minimizado baseado no snapshot canônico; o fluxo de
  produção não carrega três dashboards nem um report completo.
- Notifications V2 continua consumindo occurrences diretamente.

## Privacidade e ciclo de sessão

Providers exigem usuário autenticado e não usam fallback `anonymous`. Snapshots
e caches são indexados pela sessão que criou o provider e são descartados na
troca de usuário/logout por invalidação do grafo Riverpod. Read models não são
persistidos remotamente e logs não devem incluir textos, IDs ou métricas de
saúde.

## Escopo

Macro 3 não cria feature flags, shadow mode, tabela Supabase ou migration para
read models. Feature Flags pertencem à Macro 6.
