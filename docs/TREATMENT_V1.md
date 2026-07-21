# Tratamento V1

## Estrutura

Tratamento é a entrada única para a leitura diária e o catálogo de itens. A
tela apresenta `Hoje → Itens → edição`, sem abas por categoria. Medicamento,
vitamina, suplemento e outro são classificações de Smart Routines.

## Escrita canônica

Smart Routines continua responsável por planos versionados, schedules,
occurrences, eventos, pausas, duração, PRN, conflitos e histórico. Unified
Treatment Engine continua responsável por cutover e compatibilidade.
`TreatmentWriteCommand` é a intenção pública usada pela experiência de
Tratamento. Ela suporta as quatro categorias, múltiplos horários, todos os dias
ou dias específicos, uso único, período definido, uso contínuo explícito,
duração não informada e uso quando necessário.

Uma alteração clínica fecha uma única vez o plano vigente e cria a próxima
revisão com `effectiveFrom`. Schedules anteriores permanecem imutáveis. Pausa e
retomada persistem o intervalo, conclusão muda o ciclo de vida e exclusão usa
tombstone. Nenhuma operação remove occurrences, events ou planos anteriores.

PRN usa `asNeeded` e não contém horários recorrentes. Portanto não produz
pendência, missed ou denominador pela simples ausência de uso.
O registro manual materializa occurrence ad hoc e event `taken` append-only
com horário e observação. O detalhe único apresenta informações, schedules,
events, revisões e pausas. Conflitos só são resolvidos por escolha humana e
corrections auditáveis; nenhuma versão é apagada.

## Lembretes

Cada horário é persistido como schedule próprio e pode habilitar ou desabilitar
seu lembrete. Toda escrita solicita reconciliação do manifest local; o
reconciliador continua respeitando permissão do SO e preferências global, de
categoria, item e schedule. A UI não solicita permissão automaticamente.

## Componentes reutilizados

- `TreatmentAdherenceQueryService` para a leitura de Hoje;
- formulário unificado para todas as novas escritas visíveis;
- fachadas Medication/Vitamin preservadas somente para compatibilidade;
- `HBDialog`, `HBSnackBar`, `HBLoadingOverlay`, `HBPage` e `HBCard`.

## Compatibilidade

`/medications` e `/vitamins` redirecionam para `/treatment`. Rotas antigas de
cadastro, dados, mappings, migrations, sync e histórico permanecem preservados.
Payloads antigos de Medication/Vitamin e novos payloads de Smart Routines usam
fallback autenticado para Tratamento.
