# ssl_cli 🚀

**ssl_cli** is your opinionated command-line companion for building production-ready Flutter apps in record time. It bakes in Clean Architecture, modular scaling, design-system best practices, and DevOps automation so your team can stay focused on shipping features—not wiring boilerplate.

---

- **Architecture-first:** generate full Clean Architecture projects and modules with domain, data, and presentation layers ready to go.
- **State management flexibility:** pick Riverpod (default) or Bloc during scaffolding—ssl_cli generates the right folder structure and stubs for you.
- **Design system included:** preconfigured global widgets (text, buttons, dropdowns, images, SVGs, app bars) and asset/color enums keep UI consistent.
- **Automation everywhere:** build flavors with obfuscation, auto-share APKs to Telegram, sync assets, kick off build_runner, and generate documentation from a single CLI.

---

## Table of Contents

1. [Why ssl_cli](#why-ssl_cli)
2. [Core Capabilities](#core-capabilities)
3. [Clean Architecture Blueprint](#clean-architecture-blueprint)
4. [Quick Start](#quick-start)
5. [Command Reference](#command-reference)
6. [Generated Project Structure](#generated-project-structure)
7. [UI & Design System Guidelines](#ui--design-system-guidelines)
8. [Automation & DevOps Helpers](#automation--devops-helpers)
9. [Contributing](#contributing-)
10. [License](#license-)
11. [Support](#support-)
12. [Changelog](#changelog-)

---

## Why ssl_cli

Flutter teams fight repetitive setup: folder conventions, state management wiring, asset registries, flavor configs, documentation, and build distribution. ssl_cli turns those decisions into confident defaults:

- **Consistency:** every project and module follows the same Clean Architecture and naming conventions.
- **Scalability:** generate new modules on demand with the entire domain → data → presentation pipeline.
- **Velocity:** opinionated templates reduce the cognitive load for new developers joining mid-project.
- **Quality:** prebuilt service locator, ScreenUtil setup, networking hooks, and error handling nudge you towards best practices.
- **Automation:** everyday chores (assets, build_runner, flavor builds) become one-liners.

---

## Core Capabilities

| Area | What ssl_cli Automates |
| --- | --- |
| **Project scaffolding** | Create a Clean Architecture Flutter app from scratch with prewired core modules. |
| **Module generation** | Spin up feature modules with domain/data/presentation layers and optional Bloc or Riverpod states. |
| **Design system** | Global widgets, responsive typography via `flutter_screenutil`, centralized colors/assets enums. |
| **Assets & L10n** | Auto-generate `k_assets.dart`, create assets folders, and seed localization structure. |
| **Documentation** | Generate AI-assisted markdown docs for any folder or file. |
| **Build & Release** | Configure flavors, obfuscate builds, rename APKs by flavor, and deliver them to Telegram groups. |
| **Developer tooling** | Kick off build_runner or watch tasks with zero setup. |

---

## Clean Architecture Blueprint

ssl_cli follows a layered Clean Architecture implementation.

```
┌──────────────────────────┐
│ Presentation Layer       │  ▶️ Riverpod or Bloc wiring, pages, widgets
├──────────────────────────┤
│ Domain Layer             │  ▶️ Use cases, entities, repository contracts
├──────────────────────────┤
│ Data Layer               │  ▶️ Models, repositories, remote & local data sources
└──────────────────────────┘
```

- **Domain before details:** Entity and use case templates keep business rules pure and testable.
- **Data isolation:** Remote/local data sources and repository implementations ship with error-handling scaffolds, network checks, and caching placeholders.
- **Presentation clarity:** Choose `Riverpod` (default) for provider/notifier setups or opt into `Bloc` to generate events, states, and blocs automatically.
- **State Management Prompt:** When you scaffold a Clean Architecture project or module, ssl_cli asks for your preferred pattern and scaffolds the correct directory tree and stubs.

> 🧭 The project root also includes `core/` utilities—service locator, API helpers, global widgets, theming, navigation, and more—so modules can focus on feature logic.

---

## Quick Start

1. **Create a Flutter project (if you haven't already).**
   ```bash
   flutter create <project_name>
   ```

2. **Activate ssl_cli globally.**
   ```bash
   dart pub global activate ssl_cli
   ```

3. **Add the Dart pub cache to your PATH** (first-time setup only):
   - Windows: update *System Environment Variables*.
   - macOS: add `export PATH="$PATH":"$HOME/.pub-cache/bin"` to `~/.zshrc`.
   - Linux: add the same export to `~/.bashrc`.

4. **Navigate to your Flutter project root** and run:
   ```bash
   ssl_cli create <project_name>
   ```

   - Pick **pattern `4`** for the Clean Architecture template when prompted.
   - Choose your state management flavor (Riverpod or Bloc) when asked.

5. **Bootstrap modules anytime.**
   ```bash
   ssl_cli module <module_name>
   ```
   Select the Clean Architecture module pattern, then choose Riverpod or Bloc for that module.

> ✅ Always run commands from the Flutter project root so assets, localization, and configuration files generate in the right place.

---

## Command Reference

### Project & Module Scaffolding

```bash
ssl_cli create <project_name>      # Generate a full Flutter project (choose Clean Architecture pattern "4")
ssl_cli module <module_name>       # Add a new feature module (select Clean Architecture pattern "3")
```

### Assets & Documentation

```bash
ssl_cli generate k_assets.dart     # Build the assets enum (rerun after adding new assets)
ssl_cli generate k_assets.dart --t # Build theme-based assets enum with dark/light folder support
ssl_cli generate <path>            # Create AI-assisted documentation for a file or folder
```

**Theme-based Assets (`--t` flag):**
When your assets are organized with `dark/` and `light/` subfolders (e.g., `assets/images/dark/`, `assets/images/light/`), use the `--t` flag. This generates:
- Automatic theme switching between dark and light variants
- Fallback to common assets (files outside dark/light folders)
- Helper methods `_themedSvg()` and `_themedPng()` that check `ThemeManager().isDarkMode`

**Folder structure example:**
```
assets/
  ├─ images/
  │  ├─ dark/
  │  │  └─ bg.png
  │  ├─ light/
  │  │  └─ bg.png
  │  └─ common_image.png
  └─ svg/
     ├─ dark/
     │  └─ icon.svg
     ├─ light/
     │  └─ icon.svg
     └─ common_icon.svg
```

### Code Generation Helpers

```bash
ssl_cli generate build_runner      # Run build_runner once
ssl_cli generate build_runner_watch# Run build_runner in watch mode
```

### Flavor Setup & Builds

```bash
ssl_cli setup --flavor             # Configure flavor-based builds (works on existing projects too)
ssl_cli build apk --flavorType     # Build APK per flavor (--DEV/--LIVE/--LOCAL/--STAGE)
ssl_cli build apk --flavorType --t # Build and auto-share APK to Telegram (requires config.json)
```

> ℹ️ When using the Telegram flag (`--t`), provide `botToken` and `chatId` in the generated `config.json` file. Obtain them via [BotFather](https://core.telegram.org/bots#botfather) and the [`getUpdates` API](https://api.telegram.org/bot<token>/getUpdates).

---

## Generated Project Structure

Below is a trimmed example of what a Clean Architecture project scaffolding looks like (Riverpod option shown):

```
lib/
├─ core/
│  ├─ constants/
│  ├─ di/
│  ├─ error/
│  ├─ network/
│  ├─ presentation/
│  │  ├─ widgets/
│  │  │  ├─ global_appbar.dart
│  │  │  ├─ global_button.dart
│  │  │  ├─ global_dropdown.dart
│  │  │  ├─ global_image_loader.dart
│  │  │  ├─ global_svg_loader.dart
│  │  │  └─ global_text.dart
│  │  └─ ...
│  └─ utils/
├─ features/
│  └─ products/
│     ├─ data/
│     │  ├─ datasources/
│     │  ├─ models/
│     │  └─ repositories/
│     ├─ domain/
│     │  ├─ entities/
│     │  ├─ repositories/
│     │  └─ usecases/
│     └─ presentation/
│        ├─ pages/
│        ├─ providers/
│        │  └─ state/
│        └─ widgets/
└─ l10n/
```

Selecting Bloc replaces the `providers/` folder with a `bloc/` directory containing `event/`, `state/`, and bloc classes.

---

## UI & Design System Guidelines

ssl_cli ships with a unified design language to keep your UI consistent:

- **Typography:** Use `GlobalText`; it wraps `ScreenUtil` to ensure responsive font sizes.
- **Fields & Inputs:** Prefer `GlobalTextFormField` for form elements and `GlobalDropdown` for selects.
- **Buttons & App Bars:** Use `GlobalButton` and `GlobalAppBar` components for consistent theming.
- **Images:** Route PNG/JPEG assets through `GlobalImageLoader` and SVGs through `GlobalSvgLoader`.
- **Assets:** Register all new assets in the enum within `k_assets.dart`, referencing them via the generated enum names (e.g., `ImageNamePng.myIllustration`).
- **Colors:** Extend the enum in `k_colors.dart` and reference colors through their enum identifiers (e.g., `ColorName.primaryBackground`).
- **Fonts:** Avoid directly applying `.sp`—`GlobalText` already handles responsive scaling.

> Asset placement: store raster images under `assets/images/` and SVGs under `assets/svg/`. Re-run `ssl_cli generate k_assets.dart` whenever the folders change.

---

## Automation & DevOps Helpers

- **Flavor-aware builds:** Configure once, then ship flavor-specific APKs with automatic renaming (`appName_flavor_versionName_versionCode.apk`).
- **Code obfuscation:** Combine `ssl_cli build apk --flavorType` with Flutter’s obfuscation flags in your build config for extra protection.
- **Telegram delivery:** Append `--t` to send finished builds straight to your team chat (after configuring `config.json`).
- **Documentation generation:** Point ssl_cli at any folder or file to bootstrap human-friendly docs for handoff or onboarding.

---

## Contributing 🤝

Contributions are welcome! Please check existing issues, open new discussions, or submit a pull request to improve ssl_cli.

## License 📄

This project is licensed under the MIT License – see the [LICENSE](LICENSE) file for details.

## Support ❤️

If **ssl_cli** streamlines your workflow, please give it a ⭐ on [GitHub](https://github.com/AscEmon/SSL_CLI) and share it with your Flutter community.

## Changelog 📋

See [CHANGELOG.md](CHANGELOG.md) for a history of updates and new features.

---

Made with ❤️ by [Abu Sayed Chowdhury](https://github.com/AscEmon)