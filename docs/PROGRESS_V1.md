# Evolução V1

## Estrutura

Evolução é uma tela simples e rolável com resumos de Peso, Água, Alimentação,
Tratamento, Health Score, Bioimpedância e Relatórios. Cada seção encaminha para
o histórico completo já existente, carregado sob demanda.

## Responsabilidades

A tela não cria fonte clínica nem agrega históricos completos. O resumo de
peso reutiliza `ProgressViewModel`; cada domínio mantém seus repositories,
queries e providers. Health Score permanece fora da Home, apresenta cobertura
e inclui o aviso de que não é avaliação médica.

## Componentes reutilizados

`HBPage`, `HBCard`, `HBLoading`, `HBEmptyState`, `HealthScoreChartWidget`,
`ProgressViewModel` e as rotas existentes de cada domínio.

## Compatibilidade

Peso, Água, Refeições, Tratamento, Bioimpedância e Relatórios mantêm suas rotas
e autoridades. A raiz histórica `/progress` permanece a entrada de Evolução.
