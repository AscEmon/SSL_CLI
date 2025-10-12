import 'dart:io';
import '../clean_module_i_creators.dart';

class CleanModuleImplDirectoryCreator implements CleanModuleIDirectoryCreator {
  final String moduleName;
  final String? stateManagement;
  
  CleanModuleImplDirectoryCreator(this.moduleName, this.stateManagement);

  late final String basePath;

  @override
  Directory get moduleDir => Directory(basePath);

  @override
  Future<bool> createDirectories() async {
    try {
      final featuresDir = Directory("lib/features");

      if (await featuresDir.exists()) {
        basePath = featuresDir.absolute.path;
      } else {
        stderr.writeln('Error: lib/features directory not found!');
        stderr.writeln('Please ensure you are in a Flutter project with clean architecture structure.');
        return false;
      }

      final absModulePath = moduleDir.absolute.path;

      print('Creating clean architecture module directories...\n');
      
      // Create main module directory
      print('Creating module: $moduleName');
      await Directory('$absModulePath/$moduleName').create();

      // Create data layer
      print('Creating data layer...');
      await Directory('$absModulePath/$moduleName/data').create();
      await Directory('$absModulePath/$moduleName/data/datasources').create();
      await Directory('$absModulePath/$moduleName/data/models').create();
      await Directory('$absModulePath/$moduleName/data/repositories').create();

      // Create domain layer
      print('Creating domain layer...');
      await Directory('$absModulePath/$moduleName/domain').create();
      await Directory('$absModulePath/$moduleName/domain/entities').create();
      await Directory('$absModulePath/$moduleName/domain/repositories').create();
      await Directory('$absModulePath/$moduleName/domain/usecases').create();

      // Create presentation layer
      print('Creating presentation layer...');
      await Directory('$absModulePath/$moduleName/presentation').create();
      await Directory('$absModulePath/$moduleName/presentation/pages').create();
      
      // Create state management specific directories
      if (stateManagement == "2") {
        // Bloc pattern
        print('Creating Bloc structure...');
        await Directory('$absModulePath/$moduleName/presentation/bloc').create();
        await Directory('$absModulePath/$moduleName/presentation/bloc/state').create();
        await Directory('$absModulePath/$moduleName/presentation/bloc/event').create();
      } else {
        // Riverpod pattern (default)
        print('Creating Riverpod structure...');
        await Directory('$absModulePath/$moduleName/presentation/providers').create();
        await Directory('$absModulePath/$moduleName/presentation/providers/state').create();
      }
      
      await Directory('$absModulePath/$moduleName/presentation/widgets').create();

      print('\nDirectories created successfully!');
      return true;
    } catch (e, s) {
      stderr.writeln(e);
      stderr.writeln(s);
      return false;
    }
  }
}
