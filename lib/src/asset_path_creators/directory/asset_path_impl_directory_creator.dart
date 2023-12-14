import 'dart:io';

import '../asset_path_i_creators.dart';

class AssetPathImplDirectoryCreator implements AssetPathIDirectoryCreator {
  final _assets = 'assets';
  final _utils = 'utils';
  final _styles = 'styles';
  final _images = 'images';
  final _svg = 'svg';
  final _fonts = 'fonts';

  late final String basePath;
  late final String assetPath;

  @override
  Directory get projectDir => Directory(Directory.current.path);
  @override
  Directory get assetsDir => Directory('${projectDir.absolute.path}/$_assets');

  @override
  Directory get utilsDir => Directory('$basePath/$_utils');
  @override
  Directory get stylesSubDir => Directory('$basePath/$_utils/$_styles');

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
      } else {
        final res = await libDir.create(recursive: true);
        basePath = res.absolute.path;
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
    final stylesConstantPath = utilsDir.absolute.path;
    print('creating styles sub directories directory...');
    await Directory(stylesConstantPath).create();
  }
}
