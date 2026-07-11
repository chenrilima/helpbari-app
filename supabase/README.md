# Supabase local e migrations

O diretório versiona o schema do projeto HelpBari. A migration inicial foi
extraída do projeto remoto `idnjnpamqtygjzassgxn`. Dados de usuários e objetos
do Storage não fazem parte das migrations.

## Instalar a CLI

No macOS com Homebrew:

```bash
brew install supabase/tap/supabase
```

O ambiente local requer Docker Desktop ou Colima com Docker CLI.

## Login e vínculo

```bash
supabase login
supabase link --project-ref idnjnpamqtygjzassgxn
```

## Extrair mudanças feitas no Dashboard

Use `db pull` somente quando o remoto tiver mudanças legítimas que ainda não
estão versionadas:

```bash
supabase db pull nome_da_migration
```

Revise sempre o SQL criado antes de commitá-lo.

## Reproduzir o banco local

```bash
supabase start
supabase db reset
```

Para encerrar os containers sem apagar os volumes:

```bash
supabase stop
```

## Aplicar migrations no projeto vinculado

Primeiro confira o destino e as migrations pendentes:

```bash
supabase projects list
supabase migration list
supabase db push --dry-run
```

Somente depois de revisar o dry-run:

```bash
supabase db push
```

O banco remoto já existia antes da migration inicial. Antes do primeiro push,
marque a baseline como aplicada no remoto para que a CLI não tente recriá-la:

```bash
supabase migration repair --status applied 20260711000000
```

Esse comando altera apenas o histórico de migrations. Execute-o manualmente e
somente após confirmar que o projeto vinculado é o HelpBari correto.

## Criar uma migration

```bash
supabase migration new descricao_da_mudanca
```

Edite o SQL criado em `supabase/migrations`, valide com `supabase db reset` e
revise `supabase db push --dry-run` antes de qualquer envio remoto.
