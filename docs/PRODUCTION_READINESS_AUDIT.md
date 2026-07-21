# Production Readiness Audit — HelpBari V1

Data: 21/07/2026  
Escopo: Flutter/Android, arquitetura, Drift, Supabase/RLS, offline-first, Sync Engine, autenticação/multiusuário, notificações, Smart Routines, Unified Treatment, Home Intelligence, LGPD e testes.  
Método: leitura do código e documentação, todas as migrations SQL, análise estática, 532 testes Flutter, recriação integral do Supabase local e testes runtime PostgreSQL/RLS com dois usuários autenticados. Não houve teste em dispositivo, upgrade de APK nem build novo. A CLI vinculada foi usada somente para inspeção; nenhuma escrita remota foi realizada.

## Veredito

**❌ Não pronto para gerar novo APK de testes.**

O protocolo de revisão monotônica do servidor foi implementado no core e nos seis domínios simples já paginados; a Prescription Platform passou a usar paginação keyset. A migration foi validada do zero no Supabase local e RLS foi exercitada com dois usuários. Entretanto, a migration não foi aplicada remotamente porque o alvo não está formalmente identificado como staging/produção e não há evidência de backup. Além disso, agregados de Document Intelligence, Medical Exams, Medical Prescriptions, Smart Routines e os repositórios singleton ainda não possuem escrita CAS atômica completa. Por isso nenhum APK foi gerado.

## Scores

| Área | Score | Evidência e limite principal |
|---|---:|---|
| Geral | **72/100** | Base sólida e 532 testes; CAS parcial, paginação de agregados e backend remoto bloqueiam release |
| Arquitetura | **86/100** | Clean Architecture/feature-first preservadas; um único engine e Drift como fonte local |
| Sync | **75/100** | Revisão server-owned no core e seis domínios; agregados ainda sem CAS completo |
| Offline | **76/100** | Escrita local e fila preservadas; sem worker e sem ensaio real offline→online |
| UX | **80/100** | UI não bloqueia por sync; resolução clínica explícita; alguns erros técnicos ainda são transversais |
| Segurança | **67/100** | RLS A/B validada localmente; SQLite clínico em texto claro e remoto não validado após migration |
| Performance | **77/100** | Home limitada e rebuilds controlados; agregados remotos ainda podem exceder limite |
| Android | **64/100** | Manifest endurecido; assinatura, upgrade real, minify/shrink e artefato candidato ausentes |
| Supabase | **78/100** | Reset/migrations/RLS locais verdes; três migrations continuam pendentes no projeto remoto |
| LGPD | **77/100** | Exportação/exclusão amplas; storage/DB não são transação única e export não é criptografado |
| Testes | **75/100** | 532 Flutter + 2 runtime SQL verdes; cobertura global baixa e faltam dispositivo/upgrade/remoto |

## Achados confirmados

### A-01 — resposta de sync atravessava logout/troca de conta

- **Gravidade:** crítica. **Status:** corrigido.
- **Impacto:** resposta, ack, erro ou cursor da conta A poderia alcançar estado local depois de B entrar; RLS reduziria escrita remota, mas não corrigiria efeitos locais.
- **Reprodução:** pausar pull/push de A, trocar a sessão e liberar o Future antigo.
- **Arquivos:** `lib/core/sync/sync_session.dart`, `sync_manager.dart`, `sync_engine.dart`, `sync_providers.dart`.
- **Correção aplicada/recomendada:** geração revogável por sessão, checagens antes/depois de efeitos, backoff cancelável e execução nova serializada por geração. HTTP já enviado não é cancelável, mas seu resultado torna-se inofensivo.

### A-02 — retorno de conectividade não acionava convergência

- **Gravidade:** alta. **Status:** corrigido no foreground.
- **Impacto:** fila podia permanecer pendente até resume/mutação/manual.
- **Reprodução:** gravar offline e restaurar rede mantendo o app aberto.
- **Arquivos:** `sync_connectivity_trigger.dart`, `sync_bootstrap_provider.dart`, `app.dart`, `pubspec.yaml`.
- **Correção aplicada/recomendada:** `connectivity_plus` apenas como gatilho, false→true, debounce, foreground guard, mesmo engine/timeout/retry. Transporte não é tratado como prova de internet.

### A-03 — não existe background sync Android confiável

- **Gravidade:** média operacional. **Status:** não implementado, por decisão segura.
- **Impacto:** processo encerrado não possui prazo de convergência.
- **Reprodução:** gravar offline, encerrar o processo, restaurar rede.
- **Arquivos:** bootstrap de sync e configuração Android.
- **Correção recomendada:** worker com constraints que reutilize engine/sessão e seja validado em dispositivo; Android não garante horário exato. Não criar autoridade paralela.

### A-04 — protocolo de revisão do servidor ainda é parcial

- **Gravidade:** crítica para multi-device. **Status:** parcialmente corrigido; bloqueia APK.
- **Impacto:** Water, Weight, Meals, Appointments, Exams e Bioimpedance usam CAS com versão-base; agregados e singletons ainda podem sobrescrever estado concorrente por upsert sem precondição.
- **Reprodução:** editar a mesma entidade agregada em dois aparelhos a partir da mesma base e sincronizar em ordens opostas.
- **Arquivos:** `sync_engine.dart`, `sync_record_versions.dart`, `supabase_database.dart`, seis datasources/repositórios versionados e migration `20260724000000_sync_server_revisions.sql`.
- **Correção aplicada:** `server_revision` monotônica, `updated_at` do PostgreSQL, store Drift por usuário/repositório/registro, update condicional, conflito explícito sem retry e cursor superior obtido do servidor.
- **Correção restante:** desenhar RPCs específicas e transacionais por agregado para raiz/filhos e adaptar Smart Routines/singletons. Não usar uma RPC genérica que aceite tabela ou SQL arbitrário.

### A-05 — paginação do pull é parcial

- **Gravidade:** alta. **Status:** parcialmente corrigido; bloqueia APK.
- **Impacto:** agregados restantes podem truncar no limite PostgREST ou consumir memória/timeout.
- **Reprodução:** mais de 1.000 documentos, logs, prescrições, ocorrências ou eventos e cursor antigo.
- **Arquivos:** `supabase_database.dart`, `syncable_repository.dart`, seis datasources/repositórios de Water/Weight/Meals/Appointments/Exams/Bioimpedance.
- **Correção aplicada:** keyset `(updated_at,id)`, `user_id`, páginas, tombstones, deduplicação por id/versão, sessão por página e cursor após passe completo.
- **Correção restante:** Prescription Platform foi adaptada. Ainda faltam Document Intelligence, Medical Exams/Prescriptions e os pulls agregados de Smart Routines, preservando pai/filho e evitando N+1. Medication/Vitamin legados não estão registrados no engine atual.

### A-06 — tombstones não têm acknowledgement/compactação

- **Gravidade:** média. **Status:** risco documentado; remoção agressiva recusada.
- **Impacto:** crescimento contínuo remoto/local; purge precoce ressuscita dado em aparelho atrasado.
- **Reprodução:** criar/excluir repetidamente e manter outro dispositivo offline por longo período.
- **Arquivos:** DAOs/DTOs/migrations sincronizados.
- **Correção recomendada:** watermark por dispositivo + janela de clientes suportados; até lá reter remoto, indexar/paginar e manter exclusão LGPD separada. Compactação local exige full-resync seguro.

### A-07 — SQLite clínico não é criptografado

- **Gravidade:** alta. **Status:** risco aceito somente para teste controlado.
- **Impacto:** extração do sandbox em aparelho comprometido expõe saúde/PII.
- **Reprodução:** copiar `helpbari.sqlite` de ambiente com acesso ao sandbox e abrir em SQLite.
- **Arquivos:** conexão Drift e `docs/LOCAL_DATABASE_SECURITY.md`.
- **Correção recomendada:** SQLCipher/driver maduro, Keystore, migração atômica, integridade, rollback e matriz de upgrade. Não implementado sem essas garantias. Backup está desabilitado, cleartext bloqueado e logs sanitizados.

### A-08 — migrations remotas fora de paridade

- **Gravidade:** crítica para backend. **Status:** aberto/externo.
- **Impacto:** onboarding, preferências de notificação e revisão de sync podem não existir no remoto; o app versionado falharia até o backend estar compatível.
- **Reprodução:** `supabase migration list` mostra `20260722`, `20260723` e a nova `20260724` sem versão remota.
- **Arquivos:** `supabase/migrations/*`, `test/supabase/*`, `docs/SUPABASE_INTEGRATION_TESTS.md`.
- **Evidência:** Supabase local foi recriado do zero com todas as migrations; dois testes SQL runtime passaram, incluindo A não ler/alterar B, insert estrangeiro recusado, CAS stale recusado e tombstone incrementando revisão.
- **Correção recomendada:** identificar formalmente o projeto vinculado e ambiente, confirmar backup/PITR, aplicar somente as três pendentes e repetir smoke RLS/PostgREST no alvo. Nenhuma migration remota foi aplicada sem essas garantias.

### A-09 — pipeline Android não está fechado

- **Gravidade:** alta de distribuição. **Status:** aberto/externo.
- **Impacto:** não há evidência desta revisão para assinatura, upgrade, manifest merged release, minify/shrink ou instalação multiusuário.
- **Reprodução:** ausência de keystore/configuração segura e de relatório de artefato candidato.
- **Arquivos:** `android/app/build.gradle.kts`, manifest, `.gitignore`, `docs/APK_TEST_DISTRIBUTION.md`.
- **Correção recomendada:** chave do responsável fora do Git, verify com `apksigner`, versionCode crescente, instalação/upgrade e smoke em dispositivos. Builds com chaves diferentes não atualizam.

### A-10 — cobertura de risco ainda possui lacunas

- **Gravidade:** alta como gate. **Status:** parcialmente corrigido.
- **Impacto:** unit tests não provam rede/Postgres/Android/upgrade.
- **Reprodução:** não há Supabase local ativo, teste de dois JWTs, worker/dispositivo ou instalação sobre APK anterior.
- **Arquivos:** `test/core/sync/*` e suítes existentes.
- **Correção aplicada:** nove testes líquidos adicionais: revogação em pull/push/retry/páginas, paginação/deduplicação/falha de cursor e conectividade.
- **Correção restante:** integração RLS, >1.000 linhas via PostgREST real, upgrade representativo e smoke físico.

Cobertura medida por `lcov`: **36,3%** global (21.743/59.973). Foram adicionadas provas de conflito por revisão, base inalterada, paginação da Prescription Platform, migration SQL e RLS runtime. A cobertura continua insuficiente como único argumento de produção; os testes foram orientados a risco.

### A-11 — exclusão LGPD não é atômica entre Storage e banco

- **Gravidade:** média. **Status:** aberto; mudança grande.
- **Impacto:** falha depois de apagar objetos e antes da RPC deixa registros apontando para anexos ausentes; favorece privacidade, mas prejudica consistência/recuperação.
- **Reprodução:** interromper rede entre limpeza Storage e `delete_my_data`.
- **Arquivos:** privacy datasource/deletion service e RPCs SQL.
- **Correção recomendada:** job server-side idempotente, retomável e auditável, com recibo sem conteúdo clínico.

### A-12 — exportação não é criptografada e omite metadado de cutover

- **Gravidade:** média. **Status:** documentado, não alterado sem decisão DPO/contrato.
- **Impacto:** pacote sensível pode ser compartilhado sem proteção; `unified_treatment_cutover_states` é limpo mas não exportado.
- **Reprodução:** comparar export datasource com lista de limpeza e abrir arquivo exportado.
- **Arquivos:** privacy export/cleanup services.
- **Correção recomendada:** decisão DPO sobre portabilidade do metadado e proteção/aviso do arquivo, com schema versionado.

## Áreas auditadas sem defeito adicional confirmado

- Drift está na versão incremental existente, com foreign keys, transações, tombstones e consultas clínicas owner-scoped; migrations antigas não foram editadas.
- RLS SQL usa `auth.uid()` e FKs compostas nos agregados clínicos; não foi encontrada policy cross-user permissiva. Falta prova runtime.
- Smart Routines mantém eventos append-only, identidade original e IANA/DST; Unified Treatment preserva revisões/cutover.
- Notifications usa projeção local user-scoped, cancela no logout e separa preferências sincronizadas de IDs concretos.
- Home Intelligence compartilha fontes, limita históricos, invalida domínios e rejeita resultados assíncronos de sessão antiga.
- Router/deep links guardam sessão/onboarding e descartam subscriptions. O fluxo atual usa callback PKCE; App Links verificados não são requisito atual.
- Inspeção de mounted/dispose/timers/streams não confirmou novo leak. `SyncConnectivityTrigger` cancela subscription/timer e lifecycle observer é removido.
- Login/logout preserva dados offline isolados por design; exclusão LGPD realiza limpeza local/arquivos/notificações. O sync antigo agora é revogado.

## Gates

- Analyze: aprovado.
- Suíte Flutter: aprovada.
- Sessão: aprovada em testes determinísticos.
- Conectividade foreground: aprovada em testes unitários.
- Paginação de todas as entidades: reprovada; melhorou na Prescription Platform.
- Conflito sem autoridade exclusiva do clock: aprovado apenas no core e seis domínios simples; reprovado transversalmente.
- Upgrade automatizado representativo: evidência insuficiente.
- Supabase/RLS local: aprovado com reset integral e runtime A/B; remoto reprovado por migrations pendentes.
- SQLite: aceitável apenas como risco explícito para teste controlado, não beta.
- Android/APK: não executado porque gates anteriores falharam.

## Classificação honesta

**❌ Não pronto.** Mais precisamente: não pronto para gerar o próximo APK de testes. A base compila, os 532 testes Flutter e os 2 testes SQL passam, e o relógio do dispositivo deixou de ser autoridade nos seis domínios simples. Ainda assim, paginação e CAS não são transversais, três migrations estão pendentes no remoto e não há validação de upgrade/dispositivo. A classificação anterior “pronto apenas para testes internos via APK” aplicava-se ao artefato anterior, não a um novo candidato deste worktree.
