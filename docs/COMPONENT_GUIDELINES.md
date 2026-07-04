# Component Guidelines

## Objetivo

Definir regras para criação e manutenção dos componentes do Design System do HelpBari.

## Regra principal

Um componente do Design System nunca deve conhecer uma feature específica.

Ele não deve conhecer:

- Supabase
- Riverpod
- ViewModels
- Repositories
- Entidades específicas de features

## Um componente deve ser criado no Design System quando

- puder ser reutilizado em pelo menos três telas;
- representar um padrão visual recorrente;
- não depender de regra de negócio específica;
- melhorar consistência visual do app.

## Um componente deve ficar dentro da feature quando

- só faz sentido para uma tela específica;
- usa entidade específica da feature;
- depende de estado ou regra de negócio da feature.

## Imports

Componentes devem importar tokens pelo Design System.

Preferir:

```dart
import '../../../../design_system/design_system.dart';