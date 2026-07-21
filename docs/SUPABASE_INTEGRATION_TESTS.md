# Supabase Integration Tests

## Estado verificado em 21/07/2026

`supabase migration list` conectou ao projeto vinculado e mostrou migrations remotas até `20260721000000`. Permanecem locais e pendentes:

- `20260722000000_onboarding_v1_foundation.sql`
- `20260723000000_notifications_v1.sql`

`supabase db lint --linked` concluiu sem erros. Isso não valida RLS. `supabase status` falhou porque o daemon Docker/Colima não estava disponível.

Nenhuma migration foi aplicada: não havia confirmação documentada de que o projeto vinculado era staging/produção correta nem evidência de backup disponível.

## Execução segura

1. Confirmar project ref e ambiente com o responsável.
2. Confirmar snapshot/backup e janela de rollback.
3. Iniciar Docker/Colima e executar `supabase start`.
4. Em banco local descartável, executar `supabase db reset` e os testes SQL. Nunca usar reset no remoto.
5. Executar `supabase db lint --local` e `supabase test db`.
6. Criar dois usuários reais de teste A/B e usar tokens `authenticated`, nunca `service_role`, para provar select/insert/update/tombstone cross-user e acesso anônimo.
7. Validar onboarding, notification preferences, plans/revisions/schedules/occurrences/adherence, Storage e RPCs LGPD.
8. Somente após aprovação explícita, aplicar as migrations pendentes com `supabase db push --include-all` no ambiente confirmado.
9. Repetir `supabase migration list`, lint e testes RLS no ambiente aplicado.

## Critério de aprovação

O backend só pode ser marcado validado quando a lista estiver em paridade e testes autenticados provarem que A não lê, altera ou cria dados para B, anônimo não acessa tabelas protegidas, tombstones continuam owner-scoped e os backfills preservam usuários existentes.
