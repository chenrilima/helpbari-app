# Distribuição de APK para testes

## Gate técnico

Não gerar novo APK enquanto qualquer gate obrigatório de `V1_RELEASE_READINESS.md` estiver aberto. Em 21/07/2026, conflitos exclusivamente baseados no relógio local e paginação incompleta mantêm o gate fechado.

## Assinatura

O repositório não contém keystore nem `key.properties` real. Isso é intencional. O responsável deve criar/guardar a chave em cofre seguro, configurar o build fora do Git e registrar alias, validade e processo de recuperação. APKs assinados por chaves diferentes não atualizam uns aos outros.

Antes da distribuição, verificar:

- `applicationId`, namespace, versionName e versionCode;
- release não-debuggable;
- manifest merged, backup, cleartext, permissões, receivers e deep links;
- ambiente Supabase correto e ausência de secrets no artefato/logs;
- assinatura com `apksigner verify --verbose --print-certs`;
- instalação limpa e upgrade sobre a última versão distribuída;
- smoke offline→online, A→logout→B, notificações, exportação e exclusão;
- hash SHA-256 do APK e canal controlado de distribuição.

Minificação/shrinking só devem ser habilitados com testes de release e regras para plugins. Não alterar isso apenas para reduzir tamanho antes de validar o comportamento.
