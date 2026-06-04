import 'dart:io';
import '../rn_clean_module_i_creators.dart';

class RNCleanModuleImplFileCreator implements RNCleanModuleIFileCreator {
  final RNCleanModuleIDirectoryCreator directoryCreator;
  final String moduleName;

  RNCleanModuleImplFileCreator(this.directoryCreator, this.moduleName);

  @override
  Future<void> createNecessaryFiles() async {
    print('\nCreating necessary files...');

    final List<String> parts = moduleName.split('_');
    String className = parts.map((p) => p.capitalize()).join('');

    final basePath = '${directoryCreator.moduleDir.path}/$moduleName';
    final singular = _singular(moduleName);
    final singularClass = _singular(className);

    await _createDomainFiles(basePath, className, singular, singularClass);
    await _createDataFiles(basePath, className, singular, singularClass);
    await _createPresentationFiles(basePath, className, singular, singularClass);

    print('\nAll module files created successfully!');
  }

  String _singular(String word) {
    if (word.endsWith('s') && word.length > 1) {
      return word.substring(0, word.length - 1);
    }
    return word;
  }

  Future<void> _createDomainFiles(
    String basePath,
    String className,
    String singular,
    String singularClass,
  ) async {
    print('Creating domain layer files...');

    await _createFile(
      '$basePath/domain/entities',
      '$singular.ts',
      '''export interface ${singularClass}Entity {
  id: number;
  // Add your entity properties here
}
''',
    );

    await _createFile(
      '$basePath/domain/repositories',
      '${moduleName}_repository.ts',
      '''import { Either } from '../../../../core/error/exception_handler';
import { Failure } from '../../../../core/error/failures';
import { ${singularClass}Entity } from '../entities/$singular';

export interface ${className}Repository {
  get${className}(): Promise<Either<Failure, ${singularClass}Entity[]>>;
}
''',
    );

    await _createFile(
      '$basePath/domain/usecases',
      'get_$singular.ts',
      '''import { Either } from '../../../../core/error/exception_handler';
import { Failure } from '../../../../core/error/failures';
import { UseCase, NoParams } from '../../../../core/usecases/usecase';
import { ${singularClass}Entity } from '../entities/$singular';
import { ${className}Repository } from '../repositories/${moduleName}_repository';

export class Get${className} implements UseCase<${singularClass}Entity[], NoParams> {
  private readonly repository: ${className}Repository;

  constructor(repository: ${className}Repository) {
    this.repository = repository;
  }

  async call(_params: NoParams): Promise<Either<Failure, ${singularClass}Entity[]>> {
    return this.repository.get${className}();
  }
}
''',
    );
  }

  Future<void> _createDataFiles(
    String basePath,
    String className,
    String singular,
    String singularClass,
  ) async {
    print('Creating data layer files...');

    await _createFile(
      '$basePath/data/models',
      '${singular}_model.ts',
      '''import { ${singularClass}Entity } from '../../domain/entities/$singular';

export interface ${singularClass}Model extends ${singularClass}Entity {
  // Additional model fields
}

export function ${singular}ModelFromJson(json: Record<string, unknown>): ${singularClass}Model {
  return {
    id: json['id'] as number,
  };
}

export function ${singular}ModelToJson(model: ${singularClass}Model): Record<string, unknown> {
  return {
    id: model.id,
  };
}
''',
    );

    await _createFile(
      '$basePath/data/datasources',
      '${moduleName}_remote_datasource.ts',
      '''import { ApiClient, HttpMethod } from '../../../../core/network/api_client';
import { ${singularClass}Model, ${singular}ModelFromJson } from '../models/${singular}_model';

export interface ${className}RemoteDataSource {
  get${className}(): Promise<${singularClass}Model[]>;
}

export class ${className}RemoteDataSourceImpl implements ${className}RemoteDataSource {
  private readonly apiClient: ApiClient;

  constructor(apiClient: ApiClient) {
    this.apiClient = apiClient;
  }

  async get${className}(): Promise<${singularClass}Model[]> {
    return this.apiClient.request<${singularClass}Model[]>({
      endpoint: '/$moduleName',
      method: HttpMethod.GET,
      converter: (data) => {
        const list = data as Record<string, unknown>[];
        return list.map(${singular}ModelFromJson);
      },
    });
  }
}
''',
    );

    await _createFile(
      '$basePath/data/datasources',
      '${moduleName}_local_datasource.ts',
      '''import { ${singularClass}Model } from '../models/${singular}_model';

export interface ${className}LocalDataSource {
  getCached${className}(): Promise<${singularClass}Model[]>;
  cache${className}(items: ${singularClass}Model[]): Promise<void>;
}

export class ${className}LocalDataSourceImpl implements ${className}LocalDataSource {
  async getCached${className}(): Promise<${singularClass}Model[]> {
    return [];
  }

  async cache${className}(_items: ${singularClass}Model[]): Promise<void> {}
}
''',
    );

    await _createFile(
      '$basePath/data/repositories',
      '${moduleName}_repository_impl.ts',
      '''import { handleException, Either } from '../../../../core/error/exception_handler';
import { Failure } from '../../../../core/error/failures';
import { ${singularClass}Entity } from '../../domain/entities/$singular';
import { ${className}Repository } from '../../domain/repositories/${moduleName}_repository';
import { ${className}RemoteDataSource } from '../datasources/${moduleName}_remote_datasource';
import { ${className}LocalDataSource } from '../datasources/${moduleName}_local_datasource';

export class ${className}RepositoryImpl implements ${className}Repository {
  constructor(
    private readonly remote: ${className}RemoteDataSource,
    private readonly local: ${className}LocalDataSource
  ) {}

  async get${className}(): Promise<Either<Failure, ${singularClass}Entity[]>> {
    return handleException(() => this.remote.get${className}());
  }
}
''',
    );
  }

  Future<void> _createPresentationFiles(
    String basePath,
    String className,
    String singular,
    String singularClass,
  ) async {
    print('Creating presentation layer files...');

    await _createFile(
      '$basePath/presentation/store',
      '${singular}_state.ts',
      '''import { ${singularClass}Entity } from '../../domain/entities/$singular';
import { Failure } from '../../../../core/error/failures';

export type ${singularClass}Status = 'idle' | 'loading' | 'success' | 'error';

export interface ${singularClass}State {
  status: ${singularClass}Status;
  ${moduleName}: ${singularClass}Entity[];
  failure?: Failure;
}

export const initial${singularClass}State: ${singularClass}State = {
  status: 'idle',
  ${moduleName}: [],
  failure: undefined,
};
''',
    );

    await _createFile(
      '$basePath/presentation/store',
      '${singular}_store.ts',
      '''import { create } from 'zustand';
import { ${singularClass}State, initial${singularClass}State } from './${singular}_state';
import { Get${className} } from '../../domain/usecases/get_$singular';
import { NoParams } from '../../../../core/usecases/usecase';
import { isRight, isLeft } from '../../../../core/error/exception_handler';
import { sl } from '../../../../core/di/service_locator';

interface ${singularClass}Store extends ${singularClass}State {
  fetch${className}(): Promise<void>;
  reset(): void;
}

export const use${singularClass}Store = create<${singularClass}Store>((set) => ({
  ...initial${singularClass}State,

  fetch${className}: async () => {
    set({ status: 'loading', failure: undefined });
    const get${className} = sl.get<Get${className}>('get${className}');
    const result = await get${className}.call(new NoParams());
    if (isRight(result)) {
      set({ status: 'success', ${moduleName}: result.value });
    } else if (isLeft(result)) {
      set({ status: 'error', failure: result.value });
    }
  },

  reset: () => set(initial${singularClass}State),
}));
''',
    );

    await _createFile(
      '$basePath/presentation/screens',
      '${singularClass}Screen.tsx',
      '''import React, { useEffect } from 'react';
import { View, FlatList, StyleSheet, SafeAreaView } from 'react-native';
import { use${singularClass}Store } from '../store/${singular}_store';
import { useErrorHandler } from '../../../../core/presentation/hooks/useErrorHandler';
import GlobalLoader from '../../../../core/presentation/components/GlobalLoader';
import GlobalText from '../../../../core/presentation/components/GlobalText';
import ${singularClass}Widget from '../components/${singularClass}Widget';

const ${singularClass}Screen: React.FC = () => {
  const { status, ${moduleName}, failure, fetch${className} } = use${singularClass}Store();
  const { handleFailure } = useErrorHandler();

  useEffect(() => {
    fetch${className}();
  }, []);

  useEffect(() => {
    if (status === 'error' && failure) {
      handleFailure(failure);
    }
  }, [status, failure]);

  if (status === 'loading') {
    return (
      <SafeAreaView style={styles.center}>
        <GlobalLoader text="Loading..." />
      </SafeAreaView>
    );
  }

  return (
    <SafeAreaView style={styles.container}>
      <FlatList
        data={${moduleName}}
        keyExtractor={(item) => String(item.id)}
        renderItem={({ item }) => <${singularClass}Widget item={item} />}
        ListEmptyComponent={<GlobalText str="No data found" textAlign="center" />}
        contentContainerStyle={styles.list}
      />
    </SafeAreaView>
  );
};

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: '#fff' },
  center: { flex: 1, justifyContent: 'center', alignItems: 'center' },
  list: { padding: 16, gap: 8 },
});

export default ${singularClass}Screen;
''',
    );

    await _createFile(
      '$basePath/presentation/components',
      '${singularClass}Widget.tsx',
      '''import React from 'react';
import { View, StyleSheet } from 'react-native';
import { ${singularClass}Entity } from '../../domain/entities/$singular';
import GlobalText from '../../../../core/presentation/components/GlobalText';
import { AppColors } from '../../../../core/theme/app_colors';

interface ${singularClass}WidgetProps {
  item: ${singularClass}Entity;
}

const ${singularClass}Widget: React.FC<${singularClass}WidgetProps> = ({ item }) => {
  return (
    <View style={styles.card}>
      <GlobalText str={String(item.id)} fontSize={14} color={AppColors.textPrimary} />
    </View>
  );
};

const styles = StyleSheet.create({
  card: {
    backgroundColor: AppColors.white,
    borderRadius: 10,
    padding: 16,
    shadowColor: AppColors.black,
    shadowOpacity: 0.08,
    shadowOffset: { width: 0, height: 2 },
    shadowRadius: 4,
    elevation: 2,
  },
});

export default ${singularClass}Widget;
''',
    );
  }

  Future<void> _createFile(
      String dirPath, String fileName, String content) async {
    final file = File('$dirPath/$fileName');
    await file.writeAsString(content);
    print('  Created: $dirPath/$fileName');
  }
}

extension _StringCapitalize on String {
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }
}
