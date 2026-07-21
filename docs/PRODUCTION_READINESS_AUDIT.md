# Production Readiness Audit — HelpBari V1

Data: 21/07/2026  
Escopo: Flutter/Android, arquitetura, Drift, Supabase/RLS, offline-first, Sync Engine, autenticação/multiusuário, notificações, Smart Routines, Unified Treatment, Home Intelligence, LGPD e testes.  
Método: leitura do código e documentação, todas as migrations SQL, análise estática, 531 testes Flutter, CLI Supabase somente leitura e lint remoto. Não houve teste em dispositivo, Supabase runtime com dois JWTs, upgrade de APK nem build novo.

## Veredito

**❌ Não pronto para gerar novo APK de testes.**

O isolamento de sessão e o gatilho por conectividade foram resolvidos com testes determinísticos. A paginação keyset existe apenas em seis dos dezenove repositórios sincronizáveis. Registros mutáveis ainda resolvem concorrência por `updatedAt` do dispositivo, sem versão base/servidor. Esses dois itens violam gates obrigatórios fornecidos para esta rodada. Por isso nenhum APK foi gerado, mesmo com analyze e suíte verdes.

## Scores

| Área | Score | Evidência e limite principal |
|---|---:|---|
| Geral | **70/100** | Base sólida e 531 testes; conflito, paginação transversal e validações externas bloqueiam release |
| Arquitetura | **86/100** | Clean Architecture/feature-first preservadas; um único engine e Drift como fonte local |
| Sync | **70/100** | Sessão, timeout, retry, conectividade e páginas no core; clock e cobertura de entidades incompletos |
| Offline | **76/100** | Escrita local e fila preservadas; sem worker e sem ensaio real offline→online |
| UX | **80/100** | UI não bloqueia por sync; resolução clínica explícita; alguns erros técnicos ainda são transversais |
| Segurança | **63/100** | RLS/PKCE/logs/manifest; SQLite clínico em texto claro e RLS sem runtime |
| Performance | **77/100** | Home limitada e rebuilds controlados; agregados remotos ainda podem exceder limite |
| Android | **64/100** | Manifest endurecido; assinatura, upgrade real, minify/shrink e artefato candidato ausentes |
| Supabase | **73/100** | Lint remoto limpo; duas migrations pendentes e RLS não exercitada com usuários reais |
| LGPD | **77/100** | Exportação/exclusão amplas; storage/DB não são transação única e export não é criptografado |
| Testes | **72/100** | 531 verdes e novos testes críticos; cobertura global baixa e faltam integração/dispositivo/upgrade |

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

### A-04 — conflito de mutáveis depende exclusivamente do relógio local

- **Gravidade:** crítica para multi-device. **Status:** aberto; bloqueia APK.
- **Impacto:** dispositivo adiantado domina alterações; empate pode divergir; delete/update concorrentes podem escolher vencedor incorreto.
- **Reprodução:** editar mesma base em dois aparelhos com clock skew e sincronizar em ordens opostas.
- **Arquivos:** `sync_engine.dart`, DTOs/datasources e triggers `*_latest_updated_at_wins`.
- **Correção recomendada:** migration aditiva com revisão monotônica do servidor, versão-base no cliente, update condicional atômico e retorno do estado confirmado; conflito remoto avançado deve ir à UX explícita. Não foi criada RPC genérica/destrutiva.

### A-05 — paginação do pull é parcial

- **Gravidade:** alta. **Status:** parcialmente corrigido; bloqueia APK.
- **Impacto:** agregados restantes podem truncar no limite PostgREST ou consumir memória/timeout.
- **Reprodução:** mais de 1.000 documentos, logs, prescrições, ocorrências ou eventos e cursor antigo.
- **Arquivos:** `supabase_database.dart`, `syncable_repository.dart`, seis datasources/repositórios de Water/Weight/Meals/Appointments/Exams/Bioimpedance.
- **Correção aplicada:** keyset `(updated_at,id)`, `user_id`, páginas, tombstones, deduplicação por id/versão, sessão por página e cursor após passe completo.
- **Correção restante:** adaptar Medication/Vitamin logs, Document Intelligence, Medical Exams/Prescriptions, Prescription Platform e Smart Routines preservando agregados pai/filho e evitando N+1.

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

### A-08 — migrations remotas fora de paridade e RLS sem teste runtime

- **Gravidade:** crítica para backend. **Status:** aberto/externo.
- **Impacto:** onboarding/notification preferences podem não existir no remoto; inspeção SQL não prova isolamento.
- **Reprodução:** `supabase migration list` mostra `20260722` e `20260723` sem versão remota; testes atuais leem SQL.
- **Arquivos:** `supabase/migrations/*`, `test/supabase/*`, `docs/SUPABASE_INTEGRATION_TESTS.md`.
- **Evidência:** conexão read-only funcionou; `supabase db lint --linked` retornou zero erros. `supabase status` falhou sem Docker/Colima.
- **Correção recomendada:** confirmar alvo e backup, aplicar apenas pendentes, testar A/B/anônimo com JWT authenticated, Storage, tombstones e RPC LGPD. Nenhuma migration foi aplicada sem autorização operacional suficiente.

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

Cobertura medida por `lcov`: **36,4%** global (21.669/59.534), contra 36,3% anterior. Recortes de risco: core sync 42,9%, Drift 30,3%, Privacy 35,3%, Smart Routines 72,3% e Onboarding 60,9%. O aumento pequeno é esperado: os testes foram orientados a corridas críticas, não a inflar linhas triviais.

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
- Paginação de todas as entidades: reprovada.
- Conflito sem autoridade exclusiva do clock: reprovado.
- Upgrade automatizado representativo: evidência insuficiente.
- Supabase/RLS real: reprovado por migrations pendentes e ausência de runtime A/B.
- SQLite: aceitável apenas como risco explícito para teste controlado, não beta.
- Android/APK: não executado porque gates anteriores falharam.

## Classificação honesta

**❌ Não pronto.** Mais precisamente: não pronto para gerar o próximo APK de testes. A base compila/analyze e todos os testes passam, mas o pedido definiu paginação transversal e conflito não baseado exclusivamente no clock como gates obrigatórios. O backend também não pode ser chamado pronto até migrations/RLS reais serem validadas. A classificação anterior “pronto apenas para testes internos via APK” aplicava-se ao artefato anterior, não a um novo candidato deste worktree.
