import 'dart:io';

/// Generates the full flutter_bloc AI-guidance doc set (mirrors the
/// spaceflight_news reference project) into a freshly created project.
/// Called only when the selected state management is Bloc.
class BlocAiDocsCreator {
  Future<void> create(String basePath) async {
    await _write('$basePath/AGENTS.md', _agentsMd);
    await _write('$basePath/CLAUDE.md', _claudeMd);
    await _write('$basePath/.claude/rules/ARCHITECTURE.md', _rulesArchitectureMd);
    await _write('$basePath/.claude/rules/CLI_WORKFLOW.md', _rulesCliWorkflowMd);
    await _write('$basePath/.claude/rules/CODE_TEMPLATES.md', _rulesCodeTemplatesMd);
    await _write('$basePath/.claude/rules/UI_RULES.md', _rulesUiRulesMd);
    await _write('$basePath/.claude/skills/clean_architecture_pattern.md', _skillsCleanArchitecturePatternMd);
    await _write('$basePath/.claude/skills/qa_test.md', _skillsQaTestMd);
    await _write('$basePath/.claude/docs/SECURITY.md', _docsSecurityMd);
    await _write('$basePath/.claude/settings.json', _settingsJson);
    await _write('$basePath/.claude/mcp/mcp.json', _mcpJson);
    await _write('$basePath/.claude/hooks/_secret_patterns.sh', _hookSecretPatternsSh);
    await _write('$basePath/.claude/hooks/on_stop.sh', _hookOnStopSh);
    await _write('$basePath/.claude/hooks/post_write.sh', _hookPostWriteSh);
    await _write('$basePath/.claude/hooks/pre_bash_git_guard.sh', _hookPreBashGitGuardSh);
    await _write('$basePath/.claude/hooks/pre_commit.sh', _hookPreCommitSh);
    await _write('$basePath/.claude/hooks/pre_edit_guard.sh', _hookPreEditGuardSh);
    await _write('$basePath/.claude/hooks/scan_git_history.sh', _hookScanGitHistorySh);
    await _write('$basePath/.claude/scripts/launch_for_testing.sh', _scriptLaunchForTestingSh);
    await _write('$basePath/.claude/scripts/setup_secrets.sh', _scriptSetupSecretsSh);

    // Make hook & script shell files executable.
    final shellFiles = <String>[
      '$basePath/.claude/hooks/_secret_patterns.sh',
      '$basePath/.claude/hooks/on_stop.sh',
      '$basePath/.claude/hooks/post_write.sh',
      '$basePath/.claude/hooks/pre_bash_git_guard.sh',
      '$basePath/.claude/hooks/pre_commit.sh',
      '$basePath/.claude/hooks/pre_edit_guard.sh',
      '$basePath/.claude/hooks/scan_git_history.sh',
      '$basePath/.claude/scripts/launch_for_testing.sh',
      '$basePath/.claude/scripts/setup_secrets.sh',
    ];
    for (final path in shellFiles) {
      await Process.run('chmod', ['+x', path]);
    }
  }

  Future<void> _write(String fullPath, String content) async {
    final file = File(fullPath);
    await file.create(recursive: true);
    await file.writeAsString(content);
  }
}

// ============================================================
// Embedded doc contents (verbatim mirror of spaceflight_news).
// ============================================================

// --- AGENTS.md ---
final _agentsMd = r'''# Mobile Team — AI Agent Context

> **Canonical source of truth for every AI coding tool.**
> Read natively by: GitHub Copilot · OpenAI Codex · Cursor · Aider · Claude Code

---

## Stack (Always Active)

| Concern | Choice |
|---------|--------|
| Language | Dart / Flutter (3.11+) |
| Architecture | Clean Architecture — feature-based |
| State | flutter_bloc (Bloc + sealed Events/States) |
| HTTP | Dio 5.x — `response.data` is already parsed |
| Error type | `Either<Failure, T>` via `dartz` |
| DI | GetIt (`sl` singleton) |
| Sizing | `flutter_screenutil` (`.w .h .sp .r`) |
| Scaffolding | `ssl_cli` (Dart global) |
| Safe JSON | `autosafe_json` → `SafeJson.as*()` |
| Secrets | `envied` → always read via `Env.*` |

---

## 5 Golden Rules (Never Break)

1. **Scaffold with CLI** — never create folders manually → `ssl_cli module <name>`
2. **Safe JSON only** — never raw-cast → `SafeJson.asString(json['x'])`, not `json['x'] as String`
3. **Secrets via envied** — never hardcode → `Env.apiKey`, never `dotenv` / `String.fromEnvironment`
4. **Global widgets only** — never raw Flutter → `GlobalText`, `GlobalButton`, `GlobalLoader`, etc.
5. **Never touch generated files** — `env.g.dart`, `key.properties`, `Secret.xcconfig` are auto-generated

### Data → Domain mapping pattern (mandatory read)

Before writing **any** model, entity, or repository:

> **Read `.claude/skills/clean_architecture_pattern.md` first.**

It documents the non-negotiable layering this codebase uses: nullable `*_response.dart` DTOs decoded with `SafeJson.as*`, non-nullable `*_entity.dart` value objects with **default values for every field**, and explicit field-by-field model → entity mapping inside `*_repository_impl.dart` with `?? defaultValue` fallbacks. Models **do not** extend entities. Ground-truth reference: `lib/features/homes/` in this project.

---

## Agent Decision Flow (Run Every Task)

```
Received a task?
  ↓
ssl_cli help --all       → not found? → dart pub global activate ssl_cli
  ↓
autosafe --version       → not found? → dart pub global activate autosafe_json
  ↓
New project?    → Yes → ssl_cli create <name>   (pattern 4 · Bloc)
New feature?    → Yes → ssl_cli module <name>   (pattern 3 · Bloc)
Modified model? → Yes → autosafe /path/to/model.dart
Added assets?   → Yes → ssl_cli generate k_assets.dart
  ↓
Fill logic · Register DI in service_locator.dart · Verify .gitignore
```

---

## DI Registration Order (service_locator.dart)

```dart
// 1. DataSources    → registerLazySingleton
// 2. Repository     → registerLazySingleton
// 3. UseCases       → registerFactory   ← always Factory, never Singleton
```

---

## Widget Substitution Table

| ❌ Never | ✅ Always |
|---------|---------|
| `Text(...)` | `GlobalText(str: ...)` |
| `ElevatedButton(...)` | `GlobalButton(...)` |
| `TextFormField(...)` | `GlobalTextFormField(...)` |
| `DropdownButton(...)` | `GlobalDropdown(...)` |
| `Image.asset(...)` | `GlobalImageLoader(...)` |
| `CircularProgressIndicator()` | `GlobalLoader()` |
| `AppBar(...)` | `GlobalAppBar(...)` |
| `showSnackBar(...)` | `ViewUtil.snackbar(context, msg)` |
| `Color(0xFF...)` hardcoded | `AppColors.primary.color` |
| Asset path string | `ImageNamePng.x` / `SvgName.x` |
| `200` / `16` (raw numbers) | `200.w` / `16.sp` / `12.r` |

> **Note:** `GlobalText` handles `.sp` internally — pass `fontSize` as a plain `double`, not `16.sp`.

---

## Key Error Handling Rule

Every repository method MUST use `handleException()` — **never** manual try/catch:

```dart
@override
Future<Either<Failure, ProductEntity>> getProduct(String id) {
  return handleException(() async {
    final result = await remoteDataSource.getProduct(id);
    return result.toEntity();
  });
}
```

---

## Detailed References

Pull these files when you need full templates, patterns, or rules for a specific topic:

| Topic | File |
|-------|------|
| **Data → Domain mapping (autosafe_json, entity defaults, repo bridge)** | `.claude/skills/clean_architecture_pattern.md` |
| Architecture, folder structure, naming, DI patterns | `.claude/rules/ARCHITECTURE.md` |
| CLI usage, ssl_cli & autosafe step-by-step workflow | `.claude/rules/CLI_WORKFLOW.md` |
| Full code templates (Entity, Model, UseCase, Bloc, Page) | `.claude/rules/CODE_TEMPLATES.md` |
| UI rules, global widgets, responsive sizing | `.claude/rules/UI_RULES.md` |
| Security rules, forbidden files, envied setup, .gitignore | `.claude/docs/SECURITY.md` |
| **Push notifications (FCM) + Android 14 monochrome icon fix** | `.claude/skills/push_notification.md` |
| QA & testing guidance | `.claude/skills/qa_test.md` |

> **AI agents:** Read the relevant reference file before generating any code for that topic.

---

## Development Pipeline

```
Stage 1: User Prompt → Stage 2: Coding → Stage 3: Testing
```

- **User Prompt** → extract user demand and plan about the feature, and ask for any missing information from the user and confirm it with the user to make sure everything is correct
- **Coding** → ssl_cli → fill logic → autosafe → register DI and create test file for each usecase and bloc
- **Testing** → unit-test UseCases & Blocs · widget-test components · ≥ 80% coverage- - and manual testing using flutter-skill and run the app to test the feature, if any bug found, list them and ask user what to do.

---

*Maintained by Mobile Team · See `.claude/` for all extended rules*
''';

// --- CLAUDE.md ---
final _claudeMd = r'''# Claude Code — Mobile Team Entry Point

> **Universal rules live in `AGENTS.md`** (read by Copilot, Codex, Cursor fallback, etc.).
> Claude Code imports it below, then layers on Claude-specific automation (hooks, MCP, skills).

@AGENTS.md

---

## Claude-Specific Extensions

The sections below apply ONLY when working through Claude Code. Other IDEs ignore them.

---

### Hooks (`.claude/settings.json`)

These run automatically on every Claude Code session. They protect the codebase from accidental secret leaks and destructive operations.

| Event | Matcher | Hook script | Purpose |
|-------|---------|-------------|---------|
| `PreToolUse` | `Bash` | `pre_bash_git_guard.sh` | Intercepts every Bash call. Blocks destructive `git` ops; delegates `git commit` / `git push` to `pre_commit.sh` for full secret scan. |
| `PreToolUse` | `Write\|Edit` | `pre_edit_guard.sh` | Blocks any write to forbidden secret files (`.env`, `*.jks`, `env.g.dart`, etc.). |
| `PostToolUse` | `Write\|Edit` | `post_write.sh` | Scans the file just written for leaked secret patterns. Informational. |
| `Stop` | — | `on_stop.sh` | Appends session-end timestamp to `.claude/audit.log`. |

**Shared library:** `.claude/hooks/_secret_patterns.sh` — single source of secret regexes, sourced by all guard hooks.

**Manual scans:**
```bash
bash .claude/hooks/pre_commit.sh         # Run secret-leak scan on staged files manually
bash .claude/hooks/scan_git_history.sh   # Scan ENTIRE git history for past secret leaks
bash .claude/hooks/scan_git_history.sh --fix   # Auto-add findings to .gitignore
```

**Hook exit codes:** Exit `0` allows the operation, exit `2` blocks it. Post hooks can never block.

---

### MCP Server — `flutter-skill`

`.mcp.json` at project root → Claude Code auto-discovers on every session.

```json
{
  "mcpServers": {
    "flutter-skill": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-flutter-skill", "server"]
    }
  }
}
```

Connects to a running Flutter app via Dart VM Service URL. Used for:
- Live UI inspection (semantic snapshots of running screens)
- Automated tap / type / scroll for QA testing
- Bug detection on real devices

**MCP changes require an IDE restart.**

---

### Permissions Pre-Approved (`.claude/settings.json`)

Claude Code can run these without user prompt:

```
Bash(ssl_cli help:*) · Bash(ssl_cli create:*) · Bash(ssl_cli module:*)
Bash(ssl_cli generate:*) · Bash(ssl_cli build:*)
Bash(autosafe:*)
Bash(flutter --version) · Bash(flutter create:*) · Bash(flutter pub:*)
Bash(dart pub:*) · Bash(dart run build_runner:*)
Bash(sh .claude/scripts/setup_secrets.sh) · Bash(python3:*)
```

Anything outside this list will trigger a permission prompt.

---

### Skills — `/qa_test`

`.claude/skills/qa_test.md` — invoke via `/qa_test` to run the **Senior QA Automation Protocol**.

**Phase 1: Device discovery & connection**
1. `flutter devices` → identify attached device ID
2. `bash .claude/scripts/launch_for_testing.sh <DEVICE_ID>` → starts app, writes VM URL to `.claude/tmp/vm_url.txt`
3. Connect `flutter-skill` MCP to the VM URL

**Phase 2: Semantic discovery**
- `snapshot` / `inspect_interactive` → map every tappable & typeable element
- Build internal mental model of the UI

**Phase 3: Edge-case matrix**
| Test | Action | Looking for |
|------|--------|-------------|
| Empty state | Submit form with zero input | Required-field validation messages |
| Boundary value | Paste 200+ chars into text field | TextOverflow / RenderFlex overflow |
| Special chars | Input `🔥DROP TABLE;` | Crash / improper escaping |
| Keyboard layout | Tap input near bottom of screen | Keyboard hides submit button (BottomInset overflow) |
| Fast double-tap | Tap submit twice rapidly | Duplicate API calls |

**Phase 4: Bug report → STOP**
- Output structured markdown report with: bug, trigger sequence, suspected root cause
- **Do NOT write any fix.** Pause and ask: *"Which of these would you like me to resolve using the ssl_cli architecture?"*
- Only proceed to write code after user explicitly approves.

---

### Scripts — Quick Reference

| Script | Purpose |
|--------|---------|
| `.claude/scripts/setup_secrets.sh` | Reads `.env` → decodes JKS, Firebase configs → generates `key.properties` + `Secret.xcconfig`. Re-run whenever `.env` changes. |
| `.claude/scripts/launch_for_testing.sh <DEVICE_ID>` | Starts `flutter run` in background, captures VM URL to `.claude/tmp/vm_url.txt` for MCP testing. |
| `.claude/scripts/setup_ide.sh` | Interactive IDE setup — choose your IDE, generates only the needed config files. Also offers universal git pre-commit hook. |

---

### Modular Rules (`.claude/rules/`)

Claude Code auto-includes every `.md` file in this folder as additional context. Currently:

- `ARCHITECTURE.md` — Clean Architecture deep-dive (folder rules, layer constraints)
- `CLI_WORKFLOW.md` — Step-by-step `ssl_cli` & `autosafe_json` workflow
- `CODE_TEMPLATES.md` — Copy-paste templates (entity, model, repo, usecase, bloc, page)
- `UI_RULES.md` — Global widgets + responsive sizing details

Edit these for Claude-specific deep dives. Universal rules belong in `AGENTS.md`.

---

### Extended Docs (`.claude/docs/`)

- `SECURITY.md` — Full secret management runbook: forbidden file list, JKS placement, `.gitignore` validation, emergency response when a secret is leaked.

---

### Audit Log

`.claude/audit.log` — append-only log written by `on_stop.sh`. Records every Claude session end timestamp. Useful for compliance and incident review.

---

## How to Update This Setup

1. **Universal rule changes** → edit `AGENTS.md` (every IDE benefits)
2. **Claude-specific changes** → edit this file or `.claude/rules/*.md`
3. **Distribute to other IDEs** → `sh .claude/scripts/setup_ide.sh` (choose your IDE)
4. **Restart IDE** if you changed `.mcp.json` or `.claude/settings.json`

---

*Mobile Team · Claude Code orchestration v1*
''';

// --- .claude/rules/ARCHITECTURE.md ---
final _rulesArchitectureMd = r'''# Architecture Rules — Clean Architecture (Feature Based)

> **Purpose:** Strict structure and dependency rules for Flutter Clean Architecture with flutter_bloc.

## Core Architecture Pattern

This project follows **Clean Architecture** with **flutter_bloc** state management. All code MUST follow this three-layer structure:

```
Domain Layer (Business Logic) → Data Layer (Data Management) → Presentation Layer (UI)
```

**Dependency Rule:** Dependencies ONLY point inward. Domain has NO dependencies on outer layers.

```
┌──────────────────────────┐
│ Presentation Layer       │  Bloc (flutter_bloc), Pages, Widgets
├──────────────────────────┤
│ Domain Layer             │  UseCases, Entities, Repository Contracts
├──────────────────────────┤
│ Data Layer               │  Models, Repository Impl, Remote/Local DataSources
└──────────────────────────┘
```

---

## Mandatory Feature Module Structure

When creating ANY new feature, this exact folder structure is required:

```
lib/features/{feature_name}/
├── data/
│   ├── datasources/
│   │   ├── {feature}_remote_datasource.dart
│   │   └── {feature}_local_datasource.dart
│   ├── models/
│   │   └── {feature}_response.dart      # wire DTO (nullable, SafeJson) — does NOT extend entity
│   └── repositories/
│       └── {feature}_repository_impl.dart
├── domain/
│   ├── entities/
│   │   └── {entity_name}_entity.dart
│   ├── repositories/
│   │   └── {feature}_repository.dart
│   └── usecases/
│       └── {action}_usecase.dart
└── presentation/
    ├── pages/
    │   └── {page_name}_page.dart
    ├── bloc/
    │   ├── {feature}_bloc.dart
    │   ├── event/
    │   │   └── {feature}_event.dart
    │   └── state/
    │       └── {feature}_state.dart
    └── widgets/
        └── {widget_name}.dart
```

## Core Structure (Shared Infrastructure)

```
lib/core/
├── config/            # env.dart (envied secrets)
├── constants/         # API URLs, app constants
├── di/                # Dependency injection (GetIt)
├── entities/          # Base entities
├── error/             # Exceptions and failures
├── models/            # Global models
├── network/           # API client, network info
├── presentation/
│   ├── widgets/       # Global reusable widgets
│   └── mixins/        # Shared presentation logic
├── routes/            # Navigation
├── theme/             # Theme, colors
├── usecases/          # Base UseCase interface
└── utils/             # Helpers, extensions
```

---

## Dependency Injection Rules

```dart
// 1. Data Sources
sl.registerLazySingleton<{Feature}RemoteDataSource>(
  () => {Feature}RemoteDataSourceImpl(apiClient: sl()),
);

// 2. Repository
sl.registerLazySingleton<{Feature}Repository>(
  () => {Feature}RepositoryImpl(remoteDataSource: sl(), localDataSource: sl()),
);

// 3. Use Cases (Factory)
sl.registerFactory(() => {Action}UseCase(repository: sl()));
```

---

## Error Handling Pattern (MANDATORY)

```dart
// core/error/failures.dart
abstract class Failure extends Equatable {
  final String message;
  const Failure({required this.message});
  @override
  List<Object> get props => [message];
}

class NetworkFailure extends Failure {
  const NetworkFailure({required super.message});
}
```

**Error Flow:**
1. **Data Source:** Throw exceptions
2. **Repository:** Catch exceptions → Return `Left(Failure)`
3. **Use Case:** Pass through `Either<Failure, Data>`
4. **Bloc:** In the `on<Event>` handler, `result.fold()` → `emit()` the matching state (`{Feature}Error` / `{Feature}Loaded`)

---

## Naming Conventions (STRICT)

| Type | Pattern | Example |
|------|---------|---------|
| Entity | `{name}_entity.dart` | `home_entity.dart` |
| Response (DTO) | `{feature}_response.dart` | `home_response.dart` |
| UseCase | `{action}_usecase.dart` | `get_user_usecase.dart` |
| Repository | `{feature}_repository.dart` | `auth_repository.dart` |
| Bloc | `{feature}_bloc.dart` | `login_bloc.dart` |
| Event | `{feature}_event.dart` | `login_event.dart` |
| State | `{feature}_state.dart` | `login_state.dart` |
| Page | `{name}_page.dart` | `login_page.dart` |

---

## Common Architecture Mistakes

1. ❌ NOT checking ssl_cli before scaffolding
2. ❌ Manually creating folders/files instead of using ssl_cli
3. ❌ Skipping layers (always domain → data → presentation)
4. ❌ Domain layer importing Flutter or data layer packages
5. ❌ Not registering dependencies in service_locator.dart
''';

// --- .claude/rules/CLI_WORKFLOW.md ---
final _rulesCliWorkflowMd = r'''# CLI Workflow — ssl_cli & autosafe_json

> **Purpose:** Step-by-step workflow AI agents MUST follow before writing any code.

## ⚠️ **Before handling any secret, key, or credential — read `.claude/docs/SECURITY.md` first. Those rules are ABSOLUTE.**

## Step 1 — Check if ssl_cli is Installed

```bash
ssl_cli help --all
```

- ✅ **If output is shown** → ssl_cli is installed. Proceed to Step 2.
- ❌ **If command not found** → Install it first:

```bash
dart pub global activate ssl_cli
```

Then verify PATH is set:
- **macOS/Linux:** `export PATH="$PATH":"$HOME/.pub-cache/bin"` → add to `~/.zshrc` or `~/.bashrc`
- **Windows:** Add Dart pub cache to System Environment Variables

---

## Step 2 — Use ssl_cli for ALL Scaffolding

> 🚫 **AI agents MUST NOT manually create folders/files for project or module scaffolding.**
> ✅ **ALWAYS use ssl_cli commands. This saves tokens and ensures consistent structure.**

### Creating a New Project

```bash
ssl_cli create <project_name>
```
- When prompted for pattern → **select pattern `4`** (Clean Architecture)
- When prompted for state management → **select `Bloc`** (flutter_bloc)

### Adding a New Feature Module

```bash
ssl_cli module <module_name>
```
- When prompted for pattern → **select Clean Architecture pattern `3`**
- When prompted for state management → **select `Bloc`** (flutter_bloc)

### After Adding Assets (Images / SVGs)

> ⚠️ **Whenever any image or SVG file is added to the assets folder, run this immediately:**

```bash
ssl_cli generate k_assets.dart
```

**Rules:**
- ✅ ALWAYS run after adding any `.png`, `.jpg`, `.jpeg`, `.svg` file
- ✅ Reference assets via generated enum only (e.g. `ImageNamePng.myImage`, `SvgName.myIcon`)
- ❌ NEVER hardcode asset paths as raw strings

### Build & Release

```bash
ssl_cli build apk --flavorType       # --DEV / --LIVE / --LOCAL / --STAGE
ssl_cli build apk --flavorType --t   # Build + auto-share to Telegram
```

---

## Step 3 — Check autosafe_json

```bash
autosafe --version
```

- ❌ **If command not found** → Install:

```bash
dart pub global activate autosafe_json
```

- Add to `pubspec.yaml`:
```yaml
dependencies:
  autosafe_json: ^1.0.0
```

### After Every Model Change

```bash
autosafe /path/to/your/model/{feature}_response.dart
```

---

## Step 4 — Fill in Logic

Once ssl_cli generates the structure, fill in:
- Entity fields
- Model `fromJson` / `toJson`
- UseCase business logic
- Repository implementation
- Bloc events, states & `on<Event>` handlers
- UI page & widgets

> Only write code **inside** the generated files. Never create new folders manually.

---

## Agent Decision Flow

```
AI receives a task
       ↓
Run: ssl_cli help --all
       ↓
Found? ──No──→ dart pub global activate ssl_cli → verify → continue
       │
      Yes
       ↓
Is autosafe_json activated?
       ↓
Run: autosafe --version
       ↓
Found? ──No──→ dart pub global activate autosafe_json → verify → continue
       │
      Yes
       ↓
Is it a new project? ──Yes──→ ssl_cli create <project_name> (pick pattern 4 + Bloc)
       │                       + Verify .gitignore has all secret file entries
      No
       ↓
Is it a new feature? ──Yes──→ ssl_cli module <module_name> (pick pattern 3 + Bloc)
       │
      No
       ↓
Did you write or modify a fromJson? ──Yes──→ autosafe /path/to/model.dart
       │
      No
       ↓
Added new assets? ──Yes──→ ssl_cli generate k_assets.dart
       │
      No
       ↓
Fill in logic inside generated files following architecture rules
```
''';

// --- .claude/rules/CODE_TEMPLATES.md ---
final _rulesCodeTemplatesMd = r'''# Code Templates — Domain, Data & Presentation Layers

> **Purpose:** Copy-paste templates for every layer. All code generation MUST follow these patterns.

---

## Domain Layer Templates

### Entity Template

```dart
// lib/features/{feature}/domain/entities/{entity_name}_entity.dart
import 'package:equatable/equatable.dart';

class {EntityName}Entity extends Equatable {
  final int id;
  final String name;

  const {EntityName}Entity({
    this.id = 0,
    this.name = '',
  });

  @override
  List<Object?> get props => [id, name];
}
```

**Rules:**
- ✅ MUST extend `Equatable`
- ✅ MUST be immutable (`const` constructor, `final` fields)
- ✅ MUST be **non-nullable with defaults** (`0`, `''`, `false`, `const []`) — the UI never null-checks
- ✅ Models NEVER extend entities — the repository maps model → entity (`?? default`)
- ✅ NO Flutter imports, NO `fromJson` (entities never touch raw JSON)
- ✅ NO external package dependencies (except `equatable`)

### Repository Contract Template

```dart
// lib/features/{feature}/domain/repositories/{feature}_repository.dart
import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/{entity_name}_entity.dart';

abstract class {Feature}Repository {
  Future<Either<Failure, {Entity}Entity>> get{Entity}(String id);
  Future<Either<Failure, List<{Entity}Entity>>> get{Entity}List();
  Future<Either<Failure, void>> create{Entity}({Entity}Entity entity);
  Future<Either<Failure, void>> update{Entity}({Entity}Entity entity);
  Future<Either<Failure, void>> delete{Entity}(String id);
}
```

### UseCase Template

```dart
// lib/features/{feature}/domain/usecases/{action}_usecase.dart
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/{entity_name}_entity.dart';
import '../repositories/{feature}_repository.dart';

class {Action}UseCase implements UseCase<{Return}Entity, {Action}Params> {
  final {Feature}Repository repository;

  {Action}UseCase({required this.repository});

  @override
  Future<Either<Failure, {Return}Entity>> call({Action}Params params) async {
    return await repository.{action}(params);
  }
}

class {Action}Params extends Equatable {
  final String id;

  const {Action}Params({required this.id});

  @override
  List<Object?> get props => [id];
}
```

---

## Data Layer Templates

### 🛡️ autosafe_json — Mandatory Safe JSON Parsing

> **All models MUST use `autosafe_json`. Raw `as` casting is strictly forbidden.**

#### Helper Methods Reference

| Helper | Input type | Safe output |
|--------|-----------|-------------|
| `SafeJson.asInt(v)` | any | `int` (0 if null/invalid) |
| `SafeJson.asString(v)` | any | `String` ('' if null) |
| `SafeJson.asBool(v)` | any | `bool` (false if null) |
| `SafeJson.asDouble(v)` | any | `double` (0.0 if null) |
| `SafeJson.asNum(v)` | any | `num` (0 if null) |
| `SafeJson.asMap(v)` | list/map/null | `Map<String, dynamic>` |
| `SafeJson.asList(v)` | list/map/null | `List<dynamic>` |
| `json.autoSafe.raw` | raw json map | sanitized `Map<String, dynamic>` |

#### Integration Rule

- `json = json.autoSafe.raw;` → **ONLY in the top-level / base response model**
- **Nested models** receive the pre-sanitized map → no need to call `autoSafe.raw` again
- Use `SafeJson.as*()` helpers for every primitive field in every model

### Response Model Template (wire DTO)

> Models are **standalone DTOs** — they do **NOT** extend entities. Fields are
> nullable and decoded with `SafeJson.as*`. The repository maps this DTO to the
> entity. See `.claude/skills/clean_architecture_pattern.md` for the full pattern.

```dart
// lib/features/{feature}/data/models/{feature}_response.dart
import 'package:autosafe_json/autosafe_json.dart';

class {Feature}Response {
  final int? count;
  final List<{Item}>? results;

  {Feature}Response({this.count, this.results});

  factory {Feature}Response.fromJson(Map<String, dynamic> json) {
    json = json.autoSafe.raw; // ← top-level ONLY
    return {Feature}Response(
      count: SafeJson.asInt(json['count']),
      results: json['results'] == null || json['results'] == ''
          ? []
          : List<{Item}>.from(
              SafeJson.asList(json['results'])
                  .map((x) => {Item}.fromJson(SafeJson.asMap(x))),
            ),
    );
  }

  Map<String, dynamic> toJson() => {
        'count': count,
        'results': results == null
            ? []
            : List<dynamic>.from(results!.map((x) => x.toJson())),
      };
}

class {Item} {
  final int? id;
  final String? name;

  {Item}({this.id, this.name});

  factory {Item}.fromJson(Map<String, dynamic> json) => {Item}(
        id: SafeJson.asInt(json['id']),
        name: SafeJson.asString(json['name']),
      );

  Map<String, dynamic> toJson() => {'id': id, 'name': name};
}
```

**Rules:**
- ✅ MUST import `package:autosafe_json/autosafe_json.dart`
- ✅ MUST use `SafeJson.as*()` for every field — no raw `as` casting
- ✅ MUST call `json.autoSafe.raw` **only** in the top-level response model (nested items get an already-sanitised map)
- ✅ Fields are **nullable**; the repository coalesces them to entity defaults with `??`
- ❌ NEVER `extends {Entity}Entity` — models and entities are separate hierarchies
- ❌ NEVER use `json['field'] as String` — always use `SafeJson.asString(json['field'])`

---

## Presentation Layer Templates (flutter_bloc)

> State management is **flutter_bloc**. Each feature owns a `bloc/` folder split into
> `event/`, `state/`, and the bloc itself. **Events** and **States** are `sealed` classes
> extending `Equatable`. The UI dispatches events with
> `context.read<{Feature}Bloc>().add(...)` and rebuilds with `BlocBuilder`.

### Event Template

```dart
// lib/features/{feature}/presentation/bloc/event/{feature}_event.dart
import 'package:equatable/equatable.dart';

sealed class {Feature}Event extends Equatable {
  const {Feature}Event();

  @override
  List<Object?> get props => [];
}

class Load{Feature}s extends {Feature}Event {
  const Load{Feature}s();
}

class Refresh{Feature}s extends {Feature}Event {
  const Refresh{Feature}s();
}
```

### State Template

```dart
// lib/features/{feature}/presentation/bloc/state/{feature}_state.dart
import 'package:equatable/equatable.dart';
import '/features/{feature}/domain/entities/{entity_name}_entity.dart';

sealed class {Feature}State extends Equatable {
  const {Feature}State();

  @override
  List<Object?> get props => [];
}

class {Feature}Initial extends {Feature}State {
  const {Feature}Initial();
}

class {Feature}Loading extends {Feature}State {
  const {Feature}Loading();
}

class {Feature}Loaded extends {Feature}State {
  final List<{Entity}> items;

  const {Feature}Loaded(this.items);

  @override
  List<Object?> get props => [items];
}

class {Feature}Error extends {Feature}State {
  final String message;

  const {Feature}Error(this.message);

  @override
  List<Object?> get props => [message];
}
```

### Bloc Template

```dart
// lib/features/{feature}/presentation/bloc/{feature}_bloc.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import '/core/di/service_locator.dart';
import '/core/usecases/usecase.dart';
import '../../domain/usecases/{action}_usecase.dart';
import 'event/{feature}_event.dart';
import 'state/{feature}_state.dart';

class {Feature}Bloc extends Bloc<{Feature}Event, {Feature}State> {
  {Feature}Bloc() : super(const {Feature}Initial()) {
    on<Load{Feature}s>(_onLoad);
    on<Refresh{Feature}s>(_onRefresh);
  }

  Future<void> _onLoad(Load{Feature}s event, Emitter<{Feature}State> emit) async {
    emit(const {Feature}Loading());
    final useCase = sl<{Action}UseCase>();
    final result = await useCase(NoParams());
    result.fold(
      (failure) => emit({Feature}Error(failure.message)),
      (data) => emit({Feature}Loaded(data)),
    );
  }

  Future<void> _onRefresh(
    Refresh{Feature}s event,
    Emitter<{Feature}State> emit,
  ) async {
    await _onLoad(const Load{Feature}s(), emit);
  }
}
```

**Rules:**
- ✅ MUST make `Event` and `State` `sealed` classes extending `Equatable`
- ✅ MUST register one `on<Event>` handler per event in the constructor
- ✅ MUST resolve use cases via `sl<{Action}UseCase>()`, then `result.fold()` → `emit(...)`
- ❌ NEVER put business logic in the UI — the widget only dispatches events

### Page Template

```dart
// lib/features/{feature}/presentation/pages/{page_name}_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/presentation/widgets/global_appbar.dart';
import '../../../../core/presentation/widgets/global_text.dart';
import '../../../../core/presentation/widgets/global_loader.dart';
import '../bloc/{feature}_bloc.dart';
import '../bloc/event/{feature}_event.dart';
import '../bloc/state/{feature}_state.dart';

class {Page}Page extends StatefulWidget {
  const {Page}Page({super.key});

  @override
  State<{Page}Page> createState() => _{Page}PageState();
}

class _{Page}PageState extends State<{Page}Page> {
  @override
  void initState() {
    super.initState();
    context.read<{Feature}Bloc>().add(const Load{Feature}s());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const GlobalAppBar(title: '{Page}'),
      body: BlocBuilder<{Feature}Bloc, {Feature}State>(
        builder: (context, state) {
          return switch (state) {
            {Feature}Loading() ||
            {Feature}Initial() => const Center(child: GlobalLoader()),
            {Feature}Error(:final message) => Center(child: GlobalText(str: message)),
            {Feature}Loaded(:final items) => ListView.builder(
              itemCount: items.length,
              itemBuilder: (context, index) => GlobalText(str: '${items[index]}'),
            ),
          };
        },
      ),
    );
  }
}
```

**Providing the bloc** — wrap the page (or the app in `main.dart`) with `BlocProvider`:

```dart
BlocProvider(
  create: (_) => {Feature}Bloc(),
  child: const {Page}Page(),
)
// Multiple blocs → MultiBlocProvider(providers: [...], child: ...)
```

**Rules:**
- ✅ MUST rebuild with `BlocBuilder<{Feature}Bloc, {Feature}State>` + `switch` over the sealed state
- ✅ MUST dispatch events via `context.read<{Feature}Bloc>().add(...)` (first load in `initState`)
- ✅ MUST provide the bloc with `BlocProvider` / `MultiBlocProvider`
- ✅ MUST use global widgets (GlobalText, GlobalButton, etc.)
- ✅ MUST use ScreenUtil (.w, .h, .sp, .r)

---

## Common Code Mistakes

**autosafe_json:**
- ❌ Using raw `as` casting: `json['id'] as String`
- ❌ Adding `json.autoSafe.raw` to nested models (only in top-level)
- ❌ Forgetting to run `autosafe /path/to/model.dart` after modifying `fromJson`

**Security:**
- ❌ Hardcoding API keys, tokens, or passwords in any Dart file
- ❌ Committing `google-services.json` or `GoogleService-Info.plist`
- ❌ Using `flutter_dotenv` or `String.fromEnvironment` for secrets — use envied only
- ❌ Editing `key.properties` or `Secret.xcconfig` manually — auto-generated by script
''';

// --- .claude/rules/UI_RULES.md ---
final _rulesUiRulesMd = r'''# UI Rules — Global Widgets & Responsive Sizing

> **Purpose:** Mandatory UI component and sizing rules for all presentation layer code.

---

## Global Widgets (MANDATORY)

| ❌ DON'T USE | ✅ USE INSTEAD |
|-------------|---------------|
| `Text()` | `GlobalText()` |
| `ElevatedButton()` | `GlobalButton()` |
| `TextFormField()` | `GlobalTextFormField()` |
| `DropdownButton()` | `GlobalDropdown()` |
| `Image.asset()` | `GlobalImageLoader()` |
| `CircularProgressIndicator()` | `GlobalLoader()` |
| `AppBar()` | `GlobalAppBar()` |
| `snackbar` | `ViewUtil.snackbar(context, message)` |

---

## Responsive Sizing (MANDATORY)

All sizing MUST use `flutter_screenutil` extensions:

```dart
// ❌ DON'T
Container(width: 200, height: 100)

// ✅ DO
Container(width: 200.w, height: 100.h)
GlobalText(str: 'Hello', fontSize: 16)
```

**Extensions:**
- `.w` — width scaling
- `.h` — height scaling
- `.sp` — font size scaling
- `.r` — radius scaling

---

## Design System

- Colors defined in `AppColors` enum — never hardcode HEX values
- Assets registered in `k_assets.dart` enum — never hardcode asset paths
- After adding any image or SVG → run `ssl_cli generate k_assets.dart`

---

## Common UI Mistakes

- ❌ Using Flutter widgets directly instead of global widgets
- ❌ Hard-coded sizes without ScreenUtil
- ❌ Hardcoding color HEX values instead of using `AppColors`
- ❌ Not running `ssl_cli generate k_assets.dart` after adding new images or SVGs
''';

// --- .claude/skills/clean_architecture_pattern.md ---
final _skillsCleanArchitecturePatternMd = r'''# Clean Architecture Data → Domain Pattern

**Read this BEFORE writing any model, entity, or repository in this codebase.**

This is the canonical pattern used across all features. The pattern is non-negotiable — deviating will create review churn.

---

## TL;DR — Three Layers, Three Roles

| File | Purpose | Field shape | Null handling |
|------|---------|-------------|---------------|
| `data/models/*_response.dart` | Wire-shape DTO. Mirrors API JSON 1:1. | All fields **nullable** (`String?`, `int?`, `List<X>?`) | Decoded with `SafeJson.as*` |
| `domain/entities/*_entity.dart` | UI-facing immutable value object. Has **defaults**. | All fields **non-nullable** with defaults (`this.id = 0`, `this.items = const []`) | Cannot be null at use site |
| `data/repositories/*_repository_impl.dart` | Bridge. Maps model → entity with `?? defaultValue` fallbacks. | — | Coalesces every nullable model field into an entity default |

**Golden rule:** Models DO NOT `extend` entities. They are two independent class hierarchies that the repository wires together.

---

## Required package

```yaml
# pubspec.yaml
dependencies:
  autosafe_json: ^1.0.0
```

`autosafe_json` exposes:
- `SafeJson.asString(dynamic)` → `String?`
- `SafeJson.asInt(dynamic)` → `int?`
- `SafeJson.asDouble(dynamic)` → `double?`
- `SafeJson.asBool(dynamic)` → `bool?`
- `SafeJson.asMap(dynamic)` → `Map<String, dynamic>`
- `SafeJson.asList(dynamic)` → `List<dynamic>`
- `json.autoSafe.raw` extension on `Map<String, dynamic>` — sanitises the top-level map before parsing.

Use these everywhere you cross a JSON boundary. **Never** raw-cast (`json['x'] as String`).

---

## Template — `*_response.dart` (data/models)

Mirror the JSON shape exactly. Every field is nullable. Use defensive `null`/`""` checks before recursing into nested objects.

```dart
import 'package:autosafe_json/autosafe_json.dart';

class HomeResponse {
  final HomeResponseData? data;

  HomeResponse({this.data});

  factory HomeResponse.fromJson(Map<String, dynamic> json) {
    json = json.autoSafe.raw;                              // ← top-level sanitise
    return HomeResponse(
      data: json["data"] == null || json["data"] == ""    // ← defensive check
          ? null
          : HomeResponseData.fromJson(SafeJson.asMap(json["data"])),
    );
  }

  Map<String, dynamic> toJson() => {"data": data?.toJson()};
}

class HomeResponseData {
  final TotalData? totalData;
  final List<History>? history;

  HomeResponseData({this.totalData, this.history});

  factory HomeResponseData.fromJson(Map<String, dynamic> json) => HomeResponseData(
        totalData: json["total_data"] == null || json["total_data"] == ""
            ? null
            : TotalData.fromJson(SafeJson.asMap(json["total_data"])),
        history: json["history"] == null || json["history"] == ""
            ? []
            : List<History>.from(
                SafeJson.asList(json["history"])
                    .map((x) => History.fromJson(SafeJson.asMap(x))),
              ),
      );

  Map<String, dynamic> toJson() => {
        "total_data": totalData?.toJson(),
        "history": history == null
            ? []
            : List<dynamic>.from(history!.map((x) => x.toJson())),
      };
}

class History {
  final int? id;
  final String? deliveryDate;

  History({this.id, this.deliveryDate});

  factory History.fromJson(Map<String, dynamic> json) => History(
        id: SafeJson.asInt(json["id"]),                    // ← SafeJson.as*
        deliveryDate: SafeJson.asString(json["delivery_date"]),
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "delivery_date": deliveryDate,                     // ← snake_case keys
      };
}
```

### Conventions inside response files

- Class names: PascalCase (no `Model` suffix on inner classes — only the outer wrapper is `*Response`).
- Field names: camelCase in Dart, `snake_case` in JSON.
- Every constructor parameter is **named, optional, nullable** — no `required`.
- `fromJson` is a `factory` constructor.
- `toJson` is a regular method returning `Map<String, dynamic>`.
- Lists: default to `[]` on null/"", but the field type stays `List<X>?` (Dart nullable).
- Nested objects: defensive `json["x"] == null || json["x"] == ""` ternary before recursing.

### Generating these files

If `autosafe_json` CLI is available locally:

```bash
autosafe /path/to/raw_response.json
```

…produces the file with the exact shape above. Otherwise write by hand following the template.

---

## Template — `*_entity.dart` (domain/entities)

Pure value objects. **All fields non-nullable**. Every constructor parameter has a default. Extend `Equatable`. No `SafeJson`, no `fromJson` — entities never see raw JSON.

```dart
import 'package:equatable/equatable.dart';

class HomeEntity extends Equatable {
  final TotalDataEntity totalData;
  final List<HistoryEntity> history;
  final int historyCount;

  const HomeEntity({
    this.totalData = const TotalDataEntity(),             // ← nested entity default
    this.history = const [],                              // ← list default
    this.historyCount = 0,                                // ← primitive default
  });

  @override
  List<Object?> get props => [totalData, history, historyCount];
}

class TotalDataEntity extends Equatable {
  final int total;
  final int running;
  final int completed;

  const TotalDataEntity({this.total = 0, this.running = 0, this.completed = 0});

  @override
  List<Object?> get props => [total, running, completed];
}

class HistoryEntity extends Equatable {
  final int id;
  final String deliveryDate;
  final String quantity;

  const HistoryEntity({
    this.id = 0,
    this.deliveryDate = "",
    this.quantity = "",
  });

  @override
  List<Object?> get props => [id, deliveryDate, quantity];
}
```

### Conventions inside entity files

- Class names: PascalCase with `Entity` suffix.
- Constructor: `const`, all named, all optional with a default.
- `String` default → `""`. `int`/`double` → `0`. `bool` → `false`. `List<X>` → `const []`. Nested entity → `const FooEntity()`.
- **No nullable fields.** If the wire field is genuinely optional, give the entity a sensible empty default.
- `props` enumerates every field (Equatable).

---

## Template — `*_repository_impl.dart` (data/repositories)

This is where models become entities. Field-by-field mapping with `?? defaultValue` to coalesce model nullables. Wrap the whole thing in `handleException()`.

```dart
import 'package:dartz/dartz.dart';
import '/core/error/exception_handler.dart';
import '/core/error/failures.dart';
import '../../domain/entities/home_entity.dart';
import '../../domain/repositories/home_repository.dart';
import '../datasources/home_remote_datasource.dart';

class HomeRepositoryImpl implements HomeRepository {
  final HomeRemoteDataSource _remoteDataSource;

  HomeRepositoryImpl({required HomeRemoteDataSource remoteDataSource})
      : _remoteDataSource = remoteDataSource;

  @override
  Future<Either<Failure, HomeEntity>> getHomes() async {
    return handleException(() async {
      final response = await _remoteDataSource.getHomes();

      // Explicit data-model → domain-entity mapping. Every nullable model
      // field gets coalesced to the entity's default.
      return HomeEntity(
        totalData: TotalDataEntity(
          total: response.data?.totalData?.total ?? 0,
          running: response.data?.totalData?.running ?? 0,
          completed: response.data?.totalData?.completed ?? 0,
        ),
        history: (response.data?.history ?? [])
            .map((item) => HistoryEntity(
                  id: item.id ?? 0,
                  deliveryDate: item.deliveryDate ?? "",
                  quantity: item.quantity ?? "",
                ))
            .toList(),
        historyCount: response.data?.history?.length ?? 0,
      );
    });
  }
}
```

### Conventions inside repository impl

- One repository method per use case.
- Always wrap in `handleException(() async { ... })`.
- Build the entity inline — do not put a `.toEntity()` helper on the model. The mapping lives explicitly in the repository so it's auditable in one place.
- Use `??` for every primitive, `?? ""` for every string, `?? []` for every list, `?? const FooEntity()` for nested entities.

---

## Template — `*_remote_datasource.dart` (data/datasources)

Returns the **model/response type**, not the entity. Translates `_apiClient.request(...)` → typed response.

```dart
abstract class HomeRemoteDataSource {
  Future<HomeResponse> getHomes();
}

class HomeRemoteDataSourceImpl implements HomeRemoteDataSource {
  final ApiClient _apiClient;
  HomeRemoteDataSourceImpl({required ApiClient apiClient}) : _apiClient = apiClient;

  @override
  Future<HomeResponse> getHomes() async {
    try {
      final response = await _apiClient.request(
        endpoint: ApiUrl.getHomes.url,
        method: HttpMethod.get,
      );
      return HomeResponse.fromJson(response);
    } catch (e) {
      rethrow;                                            // ← let handleException catch it
    }
  }
}
```

---

## Template — `*_repository.dart` (domain/repositories)

Interface returns `Either<Failure, Entity>` — never the model.

```dart
abstract class HomeRepository {
  Future<Either<Failure, HomeEntity>> getHomes();
}
```

---

## Template — `*_event.dart` (presentation/bloc/event)

Events are `sealed` and extend `Equatable` — one per user intent.

```dart
import 'package:equatable/equatable.dart';

sealed class HomeEvent extends Equatable {
  const HomeEvent();

  @override
  List<Object?> get props => [];
}

class LoadHomes extends HomeEvent {
  const LoadHomes();
}

class RefreshHomes extends HomeEvent {
  const RefreshHomes();
}
```

## Template — `*_state.dart` (presentation/bloc/state)

States are `sealed` and extend `Equatable`. The loaded state carries the **entity directly** — the UI never has to null-check the data field.

```dart
import 'package:equatable/equatable.dart';
import '/features/home/domain/entities/home_entity.dart';

sealed class HomeState extends Equatable {
  const HomeState();

  @override
  List<Object?> get props => [];
}

class HomeInitial extends HomeState {
  const HomeInitial();
}

class HomeLoading extends HomeState {
  const HomeLoading();
}

class HomeLoaded extends HomeState {
  final HomeEntity homeData;                              // ← entity, non-nullable

  const HomeLoaded(this.homeData);

  @override
  List<Object?> get props => [homeData];
}

class HomeError extends HomeState {
  final String message;

  const HomeError(this.message);

  @override
  List<Object?> get props => [message];
}
```

## Template — `*_bloc.dart` (presentation/bloc)

The bloc registers one `on<Event>` handler per event, resolves the use case via `sl<...>()`, and folds the `Either` into a state.

```dart
import 'package:flutter_bloc/flutter_bloc.dart';
import '/core/di/service_locator.dart';
import '/core/usecases/usecase.dart';
import '../../domain/usecases/get_home_usecase.dart';
import 'event/home_event.dart';
import 'state/home_state.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  HomeBloc() : super(const HomeInitial()) {
    on<LoadHomes>(_onLoad);
    on<RefreshHomes>(_onRefresh);
  }

  Future<void> _onLoad(LoadHomes event, Emitter<HomeState> emit) async {
    emit(const HomeLoading());
    final result = await sl<GetHomeUseCase>()(NoParams());
    result.fold(
      (failure) => emit(HomeError(failure.message)),                // ← Left
      (entity) => emit(HomeLoaded(entity)),                         // ← Right
    );
  }

  Future<void> _onRefresh(RefreshHomes event, Emitter<HomeState> emit) async {
    await _onLoad(const LoadHomes(), emit);
  }
}
```

---

## Anti-patterns — Common Mistakes

| ❌ Don't | ✅ Do |
|---------|------|
| `class HomeModel extends Home` | Keep models and entities completely separate |
| `class Home { required this.id }` (entity) | `class HomeEntity { this.id = 0 }` (defaults) |
| `int id = json['id'] is int ? json['id'] : 0` | `int? id = SafeJson.asInt(json['id'])` (in model) |
| Inline mapping inside data source | Explicit mapping inside repository impl |
| Manual `try { } catch (e) { return Left(...) }` in repo | Wrap in `handleException()` |
| `homeData: HomeEntity?` in state | `homeData: HomeEntity = const HomeEntity()` |
| `json['x'] as Map<String, dynamic>` | `SafeJson.asMap(json['x'])` |
| Mixing `.toEntity()` helpers on models | Map field-by-field in repository |

---

## End-to-End Checklist

When adding a new feature endpoint, work top-down:

- [ ] **JSON sample** — copy the raw success response into your scratchpad.
- [ ] **Response model** (`data/models/*_response.dart`) — wire-shape DTO, all nullable, `SafeJson.as*`.
- [ ] **Entity** (`domain/entities/*_entity.dart`) — non-null with defaults, Equatable.
- [ ] **Repository interface** (`domain/repositories/*_repository.dart`) — returns `Either<Failure, Entity>`.
- [ ] **Remote datasource** (`data/datasources/*_remote_datasource.dart`) — returns the response type, `rethrow` on catch.
- [ ] **Repository impl** (`data/repositories/*_repository_impl.dart`) — `handleException` + explicit model→entity mapping with `??` fallbacks.
- [ ] **Use case** (`domain/usecases/*_usecase.dart`) — `implements UseCase<Entity, Params>`.
- [ ] **Event** (`presentation/bloc/event/*_event.dart`) — sealed events extending `Equatable`.
- [ ] **State** (`presentation/bloc/state/*_state.dart`) — sealed states; the loaded state carries the entity.
- [ ] **Bloc** (`presentation/bloc/*_bloc.dart`) — `on<Event>` handlers call the use case and fold into states.
- [ ] **DI** (`core/di/service_locator.dart`) — register datasource (lazy singleton), repo (lazy singleton), use case (factory).

---

*If anything in this skill conflicts with newer guidance in `.claude/rules/` or `AGENTS.md`, ask the user before deviating. Treat this project's `lib/features/homes/` implementation as the ground-truth reference.*
''';

// --- .claude/skills/qa_test.md ---
final _skillsQaTestMd = r'''# Senior QA Protocol — `/qa_test`

You are a **Senior QA Engineer** with 10+ years of mobile testing experience.
You do NOT just run a checklist — you think, explore, and break things like a real user.
You notice visual glitches, interaction delays, missing feedback, and edge cases.

---

## Prerequisites

`flutter_skill` must be set up in the project before using this protocol.

**pubspec.yaml:**
```bash
flutter pub add flutter_skill
```

**lib/main.dart:**
```dart
import 'package:flutter/foundation.dart';
import 'package:flutter_skill/flutter_skill.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (kDebugMode) FlutterSkillBinding.ensureInitialized();
  runApp(MyApp());
}
```

**`.mcp.json` at project root:**
```json
{
  "mcpServers": {
    "flutter-skill": {
      "command": "flutter-skill",
      "args": ["server"]
    }
  }
}
```
> MCP changes require an IDE restart to take effect.

---

## Phase 1 — Device & App Connection

### Step 1 — Check if the app is already running

Read `.claude/tmp/vm_url.txt`.

- ✅ **URL found** (e.g. `ws://127.0.0.1:PORT/.../ws`) → skip to **Step 3**.
- ❌ **File missing or empty** → proceed to Step 2.

Also check `.claude/tmp/flutter_run.log` if the file is missing:
```bash
grep -o "ws://127.0.0.1:[0-9]*/[^/]*/ws" .claude/tmp/flutter_run.log | head -1
```

### Step 2 — Launch the app (only if not already running)

```bash
flutter devices
```
Note the device ID, then run:
```bash
bash .claude/scripts/launch_for_testing.sh <DEVICE_ID>
```
This starts the app in the background and writes the VM URL to `.claude/tmp/vm_url.txt`.

Wait until `.claude/tmp/vm_url.txt` is populated with a `ws://` URL before continuing.

### Step 3 — Connect flutter-skill MCP to the running app

Call the `connect_app` tool from the `flutter-skill` MCP server.
Pass the `ws://` URL from `.claude/tmp/vm_url.txt` as the connection argument.

> `flutter_skill` only works in debug mode. Never test against `--release` or `--profile` builds.

---

## Phase 2 — Semantic Discovery

1. Call `snapshot` or `inspect_interactive` to map every visible element on the current screen.
2. Build a mental model of the UI: layout, hierarchy, tappable/typeable elements, visible states.
3. Before running any test, ask yourself:
   - What is the normal user flow on this screen?
   - What does each state look like: loading / empty / error / success?
   - What would a confused or impatient user do?

---

## Phase 3 — QA Testing

### 3a — Happy Path
Walk the screen exactly as a real user would:
- Navigate to the feature fresh (observe the loading state)
- Interact with every visible element in natural order
- Scroll all content — check for overflow, clipping, misalignment
- Check text: truncation, line wrapping, font size
- Check images: loading placeholder, broken image fallback, aspect ratio
- Check colors, spacing, alignment — does it look polished?

### 3b — Edge Case Matrix

| Test | Action | Looking For |
|------|--------|-------------|
| Empty state | View screen with no data | Proper empty-state message, not a blank screen |
| Loading flash | Watch cold start | Unexpected "No data" flash before data loads |
| Long text | Products/items with long titles | Text truncates or wraps gracefully |
| Zero values | Items with 0 price, 0 stock | No crash, no empty badge containers |
| Scroll to bottom | Scroll list to the very end | Pagination triggers, end-of-list message appears |
| Pull-to-refresh | Pull down on list | Refreshes without empty-state flash |
| Network failure | Turn off internet → trigger action | Error state shown, Retry button works |
| Fast double-tap | Tap any action button twice rapidly | No duplicate API calls or double navigation |
| Keyboard overlap | Tap input near bottom of screen | Keyboard does not hide the submit button |
| Boundary input | Paste 200+ chars in any text field | No `TextOverflow` / `RenderFlex` overflow |
| Special chars | Input `🔥DROP TABLE;` in any field | No crash, no improper escaping |
| Theme switch | Toggle dark/light mode | All colors and text adapt correctly |

### 3c — Code Quality Checks (Visual Scan)
While testing, flag any of these as bugs:
- Raw `Text()`, `ElevatedButton()`, `CircularProgressIndicator()` → must use Global widgets
- Hardcoded sizes like `width: 200` → must use `.w`, `.h`, `.sp`, `.r`
- Hardcoded hex colors → must use `AppColors.*`
- Hardcoded asset paths → must use `ImageNamePng.*` / `SvgName.*`

---

## Phase 4 — Bug Report → STOP

Output a structured report for every bug found.

| # | Severity | Bug | Steps to Trigger | Suspected Root Cause |
|---|----------|-----|-----------------|----------------------|
| 1 | Critical / High / Medium / Low | What failed | Exact steps | Widget / layer |

**[STOP HERE]** — Do NOT write any fix.

Ask the user:
> *"Here is the bug list. Which of these would you like me to resolve"*

Only write code after the user explicitly confirms.
''';

// --- .claude/docs/SECURITY.md ---
final _docsSecurityMd = r'''## 🔒 SECURITY RULES — AI AGENT HARD LIMITS (NON-NEGOTIABLE)

> 🛑 **These rules are ABSOLUTE. No exception, no override, no matter who asks.**

---

### Files AI Must NEVER Read, Display, Print, or Expose

| File / Pattern | Reason |
|----------------|--------|
| `.env`, `.env.*` | Environment secrets |
| `android/key.properties` | Gradle signing credentials + Maps key |
| `android/app/release.jks`, `*.keystore`, `*.jks` | Signing keystores |
| `ios/Flutter/Secret.xcconfig` | iOS native secrets |
| `lib/core/config/env.g.dart` | Generated obfuscated secrets |
| `google-services.json` | Firebase Android credentials |
| `GoogleService-Info.plist` | Firebase iOS credentials |
| `local.properties` | Local SDK paths |
| `serviceAccountKey.json`, `*_service_account*.json` | GCP / Firebase admin keys |
| `*.p12`, `*.pfx`, `*.pem`, `*.cer`, `*.crt` | Certificates & private keys |

---

### JKS Keystore — Fixed Location Rule

> ⚠️ **The JKS file MUST always be placed at `android/app/release.jks`. No exceptions.**

```
project-root/
└── android/
    └── app/
        └── release.jks   ← ALWAYS here. Gitignored. Never committed.
```

**When AI is asked to help set up signing:**
1. Tell the developer to place their `.jks` file at `android/app/release.jks`
2. Tell them to add `KEYSTORE_PASSWORD`, `KEY_ALIAS`, `KEY_PASSWORD` to `.env`
3. Tell them to run `sh .claude/scripts/setup_secrets.sh`
4. Never suggest a relative path or a path outside the `android/app/` folder

---

### Mandatory Security Behaviors

```
✅ DO:
  - Always use Env.* from lib/core/config/env.dart for secrets in Dart code
  - Always place JKS at android/app/release.jks
  - Always run sh .claude/scripts/setup_secrets.sh after .env changes
  - Always run dart run build_runner build after .env or env.dart changes
  - Instruct developers to fill .env from the team vault

❌ NEVER DO:
  - Print, display, or suggest any hardcoded token, password, or key
  - Read the contents of any file in the forbidden list above
  - Generate code with hardcoded API keys, secrets, or passwords
  - Suggest committing any secret file to version control
  - Write any secret value in a comment, log statement, or print()
  - Use flutter_dotenv or String.fromEnvironment — envied is the only approved method
  - Suggest placing the JKS outside android/app/ folder
```

---

### If a Secret File Is Accidentally Shared

If the user pastes content that contains secrets (tokens, keys, passwords):
1. **Do NOT** repeat, quote, or reference the secret value
2. Immediately warn: *"⚠️ This content appears to contain sensitive credentials. I will not process or display secret values. Please revoke and rotate these keys immediately if they were exposed."*
3. Provide guidance on how to secure it instead

---

### Secret Handling Code Pattern (MANDATORY — envied only)

```dart
// ❌ NEVER generate this
const apiKey = 'sk-abc123-real-secret-key';

// ❌ NEVER generate these either
final apiKey = dotenv.env['API_KEY'] ?? '';
const apiKey = String.fromEnvironment('API_KEY');

// ✅ ONLY approved pattern — read from Env.* (envied)
import 'package:your_app/core/config/env.dart';

final apiKey  = Env.paymentApiKey;
final mapsKey = Env.googleMapsApiKey;
final baseUrl = Env.baseUrlLive;
```

All fields declared in `lib/core/config/env.dart`. Generated obfuscated into `lib/core/config/env.g.dart`.

---

### .env Structure (single source of truth)

```dotenv
BASE_URL_LIVE=https://api.yourapp.com
BASE_URL_DEV=https://dev-api.yourapp.com
BASE_URL_LOCAL=http://192.168.1.100:8000
BASE_IMAGE_URL_LIVE=https://images.yourapp.com
BASE_IMAGE_URL_DEV=https://dev-images.yourapp.com
GOOGLE_MAPS_API_KEY=AIzaSyDUMMY_replace
PAYMENT_API_KEY=pk_test_DUMMY_replace
SMS_API_KEY=sms_DUMMY_replace
KEYSTORE_PASSWORD=dummy_replace
KEY_ALIAS=dummy_replace
KEY_PASSWORD=dummy_replace
```

---

### .gitignore Validation

Whenever generating a project, the AI agent MUST verify these entries exist in `.gitignore`:

```gitignore
.env
.env.*
android/key.properties
android/app/release.jks
android/app/*.jks
ios/Flutter/Secret.xcconfig
lib/core/config/env.g.dart
*.keystore
google-services.json
GoogleService-Info.plist
local.properties
serviceAccountKey.json
*.p12
*.pem
*.cer
```

---

### How Secrets Flow (full picture)

```
.env (developer fills, gitignored)
  │
  ├─ sh .claude/scripts/setup_secrets.sh
  │     ├──→ android/key.properties
  │     │     storeFile = release.jks  ← relative path inside android/app/
  │     │     storePassword, keyAlias, keyPassword, GOOGLE_MAPS_API_KEY
  │     │
  │     └──→ ios/Flutter/Secret.xcconfig
  │           GOOGLE_MAPS_API_KEY
  │
  └─ dart run build_runner build
        └──→ lib/core/config/env.g.dart  (XOR-obfuscated — Dart reads via Env.*)
```

**CI/CD:** GitHub Actions writes `.env` from GitHub Secrets, decodes JKS to `android/app/release.jks`,
runs the script, then runs build_runner, then builds.
''';

// --- .claude/settings.json ---
// Permissions intentionally empty (each project grants its own); the security
// guard hooks are kept so they run automatically on every session.
final _settingsJson = r'''{
  "permissions": {},
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "command": "bash .claude/hooks/pre_bash_git_guard.sh"
          }
        ]
      },
      {
        "matcher": "Write|Edit",
        "hooks": [
          {
            "type": "command",
            "command": "bash .claude/hooks/pre_edit_guard.sh"
          }
        ]
      }
    ],
    "PostToolUse": [
      {
        "matcher": "Write|Edit",
        "hooks": [
          {
            "type": "command",
            "command": "bash .claude/hooks/post_write.sh"
          }
        ]
      }
    ],
    "Stop": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "bash .claude/hooks/on_stop.sh"
          }
        ]
      }
    ]
  }
}''';

// --- .claude/mcp/mcp.json ---
final _mcpJson = r'''{
  "mcpServers": {
    "flutter-skill": {
      "command": "flutter-skill",
      "args": [
        "server"
      ]
    }
  }
}''';

// --- .claude/hooks/_secret_patterns.sh ---
final _hookSecretPatternsSh = r'''#!/bin/bash
# ============================================================
# _secret_patterns.sh  —  Shared detection library
# Sourced by all other hook scripts. Do NOT run directly.
# ============================================================

# ── 1. Protected filenames (never commit these) ────────────
BLOCKED_FILES=(
    ".env"
    ".env.local"
    ".env.production"
    ".env.staging"
    ".env.development"
    "key.properties"
    "local.properties"
    "keystore.jks"
    "release.jks"
    "release.keystore"
    "debug.keystore"
    "GoogleService-Info.plist"
    "google-services.json"
    "firebase_options.dart"
    "secrets.dart"
    "api_keys.dart"
    "credentials.dart"
    ".netrc"
    "service-account.json"
    "service_account.json"
)

# ── 2. Secret patterns (LABEL:::REGEX) ────────────────────
SECRET_PATTERNS=(
    "Google API Key:::AIza[0-9A-Za-z\-_]{35}"
    "Google OAuth Client ID:::[0-9]+-[0-9A-Za-z_]{32}\.apps\.googleusercontent\.com"
    "Firebase URL:::https://[a-z0-9-]+\.firebaseio\.com"
    "Generic api_key:::api[_-]?key\s*[:=]\s*['\"][A-Za-z0-9_\-]{16,}['\"]"
    "Generic apiKey:::apiKey\s*[:=]\s*['\"][A-Za-z0-9_\-]{16,}['\"]"
    "Generic secret:::secret\s*[:=]\s*['\"][A-Za-z0-9_\-]{16,}['\"]"
    "Generic token:::token\s*[:=]\s*['\"][A-Za-z0-9_\-]{20,}['\"]"
    "Generic password:::password\s*=\s*['\"][^'\"]{6,}['\"]"
    "AWS Access Key:::AKIA[0-9A-Z]{16}"
    "AWS Secret Key:::aws_secret_access_key\s*=\s*[A-Za-z0-9/+]{40}"
    "Stripe Secret Key:::sk_live_[0-9a-zA-Z]{24}"
    "Stripe Test Key:::sk_test_[0-9a-zA-Z]{24}"
    "GitHub Token:::ghp_[A-Za-z0-9]{36}"
    "Slack Token:::xox[baprs]-[0-9A-Za-z\-]{10,48}"
    "Bearer Token:::Bearer\s+[A-Za-z0-9\-._~+/]{20,}"
)

# ── Check filename against blocked list ────────────────────
is_blocked_filename() {
    local filepath="$1"
    local bname
    bname=$(basename "$filepath")
    for pattern in "${BLOCKED_FILES[@]}"; do
        if [[ "$bname" == "$pattern" ]] || [[ "$filepath" == *"/$pattern" ]]; then
            echo "$pattern"; return 0
        fi
    done
    return 1
}

# ── Scan file content for secret patterns ──────────────────
scan_file_for_secrets() {
    local filepath="$1"
    local found=0
    for entry in "${SECRET_PATTERNS[@]}"; do
        local label="${entry%%%:::*}"
        local pattern="${entry#*:::}"
        if grep -qPi "$pattern" "$filepath" 2>/dev/null; then
            local linenum
            linenum=$(grep -nPi "$pattern" "$filepath" 2>/dev/null | head -1 | cut -d: -f1)
            echo "    [SECRET] $label  →  line $linenum in $filepath"
            found=1
        fi
    done
    return $found
}

# ── Scan git diff patch for secret patterns ────────────────
scan_patch_for_secrets() {
    local patch="$1"
    local label="$2"
    local found=0
    for entry in "${SECRET_PATTERNS[@]}"; do
        local slabel="${entry%%%:::*}"
        local pattern="${entry#*:::}"
        if echo "$patch" | grep -P "^\+" | grep -qPi "$pattern" 2>/dev/null; then
            echo "    [SECRET] $slabel  →  in staged changes of $label"
            found=1
        fi
    done
    return $found
}
''';

// --- .claude/hooks/on_stop.sh ---
final _hookOnStopSh = r'''#!/bin/bash
# ============================================================
# .claude/hooks/on_stop.sh
#
# Claude Code Stop Hook — runs when the AI session ends.
# Performs a lightweight audit and logs the session.
#
# Exit 0 = always (Stop hooks are informational)
# ============================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
AUDIT_LOG="$PROJECT_ROOT/.claude/audit.log"
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

mkdir -p "$(dirname "$AUDIT_LOG")"

# ── Log session end ───────────────────────────────────────
echo "[$TIMESTAMP] SESSION END" >> "$AUDIT_LOG" 2>/dev/null

# ── Quick check: any secret files accidentally tracked? ───
if command -v git &>/dev/null && git rev-parse --is-inside-work-tree &>/dev/null; then
    TRACKED=$(git ls-files 2>/dev/null)

    SENSITIVE_FILES=(".env" "key.properties" "local.properties"
                     "release.jks" "google-services.json"
                     "GoogleService-Info.plist" "env.g.dart"
                     "Secret.xcconfig")

    FOUND_ISSUE=0
    for sf in "${SENSITIVE_FILES[@]}"; do
        if echo "$TRACKED" | grep -qF "$sf"; then
            if [ $FOUND_ISSUE -eq 0 ]; then
                echo ""
                echo "  ⚠️  SESSION END — Secret file warning:"
                FOUND_ISSUE=1
            fi
            echo "     Tracked: $sf (should be gitignored)"
            echo "[$TIMESTAMP] WARNING: $sf is tracked" >> "$AUDIT_LOG" 2>/dev/null
        fi
    done

    if [ $FOUND_ISSUE -eq 1 ]; then
        echo ""
        echo "  Fix: git rm --cached <file> && add to .gitignore"
        echo ""
    fi
fi

exit 0
''';

// --- .claude/hooks/post_write.sh ---
final _hookPostWriteSh = r'''#!/bin/bash
# ============================================================
# .claude/hooks/post_write.sh
#
# Claude Code PostToolUse Hook — runs after every Write|Edit.
# Performs lightweight checks on the written file.
#
# Exit 0 = success (informational only, post hooks don't block)
# ============================================================

INPUT=$(cat)

# ── Extract the target file path ──────────────────────────
FILE=$(echo "$INPUT" | python3 -c "
import json, sys
try:
    d = json.load(sys.stdin)
    ti = d.get('tool_input', d)
    path = ti.get('file_path', ti.get('path', ti.get('target', '')))
    print(path)
except:
    print('')
" 2>/dev/null)

[ -z "$FILE" ] && exit 0

BNAME=$(basename "$FILE")

# ── Reminder: regenerate assets if an image/svg was added ─
case "$BNAME" in
    *.png|*.jpg|*.jpeg|*.svg|*.webp)
        echo ""
        echo "  📸 Asset file written: $BNAME"
        echo "  💡 Remember to run: ssl_cli generate k_assets.dart"
        echo ""
        ;;
esac

# ── Reminder: run autosafe if a model / response DTO was modified ───
if [[ "$FILE" == *"_model.dart" || "$FILE" == *"_response.dart" ]]; then
    echo ""
    echo "  🔧 Model/DTO file modified: $BNAME"
    echo "  💡 Remember to run: autosafe $FILE"
    echo ""
fi

# ── Reminder: run build_runner if env.dart was modified ───
if [[ "$BNAME" == "env.dart" && "$FILE" == *"core/config/env.dart"* ]]; then
    echo ""
    echo "  🔐 env.dart modified"
    echo "  💡 Remember to run: dart run build_runner build --delete-conflicting-outputs"
    echo ""
fi

exit 0
''';

// --- .claude/hooks/pre_bash_git_guard.sh ---
final _hookPreBashGitGuardSh = r'''#!/bin/bash
# ============================================================
# .claude/hooks/pre_bash_git_guard.sh
#
# Claude Code PreToolUse Hook — intercepts every Bash tool call.
# When Claude tries to run "git commit" or "git push",
# it delegates to pre_commit.sh for the full secret check.
#
# Exit 0 = allow the command
# Exit 2 = BLOCK the command (Claude Code specific)
# ============================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ── Read the bash command Claude wants to run ─────────────
INPUT=$(cat)
COMMAND=$(echo "$INPUT" | python3 -c "
import json, sys
try:
    d = json.load(sys.stdin)
    ti = d.get('tool_input', d)
    print(ti.get('command', ''))
except:
    print('')
" 2>/dev/null)

# ── Only intercept git commit / git push ──────────────────
if ! echo "$COMMAND" | grep -qE "git\s+(commit|push)"; then
    exit 0
fi

# ── Log the attempt ───────────────────────────────────────
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
mkdir -p ".claude"
echo "[$TIMESTAMP] GIT CMD: $COMMAND" >> ".claude/audit.log" 2>/dev/null

# ── Delegate to the shared pre_commit.sh ─────────────────
bash "$SCRIPT_DIR/pre_commit.sh"
RESULT=$?

if [ $RESULT -ne 0 ]; then
    # pre_commit.sh already printed the full error + fix steps
    echo ""
    echo "  [Claude Hook] Commit blocked by Secret Guard."
    echo "  Fix the issues above, then ask me to commit again."
    echo ""
    exit 2   # EXIT CODE 2 = Claude Code hard block
fi

exit 0
''';

// --- .claude/hooks/pre_commit.sh ---
final _hookPreCommitSh = r'''#!/bin/bash
# ============================================================
# .claude/hooks/pre_commit.sh
#
# The commit guard — runs ALL secret checks before any commit.
# Called automatically by pre_bash_git_guard.sh when Claude
# (or the developer) runs "git commit".
#
# Can also be run manually at any time:
#   bash .claude/hooks/pre_commit.sh
# ============================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/_secret_patterns.sh"

BLOCKED=0
declare -a BLOCKED_FILES_LIST

echo ""
echo "┌──────────────────────────────────────────────────────────┐"
echo "│  SECRET GUARD — Pre-Commit Check                        │"
echo "└──────────────────────────────────────────────────────────┘"

# ── Get staged files ──────────────────────────────────────
STAGED=$(git diff --cached --name-only 2>/dev/null)

if [ -z "$STAGED" ]; then
    echo "  No staged files. Nothing to check."
    exit 0
fi

FILE_COUNT=$(echo "$STAGED" | grep -c . 2>/dev/null || echo 0)
echo "  Staged files : $FILE_COUNT"
echo ""

# ─────────────────────────────────────────────────────────
# CHECK 1 — Blocked filenames
# ─────────────────────────────────────────────────────────
echo "  ▶ CHECK 1: Sensitive filename scan"

while IFS= read -r file; do
    [ -z "$file" ] && continue
    match=$(is_blocked_filename "$file")
    if [ $? -eq 0 ]; then
        echo "    ✖  $file  →  blocked pattern: '$match'"
        BLOCKED_FILES_LIST+=("$file")
        BLOCKED=1
    fi
done <<< "$STAGED"

[ $BLOCKED -eq 0 ] && echo "    ✔  No blocked files found"

# ─────────────────────────────────────────────────────────
# CHECK 2 — Secret patterns in staged diffs
# ─────────────────────────────────────────────────────────
echo ""
echo "  ▶ CHECK 2: Secret pattern scan (staged content only)"

while IFS= read -r file; do
    [ -z "$file" ] && continue

    # Only scan the diff (added lines) — not full file content
    PATCH=$(git diff --cached -- "$file" 2>/dev/null)
    [ -z "$PATCH" ] && continue

    FILE_BLOCKED=0
    for entry in "${SECRET_PATTERNS[@]}"; do
        label="${entry%%%:::*}"
        pattern="${entry#*:::}"

        # grep only the '+' lines from the diff
        HIT=$(echo "$PATCH" | grep -P "^\+" | grep -Pi "$pattern" 2>/dev/null | head -1)
        if [ -n "$HIT" ]; then
            echo "    ✖  $file"
            echo "       Secret type : $label"
            # Show redacted snippet
            SNIPPET=$(echo "$HIT" | sed 's/^\+//' | cut -c1-60)
            echo "       Snippet     : ${SNIPPET}..."
            BLOCKED_FILES_LIST+=("$file")
            BLOCKED=1
            FILE_BLOCKED=1
            break   # one match per file is enough
        fi
    done
done <<< "$STAGED"

[ $BLOCKED -eq 0 ] && echo "    ✔  No secret patterns detected"

# ─────────────────────────────────────────────────────────
# CHECK 3 — .gitignore coverage
# ─────────────────────────────────────────────────────────
echo ""
echo "  ▶ CHECK 3: .gitignore coverage"

MUST_IGNORE=(
    ".env" ".env.*" "*.env"
    "key.properties" "local.properties"
    "*.keystore" "*.jks"
    "google-services.json" "GoogleService-Info.plist"
    "secrets.dart" "api_keys.dart" "credentials.dart"
    "*.p12" "*.pem" "*.pfx"
    "service-account.json" "service_account.json"
    ".claude/audit.log" ".claude/secret_guard_report.txt"
)

MISSING_IGNORES=()
for item in "${MUST_IGNORE[@]}"; do
    if ! grep -qF "$item" .gitignore 2>/dev/null; then
        MISSING_IGNORES+=("$item")
    fi
done

if [ ${#MISSING_IGNORES[@]} -gt 0 ]; then
    echo "    ⚠  Missing from .gitignore:"
    for m in "${MISSING_IGNORES[@]}"; do
        echo "       $m"
    done
    echo ""
    echo "    Auto-fix command:"
    echo "       bash .claude/hooks/setup.sh --fix-gitignore"
else
    echo "    ✔  .gitignore looks good"
fi

# ─────────────────────────────────────────────────────────
# RESULT
# ─────────────────────────────────────────────────────────
echo ""
if [ $BLOCKED -eq 1 ]; then
    # Deduplicate
    UNIQUE=($(printf "%s\n" "${BLOCKED_FILES_LIST[@]}" | sort -u))

    echo "┌──────────────────────────────────────────────────────────┐"
    echo "│  ✖  COMMIT BLOCKED — sensitive data detected             │"
    echo "└──────────────────────────────────────────────────────────┘"
    echo ""
    echo "  HOW TO FIX:"
    echo ""
    echo "  1.  Unstage the file(s):"
    for f in "${UNIQUE[@]}"; do
        echo "        git restore --staged \"$f\""
    done
    echo ""
    echo "  2.  Add to .gitignore so it never stages again:"
    for f in "${UNIQUE[@]}"; do
        bname=$(basename "$f")
        echo "        echo '$bname' >> .gitignore && git add .gitignore"
    done
    echo ""
    echo "  3.  Use envied for secrets (the only approved method):"
    echo "      Flutter example:"
    echo "        import 'package:your_app/core/config/env.dart';"
    echo "        final apiKey = Env.paymentApiKey;"
    echo ""
    echo "  4.  Already in git history? Run the history scanner:"
    echo "        bash .claude/hooks/scan_git_history.sh"
    echo ""
    echo "  5.  ROTATE exposed credentials immediately — treat as leaked."
    echo ""
    exit 1   # non-zero = abort commit (used by git pre-commit hook)
else
    echo "  ✔  All clear — commit is safe to proceed."
    echo ""
    exit 0
fi
''';

// --- .claude/hooks/pre_edit_guard.sh ---
final _hookPreEditGuardSh = r'''#!/bin/bash
# ============================================================
# .claude/hooks/pre_edit_guard.sh
#
# Claude Code PreToolUse Hook — intercepts Write|Edit tool calls.
# Blocks the AI from writing to sensitive / secret files.
#
# Exit 0 = allow the edit
# Exit 2 = BLOCK the edit (Claude Code specific)
# ============================================================

INPUT=$(cat)

# ── Extract the target file path from the tool input ──────
FILE=$(echo "$INPUT" | python3 -c "
import json, sys
try:
    d = json.load(sys.stdin)
    ti = d.get('tool_input', d)
    # Claude Code sends file path in different keys depending on tool
    path = ti.get('file_path', ti.get('path', ti.get('target', '')))
    print(path)
except:
    print('')
" 2>/dev/null)

# If we couldn't extract a path, allow (fail-open for non-file edits)
[ -z "$FILE" ] && exit 0

BNAME=$(basename "$FILE")

# ── Blocked file patterns ─────────────────────────────────
BLOCKED_NAMES=(
    ".env"
    ".env.local"
    ".env.production"
    ".env.staging"
    ".env.development"
    "key.properties"
    "local.properties"
    "release.jks"
    "keystore.jks"
    "release.keystore"
    "debug.keystore"
    "google-services.json"
    "GoogleService-Info.plist"
    "env.g.dart"
    "Secret.xcconfig"
    "serviceAccountKey.json"
    "service_account.json"
    "service-account.json"
)

BLOCKED_EXTENSIONS=(
    ".jks"
    ".keystore"
    ".p12"
    ".pfx"
    ".pem"
    ".cer"
    ".crt"
)

# ── Check exact filename match ────────────────────────────
for blocked in "${BLOCKED_NAMES[@]}"; do
    if [[ "$BNAME" == "$blocked" ]]; then
        echo ""
        echo "  ✖  EDIT BLOCKED — Secret file detected"
        echo "     File: $FILE"
        echo "     Rule: AI agents must never write to '$blocked'"
        echo ""
        echo "  If this file needs updating:"
        echo "    • For .env → edit manually, then run: sh .claude/scripts/setup_secrets.sh"
        echo "    • For env.g.dart → run: dart run build_runner build"
        echo "    • For key.properties / Secret.xcconfig → auto-generated by setup_secrets.sh"
        echo ""
        exit 2
    fi
done

# ── Check blocked extensions ──────────────────────────────
for ext in "${BLOCKED_EXTENSIONS[@]}"; do
    if [[ "$BNAME" == *"$ext" ]]; then
        echo ""
        echo "  ✖  EDIT BLOCKED — Sensitive file type"
        echo "     File: $FILE"
        echo "     Rule: AI agents must never write to '*$ext' files"
        echo ""
        exit 2
    fi
done

# ── Allow everything else ─────────────────────────────────
exit 0
''';

// --- .claude/hooks/scan_git_history.sh ---
final _hookScanGitHistorySh = r'''#!/bin/bash
# ============================================================
# scan_git_history.sh
# Scans the ENTIRE git history for secrets that may have
# already been committed. Shows exact commits + remediation.
#
# Usage:
#   bash .claude/hooks/scan_git_history.sh
#   bash .claude/hooks/scan_git_history.sh --fix    (auto-add to .gitignore)
# ============================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/_secret_patterns.sh"

FIX_MODE=0
[[ "$1" == "--fix" ]] && FIX_MODE=1

echo ""
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║   SECRET GUARD — Full Git History Scanner                   ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

PROJECT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null)
if [ -z "$PROJECT_ROOT" ]; then
    echo "  ERROR: Not inside a git repository."
    exit 1
fi

TOTAL_COMMITS=$(git rev-list --count HEAD 2>/dev/null || echo "?")
echo "  Repository : $PROJECT_ROOT"
echo "  Commits    : $TOTAL_COMMITS"
echo "  Started    : $(date '+%Y-%m-%d %H:%M:%S')"
echo ""

FOUND_ANY=0
declare -a LEAK_REPORT

# ── SCAN 1: Check if blocked files exist in history ───────
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  [SCAN 1] Checking if sensitive files exist in history..."
echo ""

for fname in "${BLOCKED_FILES[@]}"; do
    # git log searches for commits that touched files matching this name
    COMMITS=$(git log --all --full-history --oneline -- "**/$fname" "*./$fname" "$fname" 2>/dev/null | head -5)
    if [ -n "$COMMITS" ]; then
        echo "  ✖ FOUND IN HISTORY: $fname"
        echo "$COMMITS" | while read -r line; do
            echo "      Commit: $line"
        done
        LEAK_REPORT+=("file_in_history:$fname")
        FOUND_ANY=1
        echo ""
    fi
done

# ── SCAN 2: Grep full history content for secret patterns ─
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  [SCAN 2] Scanning all commit diffs for secret patterns..."
echo "  (This may take a minute on large repos)"
echo ""

for entry in "${SECRET_PATTERNS[@]}"; do
    label="${entry%%%:::*}"
    pattern="${entry#*:::}"

    # Search all commits for this pattern in added lines
    HITS=$(git log --all -p --follow 2>/dev/null | grep -Pi "^\+.*$pattern" 2>/dev/null | head -3)

    if [ -n "$HITS" ]; then
        # Find which commit(s)
        COMMIT_HASHES=$(git log --all --oneline -S"$(echo "$HITS" | head -1 | sed 's/^\+//')" 2>/dev/null | head -3)
        echo "  ✖ PATTERN FOUND: $label"
        if [ -n "$COMMIT_HASHES" ]; then
            echo "$COMMIT_HASHES" | while read -r c; do
                echo "      Commit : $c"
            done
        fi
        echo "      Sample : $(echo "$HITS" | head -1 | cut -c1-80)..."
        LEAK_REPORT+=("pattern_in_history:$label")
        FOUND_ANY=1
        echo ""
    fi
done

# ── SCAN 3: Check current working tree ────────────────────
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  [SCAN 3] Checking current working tree..."
echo ""

# Check tracked files that should NOT be tracked
TRACKED=$(git ls-files 2>/dev/null)
while IFS= read -r file; do
    match=$(is_blocked_filename "$file")
    if [ $? -eq 0 ]; then
        echo "  ⚠ TRACKED (should not be): $file"
        LEAK_REPORT+=("tracked_sensitive:$file")
        FOUND_ANY=1
    fi
done <<< "$TRACKED"

# ── REPORT ────────────────────────────────────────────────
echo ""
echo "╔══════════════════════════════════════════════════════════════╗"
if [ $FOUND_ANY -eq 0 ]; then
    echo "║  ✔  CLEAN — No secrets found in git history              ║"
    echo "╚══════════════════════════════════════════════════════════╝"
    exit 0
fi

echo "║  ✖  SECRETS DETECTED IN HISTORY — Action required!          ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  REMEDIATION GUIDE"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "  STEP 1 — ROTATE ALL EXPOSED CREDENTIALS IMMEDIATELY"
echo "  ─────────────────────────────────────────────────────"
echo "  Do this FIRST, before anything else."
echo "  Treat any found key/secret as already compromised."
echo ""
echo "  STEP 2 — REMOVE FROM CURRENT TRACKING"
echo "  ─────────────────────────────────────────────────────"
for entry in "${LEAK_REPORT[@]}"; do
    type="${entry%%:*}"
    value="${entry#*:}"
    if [[ "$type" == "tracked_sensitive" ]]; then
        echo "    git rm --cached $value"
        echo "    echo '$value' >> .gitignore"
    fi
done
echo ""
echo "  STEP 3 — PURGE FROM GIT HISTORY"
echo "  ─────────────────────────────────────────────────────"
echo "  Option A — BFG Repo Cleaner (recommended, faster):"
echo ""
echo "    # Install: brew install bfg  OR  download bfg.jar"
echo ""
echo "    # Remove a specific file from all history:"
echo "    bfg --delete-files .env"
echo "    bfg --delete-files key.properties"
echo "    bfg --delete-files google-services.json"
echo ""
echo "    # Replace secret strings in history:"
echo "    echo 'AIzaXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX' > secrets.txt"
echo "    bfg --replace-text secrets.txt"
echo ""
echo "    # Then clean up and force-push:"
echo "    git reflog expire --expire=now --all"
echo "    git gc --prune=now --aggressive"
echo "    git push --force --all"
echo ""
echo "  Option B — git filter-repo (built-in, slower):"
echo ""
echo "    pip install git-filter-repo"
echo "    git filter-repo --path .env --invert-paths"
echo "    git filter-repo --path key.properties --invert-paths"
echo "    git push --force --all"
echo ""
echo "  Option C — git filter-branch (legacy, slowest):"
echo ""
echo "    git filter-branch --force --index-filter \\"
echo "      'git rm --cached --ignore-unmatch .env key.properties' \\"
echo "      --prune-empty --tag-name-filter cat -- --all"
echo "    git push --force --all"
echo ""
echo "  STEP 4 — NOTIFY YOUR TEAM"
echo "  ─────────────────────────────────────────────────────"
echo "  Anyone who has cloned/pulled this repo must:"
echo "    git fetch --all && git reset --hard origin/main"
echo "  (Their local history may still contain the secrets)"
echo ""
echo "  STEP 5 — PREVENT FUTURE LEAKS"
echo "  ─────────────────────────────────────────────────────"
echo "  Claude Code hooks are in .claude/hooks/ — no manual git hook needed."
echo "  Ensure .claude/settings.local.json is configured correctly."
echo "  Run: bash .claude/hooks/pre_commit.sh  (manual check anytime)"
echo ""
echo "  Add all sensitive patterns to .gitignore:"
for fname in ".env" ".env.*" "key.properties" "local.properties" \
             "*.keystore" "*.jks" "google-services.json" \
             "GoogleService-Info.plist" "secrets.dart" "api_keys.dart"; do
    if ! grep -qxF "$fname" .gitignore 2>/dev/null; then
        echo "    echo '$fname' >> .gitignore"
        if [ $FIX_MODE -eq 1 ]; then
            echo "$fname" >> .gitignore
        fi
    fi
done

if [ $FIX_MODE -eq 1 ]; then
    echo ""
    echo "  --fix mode: .gitignore entries added automatically."
fi

echo ""
echo "  Report saved to: .claude/secret_guard_report.txt"
echo ""

# Save report
{
    echo "Secret Guard Report — $(date)"
    echo "=========================="
    for entry in "${LEAK_REPORT[@]}"; do
        echo "LEAK: $entry"
    done
} > ".claude/secret_guard_report.txt" 2>/dev/null

exit 1
''';

// --- .claude/scripts/launch_for_testing.sh ---
final _scriptLaunchForTestingSh = r'''#!/bin/bash
# ============================================================
# .claude/scripts/launch_for_testing.sh
#
# Launches the app in testing mode and extracts the VM Service URL.
# This prevents AI from hanging on compilation logs.
# ============================================================

echo "Starting Flutter in testing mode..."

# Ensure temp directory exists
mkdir -p .claude/tmp

# Get the device ID from the first argument (if provided by Claude)
DEVICE_ID=${1:-""}

if [ -n "$DEVICE_ID" ]; then
    echo "Launching on specific device: $DEVICE_ID"
    flutter run -d "$DEVICE_ID" > .claude/tmp/flutter_run.log &
else
    echo "Launching on default device..."
    flutter run > .claude/tmp/flutter_run.log &
fi

# Wait and extract the URL
echo "Waiting for VM Service URL..."
while true; do
    URL=$(grep -o "ws://127.0.0.1:[0-9]*/ws" .claude/tmp/flutter_run.log | head -1)
    if [ ! -z "$URL" ]; then
        echo "$URL" > .claude/tmp/vm_url.txt
        echo "✅ App running! VM Service URL saved to .claude/tmp/vm_url.txt"
        break
    fi
    sleep 2
done
''';

// --- .claude/scripts/setup_secrets.sh ---
final _scriptSetupSecretsSh = r'''#!/bin/bash
# .claude/scripts/setup_secrets.sh
#
# PURPOSE:
#   Reads .env and:
#     1. Decodes RELEASE_JKS_BASE64          → android/app/release.jks
#     2. Decodes GOOGLE_SERVICES_JSON_BASE64  → android/app/google-services.json
#     3. Decodes GOOGLE_SERVICE_INFO_BASE64   → ios/Runner/GoogleService-Info.plist
#     4. Generates android/key.properties     (Gradle signing + Maps key)
#     5. Generates ios/Flutter/Secret.xcconfig (Xcode Maps key)
#
# HOW TO RUN (always from project root):
#   sh .claude/scripts/setup_secrets.sh
#
# RE-RUN whenever .env changes.
# All generated / decoded files are gitignored — never commit them.

set -e

# ── Resolve project root ──────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

ENV_FILE="$PROJECT_ROOT/.env"
KEY_PROPS="$PROJECT_ROOT/android/key.properties"
XCCONFIG_FILE="$PROJECT_ROOT/ios/Flutter/Secret.xcconfig"
JKS_PATH="$PROJECT_ROOT/android/app/release.jks"
GOOGLE_SERVICES_PATH="$PROJECT_ROOT/android/app/google-services.json"
GOOGLE_SERVICE_INFO_PATH="$PROJECT_ROOT/ios/Runner/GoogleService-Info.plist"

echo "📂 Project root : $PROJECT_ROOT"
echo ""

# ── Check .env exists ─────────────────────────────────────────────
if [ ! -f "$ENV_FILE" ]; then
    echo "❌  .env not found."
    echo "    Run:  cp .env.example .env"
    echo "    Then fill in real values from the team vault."
    exit 1
fi

# ── Helper: read a key from .env ─────────────────────────────────
get_env() {
    local key="$1"
    grep -E "^${key}[[:space:]]*=" "$ENV_FILE" \
        | head -n 1 \
        | sed "s/^${key}[[:space:]]*=[[:space:]]*//" \
        | tr -d '\r' \
        | sed "s/^['\"]//; s/['\"]$//"
}

# ── Helper: decode base64 value to file ──────────────────────────
decode_to_file() {
    local value="$1"
    local output="$2"
    local label="$3"
    # Skip placeholders
    if [ -z "$value" ] || echo "$value" | grep -q "^<"; then
        echo "⏭️   $label — placeholder in .env, skipping"
        return
    fi
    mkdir -p "$(dirname "$output")"
    printf '%s' "$value" | base64 -d > "$output"
    echo "✅  $label decoded → $(basename "$output")"
}

# ── Read values from .env ─────────────────────────────────────────
KEYSTORE_PASSWORD=$(get_env "KEYSTORE_PASSWORD")
KEY_ALIAS=$(get_env "KEY_ALIAS")
KEY_PASSWORD=$(get_env "KEY_PASSWORD")
GOOGLE_MAPS_API_KEY=$(get_env "GOOGLE_MAPS_API_KEY")
RELEASE_JKS_BASE64=$(get_env "RELEASE_JKS_BASE64")
GOOGLE_SERVICES_JSON_BASE64=$(get_env "GOOGLE_SERVICES_JSON_BASE64")
GOOGLE_SERVICE_INFO_BASE64=$(get_env "GOOGLE_SERVICE_INFO_BASE64")

# ── Decode binary files from base64 ──────────────────────────────
echo "── Decoding binary files ────────────────────────────────────"
decode_to_file "$RELEASE_JKS_BASE64"         "$JKS_PATH"                  "release.jks"
decode_to_file "$GOOGLE_SERVICES_JSON_BASE64" "$GOOGLE_SERVICES_PATH"     "google-services.json"
decode_to_file "$GOOGLE_SERVICE_INFO_BASE64"  "$GOOGLE_SERVICE_INFO_PATH" "GoogleService-Info.plist"
echo ""

# ── Warn if JKS still missing ─────────────────────────────────────
if [ ! -f "$JKS_PATH" ]; then
    echo "⚠️  release.jks not found — add RELEASE_JKS_BASE64 to .env"
    echo "   Debug builds still work. Release builds will fail."
    echo ""
fi

# ── Validate signing fields ───────────────────────────────────────
HAS_WARNING=false
check_field() {
    local name="$1"
    local value="$2"
    if [ -z "$value" ]; then
        echo "⚠️   $name is empty in .env"
        HAS_WARNING=true
    fi
}
check_field "KEYSTORE_PASSWORD"   "$KEYSTORE_PASSWORD"
check_field "KEY_ALIAS"           "$KEY_ALIAS"
check_field "KEY_PASSWORD"        "$KEY_PASSWORD"
check_field "GOOGLE_MAPS_API_KEY" "$GOOGLE_MAPS_API_KEY"

if [ "$HAS_WARNING" = true ]; then
    echo ""
    echo "   Fill the missing values in .env and re-run this script."
    echo ""
fi

# ── Generate android/key.properties ──────────────────────────────
echo "── Generating native config files ───────────────────────────"
mkdir -p "$(dirname "$KEY_PROPS")"
{
    echo "# Auto-generated — DO NOT edit. Edit .env and re-run script."
    echo ""
    echo "storeFile=release.jks"
    echo "storePassword=$KEYSTORE_PASSWORD"
    echo "keyAlias=$KEY_ALIAS"
    echo "keyPassword=$KEY_PASSWORD"
    echo "GOOGLE_MAPS_API_KEY=$GOOGLE_MAPS_API_KEY"
} > "$KEY_PROPS"
echo "✅  android/key.properties generated"

# ── Generate ios/Flutter/Secret.xcconfig ─────────────────────────
mkdir -p "$(dirname "$XCCONFIG_FILE")"
{
    echo "// Auto-generated — DO NOT edit. Edit .env and re-run script."
    echo ""
    echo "GOOGLE_MAPS_API_KEY = $GOOGLE_MAPS_API_KEY"
} > "$XCCONFIG_FILE"
echo "✅  ios/Flutter/Secret.xcconfig generated"

echo ""
echo "✅  All done. Next step:"
echo "    dart run build_runner build --delete-conflicting-outputs"
''';

