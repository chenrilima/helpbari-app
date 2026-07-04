# Code Style

## Widgets

Toda UI reutilizável deve ficar em shared/widgets.

Nunca duplicar widgets.

---

## Tokens

Nunca utilizar números mágicos.

❌

```dart
SizedBox(height: 18)
```

✔

```dart
SizedBox(height: AppSpacing.md)
```

---

## Cores

Nunca usar Color diretamente.

Sempre AppColors.

---

## Radius

Sempre AppRadius.

---

## Durations

Sempre AppDurations.

---

## Sombras

Sempre AppShadows.

---

## Tamanho

Sempre AppSizes.

---

## ViewModels

Toda regra de negócio fica na ViewModel.

A tela apenas renderiza.

---

## Repository

Toda comunicação externa fica em Repository.

Nunca acessar Supabase na UI.