import 'dart:io';
import 'package:ssl_cli/utils/extension.dart';

import '../clean_module_i_creators.dart';

class CleanModuleImplFileCreator implements CleanModuleIFileCreator {
  final CleanModuleIDirectoryCreator directoryCreator;
  final String moduleName;
  final String? stateManagement;

  CleanModuleImplFileCreator(
    this.directoryCreator,
    this.moduleName,
    this.stateManagement,
  );

  @override
  Future<void> createNecessaryFiles() async {
    print('\nCreating necessary files...');
    final List<String> split = moduleName.split("_");
    String className = "";
    if (split.length > 1) {
      for (var element in split) {
        className += element.capitalize();
      }
    } else {
      className = split.first.capitalize();
    }

    final basePath = directoryCreator.moduleDir.path + "/$moduleName";

    // Get singular form for better naming
    final singularModuleName = _getSingularForm(moduleName);
    final singularClassName = _getSingularForm(className);

    // Create Domain Layer Files
    await _createDomainFiles(
      basePath,
      className,
      singularModuleName,
      singularClassName,
    );

    // Create Data Layer Files
    await _createDataFiles(
      basePath,
      className,
      singularModuleName,
      singularClassName,
    );

    // Create Presentation Layer Files
    await _createPresentationFiles(
      basePath,
      className,
      singularModuleName,
      singularClassName,
    );

    print('\nAll files created successfully!');
  }

  String _getSingularForm(String word) {
    // Simple pluralization removal - remove trailing 's' if present
    if (word.endsWith('s') && word.length > 1) {
      return word.substring(0, word.length - 1);
    }
    return word;
  }

  Future<void> _createDomainFiles(
    String basePath,
    String className,
    String singularModuleName,
    String singularClassName,
  ) async {
    print('Creating domain layer files...');

    // Entity — non-nullable with defaults, Equatable, no fromJson. The
    // repository maps the wire DTO into this. Entities never extend models.
    await _createFile(
      '$basePath/domain/entities',
      '${singularModuleName}_entity',
      content: '''import 'package:equatable/equatable.dart';

/// $singularClassName domain entity — non-nullable with defaults.
class ${singularClassName}Entity extends Equatable {
  final int id;
  // Add your entity properties here (all with defaults)

  const ${singularClassName}Entity({this.id = 0});

  @override
  List<Object?> get props => [id];
}
''',
    );

    // Repository Interface
    await _createFile(
      '$basePath/domain/repositories',
      singularModuleName + '_repository',
      content: '''import 'package:dartz/dartz.dart';

import '/core/error/failures.dart';
import '/features/$moduleName/domain/entities/${singularModuleName}_entity.dart';

/// Repository interface for $singularModuleName functionality
abstract class ${singularClassName}Repository {
  /// Get list of ${moduleName}
  Future<Either<Failure, List<${singularClassName}Entity>>> get${className}();
}
''',
    );

    // UseCase - Get List
    await _createFile(
      '$basePath/domain/usecases',
      'get_$moduleName',
      content: '''import 'package:dartz/dartz.dart';

import '/core/error/failures.dart';
import '/core/usecases/usecase.dart';
import '/features/$moduleName/domain/entities/${singularModuleName}_entity.dart';
import '/features/$moduleName/domain/repositories/${singularModuleName}_repository.dart';

/// Use case for getting $moduleName
class Get${className} implements UseCase<List<${singularClassName}Entity>, NoParams> {
  final ${singularClassName}Repository _repository;

  Get${className}(this._repository);

  @override
  Future<Either<Failure, List<${singularClassName}Entity>>> call(NoParams params) async {
    return await _repository.get${className}();
  }
}
''',
    );
  }

  Future<void> _createDataFiles(
    String basePath,
    String className,
    String singularModuleName,
    String singularClassName,
  ) async {
    print('Creating data layer files...');

    // Response DTO — nullable, SafeJson, autoSafe.raw top-level only; does NOT
    // extend the entity. The repository maps it to the entity.
    await _createFile(
      '$basePath/data/models',
      '${singularModuleName}_response',
      content: '''import 'package:autosafe_json/autosafe_json.dart';

/// Wire DTO for $singularClassName. All fields nullable, decoded with SafeJson.
/// Mapped to ${singularClassName}Entity in the repository. Models never extend entities.
class ${singularClassName}Response {
  final List<${singularClassName}Data>? results;

  ${singularClassName}Response({this.results});

  factory ${singularClassName}Response.fromJson(Map<String, dynamic> json) {
    json = json.autoSafe.raw; // top-level sanitise only
    return ${singularClassName}Response(
      results: json['results'] == null || json['results'] == ''
          ? []
          : List<${singularClassName}Data>.from(
              SafeJson.asList(json['results'])
                  .map((x) => ${singularClassName}Data.fromJson(SafeJson.asMap(x))),
            ),
    );
  }

  Map<String, dynamic> toJson() => {
        'results': results == null
            ? []
            : List<dynamic>.from(results!.map((x) => x.toJson())),
      };
}

class ${singularClassName}Data {
  final int? id;

  ${singularClassName}Data({this.id});

  factory ${singularClassName}Data.fromJson(Map<String, dynamic> json) =>
      ${singularClassName}Data(id: SafeJson.asInt(json['id']));

  Map<String, dynamic> toJson() => {'id': id};
}
''',
    );

    // Remote DataSource — returns the DTO
    await _createFile(
      '$basePath/data/datasources',
      '${singularModuleName}_remote_datasource',
      content: '''import '/core/network/api_client.dart';
import '/features/$moduleName/data/models/${singularModuleName}_response.dart';

/// Interface for $singularModuleName remote data source
abstract class ${singularClassName}RemoteDataSource {
  /// Get $moduleName from the remote API
  Future<${singularClassName}Response> get${className}();
}

/// Implementation of $singularModuleName remote data source
class ${singularClassName}RemoteDataSourceImpl implements ${singularClassName}RemoteDataSource {
  final ApiClient _apiClient;

  ${singularClassName}RemoteDataSourceImpl({required ApiClient apiClient})
      : _apiClient = apiClient;

  @override
  Future<${singularClassName}Response> get${className}() async {
    try {
      final response = await _apiClient.request(
        endpoint: '/$moduleName', // TODO: set your API endpoint
        method: HttpMethod.get,
      );
      return ${singularClassName}Response.fromJson(response);
    } catch (e) {
      rethrow;
    }
  }
}
''',
    );

    // Local DataSource — caches the DTO items
    await _createFile(
      '$basePath/data/datasources',
      '${singularModuleName}_local_datasource',
      content:
          '''import '/features/$moduleName/data/models/${singularModuleName}_response.dart';

/// Interface for $singularModuleName local data source
abstract class ${singularClassName}LocalDataSource {
  /// Get cached $moduleName
  Future<List<${singularClassName}Data>> get${className}();

  /// Cache $moduleName
  Future<void> cache${className}(List<${singularClassName}Data> $moduleName);
}

/// Implementation of $singularModuleName local data source
class ${singularClassName}LocalDataSourceImpl implements ${singularClassName}LocalDataSource {
  List<${singularClassName}Data> _cached = [];

  @override
  Future<List<${singularClassName}Data>> get${className}() async {
    return _cached;
  }

  @override
  Future<void> cache${className}(List<${singularClassName}Data> $moduleName) async {
    _cached = $moduleName;
  }
}
''',
    );

    // Repository Implementation — maps DTO -> entity
    await _createFile(
      '$basePath/data/repositories',
      '${singularModuleName}_repository_impl',
      content: '''import 'package:dartz/dartz.dart';
import '../../../../core/error/exception_handler.dart';

import '/core/error/failures.dart';
import '/features/$moduleName/data/datasources/${singularModuleName}_local_datasource.dart';
import '/features/$moduleName/data/datasources/${singularModuleName}_remote_datasource.dart';
import '/features/$moduleName/domain/entities/${singularModuleName}_entity.dart';
import '/features/$moduleName/domain/repositories/${singularModuleName}_repository.dart';

/// Implementation of ${singularClassName}Repository
class ${singularClassName}RepositoryImpl implements ${singularClassName}Repository {
  final ${singularClassName}RemoteDataSource _remoteDataSource;
  final ${singularClassName}LocalDataSource _localDataSource;

  ${singularClassName}RepositoryImpl({
    required ${singularClassName}RemoteDataSource remoteDataSource,
    required ${singularClassName}LocalDataSource localDataSource,
  })  : _remoteDataSource = remoteDataSource,
        _localDataSource = localDataSource;

  @override
  Future<Either<Failure, List<${singularClassName}Entity>>> get${className}() async {
    return handleException(() async {
      final response = await _remoteDataSource.get${className}();
      final items = response.results ?? [];
      await _localDataSource.cache${className}(items);
      // Explicit DTO -> entity mapping with ?? fallbacks.
      return items.map((e) => ${singularClassName}Entity(id: e.id ?? 0)).toList();
    });
  }
}
''',
    );
  }

  Future<void> _createPresentationFiles(
    String basePath,
    String className,
    String singularModuleName,
    String singularClassName,
  ) async {
    print('Creating presentation layer files...');

    if (stateManagement == "2") {
      // Create Bloc files
      await _createBlocFiles(
        basePath,
        className,
        singularModuleName,
        singularClassName,
      );
    } else {
      // Create Riverpod files (default)
      await _createRiverpodFiles(
        basePath,
        className,
        singularModuleName,
        singularClassName,
      );
    }

    // Page
    await _createFile(
      '$basePath/presentation/pages',
      '${singularModuleName}_page',
      content: '''import 'package:flutter/material.dart';

import '../../../../core/presentation/widgets/global_appbar.dart';
import '../../../../core/presentation/widgets/global_text.dart';

class ${singularClassName}Page extends StatelessWidget {
  const ${singularClassName}Page({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: GlobalAppBar(
        title: "${singularClassName.convertToCamelCase()}",
      ),
      body: Center(
        child: GlobalText(str: "${singularClassName.convertToCamelCase()} Page"),
      ),
    );
  }
}
''',
    );

    // Widget placeholder
    await _createFile(
      '$basePath/presentation/widgets',
      '${singularModuleName}_widget',
      content: '''import 'package:flutter/material.dart';

class ${singularClassName}Widget extends StatelessWidget {
  const ${singularClassName}Widget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      // TODO: Implement your widget
      child: const Text('${singularClassName} Widget'),
    );
  }
}
''',
    );
  }

  Future<void> _createRiverpodFiles(
    String basePath,
    String className,
    String singularModuleName,
    String singularClassName,
  ) async {
    print('Creating Riverpod files...');

    // State
    await _createFile(
      '$basePath/presentation/providers/state',
      '${singularModuleName}_state',
      content: '''import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

import '/core/error/failures.dart';
import '/features/$moduleName/domain/entities/${singularModuleName}_entity.dart';

@immutable
class ${singularClassName}State extends Equatable {
  final bool isLoading;
  final List<${singularClassName}Entity> ${moduleName};
  final Failure? failure;

  const ${singularClassName}State({
    this.isLoading = false,
    this.${moduleName} = const [],
    this.failure,
  });

  ${singularClassName}State copyWith({
    bool? isLoading,
    List<${singularClassName}Entity>? ${moduleName},
    Failure? failure,
  }) {
    return ${singularClassName}State(
      isLoading: isLoading ?? this.isLoading,
      ${moduleName}: ${moduleName} ?? this.${moduleName},
      failure: failure,
    );
  }

  @override
  List<Object?> get props => [isLoading, ${moduleName}, failure];
}
''',
    );

    // Notifier + Provider (no code generation)
    await _createFile(
      '$basePath/presentation/providers',
      '${singularModuleName}_provider',
      content: '''import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/service_locator.dart';
import '/core/usecases/usecase.dart';
import '/features/$moduleName/domain/usecases/get_$moduleName.dart';
import '/features/$moduleName/presentation/providers/state/${singularModuleName}_state.dart';

class ${singularClassName}Notifier extends Notifier<${singularClassName}State> {
  @override
  ${singularClassName}State build() {
    return const ${singularClassName}State();
  }

  Future<void> get${className}() async {
    state = state.copyWith(isLoading: true);
    final result = await sl<Get${className}>().call(NoParams());
    result.fold(
      (failure) => state = state.copyWith(isLoading: false, failure: failure),
      (data) => state = state.copyWith(isLoading: false, ${moduleName}: data),
    );
  }
}

final ${singularModuleName}NotifierProvider =
    NotifierProvider<${singularClassName}Notifier, ${singularClassName}State>(
  ${singularClassName}Notifier.new,
);
''',
    );
  }

  Future<void> _createBlocFiles(
    String basePath,
    String className,
    String singularModuleName,
    String singularClassName,
  ) async {
    print('Creating Bloc files...');

    // State
    await _createFile(
      '$basePath/presentation/bloc/state',
      '${singularModuleName}_state',
      content: '''import 'package:equatable/equatable.dart';

import '/features/$moduleName/domain/entities/${singularModuleName}_entity.dart';

/// State for $singularClassName
sealed class ${singularClassName}State extends Equatable {
  const ${singularClassName}State();
  
  @override
  List<Object?> get props => [];
}

class ${singularClassName}Initial extends ${singularClassName}State {
  const ${singularClassName}Initial();
}

class ${singularClassName}Loading extends ${singularClassName}State {
  const ${singularClassName}Loading();
}

class ${singularClassName}Loaded extends ${singularClassName}State {
  final List<${singularClassName}Entity> $moduleName;
  
  const ${singularClassName}Loaded(this.$moduleName);
  
  @override
  List<Object?> get props => [$moduleName];
}

class ${singularClassName}Error extends ${singularClassName}State {
  final String message;
  
  const ${singularClassName}Error(this.message);
  
  @override
  List<Object?> get props => [message];
}
''',
    );

    // Event
    await _createFile(
      '$basePath/presentation/bloc/event',
      '${singularModuleName}_event',
      content: '''import 'package:equatable/equatable.dart';

/// Events for $singularClassName
sealed class ${singularClassName}Event extends Equatable {
  const ${singularClassName}Event();
  
  @override
  List<Object?> get props => [];
}

class Load${className} extends ${singularClassName}Event {
  const Load${className}();
}

class Refresh${className} extends ${singularClassName}Event {
  const Refresh${className}();
}
''',
    );

    // Bloc — resolves the use case via sl and folds the Either into state
    await _createFile(
      '$basePath/presentation/bloc',
      '${singularModuleName}_bloc',
      content: '''import 'package:flutter_bloc/flutter_bloc.dart';

import '/core/di/service_locator.dart';
import '/core/usecases/usecase.dart';
import '/features/$moduleName/domain/usecases/get_$moduleName.dart';
import '/features/$moduleName/presentation/bloc/event/${singularModuleName}_event.dart';
import '/features/$moduleName/presentation/bloc/state/${singularModuleName}_state.dart';

class ${singularClassName}Bloc extends Bloc<${singularClassName}Event, ${singularClassName}State> {
  ${singularClassName}Bloc() : super(const ${singularClassName}Initial()) {
    on<Load${className}>(_onLoad);
    on<Refresh${className}>(_onRefresh);
  }

  Future<void> _onLoad(
    Load${className} event,
    Emitter<${singularClassName}State> emit,
  ) async {
    emit(const ${singularClassName}Loading());
    try {
      final result = await sl<Get${className}>()(NoParams());
      result.fold(
        (failure) => emit(${singularClassName}Error(failure.message)),
        (data) => emit(${singularClassName}Loaded(data)),
      );
    } catch (e) {
      emit(${singularClassName}Error(e.toString()));
    }
  }

  Future<void> _onRefresh(
    Refresh${className} event,
    Emitter<${singularClassName}State> emit,
  ) async {
    await _onLoad(Load${className}(), emit);
  }
}
''',
    );
  }

  Future<void> _createFile(
    String basePath,
    String fileName, {
    String? content,
    String? fileExtention = 'dart',
  }) async {
    String fileType;
    if (fileExtention == 'yaml') {
      fileType = 'yaml';
    } else if (fileExtention == 'arb') {
      fileType = 'arb';
    } else {
      fileType = 'dart';
    }

    try {
      // recursive: true also creates any missing parent directories.
      final file = await File(
        '$basePath/$fileName.$fileType',
      ).create(recursive: true);

      if (content != null) {
        final writer = file.openWrite();
        writer.write(content);
        await writer.close();
      }
    } catch (e) {
      print(e.toString());
      stderr.write('creating $fileName.$fileType failed!');
      exit(2);
    }
  }
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1).toLowerCase()}";
  }
}
