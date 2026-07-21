# Production Readiness Audit — HelpBari

Data da auditoria: 21/07/2026  
Escopo: aplicação Flutter/Android, arquitetura, Drift, Supabase SQL/RLS, sincronização, notificações, Smart Routines, Unified Treatment, Home Intelligence, autenticação, privacidade e testes.  
Método: inspeção estática dos caminhos ativos e referências Water/Profile/Settings, execução integral dos testes, análise Flutter e build APK release. Não houve teste contra um projeto Supabase remoto nem teste em dispositivo físico.

## Veredito

**⚠️ Pronto apenas para testes internos via APK**

O aplicativo possui uma base arquitetural consistente, grava localmente antes do sync, isola consultas Drift por `userId`, usa tombstones, RLS e PKCE, tem boa cobertura comportamental dos motores clínicos e gera um APK release. Ainda não é honesto classificá-lo como Beta Interno: não existe validação end-to-end contra Supabase/RLS real, o sync pode atravessar uma troca de sessão, não há convergência em background/conectividade, o banco clínico local permanece em texto claro e o processo de assinatura/distribuição não está definido no repositório. Esses itens exigem desenho e validação de release; não foram implementados automaticamente.

## Scores

Escala: 0–100, considerando evidência disponível no repositório e validações executadas.

| Área | Score | Fundamentação curta |
|---|---:|---|
| Geral | **67** | Boa base e testes, com bloqueadores de sync, segurança local e release |
| Arquitetura | **84** | Feature-first/Clean Architecture coerente; dependências seguem Presentation → Domain/Application → Data |
| Sync | **62** | Local-first, cursor e deduplicação; falta isolamento de sessão em voo e paginação |
| Offline | **70** | CRUD local é funcional; reconexão/background não garantem convergência |
| UX | **79** | Estados offline, feedback e design system presentes; alguns erros técnicos ainda chegam à UI |
| Segurança | **61** | RLS/PKCE e logs endurecidos; SQLite local não criptografado |
| Performance | **73** | Home compartilha fontes e paraleliza; pull remoto e tombstones não têm limites de crescimento |
| Android | **64** | APK release compila e manifest de notificações está correto; signing/minify/release pipeline pendentes |
| Supabase | **72** | Migrações owner-scoped e funções endurecidas; falta teste real de políticas e concorrência |
| LGPD | **76** | Exportação/exclusão amplas; arquivo exportado não é criptografado e há pequena lacuna de portabilidade |
| Testes | **68** | 522 testes verdes, mas cobertura de linhas é 36,3% e faltam E2E, dispositivo, upgrade matrix e Supabase real |

## Arquitetura observada

- `main` inicializa timezone, Supabase, SharedPreferences e Drift antes do `ProviderScope`.
- Drift é a fonte local principal. Repositórios gravam localmente, expõem pending operations e delegam acesso remoto a datasources Supabase.
- `SyncEngine` faz pull, resolve conflito e envia pendências por repositório. Cursores são por usuário/repositório nos domínios migrados.
- Router e providers são session-aware. Home usa providers-fonte compartilhados e composições determinísticas, evitando repetir as consultas mais caras.
- Smart Routines preserva identidade de ocorrências, eventos clínicos append-only e semântica IANA/DST. Unified Treatment usa rollout/cutover versionado e revisões imutáveis.
- Notificações são projeções locais, segregadas por usuário; preferências de negócio sincronizam, IDs concretos e manifestos ficam no dispositivo.
- Supabase aplica RLS por `auth.uid()`, chaves compostas com `user_id`, PKCE e funções LGPD `SECURITY DEFINER` com `search_path` vazio e grants restritos.

## Achados

### A-01 — Sync em voo não é cancelado nem vinculado à sessão ativa

- **Gravidade:** alta; complexidade de correção: alta; **não corrigido**.
- **Impacto:** se A sair e B entrar enquanto `_activeSync` ainda executa, B pode receber o Future do sync de A. As chamadas remotas seguintes usam a sessão Supabase corrente, enquanto os repositórios capturaram o `userId` de A. RLS tende a rejeitar, mas o sync inicial de B pode ser considerado aguardado sem ter sido executado e registros de A podem ser marcados localmente como falhos.
- **Reprodução:** bloquear um `pull` da sessão A; executar logout/login B; chamar `syncNow` antes de liberar A; observar que há um único `_activeSync` sem chave de usuário.
- **Arquivos:** `lib/core/sync/sync_manager.dart`, `lib/core/sync/sync_providers.dart`, `lib/app/bootstrap/sync_bootstrap_provider.dart`.
- **Correção recomendada:** introduzir geração/cancellation token por sessão, validar a sessão antes de cada commit local e chamada remota, serializar por usuário e obrigar um novo passe para B após cancelamento de A. Criar teste concorrente A→logout→B com remote fake.

### A-02 — Não há convergência orientada por conectividade ou worker em background

- **Gravidade:** alta para promessa offline-first; complexidade: alta; **não corrigido**.
- **Impacto:** dados ficam seguros localmente, mas só sincronizam em login, resume, mutações específicas ou retry manual. Se o usuário gravar offline e mantiver o app em foreground quando a rede voltar, ou fechar o app, não existe garantia temporal de envio.
- **Reprodução:** iniciar sem rede, gravar, restaurar rede sem pausar/reabrir o app e sem nova mutação; nenhuma fonte observa conectividade. Fechar o app e aguardar; não há WorkManager/background fetch.
- **Arquivos:** `lib/app/bootstrap/sync_bootstrap_provider.dart`, `lib/core/sync/sync_manager.dart`, `pubspec.yaml`, Android manifest.
- **Correção recomendada:** desenhar um coordenador único que observe conectividade apenas como sinal, mantenha debounce/backoff persistente e use worker Android com constraints; preservar o mesmo Sync Engine e idempotência. Definir limites de bateria e dados.

### A-03 — LWW depende do relógio do dispositivo e empate favorece o local

- **Gravidade:** alta para edição multi-device; complexidade: alta; **não corrigido**.
- **Impacto:** relógio adiantado pode dominar alterações válidas indefinidamente. Timestamps iguais com payloads diferentes escolhem local em cada dispositivo, sem desempate global explícito. Os triggers `latest_updated_at_wins` evitam regressão no servidor, mas não resolvem relógio incorreto.
- **Reprodução:** em dois dispositivos, adiantar o relógio de A, editar o mesmo registro em A e depois em B; sincronizar B. Para empate, produzir o mesmo `updatedAt` com payload diferente.
- **Arquivos:** `lib/core/sync/sync_engine.dart`, DTOs/datasources sincronizados, migrações Supabase com funções `*_latest_updated_at_wins`.
- **Correção recomendada:** adotar revisão/ETag ou Hybrid Logical Clock atribuído pelo servidor, manter `device_id` e desempate determinístico documentado; criar matriz de conflitos update/update, update/delete e delete/recreate.

### A-04 — Banco clínico local não possui criptografia em repouso

- **Gravidade:** alta; complexidade: alta; **não corrigido**.
- **Impacto:** `helpbari.sqlite` contém dados de saúde em SQLite padrão. O sandbox Android reduz exposição, e backups foram desabilitados nesta auditoria, mas extração de aparelho comprometido/debuggable ainda revela conteúdo.
- **Reprodução:** em dispositivo/emulador com acesso ao sandbox, copiar `Application Support/helpbari.sqlite` e abrir com SQLite.
- **Arquivos:** `lib/core/database/drift/database_connection.dart`, tabelas Drift, configuração Android.
- **Correção recomendada:** avaliar SQLCipher/criptografia suportada por Drift, chave no Android Keystore, rotação e migração atômica do banco existente. Exige teste de upgrade, recuperação e impacto de performance.

### A-05 — Pull remoto não é paginado

- **Gravidade:** média; complexidade: alta transversal; **não corrigido**.
- **Impacto:** o primeiro sync ou um cursor antigo carrega todas as linhas alteradas em memória. Histórico longo e tombstones elevam latência, RAM e risco de timeout.
- **Reprodução:** popular milhares de registros para um usuário, limpar cursor e executar sync; observar `select().order('updated_at')` sem `range/limit`.
- **Arquivos:** datasources `*_supabase_datasource.dart`, `lib/core/sync/syncable_repository.dart`, `lib/core/sync/sync_engine.dart`.
- **Correção recomendada:** cursor composto inclusivo `(updated_at,id)`, páginas limitadas e commit de cursor somente após página aplicada; tratar empates sem perda.

### A-06 — Tombstones não têm protocolo de retenção/compactação

- **Gravidade:** média; complexidade: alta; **não corrigido**.
- **Impacto:** exclusões propagam corretamente, porém linhas apagadas permanecem local e remotamente por tempo indeterminado, agravando A-05 e retenção LGPD operacional.
- **Reprodução:** criar/excluir repetidamente registros e inspecionar tabelas: `deleted_at` é preservado e não há job de purge seguro.
- **Arquivos:** tabelas/DAOs Drift, tabelas Supabase, repositórios de sync.
- **Correção recomendada:** política documentada de retenção, watermark por dispositivo e purge somente quando todos os clientes suportados puderem ter observado o tombstone. Exclusão LGPD continua imediata e separada.

### A-07 — Supabase/RLS só possui testes estáticos de migração

- **Gravidade:** alta como gate de release; complexidade: alta; **não corrigido**.
- **Impacto:** os testes confirmam texto SQL, mas não provam que migrações aplicam em ordem, RLS bloqueia usuário B, Storage remove/lista recursivamente, triggers funcionam sob concorrência ou RPCs LGPD executam no ambiente implantado.
- **Reprodução:** a suíte `test/supabase` lê arquivos; não sobe Postgres/Supabase local nem autentica dois usuários.
- **Arquivos:** `test/supabase/*`, `supabase/migrations/*`, `supabase/tests/smart_routines_runtime_test.sql`.
- **Correção recomendada:** CI com `supabase start/db reset`, testes SQL/runtime, dois JWTs, Storage e RPC; aplicar migrações do zero e sobre snapshot anterior.

### A-08 — Processo Android de release não está fechado

- **Gravidade:** alta como gate de distribuição; complexidade: alta organizacional; **não corrigido**.
- **Impacto:** APK release compila, mas signing é deliberadamente externo e não foi verificável; não há configuração visível de CI, Play App Signing, AAB, mapping/symbol upload ou matriz de upgrade. Minificação e shrink de resources não estão habilitados explicitamente. O APK universal tem 106 MB.
- **Reprodução:** executar `flutter build apk --release`; artefato é gerado. O host não expôs Java para `jarsigner`, portanto assinatura não pôde ser confirmada fora do Gradle usado pelo Flutter.
- **Arquivos:** `android/app/build.gradle.kts`, `android/app/proguard-rules.pro`, `pubspec.yaml`.
- **Correção recomendada:** pipeline seguro para AAB assinado, flavors staging/prod, `isMinifyEnabled`/`isShrinkResources` validados, upload de símbolos, testes de instalação/upgrade e checklist Play Console.

### A-09 — Exportação local não inclui o estado de cutover por usuário

- **Gravidade:** média; complexidade: baixa, mas **não corrigido** para não alterar o contrato de exportação sem decisão de produto/jurídico.
- **Impacto:** os dados clínicos principais, documentos, prescrições, rotinas e eventos são exportados; `unified_treatment_cutover_states` é limpo na exclusão, mas não aparece no pacote de portabilidade. É metadado pessoal operacional e deve ter decisão explícita de escopo LGPD.
- **Reprodução:** gerar exportação e comparar `_userTables` da limpeza com chaves de `PrivacyClinicalExportDatasource`.
- **Arquivos:** `lib/features/privacy/data/datasources/privacy_clinical_export_datasource.dart`, `lib/features/privacy/data/services/privacy_local_cleanup_service.dart`, `lib/features/privacy/application/privacy_export_service.dart`.
- **Correção recomendada:** validar com DPO se o metadado integra portabilidade; se sim, incluir em seção versionada e testar schema. Também informar ao usuário que o ZIP contém dados sensíveis sem senha.

### A-10 — Exclusão de Storage precede RPC transacional do banco

- **Gravidade:** média; complexidade: alta; **não corrigido**.
- **Impacto:** falha da RPC após remoção dos arquivos deixa registros remotos sem anexos. O fluxo é seguro para privacidade, porém parcialmente destrutivo e exige recuperação explícita.
- **Reprodução:** concluir `_deleteStorage` e provocar falha/rede perdida antes de `delete_my_data`.
- **Arquivos:** `lib/features/privacy/data/datasources/privacy_supabase_datasource.dart`, `lib/features/privacy/application/privacy_deletion_service.dart`.
- **Correção recomendada:** solicitação de deleção persistida/server-side, estado idempotente e retomável, processamento privilegiado no backend e recibo auditável sem conteúdo clínico.

### A-11 — Timeouts e retry do Sync Engine eram ilimitado/em rajada

- **Gravidade:** média; complexidade: baixa; **corrigido**.
- **Impacto anterior:** pull/push pendurado mantinha `_activeSync` indefinidamente; três tentativas imediatas ampliavam falhas transitórias.
- **Reprodução anterior:** retornar um Future nunca concluído em `pull`; ou falhar push repetidamente e observar tentativas sem intervalo.
- **Arquivos:** `lib/core/sync/sync_engine.dart`, `test/core/sync/sync_engine_test.dart`.
- **Correção aplicada:** timeout de 15 s em carregamento de pendências, pull e push; backoff exponencial curto entre tentativas; teste prova que pull travado não impede push local subsequente.
- **Observação:** classificação transitória/permanente continua parte do redesenho maior de retry.

### A-12 — Versão persistida do sync era sempre `unknown`

- **Gravidade:** baixa; complexidade: baixa; **corrigido**.
- **Impacto anterior:** diagnóstico e evolução do estado de sync não distinguiam builds instalados.
- **Reprodução anterior:** ler `syncAppVersionProvider`; retornava literal `unknown`.
- **Arquivos:** `lib/main.dart`, `lib/core/sync/sync_providers.dart`, `pubspec.yaml`, `pubspec.lock`.
- **Correção aplicada:** leitura de `PackageInfo` no bootstrap e override com `version+buildNumber`.

### A-13 — Stream de taps do serviço nativo não era fechado

- **Gravidade:** baixa; complexidade: baixa; **corrigido**.
- **Impacto anterior:** ao descartar/recriar o container, o `StreamController` interno permanecia aberto.
- **Reprodução anterior:** criar/descartar `ProviderContainer`; somente o stream do scheduler era fechado.
- **Arquivos:** `lib/core/services/notifications/app_local_notification_service.dart`, `lib/core/services/service_providers.dart`.
- **Correção aplicada:** `dispose` no serviço e registro em `ref.onDispose`.

### A-14 — Backup Android e tráfego cleartext não estavam explicitamente bloqueados

- **Gravidade:** média; complexidade: baixa; **corrigido**.
- **Impacto anterior:** defaults/plataformas OEM poderiam permitir backup de dados locais; HTTP claro não era explicitamente recusado.
- **Reprodução anterior:** inspecionar `<application>` sem `allowBackup`, `fullBackupContent` ou `usesCleartextTraffic`.
- **Arquivos:** `android/app/src/main/AndroidManifest.xml`, `test/android/notification_manifest_test.dart`.
- **Correção aplicada:** backup desabilitado e cleartext recusado, com teste de contrato do manifest.

### A-15 — Logs de produção podiam anexar exceção e stack completos

- **Gravidade:** média; complexidade: baixa; **corrigido**.
- **Impacto anterior:** exceções Supabase/Drift poderiam carregar detalhes internos para logcat/telemetria futura; um fallback de Profile interpolava o erro diretamente.
- **Reprodução anterior:** provocar erro Supabase e observar `AppLogger.error(... error, stackTrace)` fora de dev.
- **Arquivos:** `lib/core/logger/app_logger.dart`, `lib/core/services/logger_service.dart`, `lib/core/supabase/interceptors/logging_supabase_interceptor.dart`, `lib/features/profile/data/repositories/drift_primary_profile_repository.dart`.
- **Correção aplicada:** detalhes e stack apenas em dev; produção mantém mensagem operacional e tipo seguro onde necessário.

## Áreas auditadas sem defeito confirmado

- **Drift/migrations:** schema versionado incrementalmente até 22, sem reescrita de migrações; `foreign_keys=ON`; transações em agregados e migrações críticas; testes de rollback, idempotência e isolamento.
- **RLS/multi-user:** políticas de select/insert/update usam `auth.uid()` e relações clínicas compostas incluem `user_id`. Não foi encontrada política permissiva cross-user. A confirmação runtime continua pendente em A-07.
- **Tombstones:** create/update/delete e `deletedAt/syncStatus` são preservados; DAOs excluem tombstones das leituras ativas e incluem pendências. Retenção é a lacuna A-06.
- **Notifications:** payload tipado e user-scoped, cancelamento no logout/troca de usuário, restore no resume/boot, deduplicação e ações em background persistidas. Manifest declara permissões/receivers necessários.
- **Smart Routines/Unified Treatment:** eventos append-only, identidade original imutável, revisões clínicas protegidas, migração idempotente e rollout/cutover testados. Não foi encontrada mutação direta da prescrição confirmada.
- **Home Intelligence/performance de rebuild:** fontes compartilhadas, `Future.wait`, invalidação por domínio e guarda de sessão. Não há refresh global no caminho normal; full refresh é fallback explícito.
- **Router/deep links:** redirect centralizado, destino pendente vinculado ao usuário, stream/subscriptions descartados e payload de notificação filtrado pela sessão. O callback PKCE custom scheme está consistente com `APP_REDIRECT_URL`; Universal/App Links verificados não estão configurados, mas não são necessários ao fluxo atual.
- **Async/mounted/dispose:** páginas inspecionadas cancelam timers, observers, subscriptions e controllers; usos de contexto após await possuem guardas relevantes. Nenhum leak adicional reproduzível foi confirmado.
- **Timezone/DST:** schedules preservam wall-clock e IANA zone; ocorrências preservam data/hora/zona original; há testes de DST e restauração. A Home recalcula dia clínico em resume e mudança de timezone.
- **Login/logout:** router e notificações limpam estado por usuário; consultas Drift são scoped. O único risco confirmado é sync em voo (A-01). Logout comum preserva dados locais por design offline; exclusão LGPD remove dados e arquivos.
- **Exception handling/UX offline:** mutações locais sobrevivem a erro remoto e apresentam warning. Alguns ViewModels ainda usam `error.toString()` para estado visual; não foi alterado por exigir padronização transversal pelo mapper existente.
- **LGPD exclusão:** RPCs autenticadas, grants restritos, `search_path=''`, deleção de tabelas clínicas recentes, storage owner-scoped e limpeza local transacional. A-10 descreve atomicidade entre Storage e DB.

## Testes e validações executados

1. `flutter analyze` — sem issues antes e depois das mudanças.
2. `flutter test` — 521 testes originais, todos aprovados.
3. Testes novos: timeout/continuidade do sync e hardening do Android manifest.
4. `flutter test test/core/sync/sync_engine_test.dart test/android/notification_manifest_test.dart` — 14 testes, todos aprovados.
5. `flutter test --coverage` — 522 testes aprovados; 21.565/59.362 linhas, **36,3%**.
6. `flutter build apk --release` — sucesso; APK universal de 106 MB em `build/app/outputs/flutter-apk/app-release.apk`.

## Gates para avançar de classificação

Para **Beta Interno**: resolver A-01; executar A-07; fechar assinatura/AAB e upgrade Android; decidir risco A-04; ensaiar offline→online, logout/login e exclusão em dispositivos reais.

Para **Beta Fechado**: além dos itens anteriores, implementar convergência A-02, paginação A-05, política de tombstones A-06, observabilidade sem PII e teste de carga/longa duração.

Para produção pública: threat model formal, DPIA/ROPA e política LGPD aprovadas, criptografia local/migração, pentest, disaster recovery Supabase, SLOs de sync, Play Console/Data Safety e runbook de incidentes.
