# AI Coding Rules - Flutter Clean Architecture (Feature Based Pattern)

> **Purpose:** This document provides AI coding assistants with strict rules and patterns for generating Flutter code following Clean Architecture. State management is **selectable** when scaffolding with `ssl_cli` — **Riverpod** or **flutter_bloc**.
>
> **State management is selectable.** `ssl_cli create`/`module` prompts for `1` (Riverpod) or `2` (Bloc). The templates below show the **Riverpod** variant; every generated project also ships an authoritative, state-management-specific rule set in its own `.claude/` (`.claude/rules/*.md`, `.claude/skills/clean_architecture_pattern.md`) plus `AGENTS.md`/`CLAUDE.md` — treat those as the source of truth for the chosen state management. The **domain/data layer is identical for both** (see the Data Layer rules below).

---

## 🎯 Core Architecture Pattern

This project follows **Clean Architecture**. All code generation MUST follow this three-layer structure (only the presentation layer differs between Riverpod and Bloc):

```
Domain Layer (Business Logic) → Data Layer (Data Management) → Presentation Layer (UI)
```

**Dependency Rule:** Dependencies ONLY point inward. Domain has NO dependencies on outer layers.

---

## 📁 Mandatory Project Structure

### Feature Module Structure (STRICT)

When creating ANY new feature, you MUST create this exact folder structure:

```
lib/features/{feature_name}/
├── data/
│   ├── datasources/
│   │   ├── {feature}_remote_datasource.dart
│   │   └── {feature}_local_datasource.dart
│   ├── models/
│   │   └── {model_name}_model.dart
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
    ├── providers/                     # Riverpod variant
    │   ├── {feature}_provider.dart
    │   └── state/
    │       └── {feature}_state.dart
    │   # Bloc variant instead uses:
    │   #   bloc/{feature}_bloc.dart
    │   #   bloc/event/{feature}_event.dart
    │   #   bloc/state/{feature}_state.dart
    └── widgets/
        └── {widget_name}.dart
```

### Core Structure (Shared Infrastructure)

```
lib/core/
├── constants/          # API URLs, app constants
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

## 🔧 Code Generation Rules

### 1. Domain Layer Rules

#### Entity Template

```dart
// lib/features/{feature}/domain/entities/{entity_name}_entity.dart
import 'package:equatable/equatable.dart';

class {EntityName}Entity extends Equatable {
  final int id;
  final String name;
  // Add fields here (all non-nullable, all with defaults)

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
- ✅ MUST be **non-nullable with defaults** (`0`, `''`, `false`, `const []`) — never `required`, never nullable; the UI never null-checks
- ✅ Models NEVER extend entities — the repository maps model → entity (see Data Layer)
- ✅ NO Flutter imports, NO `fromJson` (entities never touch raw JSON)
- ✅ NO external package dependencies (except `equatable`)

#### Repository Contract Template

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

**Rules:**
- ✅ MUST be abstract class
- ✅ MUST return `Either<Failure, T>`
- ✅ MUST use entities, NOT models

#### UseCase Template

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
  // Add parameters here
  
  const {Action}Params({
    required this.id,
  });
  
  @override
  List<Object?> get props => [id];
}
```

**Rules:**
- ✅ MUST implement `UseCase<ReturnType, ParamsType>`
- ✅ Params MUST extend `Equatable`
- ✅ One use case = one business action
- ✅ MUST inject repository through constructor

### 2. Data Layer Rules

#### Response Model Template (wire DTO — does NOT extend the entity)

```dart
// lib/features/{feature}/data/models/{feature}_response.dart
import 'package:autosafe_json/autosafe_json.dart';

/// Wire DTO. All fields nullable, decoded with SafeJson. The repository maps
/// it to the entity — models and entities are SEPARATE hierarchies.
class {Feature}Response {
  final List<{Item}Data>? results;

  {Feature}Response({this.results});

  factory {Feature}Response.fromJson(Map<String, dynamic> json) {
    json = json.autoSafe.raw; // top-level ONLY
    return {Feature}Response(
      results: json['results'] == null || json['results'] == ''
          ? []
          : List<{Item}Data>.from(
              SafeJson.asList(json['results'])
                  .map((x) => {Item}Data.fromJson(SafeJson.asMap(x))),
            ),
    );
  }

  Map<String, dynamic> toJson() => {
        'results': results == null
            ? []
            : List<dynamic>.from(results!.map((x) => x.toJson())),
      };
}

class {Item}Data {
  final int? id;
  final String? name;

  {Item}Data({this.id, this.name});

  factory {Item}Data.fromJson(Map<String, dynamic> json) => {Item}Data(
        id: SafeJson.asInt(json['id']),
        name: SafeJson.asString(json['name']),
      );

  Map<String, dynamic> toJson() => {'id': id, 'name': name};
}
```

**Rules:**
- ✅ MUST use `SafeJson.as*()` for every field — no raw `as` casts
- ✅ MUST call `json.autoSafe.raw` ONLY in the top-level response model
- ✅ Fields are **nullable**; the repository coalesces them to entity defaults with `??`
- ❌ NEVER `extends {Entity}Entity` — models and entities are separate hierarchies
- ✅ MUST have `fromJson` factory and `toJson` method

#### Remote Data Source Template

```dart
// lib/features/{feature}/data/datasources/{feature}_remote_datasource.dart
import 'package:dio/dio.dart';
import '../../../../core/constants/api_urls.dart';
import '../../../../core/network/api_client.dart';
import '../models/{model_name}_model.dart';

abstract class {Feature}RemoteDataSource {
  Future<{Model}Model> get{Entity}(String id);
  Future<List<{Model}Model>> get{Entity}List();
}

class {Feature}RemoteDataSourceImpl implements {Feature}RemoteDataSource {
  final ApiClient _apiClient;
  
  {Feature}RemoteDataSourceImpl({required ApiClient apiClient})
      : _apiClient = apiClient;
  
  @override
  Future<{Model}Model> get{Entity}(String id) async {
    try {
      final response = await _apiClient.request(
        endpoint: ApiUrl.{endpoint}.url,
        method: HttpMethod.get,
        queryParameters: {'id': id},
      );
      return {Model}Model.fromJson(response);
    } catch (e) {
      rethrow;
    }
  }
  
  @override
  Future<List<{Model}Model>> get{Entity}List() async {
    try {
      final response = await _apiClient.request(
        endpoint: ApiUrl.{endpoint}.url,
        method: HttpMethod.get,
      );
      return (response['data'] as List)
          .map((json) => {Model}Model.fromJson(json))
          .toList();
    } catch (e) {
      rethrow;
    }
  }
}
```

**Rules:**
- ✅ MUST have abstract class and implementation
- ✅ MUST inject `ApiClient` (NOT Dio directly)
- ✅ MUST use `ApiUrl` enum for endpoints
- ✅ MUST use handleException


#### Repository Implementation Template

```dart
// lib/features/{feature}/data/repositories/{feature}_repository_impl.dart
import 'package:dartz/dartz.dart';
import 'dart:io';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/{entity_name}_entity.dart';
import '../../domain/repositories/{feature}_repository.dart';
import '../datasources/{feature}_remote_datasource.dart';
import '../datasources/{feature}_local_datasource.dart';
import '../models/{model_name}_model.dart';

class {Feature}RepositoryImpl implements {Feature}Repository {
  final {Feature}RemoteDataSource remoteDataSource;
  final {Feature}LocalDataSource localDataSource;
  
  {Feature}RepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
  });
  
  @override
  Future<Either<Failure, {Entity}Entity>> get{Entity}(String id) async {
    return handleException(() async {
      final dto = await remoteDataSource.get{Entity}(id);
      // Explicit DTO -> entity mapping with `?? default` fallbacks.
      return {Entity}Entity(
        id: dto.id ?? 0,
        name: dto.name ?? '',
      );
    });
  }
}
    
```

**Rules:**
- ✅ MUST implement domain repository contract
- ✅ MUST inject data sources
- ✅ MUST map the wire DTO → entity (models never extend entities) with `?? default` fallbacks
- ✅ MUST wrap in `handleException()` and return `Either<Failure, Entity>`
- ✅ Handle `ServerException`, `SocketException`, and generic exceptions

### 3. Presentation Layer Rules

#### Provider Template (Riverpod Code Generation)

```dart
// lib/features/{feature}/presentation/providers/{feature}_provider.dart
import '../../../../core/di/service_locator.dart';
import '../../domain/usecases/{action}_usecase.dart';
import 'state/{feature}_state.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

class {Feature}Notifier extends Notifier<{Feature}State> {
  @override
  {Feature}State build() => const {Feature}State();
  
  Future<void> {action}({required String param}) async {
    final useCase = await sl<{Action}UseCase>();
    final result = await useCase({Action}Params(param: param));
   
    result.fold(
      (failure) => state = state.copyWith(failure: failure),
      (entity){
        <!-- state = state.copyWith(entity: entity); -->
      },
    );
  }
}
```

**Rules:**
- ✅ MUST use `sl<UseCase>()` for dependency injection
- ✅ MUST update state based on `Either` result
- ✅ Call use cases, NOT repositories directly


#### Page Template

```dart
// lib/features/{feature}/presentation/pages/{page_name}_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/presentation/widgets/global_text.dart';
import '../../../../core/presentation/widgets/global_button.dart';
import '../../../../core/presentation/widgets/global_loader.dart';
import '../providers/{feature}_provider.dart';

class {Page}Page extends ConsumerWidget {
  const {Page}Page({super.key});
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch({feature}NotifierProvider);
    
    return Scaffold(
      appBar: AppBar(title: const GlobalText(str: '{Page}')),
      body: state.when(
        initial: () => const Center(child: GlobalText(str: 'Initial')),
        loading: () => const Center(child: GlobalLoader()),
        success: (entity) => const Center(child: GlobalText(str: 'Success')),
        error: (message) => const Center(child: GlobalText(str: 'Error')),
      ),
    );
  }
  
}
```

**Rules:**
- ✅ MUST use `StatelessWidget` if need Statefull then use `ConsumerWidget` if you need statefullWidget then use `ConsumerStatefulWidget`
- ✅ MUST use `ref.watch()` for state
- ✅ MUST use `ref.read().notifier` for actions
- ✅ MUST use global widgets (GlobalText, GlobalButton, etc.)
- ✅ MUST use ScreenUtil (.w, .h, .sp, .r)
- ✅ AllWayes Create Component based widget and place this widget in the `lib/features/{feature}/presentation/widgets` directory.
- ✅ When create component based widget then use always try to use StatelessWidget.


---

## 🎨 UI Component Rules

### Global Widgets (MANDATORY)

**NEVER use base Flutter widgets. ALWAYS use global widgets:**

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
| `showDialog` | `ViewUtil.showDialog(context, message)` |
| `showBottomSheet` | `ViewUtil.showBottomSheet(context, message)` |
| `showSnackBar` | `ViewUtil.showSnackBar(context, message)` |
| `showBottomSheet` | `ViewUtil.showBottomSheet(context, message)` |
| `showBottomSheet` | `ViewUtil.showBottomSheet(context, message)` |
| `showBottomSheet` | `ViewUtil.showBottomSheet(context, message)` |



### GlobalText Usage
"For GlobalText dont use .sp as it handle in GlobalText inside"

```dart
GlobalText(
  str: 'Hello World',
  fontSize: 16,
)
```
### GlobalButton Usage

```dart
GlobalButton(
  btnText: 'Submit',
  onPressed: (){},
)
```

### GlobalTextFormField Usage

```dart
GlobalTextFormField(
  hintText: 'Enter name',
  labelText: 'Name',
  validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
)
```

### Responsive Sizing (MANDATORY)

```dart
// ❌ DON'T
Container(width: 200, height: 100)
Text('Hello', style: TextStyle(fontSize: 16))

// ✅ DO
Container(width: 200.w, height: 100.h)
GlobalText(str: 'Hello', fontSize: 16.sp)
```

**ScreenUtil Extensions:**
- `.w` - Responsive width
- `.h` - Responsive height
- `.sp` - Responsive font size
- `.r` - Responsive radius/padding

---

## 🔗 Dependency Injection Rules

### Registration Pattern (service_locator.dart)

When adding a new feature, ALWAYS register dependencies in this order:

```dart
// 1. Data Sources
sl.registerLazySingleton<{Feature}RemoteDataSource>(
  () => {Feature}RemoteDataSourceImpl(apiClient: sl()),
);

sl.registerLazySingleton<{Feature}LocalDataSource>(
  () => {Feature}LocalDataSourceImpl(prefHelper: sl()),
);

// 2. Repository
sl.registerLazySingleton<{Feature}Repository>(
  () => {Feature}RepositoryImpl(
    remoteDataSource: sl(),
    localDataSource: sl(),
  ),
);

// 3. Use Cases (Factory)
sl.registerFactory(() => {Action}UseCase(repository: sl()));
```

**Rules:**
- ✅ Data sources & repositories: `registerLazySingleton`
- ✅ Use cases: `registerFactory`
- ✅ MUST register in `initDependencies()` function
- ✅ MUST call `sl()` to resolve dependencies

---

## 📝 Naming Conventions (STRICT)

### Files

| Type | Pattern | Example |
|------|---------|---------|
| Entity | `{name}_entity.dart` | `user_entity.dart` |
| Response (DTO) | `{feature}_response.dart` | `user_response.dart` |
| UseCase | `{action}_usecase.dart` | `get_user_usecase.dart` |
| Repository | `{feature}_repository.dart` | `auth_repository.dart` |
| Repository Impl | `{feature}_repository_impl.dart` | `auth_repository_impl.dart` |
| Data Source | `{feature}_{type}_datasource.dart` | `auth_remote_datasource.dart` |
| Provider (Riverpod) | `{feature}_provider.dart` | `login_provider.dart` |
| Bloc (Bloc) | `{feature}_bloc.dart` | `login_bloc.dart` |
| Event (Bloc) | `{feature}_event.dart` | `login_event.dart` |
| State | `{feature}_state.dart` | `login_state.dart` |
| Page | `{name}_page.dart` | `login_page.dart` |

### Classes

| Type | Pattern | Example |
|------|---------|---------|
| Entity | `{Name}Entity` | `UserEntity` |
| Model | `{Name}Model` | `UserModel` |
| UseCase | `{Action}UseCase` | `GetUserUseCase` |
| Params | `{Action}Params` | `GetUserParams` |
| Repository | `{Feature}Repository` | `AuthRepository` |
| Repository Impl | `{Feature}RepositoryImpl` | `AuthRepositoryImpl` |
| Data Source | `{Feature}{Type}DataSource` | `AuthRemoteDataSource` |
| Provider | `{Feature}Provider` | `LoginProvider` |
| State | `{Feature}State` | `LoginState` |
| Page | `{Name}Page` | `LoginPage` |

---

## ⚠️ Error Handling Pattern (MANDATORY)

### Exception Hierarchy

```dart
// core/error/exceptions.dart
class ServerException implements Exception {
  final String message;
  ServerException({required this.message});
}

```

### Failure Hierarchy

```dart
// core/error/failures.dart
import 'package:equatable/equatable.dart';

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

### Error Flow

1. **Data Source:** Throw exceptions
2. **Repository:** Catch exceptions → Return `Left(Failure)` (and map DTO → entity)
3. **Use Case:** Pass through `Either<Failure, Data>`
4. **Provider / Bloc:** Handle with `fold()` → update state (Riverpod: `state = state.copyWith(...)`; Bloc: `emit(...)`)



## ✅ Feature Creation Checklist

When creating a new feature, follow this order:

1. **Domain Layer**
   - [ ] Create entity in `domain/entities/`
   - [ ] Create repository contract in `domain/repositories/`
   - [ ] Create use cases in `domain/usecases/`

2. **Data Layer**
   - [ ] Create response DTO in `data/models/{feature}_response.dart` (nullable, `SafeJson`, does NOT extend entity)
   - [ ] Create remote data source in `data/datasources/`
   - [ ] Create local data source in `data/datasources/` (if needed)
   - [ ] Create repository implementation in `data/repositories/`

3. **Dependency Injection**
   - [ ] Register data sources in `service_locator.dart`
   - [ ] Register repository in `service_locator.dart`
   - [ ] Register use cases in `service_locator.dart`

4. **Presentation Layer**
   - [ ] Create state in `presentation/providers/state/`
   - [ ] Create provider in `presentation/providers/`
   - [ ] Create page in `presentation/pages/`
   - [ ] Create widgets in `presentation/widgets/` (if needed)


---

## 🎯 Quick Reference: Common Patterns

### API Call Pattern

```dart
// 1. Define endpoint in core/constants/api_urls.dart
enum ApiUrl {
  getUsers,
}

extension ApiUrlExtension on ApiUrl {
  String get url {
    switch (this) {
      case ApiUrl.getUsers:
        return '/users';
    }
  }
}

// 2. Use in data source
final response = await _apiClient.request(
  endpoint: ApiUrl.getUsers.url,
  method: HttpMethod.get,
);
```

### Navigation Pattern

```dart
// Use centralized navigation
Navigation.push(context, appRoutes: AppRoutes.login);
Navigation.pop(context);
```

### Theme/Color Pattern

```dart
// Define in core/theme/app_colors.dart
enum AppColors {
  scaffold(Color.fromARGB(255, 222, 242, 240)),
  // Primary colors
  primary(Color(0xFF28294D)),
  primaryLight(Color(0xFF42A5F5)),
  
  final Color color;
  const AppColors(this.color);
}

// Use in widgets
Container(color: AppColors.primary.color)
```

---

## 🚫 Common Mistakes to Avoid

1. ❌ Using Flutter widgets directly instead of global widgets
2. ❌ Importing repositories in presentation layer (use use cases)
3. ❌ Returning models from use cases (use entities)
4. ❌ Hard-coded sizes without ScreenUtil
5. ❌ Forgetting to register dependencies in service_locator
6. ❌ Not handling all state cases in UI
7. ❌ Using `registerLazySingleton` for use cases (use `registerFactory`)
8. ❌ Throwing failures instead of exceptions in data layer
9. ❌ Not running build_runner after creating providers/states

---

**🤖 AI Assistant Instructions:**

When generating code for this project:
1. ALWAYS follow the exact folder structure defined above
2. ALWAYS use the provided templates
3. ALWAYS use global widgets instead of base Flutter widgets
4. ALWAYS use ScreenUtil for sizing
5. ALWAYS register dependencies in service_locator.dart (blocs as `registerFactory`)
6. ALWAYS handle errors with Either<Failure, Data>
7. ALWAYS use the state management selected at scaffold time — Riverpod OR flutter_bloc (never mix)
8. NEVER skip layers (always create domain → data → presentation)
9. NEVER use repositories directly in presentation (use use cases)
10. NEVER let models extend entities — the repository maps DTO → entity


**This is a strict, opinionated architecture. Follow it exactly.**
