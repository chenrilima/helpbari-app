# Mais V1

## Estrutura

Mais organiza destinos de menor frequência em Acompanhamento, Conteúdo, Conta
e preferências, Privacidade e dados e Ajuda. Prescrições não têm entrada nessa
superfície.

## Responsabilidades

Mais é somente navegação. Consultas, Exames, Documentos, Relatórios, Academia,
Perfil, Settings, Privacy e BarIA continuam responsáveis por seus estados e
operações.

## Componentes reutilizados

`HBPage`, `HBAppBar`, `HBCard`, rotas existentes da Academia e o fluxo LGPD de
Privacy para consentimentos, exportação e exclusão.

## Compatibilidade

As rotas diretas anteriores permanecem registradas. Relatórios abertos por
Evolução ou Mais usam a mesma rota. Rotas e deep links de Prescrições são
preservados somente como fallback autenticado, sem promoção na UX.
