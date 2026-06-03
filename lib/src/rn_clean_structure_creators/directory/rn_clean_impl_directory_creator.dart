import 'dart:io';
import '../rn_clean_i_creators.dart';

class RNCleanImplDirectoryCreator implements RNIDirectoryCreator {
  final String projectName;

  RNCleanImplDirectoryCreator(this.projectName);

  late final String basePath;

  @override
  Directory get srcDir => Directory('$basePath/src');

  @override
  Directory get coreDir => Directory('$basePath/src/core');

  @override
  Directory get featuresDir => Directory('$basePath/src/features');

  @override
  Future<bool> createDirectories() async {
    try {
      final currentDir = Directory.current.path;
      basePath = currentDir;

      print('Creating React Native Clean Architecture directories...\n');

      final absSrcPath = srcDir.absolute.path;
      final absCorePath = coreDir.absolute.path;
      final absFeaturesPath = featuresDir.absolute.path;

      // src/
      await Directory(absSrcPath).create(recursive: true);

      // core/
      await Directory(absCorePath).create();
      await Directory('$absCorePath/constants').create();
      await Directory('$absCorePath/di').create();
      await Directory('$absCorePath/error').create();
      await Directory('$absCorePath/models').create();
      await Directory('$absCorePath/network').create();
      await Directory('$absCorePath/presentation').create();
      await Directory('$absCorePath/presentation/components').create();
      await Directory('$absCorePath/presentation/hooks').create();
      await Directory('$absCorePath/routes').create();
      await Directory('$absCorePath/theme').create();
      await Directory('$absCorePath/usecases').create();
      await Directory('$absCorePath/utils').create();

      // features/homes (example module)
      await Directory(absFeaturesPath).create();
      await Directory('$absFeaturesPath/homes').create();

      // domain layer
      await Directory('$absFeaturesPath/homes/domain').create();
      await Directory('$absFeaturesPath/homes/domain/entities').create();
      await Directory('$absFeaturesPath/homes/domain/repositories').create();
      await Directory('$absFeaturesPath/homes/domain/usecases').create();

      // data layer
      await Directory('$absFeaturesPath/homes/data').create();
      await Directory('$absFeaturesPath/homes/data/datasources').create();
      await Directory('$absFeaturesPath/homes/data/models').create();
      await Directory('$absFeaturesPath/homes/data/repositories').create();

      // presentation layer (Zustand store)
      await Directory('$absFeaturesPath/homes/presentation').create();
      await Directory('$absFeaturesPath/homes/presentation/screens').create();
      await Directory('$absFeaturesPath/homes/presentation/components').create();
      await Directory('$absFeaturesPath/homes/presentation/store').create();

      print('All directories created successfully!');
      return true;
    } catch (e, s) {
      stderr.writeln(e);
      stderr.writeln(s);
      return false;
    }
  }
}
