import 'dart:io';
import '../i_creators.dart';

class ImplDirectoryCreator implements IDirectoryCreator {
  final _constant = 'constant';
  final _dataProvider = 'data_provider';
  final _global = 'global';
  final _l10n = 'l10n';
  final _mvc = 'mvc';
  final _utils = 'utils';

  late final String basePath;

  @override
  // TODO: implement constantDir
  Directory get constantDir => Directory('$basePath/$_constant');

  @override
  // TODO: implement dataProviderDir
  Directory get dataProviderDir => Directory('$basePath/$_dataProvider');

  @override
  // TODO: implement globalDir
  Directory get globalDir => Directory('$basePath/$_global');

  @override
  // TODO: implement l10nDir
  Directory get l10nDir => Directory('$basePath/$_l10n');

  @override
  // TODO: implement mvc
  Directory get mvcDir => Directory('$basePath/$_mvc');

  @override
  // TODO: implement utils
  Directory get utilsDir => Directory('$basePath/$_utils');

  @override
  Future<bool> createDirectories() async {
    try {
      final libDir = Directory('lib');

      if (await libDir.exists()) {
        basePath = libDir.absolute.path;
      } else {
        final res = await Directory('lib').create(recursive: true);
        basePath = res.absolute.path;
      }

      final absConstantPath = constantDir.absolute.path;
      final absDataProviderPath = dataProviderDir.absolute.path;
      final absGlobalPath = globalDir.absolute.path;
      final absl10nPath = l10nDir.absolute.path;
      final absMvcPath = mvcDir.absolute.path;
      final absUtilsPath = utilsDir.absolute.path;

      print('creating directories...\n');

      // bloc directory
      print('creating constant directory...');
      await Directory(absConstantPath).create();
      // await Directory('$absBlocPath/$_core').create();

      // data directory
      print('creating data directory...');
      await Directory(absDataProviderPath).create();
      await Directory(absGlobalPath).create();
      await Directory(absl10nPath).create();
      await Directory(absMvcPath).create();
      await Directory(absUtilsPath).create();

      // await Directory('$absDataPath/$_core').create();
      // await Directory('$absDataPath/models').create();
      // await Directory('$absDataPath/repositories').create();
      // await Directory('$absDataPath/contractors').create();
      // await Directory('$absDataPath/data_providers').create();

      // ui directory
      // print('creating ui directory...');
      // await Directory(absUiPath).create();
      // await Directory('$absUiPath/pages').create();
      // await Directory('$absUiPath/dialogs').create();
      // await Directory('$absUiPath/$_core').create();
      // await Directory('$absUiPath/global').create();

      // await Directory('$absUiPath/mvc/get_module/controller').create();
      // await Directory('$absUiPath/mvc/get_module/model').create();
      // await Directory('$absUiPath/mvc/get_module/views').create();

      // utils directory
      print('creating utils directory...');
      await Directory('$basePath/$_utils').create();

      return true;
    } catch (e, s) {
      stderr.writeln(e);
      stderr.writeln(s);
      return false;
    }
  }
}
