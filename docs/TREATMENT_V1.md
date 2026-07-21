# Tratamento V1

## Estrutura

Tratamento é a entrada única para a leitura diária e o catálogo de itens. A
tela apresenta `Hoje → Itens → edição`, sem abas por categoria. Medicamento,
vitamina, suplemento e outro permanecem classificações internas de Smart
Routines.

## Responsabilidades

Smart Routines continua responsável por planos versionados, schedules,
occurrences, eventos, pausas, duração, PRN, conflitos e histórico. Unified
Treatment Engine continua responsável por cutover e compatibilidade. A camada
de apresentação apenas consulta os read models e dispara as fachadas existentes.

## Componentes reutilizados

- `TreatmentAdherenceQueryService` para a leitura de Hoje;
- fachadas Medication/Vitamin para os formulários compatíveis;
- `MedicationTile` e `VitaminTile` para ações e edição;
- `HBBottomSheet`, `HBDialog`, `HBSnackBar` e `HBLoadingOverlay`.

## Compatibilidade

`/medications` e `/vitamins` redirecionam para `/treatment`. Rotas de cadastro,
dados, mappings, migrations, sync e histórico permanecem preservados.
