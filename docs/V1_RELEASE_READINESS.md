# HelpBari V1 — Release readiness

Atualizado em 2026-07-21. Este documento não substitui
`PRODUCT_FREEZE_V1.md` e não declara publicação em loja.

## Escopo concluído

- shell com Hoje, Tratamento, Evolução e Mais;
- onboarding versionado e recuperação sem splash infinita;
- Tratamento visível unificado sobre Smart Routines;
- escrita das quatro categorias, múltiplos horários, dias específicos, PRN,
  uso único e quatro semânticas explícitas de duração;
- revisão futura com preservação de planos, occurrences e events anteriores;
- pausa, retomada, conclusão e exclusão lógica;
- reconciliação de notificações após escrita e deep link seguro;
- exportação e limpeza LGPD da família Smart Routines, onboarding e Settings;
- Prescrições ocultas da navegação, com contratos e dados preservados.

## Pendências reais e riscos

- conflito append-only possui revisão visual e resolução humana append-only;
- Tratamento possui detalhe dedicado com histórico, revisões, eventos e pausas;
- PRN possui registro ad hoc com horário e observação, sem recorrência;
- posicionamento do deep link por ID exige confirmação no smoke candidato;
- TalkBack, VoiceOver, timezone/DST real, reboot, background e rede degradada
  exigem validação em aparelho;
- assinatura release e credenciais de produção precisam ser confirmadas fora
  do repositório.

## Migrations

Nenhuma migration foi criada neste fechamento. O código depende das migrations
aditivas existentes de Smart Routines, UTE, Notifications V1 e Onboarding V1.
A paridade remota deve ser confirmada com:

```sh
supabase migration list
supabase db lint --local
```

O último registro confirmou paridade até `20260721000000`. As migrations
`20260722000000` e `20260723000000` ainda exigem aplicação/verificação remota.
A auditoria estática confirmou RLS/policies por `auth.uid()`, triggers do
domínio e storage isolado. Migration list, db lint e testes com dois usuários
continuam obrigatórios no ambiente de release.

## Matriz automatizada

| Área | Cobertura |
| --- | --- |
| Tratamento | revisão imutável, múltiplos horários/dias, PRN, pausa, retomada, conclusão, tombstone |
| UI | formulário unificado, telefone pequeno, fonte ampliada e overflow |
| Notificações | diff, deduplicação, preferência, permissão negada, inbox e usuário |
| Upgrade | Drift, legado Medication/Vitamin, mappings e onboarding |
| Privacidade | exportação clínica e limpeza local por usuário |
| Router | guards, rotas legadas e payloads para Tratamento |

## Checklist de ambiente e Supabase

- [ ] selecionar explicitamente dev/staging/prod;
- [ ] fornecer URL/key com mecanismo seguro e confirmar ausência de secrets;
- [ ] confirmar RLS por `auth.uid()` e paridade de migrations;
- [ ] executar `supabase db lint --local` com stack local disponível;
- [ ] habilitar `remoteSyncEnabled` somente após migration remota;
- [ ] testar dois usuários e conflito em dois dispositivos.

## Checklist Android

- [x] placeholder removido; Android usa `io.helpbari.app`, sujeito à aprovação;
- [x] assinatura debug removida do release;
- [ ] injetar keystore seguro no CI/ambiente de release;
- [x] nome visível `HelpBari`; confirmar versão/build do candidato;
- [ ] validar ícones e splash em aparelho;
- [ ] inspecionar manifest merged, permissões e notification channels;
- [ ] validar app links, reboot, timezone e regras de backup;
- [ ] executar smoke test no APK/AAB pretendido.

## Checklist testes e smoke

- [x] cobertura automatizada de isolamento, upgrade e domínios críticos;
- [x] testes de PRN ad hoc e conflito explícito;
- [ ] analyze/test completos no commit candidato;
- [ ] executar `SMOKE_TEST_PLAN.md` em Android real;
- [ ] validar TalkBack, background, reboot, timezone/DST e rede degradada.

## Checklist LGPD

- [x] dados canônicos de Tratamento exportáveis;
- [x] onboarding e preferências de notificação exportáveis;
- [x] limpeza local isolada por usuário;
- [x] payload de notificação sem conteúdo clínico;
- [ ] validar exportação e exclusão ponta a ponta no remoto;
- [ ] revisar links públicos de Termos e Privacidade no beta.

## Critérios de promoção

Beta interno exige analyze e suíte completos, build Android instalável e smoke
test em aparelho. Beta fechado exige paridade remota, lint do banco, assinatura
release segura, conflito revisável e validação manual de acessibilidade e
notificações. Sem essas evidências, o critério é **não pronto para beta
fechado**.

## Checklist Play Store

- [ ] reservar/aprovar `io.helpbari.app` antes da publicação;
- [ ] configurar Play App Signing e upload key fora do repositório;
- [ ] gerar e validar AAB release no ambiente seguro;
- [ ] preencher Data safety, política pública e exclusão de conta;
- [ ] fornecer assets e texto sem alegação médica;
- [ ] classificar conteúdo, público-alvo, anúncios e acesso do revisor;
- [ ] revisar/justificar câmera, mídia e notificações;
- [ ] testar app links/callbacks nas trilhas interna e fechada;
- [ ] documentar rollback, suporte, monitoramento e promoção.

## Critérios beta

### Beta interno

- [ ] analyze/test/build verdes no commit candidato;
- [ ] staging com migrations completas e dois usuários isolados;
- [ ] smoke crítico de instalação a LGPD;
- [ ] artefato assinado pelo processo interno e acesso restrito.

### Beta fechado

- [ ] todos os itens do beta interno;
- [ ] smoke integral em matriz de aparelhos/Android;
- [ ] Supabase lint, RLS, storage e exclusão remota validados;
- [ ] assinatura Play, ficha, Data safety e links legais aprovados;
- [ ] acessibilidade, deep links, upgrade, reboot, DST e rede aprovados;
- [ ] suporte, telemetria minimizada, incidentes e rollback operacionais.

## Evidências desta execução

- `flutter analyze`: sem problemas;
- suíte Flutter: 521 testes aprovados;
- build Android: APK debug gerado com sucesso em
  `build/app/outputs/flutter-apk/app-debug.apk` (aproximadamente 204 MB);
- APK release gerado após adicionar regras R8 apenas para scripts opcionais do
  ML Kit; assinatura de distribuição continua externa ao repositório;
- manifest merged debug inspecionado: permissões de rede,
  notificações, reboot, câmera e mídia presentes;
- nenhuma validação foi executada em aparelho físico ou em loja.

### Auditoria de hardening — 21/07/2026

- `flutter analyze`: limpo;
- `flutter test`: 531 testes aprovados;
- isolamento de sessão e recuperação de conectividade: implementados e
  testados deterministicamente;
- paginação keyset: implementada em seis domínios, ainda incompleta nos
  agregados clínicos;
- `supabase migration list`: conexão remota somente leitura bem-sucedida;
  `20260722` e `20260723` permanecem pendentes;
- `supabase db lint --linked`: sem erros;
- RLS runtime: não validada; Docker local indisponível e migrations não foram
  aplicadas sem confirmação de alvo/backup;
- conflito ainda depende de `updatedAt` local nos registros mutáveis;
- novo APK: não gerado, porque os gates obrigatórios de conflito e paginação
  transversal permanecem abertos.

Classificação desta revisão: **não pronto para gerar novo APK de testes**. O APK
anterior não constitui evidência para este worktree.

## Rollback

Não apagar dados. Antes de qualquer escrita nova, o rollout pode voltar à
leitura legada conforme o UTE. Depois de `Write New`, Smart Routines permanece
a autoridade; recuperação deve desabilitar novas entradas por flag, preservar
dados e corrigir de forma aditiva. Notificações podem ser reconstruídas porque
são projeções locais.

## Fora da V1

Macro 4, exposição de Prescrições, recomendação clínica automática, publicação
na Play Store, prontuário profissional e remoções físicas de legado.
