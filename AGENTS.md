@RTK.md

# HelpBari - AI Agent Instructions

## Project Overview

HelpBari is a Flutter application that helps bariatric patients manage their daily health.

The codebase follows:

- Flutter
- Dart
- Clean Architecture
- Feature First
- MVVM
- Riverpod 3 (Notifier / AsyncNotifier)
- Drift (local database)
- Supabase (authentication + synchronization)
- Offline-first architecture
- Custom Design System

---

# Primary Goal

Always produce production-ready code.

Prefer extending existing architecture instead of introducing new abstractions.

Keep implementations simple, reusable and consistent with the rest of the project.

---

# Architecture

Always respect:

Presentation

↓

Application / Domain

↓

Data

Presentation must never depend directly on:

- Drift
- Supabase
- SQL
- HTTP
- Storage

Repositories are responsible for deciding where data comes from.

---

# Feature Structure

Each feature should follow the existing project organization.

Typical layers:

- presentation
- domain
- data

Do not reorganize folders unless explicitly requested.

---

# Existing Technologies

Use existing implementations whenever possible.

Priority:

1. Design System
2. Existing Providers
3. Existing Repositories
4. Existing Use Cases
5. Existing Services

Never create duplicate infrastructure.

---

# Flutter Rules

Always:

- keep widgets small
- keep business rules outside widgets
- reuse components
- avoid duplicated UI
- use const constructors whenever possible
- avoid rebuilding unnecessarily

---

# Riverpod Rules

Use Riverpod 3 patterns already adopted.

Prefer:

- Notifier
- AsyncNotifier

Do not duplicate providers.

Keep providers focused.

Avoid business logic inside widgets.

---

# Drift Rules

Drift is the local source of truth.

Always:

- preserve migrations
- use transactions
- keep DAOs focused
- preserve existing schema

Never rewrite old migrations.

---

# Supabase Rules

Supabase is responsible for remote synchronization.

Always:

- respect RLS
- use authenticated userId
- preserve updatedAt
- preserve createdAt
- preserve deletedAt
- preserve syncStatus

Never bypass repository abstractions.

---

# Offline First

Repositories must:

- save locally first
- sync afterwards
- never block UI
- preserve local consistency
- invalidate only affected providers

Reuse the existing Sync Engine.

Never implement a second synchronization solution.

---

# Existing References

Before implementing anything, inspect similar features.

Primary references:

- Water
- Profile
- Settings

Reuse their architecture.

---

# Design System

Always use existing HelpBari components.

Prefer:

- HBSnackBar
- HBDialog
- HBBottomSheet
- HBLoadingOverlay

Avoid raw Material widgets when an HB component already exists.

---

# Security

HelpBari handles sensitive health data.

Never:

- expose secrets
- expose Supabase keys
- expose access tokens
- log health records
- log personal information

Always preserve user isolation.

---

# Testing

When behavior changes:

- update unit tests
- update widget tests if necessary
- update repository tests

Run only the minimum validation necessary during development.

---

# Git

Never:

- reset user changes
- clean repository
- overwrite unrelated files

Keep changes scoped.

---

# Performance

Prefer:

- reusable widgets
- lazy loading
- efficient queries
- provider invalidation instead of global refreshes

Avoid unnecessary rebuilds.

---

# Code Quality

Always:

- use explicit typing
- keep methods small
- avoid duplicated code
- keep naming consistent
- keep imports organized

Prefer readability over clever implementations.

---

# Final Response

Always finish with:

- What changed
- Files modified
- Tests executed
- Remaining observations (if any)

Keep responses concise.