# Validação manual de autenticação, onboarding e sync

## Builds

Nunca habilite `ALLOW_DEV_AUTH` em staging/prod. DevAuth também é bloqueado em
builds release, mesmo se a flag for passada.

```bash
flutter build apk --debug --dart-define=ENV=dev --dart-define=ALLOW_DEV_AUTH=true
flutter build apk --release --dart-define=ENV=staging --dart-define=SUPABASE_URL=https://STAGING.supabase.co --dart-define=SUPABASE_ANON_KEY=STAGING_PUBLISHABLE_KEY
flutter build apk --release --dart-define=ENV=prod --dart-define=SUPABASE_URL=https://PROD.supabase.co --dart-define=SUPABASE_ANON_KEY=PROD_PUBLISHABLE_KEY
```

Uma build staging/prod sem URL ou chave deve falhar no bootstrap. Uma build sem
defines não pode aceitar autenticação local. Para testar o backend real em dev,
omita `ALLOW_DEV_AUTH` e informe as credenciais Supabase.

## Roteiro

1. Faça uma instalação limpa e cadastre um e-mail novo.
2. Confirme o UUID em `auth.users`; se confirmação de e-mail estiver ativa,
   confirme o endereço e só então faça login.
3. Preencha o onboarding e confira no Drift que profile, consentimento,
   configurações e peso usam o mesmo UUID e permanecem `pending` até o commit.
4. Confira os registros no Supabase, encerre/reabra o app e valide que o
   onboarding não reaparece.
5. Repita o onboarding em modo avião. A Home deve abrir após a conclusão local;
   ao reconectar, o estado pending deve ser processado.
6. Force uma falha remota, valide que os dados continuam locais/pending e use o
   retry após restaurar a conexão.
7. Faça logout e entre com uma segunda conta. Ela deve ter onboarding, dados e
   fila próprios, sem visualizar registros da primeira.
8. Tente senha incorreta e confirme que Home/onboarding não são liberados.
9. Execute builds sem defines, dev com `ALLOW_DEV_AUTH=true` e staging/prod sem
   essa flag, validando os comportamentos descritos acima.

Registros legados com `user_id` igual a `dev-user` ou `anonymous` não são
reassociados automaticamente e devem permanecer isolados para revisão manual.
