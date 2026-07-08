# Arquitetura

Cada feature possui:

```
feature/

domain/

data/

presentation/
```

Domain:

- entities
- repositories
- usecases
- value_objects
- models

Data:

- fake_repository

Presentation:

- pages
- widgets
- providers
- states
- viewmodels

Nunca acessar Repository diretamente pela UI.

Sempre:

UI

↓

ViewModel

↓

UseCases

↓

Repository