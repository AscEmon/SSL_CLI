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

    // Entity
    await _createFile(
      '$basePath/domain/entities',
      '$singularModuleName',
      content: '''import 'package:equatable/equatable.dart';

/// ${singularClassName} entity - Represents $singularModuleName in the business domain
class $singularClassName extends Equatable {
  final int id;
  // Add your entity properties here

  const $singularClassName({
    required this.id,

  });

  @override
  List<Object?> get props => [id];
}
''',
    );

    // Repository Interface
    await _createFile(
      '$basePath/domain/repositories',
      '${singularModuleName}_repository',
      content: '''import 'package:dartz/dartz.dart';

import '/core/error/failures.dart';
import '/features/$moduleName/domain/entities/$singularModuleName.dart';

/// Repository interface for $singularModuleName functionality
abstract class ${singularClassName}Repository {
  /// Get list of ${moduleName}
  Future<Either<Failure, List<$singularClassName>>> get${className}();
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
import '/features/$moduleName/domain/entities/$singularModuleName.dart';
import '/features/$moduleName/domain/repositories/${singularModuleName}_repository.dart';

/// Use case for getting $moduleName
class Get${className} implements UseCase<List<$singularClassName>, NoParams> {
  final ${singularClassName}Repository _repository;

  Get${className}(this._repository);

  @override
  Future<Either<Failure, List<$singularClassName>>> call(NoParams params) async {
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

    // Model
    await _createFile(
      '$basePath/data/models',
      '${singularModuleName}_model',
      content:
          '''import '/features/$moduleName/domain/entities/$singularModuleName.dart';

/// Model class for $singularClassName that extends the domain entity
class ${singularClassName}Model extends $singularClassName {
  const ${singularClassName}Model({
    required super.id,
  });

  /// Create a ${singularClassName}Model from JSON
  factory ${singularClassName}Model.fromJson(Map<String, dynamic> json) {
    return ${singularClassName}Model(
      id: json['id'] as int,
    
    );
  }

  /// Convert ${singularClassName}Model to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
     
    };
  }
}
''',
    );

    // Remote DataSource
    await _createFile(
      '$basePath/data/datasources',
      '${singularModuleName}_remote_datasource',
      content: '''import 'package:dio/dio.dart';

import '/core/network/api_client.dart';
import '/features/$moduleName/data/models/${singularModuleName}_model.dart';

/// Interface for $singularModuleName remote data source
abstract class ${singularClassName}RemoteDataSource {
  /// Get $moduleName from the remote API
  Future<List<${singularClassName}Model>> get${className}();

}

/// Implementation of $singularModuleName remote data source
class ${singularClassName}RemoteDataSourceImpl implements ${singularClassName}RemoteDataSource {
  final ApiClient _apiClient;

  ${singularClassName}RemoteDataSourceImpl({required ApiClient apiClient})
      : _apiClient = apiClient;

  @override
  Future<List<${singularClassName}Model>> get${className}() async {
    try {
      final response = await _apiClient.request(
        endpoint: '/${moduleName}s', // Update with your API endpoint
        method: HttpMethod.get,
      );

      final List<dynamic> data = response as List<dynamic>;
      return data.map((json) => ${singularClassName}Model.fromJson(json)).toList();
    } on DioException catch (e) {
      throw Exception('Failed to load $moduleName: \${e.message}');
    } catch (e) {
      throw Exception('Failed to load $moduleName: \$e');
    }
  }

}
''',
    );

    // Local DataSource
    await _createFile(
      '$basePath/data/datasources',
      '${singularModuleName}_local_datasource',
      content:
          '''import '/features/$moduleName/data/models/${singularModuleName}_model.dart';

/// Interface for $singularModuleName local data source
abstract class ${singularClassName}LocalDataSource {
  /// Get cached $moduleName
  Future<List<${singularClassName}Model>> get${className}();

  /// Get a specific cached $singularModuleName by ID
  Future<${singularClassName}Model> get${singularClassName}ById(int id);

  /// Cache $moduleName
  Future<void> cache${className}(List<${singularClassName}Model> $moduleName);

  /// Cache a single $singularModuleName
  Future<void> cache${singularClassName}(${singularClassName}Model $singularModuleName);
}

/// Implementation of $singularModuleName local data source
class ${singularClassName}LocalDataSourceImpl implements ${singularClassName}LocalDataSource {
  // TODO: Implement local caching using SharedPreferences, Hive, or other storage
  
  @override
  Future<List<${singularClassName}Model>> get${className}() async {
    // TODO: Implement getting cached $moduleName
    throw UnimplementedError();
  }

  @override
  Future<${singularClassName}Model> get${singularClassName}ById(int id) async {
    // TODO: Implement getting cached $singularModuleName by ID
    throw UnimplementedError();
  }

  @override
  Future<void> cache${className}(List<${singularClassName}Model> $moduleName) async {
    // TODO: Implement caching $moduleName
  }

  @override
  Future<void> cache${singularClassName}(${singularClassName}Model $singularModuleName) async {
    // TODO: Implement caching single $singularModuleName
  }
}
''',
    );

    // Repository Implementation
    await _createFile(
      '$basePath/data/repositories',
      '${singularModuleName}_repository_impl',
      content: '''import 'package:dartz/dartz.dart';

import '/core/error/failures.dart';
import '/core/network/network_info.dart';
import '/features/$moduleName/data/datasources/${singularModuleName}_local_datasource.dart';
import '/features/$moduleName/data/datasources/${singularModuleName}_remote_datasource.dart';
import '/features/$moduleName/domain/entities/$singularModuleName.dart';
import '/features/$moduleName/domain/repositories/${singularModuleName}_repository.dart';

/// Implementation of ${singularClassName}Repository
class ${singularClassName}RepositoryImpl implements ${singularClassName}Repository {
  final ${singularClassName}RemoteDataSource _remoteDataSource;
  final ${singularClassName}LocalDataSource _localDataSource;
  final NetworkInfo _networkInfo;

  ${singularClassName}RepositoryImpl({
    required ${singularClassName}RemoteDataSource remoteDataSource,
    required ${singularClassName}LocalDataSource localDataSource,
    required NetworkInfo networkInfo,
  })  : _remoteDataSource = remoteDataSource,
        _localDataSource = localDataSource,
        _networkInfo = networkInfo;

  @override
  Future<Either<Failure, List<$singularClassName>>> get${className}() async {
    if (await _networkInfo.internetAvailable()) {
      try {
        final remote${className} = await _remoteDataSource.get${className}();
        await _localDataSource.cache${className}(remote${className});
        return Right(remote${className});
      } catch (e) {
        return Left(ServerFailure(message: e.toString()));
      }
    } else {
      try {
        final local${className} = await _localDataSource.get${className}();
        return Right(local${className});
      } catch (e) {
        return Left(CacheFailure(message: e.toString()));
      }
    }
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

import '/features/$moduleName/domain/entities/$singularModuleName.dart';

/// State for $singularClassName
class ${singularClassName}State {
  final bool isLoading;
  final String? errorMessage;

  const ${singularClassName}State({
    this.isLoading = false,
    this.errorMessage,
  });

  ${singularClassName}State copyWith({
    bool? isLoading,
    String? errorMessage,
  }) {
    return ${singularClassName}State(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}
''',
    );

    // Provider
    await _createFile(
      '$basePath/presentation/providers',
      '${singularModuleName}_provider',
      content: '''import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '/features/$moduleName/presentation/providers/state/${singularModuleName}_state.dart';

part '${singularModuleName}_provider.g.dart';

@riverpod
class ${singularClassName}Notifier extends _\$${singularClassName}Notifier {
  @override
  ${singularClassName}State build() {
    return const ${singularClassName}State();
  }

}
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

import '/features/$moduleName/domain/entities/$singularModuleName.dart';

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
  final List<$singularClassName> $moduleName;
  
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

    // Bloc
    await _createFile(
      '$basePath/presentation/bloc',
      '${singularModuleName}_bloc',
      content: '''import 'package:flutter_bloc/flutter_bloc.dart';

import '/features/$moduleName/presentation/bloc/event/${singularModuleName}_event.dart';
import '/features/$moduleName/presentation/bloc/state/${singularModuleName}_state.dart';

class ${singularClassName}Bloc extends Bloc<${singularClassName}Event, ${singularClassName}State> {
  ${singularClassName}Bloc() : super(const ${singularClassName}Initial()) {
    on<Load${className}>(_onLoad${className});
    on<Refresh${className}>(_onRefresh${className});
  }

  Future<void> _onLoad${className}(
    Load${className} event,
    Emitter<${singularClassName}State> emit,
  ) async {
    emit(const ${singularClassName}Loading());
    
    try {
      // TODO: Implement use case call
      // final result = await _get${className}UseCase(NoParams());
      
      // result.fold(
      //   (failure) => emit(${singularClassName}Error(failure.message)),
      //   (data) => emit(${singularClassName}Loaded(data)),
      // );
      
      // Placeholder
      emit(const ${singularClassName}Loaded([]));
    } catch (e) {
      emit(${singularClassName}Error(e.toString()));
    }
  }

  Future<void> _onRefresh${className}(
    Refresh${className} event,
    Emitter<${singularClassName}State> emit,
  ) async {
    // Same as load but can be customized
    await _onLoad${className}(const Load${className}(), emit);
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
      final file = await File('$basePath/$fileName.$fileType').create();

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
