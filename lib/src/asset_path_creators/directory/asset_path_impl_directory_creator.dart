import 'dart:io';

import '../asset_path_i_creators.dart';

class AssetPathImplDirectoryCreator implements AssetPathIDirectoryCreator {
  final _assets = 'assets';
  final _utils = 'utils';
  final _styles = 'styles';
  final _core = 'core';
  final _images = 'images';
  final _svg = 'svg';
  final _fonts = 'fonts';

  late final String basePath;
  late final String assetPath;
  late final bool isCleanArchitecture;

  @override
  Directory get projectDir => Directory(Directory.current.path);
  @override
  Directory get assetsDir => Directory('${projectDir.absolute.path}/$_assets');

  @override
  Directory get utilsDir => isCleanArchitecture 
      ? Directory('$basePath/$_core/$_utils')
      : Directory('$basePath/$_utils');
  
  @override
  Directory get stylesSubDir => isCleanArchitecture
      ? Directory('$basePath/$_core/$_utils/$_styles')
      : Directory('$basePath/$_utils/$_styles');

  @override
  Future<bool> createDirectories() async {
    try {
      final libDir = Directory("lib");
      // final assetsDir = Directory("assets");


      if (await assetsDir.exists()) {
        assetPath = assetsDir.absolute.path;
      } else {
        print('creating asset directory...');
        final res = await assetsDir.create();
        assetPath = res.absolute.path;
        await createSubDirectoriesInsideAsset();
      }


      if (await libDir.exists()) {
        basePath = libDir.absolute.path;
        
        // Check if it's a clean architecture project
        final coreDir = Directory('$basePath/$_core');
        isCleanArchitecture = await coreDir.exists();
        
        if (isCleanArchitecture) {
          print('Detected Clean Architecture project structure');
          print('Using path: lib/core/utils/styles/k_assets.dart');
        } else {
          print('Detected legacy project structure');
          print('Using path: lib/utils/styles/k_assets.dart');
        }
      } else {
        final res = await libDir.create(recursive: true);
        basePath = res.absolute.path;
        isCleanArchitecture = false;
      }


      final utilsConstantPath = utilsDir.absolute.path;


      if (await utilsDir.exists()) {
        if (!(await stylesSubDir.exists())) {
          await createSubDirectoriesInsideUtil();
        }
      } else {
        print('creating directories...\n');
        print('creating utils directory...');
        await Directory(utilsConstantPath).create();
        await createSubDirectoriesInsideUtil();
      }
      return true;
    } catch (e, s) {
      stderr.writeln(e);
      stderr.writeln(s);
      return false;
    }
  }

  Future<void> createSubDirectoriesInsideAsset() async {
    await Directory('$assetPath/$_fonts').create();
    await Directory('$assetPath/$_images').create();
    await Directory('$assetPath/$_svg').create();
  }

  Future<void> createSubDirectoriesInsideUtil() async {
    print('creating styles sub directories directory...');
    
    if (isCleanArchitecture) {
      // For clean architecture: lib/core/utils/styles
      final coreUtilsPath = '$basePath/$_core/$_utils';
      await Directory(coreUtilsPath).create(recursive: true);
      await Directory('$coreUtilsPath/$_styles').create();
    } else {
      // For legacy: lib/utils/styles
      final utilsPath = '$basePath/$_utils';
      await Directory(utilsPath).create(recursive: true);
      await Directory('$utilsPath/$_styles').create();
    }
  }
}
