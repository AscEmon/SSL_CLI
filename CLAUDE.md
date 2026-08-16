# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

---

## What This Project Is

`ssl_cli` (v4.0.5) is a Dart CLI tool that scaffolds production-ready Flutter apps. It generates full project structures and feature modules following Clean Architecture, wires up Riverpod or Bloc state management, creates asset enums, configures build flavors, and automates APK delivery to Telegram.

---

## Development Commands

**Install/activate locally:**
```sh
dart pub get
dart pub global activate --source path .
```

**Run directly (without activating):**
```sh
dart run bin/ssl_cli.dart <command>
```

**Run tests:**
```sh
dart test
```

**Run a single test file:**
```sh
dart test test/<test_file>.dart
```

**Analyze / lint:**
```sh
dart analyze
```

**Format:**
```sh
dart format lib/
```

---

## Architecture Overview

### Entry Point & Command Routing

`bin/ssl_cli.dart` → `SSLCommandRunner.run()` in `lib/src/ssl_command_runner.dart`.

`SSLCommandRunner` uses the `args` package to parse subcommands, then routes to an `ICommand` implementation via a switch statement. Interactive stdin prompts (welcome, pattern selection, state management) are collected before the command executes.

```
bin/ssl_cli.dart
  └── SSLCommandRunner.run()
        ├── create → CreateCommand (project scaffold)
        ├── module → CreateCommand (feature module scaffold)
        ├── generate → AssetGenerationCommand | DocGenerator | build_runner
        ├── build/clean/pub/run → BuildFlavorCommand
        ├── setup --flavor → SetupFlavor
        ├── sent --apk → SentApkTelegramMixin
        ├── override --config.json → ConfigCommand
        └── help → HelpCommand
```

All commands implement `ICommand` (`lib/src/command/i_command.dart`) with a single `execute()` method.

### Creator Pattern (Strategy)

Scaffolding logic is split into three collaborating classes per architecture type:

| Role | Responsibility |
|------|---------------|
| `ISSLCreator` | Orchestrator — calls directory + file creator |
| `IDirectoryCreator` | Creates the folder tree |
| `IFileCreator` | Writes templated Dart/YAML/config files |

Implementations live in their own subdirectories under `lib/src/`:

- `clean_structure_creators/` — full Clean Architecture project
- `clean_module_creators/` — Clean Architecture feature module
- `repo_structure_creators/` / `repo_module_creators/` — Repository pattern
- `bloc_structure_creators/` — Bloc pattern project
- `mvc_structure_creators/` — MVC (deprecated)
- `asset_path_creators/` — `k_assets.dart` enum generation (standard & themed)

When adding a new architecture or generation type, follow this three-class split.

### Interactive Prompts → Routing Logic

`create` and `module` commands ask the user to pick a pattern number:

- **create**: `1`=MVC, `2`=Repository, `3`=Bloc, `4`=Clean Architecture. If `4`, also asks state management (`1`=Riverpod, `2`=Bloc).
- **module**: `1`=Bloc, `2`=Others, `3`=Clean Architecture. If `3`, also asks state management.

The selected numbers are passed as strings to `CreateCommand` and used to select the correct creator implementation.

### Utilities (`lib/utils/`)

| File | Purpose |
|------|---------|
| `extension.dart` | `printWithColor()`, `isValidFilePath()`, camelCase helpers |
| `enum.dart` | `PrintType` (success/warning/error) for colored output |
| `setup_flavor.dart` | Modifies `build.gradle` / `build.gradle.kts` for Android flavors |
| `pubspec_edit.dart` | Programmatically edits `pubspec.yaml` |
| `doc_generation.dart` | AI-assisted docs via OpenAI / Gemini (reads `config.json`) |
| `mixin/sent_apk_telegram_mixin.dart` | Sends APKs to Telegram using `config.json` credentials |
| `color_extension.dart` | ANSI escape codes for terminal colors |

### Key Config File

`config.json` (generated in the target Flutter project by `ssl_cli setup --flavor`) stores:
- `botToken` and `chatId` for Telegram delivery
- API keys for AI doc generation (OpenAI / Gemini)

---

## Generated Code Conventions (AI_CODING_RULES.md)

When generating or modifying Flutter code that the CLI produces, follow these rules:

- **Dependency direction:** Domain → Data → Presentation. Domain layer has zero dependencies on outer layers.
- **Entities** extend `Equatable` and list all fields in `props`.
- **Models** implement their entity via `Freezed` (`@freezed` annotation).
- **Repository contracts** live in `domain/repositories/`; implementations in `data/repositories/`.
- **Use cases** extend a `BaseUseCase` abstract class.
- **State management (Riverpod):** Pages use `ConsumerWidget` or `ConsumerStatefulWidget`; providers expose `AsyncNotifier`/`StateNotifier`.
- **State management (Bloc):** Generate `event/`, `state/`, and the bloc class under `presentation/bloc/`.
- **Error handling:** Use `Failure` classes (not raw exceptions) returned from repository implementations.
- **Asset naming:** All assets accessed through the generated `KAssets` enum, never as raw strings.

The full rules document is in `AI_CODING_RULES.md` at the project root.

---

## Adding a New Command

1. Create a class in `lib/src/command/` implementing `ICommand`.
2. Register the subcommand in `SSLCommandRunner._setupArgParser()`.
3. Add a `case` branch in `SSLCommandRunner.run()`.
4. Wire any required flags in `_setupArgParser()`.
