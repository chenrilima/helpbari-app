# RTK - HelpBari Token Optimization

## Objective

Use RTK whenever possible to reduce terminal output, minimize context usage and lower token consumption while preserving enough information to implement features safely.

Correctness always has higher priority than token savings.

---

# Command Routing

Always prefer RTK commands.

Examples:

```bash
rtk git status
rtk git diff
rtk git log

rtk flutter analyze
rtk flutter test
rtk dart test

rtk rg "WeightRepository"
rtk rg "WaterRepository"
rtk rg "SyncEngine"

rtk ls
```

Never execute raw commands unless:

- RTK does not support the command;
- RTK hides information required to solve the issue;
- the user explicitly requests raw output.

If raw commands are necessary, keep output as small as possible.

---

# Repository Inspection

Always inspect the repository using the following order:

1. Search
2. Read only relevant files
3. Implement
4. Validate
5. Finish

Never inspect the entire repository.

Prefer:

```bash
rtk rg "WeightRepository"
rtk rg "class WaterDao"
rtk rg "repositoryKey"
```

Avoid:

- tree
- find .
- recursive ls
- recursive grep

unless absolutely necessary.

---

# File Reading

Before opening files:

1. Locate the exact symbol using `rtk rg`.
2. Read only the files that contain the implementation.
3. Expand the search only if necessary.

Never read the entire repository.

Avoid reading:

- pubspec.lock
- generated *.g.dart
- *.freezed.dart
- build/
- .dart_tool/
- ios/Pods/
- android/.gradle/
- binary assets

unless the task explicitly requires them.

For large files:

- search first;
- read only the relevant section;
- avoid reopening the same file multiple times.

---

# Flutter Development

For Flutter projects always prefer the smallest possible validation.

Order:

1. dart format
2. flutter analyze (affected files/package)
3. flutter test (affected tests)
4. full analyze
5. full test

Prefer:

```bash
rtk dart format lib/features/weight

rtk flutter analyze lib/features/weight

rtk flutter test test/features/weight
```

Only execute:

```bash
rtk flutter analyze

rtk flutter test
```

when:

- requested by the user;
- preparing a final validation;
- changes affect multiple modules.

Never execute a full test suite after every small modification.

---

# Riverpod

Before creating a provider:

- search for existing providers;
- search for existing repositories;
- search for existing use cases.

Prefer extending the current architecture.

Avoid duplicate providers.

Keep business logic outside widgets.

Keep repositories independent from presentation.

---

# Drift

When changing Drift:

- modify only necessary tables;
- preserve migrations;
- never rewrite old migrations;
- use transactions when appropriate;
- keep DAO focused.

Always search for existing DAO implementations before creating new ones.

Prefer existing patterns from:

- Water
- Profile
- Settings

---

# Supabase

Use existing clients.

Never duplicate repositories.

Never bypass RLS.

Always preserve:

- createdAt
- updatedAt
- deletedAt
- syncStatus
- userId

Avoid unnecessary remote calls.

Prefer local-first behavior.

---

# Offline First

Repositories should:

- save locally first;
- synchronize afterwards;
- never block UI waiting for Supabase;
- invalidate only affected providers;
- preserve conflict resolution rules.

Prefer latest updatedAt when applicable.

Reuse existing Sync Engine.

Never create another synchronization mechanism.

---

# Git

Before implementing:

```bash
rtk git status

rtk git diff --stat
```

Inspect only affected files.

Avoid:

```bash
git diff
```

for the entire repository.

Never execute:

```bash
git reset --hard

git clean -fd

git checkout .

git restore .
```

unless explicitly requested.

Never overwrite user changes.

---

# Searching

Always prefer:

```bash
rtk rg "WeightRepository"

rtk rg "WaterRecord"

rtk rg "repositoryKey"

rtk rg "HBLoadingOverlay"
```

instead of:

```bash
find

grep -R

tree
```

Search for one concern at a time.

Do not perform broad searches repeatedly.

---

# Build Runner

Run build_runner only when:

- Drift schema changed;
- Riverpod generated code changed;
- Freezed changed.

Example:

```bash
rtk dart run build_runner build --delete-conflicting-outputs
```

Never regenerate code without necessity.

Never inspect generated files completely.

Inspect only generated diffs.

---

# Tests

Run only the relevant tests first.

When a test fails:

- identify the failing test;
- identify the root cause;
- rerun only the affected test.

Avoid printing the complete output of large test suites.

Summarize failures whenever possible.

---

# Logging

Prefer summaries over raw logs.

For Gradle, Flutter or Xcode:

- show the first actionable error;
- ignore duplicated downstream failures;
- avoid thousands of log lines.

---

# Security

Never expose:

- Supabase keys
- access tokens
- refresh tokens
- .env values
- signing keys
- service account credentials

Never print user health data unless required.

Never dump database contents.

---

# Token Saving Rules

Always prefer:

- targeted searches;
- targeted analysis;
- targeted tests;
- concise git diffs;
- concise terminal output.

Avoid:

- repository-wide scans;
- repeated analysis;
- repeated test execution;
- repeated file reads;
- unnecessary logs.

---

# Completion

Before finishing:

- summarize implementation;
- summarize changed files;
- summarize executed validations;
- report remaining risks if any.

Do not include unnecessary terminal output.

Use concise responses whenever possible.

Correctness is always more important than token reduction.