# Onboarding V1 — Fundação de entrada

Este documento descreve a implementação do Bloco A do Product Freeze V1. Em
caso de conflito com documentação histórica, `docs/PRODUCT_FREEZE_V1.md`
prevalece.

## Contrato canônico

O estado do onboarding é versionado por usuário em `onboarding_states`. Os
status válidos são `notStarted`, `inProgress`, `completed` e `needsReview`. A
versão atual é `1` e usa os IDs estáveis `welcome`, `legalConsents`,
`basicProfile`, `bariatricJourney`, `weightAndGoals`, `trackingPreferences`,
`trackingConfiguration`, `reminderPreference` e `completion`.

Drift é a fonte local da verdade. Cada avanço é salvo localmente e entra na
fila do Sync Engine existente. Conflitos entre dispositivos seguem o contrato
LWW por `updatedAt`; tombstones e cursores continuam no mesmo pipeline. O
registro é isolado por `userId`, possui RLS de leitura/escrita do próprio
usuário e integra exportação e exclusão LGPD.

## Entrada do aplicativo

`AppRedirectResolver` concentra a máquina de estados de entrada:
inicialização, não autenticado, resolução da conta, onboarding obrigatório,
pronto, sessão expirada e recuperação fatal. O app só libera rotas protegidas
após restaurar sessão, sync inicial, perfil, consentimento e progresso
canônico.

Usuários anteriores com perfil e consentimento válidos recebem backfill
idempotente como concluídos. Conclusões legadas sem os dados obrigatórios não
liberam o app: tornam-se `needsReview` no primeiro passo faltante.

## Preferências e permissões

Tratamento, água, alimentação e peso são escolhas explícitas. As preferências
ficam em Settings e podem ser alteradas posteriormente. A meta de água só é
validada e atualizada quando o acompanhamento de água está ativo.

Notificações são opt-in. Login e bootstrap não solicitam permissão do sistema;
o pedido ocorre somente após ação afirmativa no onboarding. A preferência do
app é preservada mesmo se o sistema operacional negar a permissão.

## Evolução segura

Novas versões devem acrescentar IDs estáveis e migrar o estado de forma
idempotente. Uma versão concluída só pode continuar concluída se os invariantes
atuais de perfil e consentimento forem satisfeitos; caso contrário, deve virar
`needsReview`. Migrations antigas não devem ser reescritas.

Validação mínima: `flutter analyze`, testes de onboarding/roteamento/Settings,
testes Drift, teste da migration Supabase e a suíte Flutter completa.
