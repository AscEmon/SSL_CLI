import 'dart:io';
import '../rn_clean_module_i_creators.dart';

class RNCleanModuleImplDirectoryCreator
    implements RNCleanModuleIDirectoryCreator {
  final String moduleName;

  RNCleanModuleImplDirectoryCreator(this.moduleName);

  late final String basePath;

  @override
  Directory get moduleDir => Directory(basePath);

  @override
  Future<bool> createDirectories() async {
    try {
      final featuresDir = Directory('src/features');

      if (await featuresDir.exists()) {
        basePath = featuresDir.absolute.path;
      } else {
        stderr.writeln('Error: src/features directory not found!');
        stderr.writeln(
            'Please ensure you are in a React Native project with clean architecture structure.');
        return false;
      }

      final absModulePath = moduleDir.absolute.path;

      print('Creating React Native clean architecture module directories...\n');
      print('Creating module: $moduleName');

      await Directory('$absModulePath/$moduleName').create();

      // Domain layer
      await Directory('$absModulePath/$moduleName/domain').create();
      await Directory('$absModulePath/$moduleName/domain/entities').create();
      await Directory('$absModulePath/$moduleName/domain/repositories').create();
      await Directory('$absModulePath/$moduleName/domain/usecases').create();

      // Data layer
      await Directory('$absModulePath/$moduleName/data').create();
      await Directory('$absModulePath/$moduleName/data/datasources').create();
      await Directory('$absModulePath/$moduleName/data/models').create();
      await Directory('$absModulePath/$moduleName/data/repositories').create();

      // Presentation layer (Zustand)
      await Directory('$absModulePath/$moduleName/presentation').create();
      await Directory('$absModulePath/$moduleName/presentation/screens').create();
      await Directory('$absModulePath/$moduleName/presentation/components').create();
      await Directory('$absModulePath/$moduleName/presentation/store').create();

      print('\nDirectories created successfully!');
      return true;
    } catch (e, s) {
      stderr.writeln(e);
      stderr.writeln(s);
      return false;
    }
  }
}
