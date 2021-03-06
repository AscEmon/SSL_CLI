import 'dart:io';
import '../i_creators.dart';

class ImplDirectoryCreator implements IDirectoryCreator {
  final _constant = 'constant';
  final _dataProvider = 'data_provider';
  final _global = 'global';
  final _l10n = 'l10n';
  final _mvc = 'mvc';
  final _utils = 'utils';
  final _model = 'model';
  final _widget = 'widget';
  final _views = 'views';
  final _module_name = 'module_name';
  final _controller = 'controller';
  final _styles = 'styles';
  final _components = 'components';
  final _assets='assets';
  final _images='images';
  final _svg='svg';

  final String projectName;
  ImplDirectoryCreator(this.projectName);

  late final String basePath;
  late final String projectDirPath;

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
      final libDir = Directory("lib");
      

      if (await libDir.exists()) {
        basePath = libDir.absolute.path;
      } else {
        final res = await Directory("lib").create(recursive: true);
        basePath = res.absolute.path;
      }

      final absConstantPath = constantDir.absolute.path;
      final absDataProviderPath = dataProviderDir.absolute.path;
      final absGlobalPath = globalDir.absolute.path;
      final absl10nPath = l10nDir.absolute.path;
      final absMvcPath = mvcDir.absolute.path;
      final absUtilsPath = utilsDir.absolute.path;
      final assetPath=Directory(Directory.current.path).absolute.path;

      print('creating directories...\n');
      
      //create aaset folder 
      print('creating asset directory...');
      await Directory('$assetPath/$_assets').create();
      await Directory('$assetPath/$_assets/$_images').create();
      await Directory('$assetPath/$_assets/$_svg').create();


      //constant directory
      print('creating constant directory...');
      await Directory(absConstantPath).create();

      // dataProvider directory
      print('creating dataProvider directory...');
      await Directory(absDataProviderPath).create();

      //global directory
      print('creating global directory...');
      await Directory(absGlobalPath).create();
      await Directory('$absGlobalPath/$_model').create();
      await Directory('$absGlobalPath/$_widget').create();

      //l10n directory
      print('creating l10n directory...');
      await Directory(absl10nPath).create();

      //MVC directory
      print('creating mvc directory...');
      await Directory(absMvcPath).create();
      await Directory('$absMvcPath/$_module_name').create();

      await Directory('$absMvcPath/$_module_name/$_controller').create();
      await Directory('$absMvcPath/$_module_name/$_model').create();
      await Directory('$absMvcPath/$_module_name/$_views').create();
      await Directory('$absMvcPath/$_module_name/$_views/$_components')
          .create();

      //Utils directory
      print('creating util directory...');
      await Directory(absUtilsPath).create();
      await Directory('$absUtilsPath/$_styles').create();

      return true;
    } catch (e, s) {
      stderr.writeln(e);
      stderr.writeln(s);
      return false;
    }
  }
}
