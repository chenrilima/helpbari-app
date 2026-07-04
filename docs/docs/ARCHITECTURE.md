# HelpBari Architecture

## Objetivo

HelpBari é um aplicativo Flutter voltado para o acompanhamento da jornada de pacientes bariátricos.

O projeto foi desenvolvido para ser escalável, modular e de fácil manutenção, permitindo no futuro a evolução para uma plataforma utilizada também por clínicas e profissionais da saúde.

---

# Stack

- Flutter
- Riverpod
- MVVM
- Supabase
- GoRouter

---

# Organização

lib/

app/
core/
shared/
features/

---

# Features

Cada feature possui sua própria estrutura.

feature/

data/
domain/
presentation/

---

# Camadas

## Domain

Contém regras de negócio.

Não conhece Flutter.

Não conhece Supabase.

Não conhece UI.

---

## Data

Contém implementações.

Supabase

REST

Storage

Cache

Modelos

---

## Presentation

Contém:

Pages

Widgets

ViewModels

States

---

# Shared

Widgets reutilizáveis.

---

# Core

Utilitários globais.

Validators

Extensions

Result

Errors

Logger

Formatter

Config

---

# Princípios

- Clean Code
- SOLID
- Baixo acoplamento
- Alta coesão
- Componentização
- Testabilidade
- Reutilização