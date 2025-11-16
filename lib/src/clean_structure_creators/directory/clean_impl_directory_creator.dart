import 'dart:io';

import 'package:ssl_cli/utils/pubspec_edit.dart';

import '../../../utils/setup_flavor.dart';
import '../clean_i_creators.dart';

class CleanImplDirectoryCreator implements IDirectoryCreator {
  final String projectName;
  final String? stateManagement;

  CleanImplDirectoryCreator(this.projectName, this.stateManagement);

  late final String basePath;
  late final String projectDirPath;

  @override
  Directory get coreDir => Directory('$basePath/core');

  @override
  Directory get featuresDir => Directory('$basePath/features');

  @override
  Directory get assetsDir => Directory('${Directory.current.path}/assets');

  @override
  Future<bool> createDirectories() async {
    try {
      final libDir = Directory("lib");

      if (await libDir.exists()) {
        basePath = libDir.absolute.path;
      } else {
        final res = await Directory("lib").create(recursive: true);
        basePath = res.absolute.path;
      }

      final absCorePath = coreDir.absolute.path;
      final absFeaturesPath = featuresDir.absolute.path;
      final absAssetsPath = assetsDir.absolute.path;

      print('Creating Clean Architecture directories...\n');

      // Create assets folder
      print('Creating assets directory...');
      await Directory('$absAssetsPath').create();
      await Directory('$absAssetsPath/fonts').create();
      await Directory('$absAssetsPath/images/dark').create(recursive: true);
      await Directory('$absAssetsPath/images/light').create(recursive: true);
      await Directory('$absAssetsPath/svg/dark').create(recursive: true);
      await Directory('$absAssetsPath/svg/light').create(recursive: true);

      // Create core directory structure
      print('Creating core directory...');
      await Directory(absCorePath).create();

      // Core subdirectories
      await Directory('$absCorePath/constants').create();
      await Directory('$absCorePath/di').create();
      await Directory('$absCorePath/error').create();
      await Directory('$absCorePath/models').create();
      await Directory('$absCorePath/network').create();
      await Directory('$absCorePath/presentation').create();
      await Directory('$absCorePath/presentation/widgets').create();
      await Directory('$absCorePath/presentation/mixins').create();
      await Directory('$absCorePath/routes').create();
      await Directory('$absCorePath/theme').create();
      await Directory('$absCorePath/usecases').create();
      await Directory('$absCorePath/utils').create();
      await Directory('$absCorePath/utils/styles').create();

      // Create features directory with example feature (homes)
      print('Creating features directory with example module...');
      await Directory(absFeaturesPath).create();
      await Directory('$absFeaturesPath/homes').create();

      // Domain layer
      await Directory('$absFeaturesPath/homes/domain').create();
      await Directory('$absFeaturesPath/homes/domain/entities').create();
      await Directory('$absFeaturesPath/homes/domain/repositories').create();
      await Directory('$absFeaturesPath/homes/domain/usecases').create();

      // Data layer
      await Directory('$absFeaturesPath/homes/data').create();
      await Directory('$absFeaturesPath/homes/data/models').create();
      await Directory('$absFeaturesPath/homes/data/datasources').create();
      await Directory('$absFeaturesPath/homes/data/repositories').create();

      // Presentation layer
      await Directory('$absFeaturesPath/homes/presentation').create();
      await Directory('$absFeaturesPath/homes/presentation/pages').create();
      await Directory('$absFeaturesPath/homes/presentation/widgets')
          .create();
      
      // Create state management specific directories
      if (stateManagement == "2") {
        // Bloc pattern
        await Directory('$absFeaturesPath/homes/presentation/bloc').create();
        await Directory('$absFeaturesPath/homes/presentation/bloc/state').create();
        await Directory('$absFeaturesPath/homes/presentation/bloc/event').create();
      } else {
        // Riverpod pattern (default)
        await Directory('$absFeaturesPath/homes/presentation/providers')
            .create();
        await Directory('$absFeaturesPath/homes/presentation/providers/state')
            .create();
      }

      // Create l10n directory
      print('Creating l10n directory...');
      await Directory('$basePath/l10n').create();

      print('SSL CLI build setup initiate...');
      final appBuildGradleEdit = SetupFlavor();
      appBuildGradleEdit.appBuildGradleEditFunc();

      // Pubspec edit file
      print('Pubspec generate with packages and other configuration...');
      final pubspecEdit = PubspecEdit();
      final pubspecFilePath = "${Directory.current.path}/pubspec.yaml";
      pubspecEdit.pubspecEditConfig(pubspecFilePath, patternNumber: "4", stateManagement: stateManagement);

      return true;
    } catch (e, s) {
      stderr.writeln(e);
      stderr.writeln(s);
      return false;
    }
  }
}
