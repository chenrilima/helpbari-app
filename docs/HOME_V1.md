# Home V1

Este documento registra a implementação do Bloco C. O contrato de produto
permanece em `PRODUCT_FREEZE_V1.md`.

## Shell

O produto autenticado usa `StatefulShellRoute.indexedStack` com quatro áreas:
Hoje, Tratamento, Evolução e Mais. Cada área mantém seu Navigator e seu estado
ao alternar a navegação inferior. Rotas de detalhe continuam no roteador
existente, preservando deep links, guards de sessão/onboarding e navegação de
notificações.

## Hoje

A rota `/home` continua usando a Home Intelligence Platform. A tela consome os
providers independentes de Agora, agenda, progresso, insights e ações rápidas;
falhas parciais não bloqueiam as demais seções e o snapshot anterior permanece
visível durante refresh.

Agora apresenta somente a ação de maior prioridade. Seu dia é uma única
timeline com alternância Hoje/Próximos 7 dias. Como está seu dia mostra apenas
os acompanhamentos diários aplicáveis. O feed determinístico fornece no máximo
um insight.

## Ações rápidas

As ações vêm do read model canônico e respeitam as preferências de
acompanhamento em Settings. A lista possui no máximo quatro itens: registrar
água, registrar refeição, ver tratamento e adicionar consulta. Abrir uma ação
de navegação nunca grava dados automaticamente.

## BarIA

A BarIA é aberta por um FAB contextual na área Hoje. Ela não ocupa uma aba e
continua usando a página, o histórico e o contexto minimizado existentes.

## Compatibilidade

As rotas anteriores permanecem registradas. `/home` e `/progress` agora são
raízes das áreas Hoje e Evolução. Taps de notificações continuam sendo
validados contra o usuário ativo antes da navegação. A máquina de entrada de
Auth/Onboarding permanece a autoridade para liberar o shell.

## Decisões arquiteturais

- nenhuma nova fonte de dados, repository, query ou provider foi criada;
- Home Intelligence Platform continua read-only e reconstruível;
- Smart Routines e Unified Treatment Engine não foram alterados;
- Notifications V1 e Onboarding V1 não foram alterados;
- Drift e o Sync Engine permanecem as autoridades existentes.
