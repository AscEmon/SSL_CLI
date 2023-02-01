import 'dart:io';
import '../repo_i_creators.dart';

class RepoImplDirectoryCreator implements IDirectoryCreator {
  final _constant = 'constant';
  final _dataProvider = 'data_provider';
  final _global = 'global';
  final _l10n = 'l10n';
  final _utils = 'utils';
  final _model = 'model';
  final _widget = 'widget';
  final _views = 'views';
  final _moduleName = 'module_name';
  final _controller = 'controller';
  final _styles = 'styles';
  final _components = 'components';
  final _assets = 'assets';
  final _images = 'images';
  final _svg = 'svg';
  final _module = 'module';
  final _fonts = 'fonts';
  final _repository = 'repository';
  final _state = 'state';

  final String projectName;
  RepoImplDirectoryCreator(this.projectName);

  late final String basePath;
  late final String projectDirPath;

  @override
  Directory get constantDir => Directory('$basePath/$_constant');

  @override
  Directory get dataProviderDir => Directory('$basePath/$_dataProvider');

  @override
  Directory get globalDir => Directory('$basePath/$_global');

  @override
  Directory get l10nDir => Directory('$basePath/$_l10n');

  @override
  Directory get moduleDir => Directory('$basePath/$_module');

  @override
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
      final absMvcPath = moduleDir.absolute.path;
      final absUtilsPath = utilsDir.absolute.path;
      final assetPath = Directory(Directory.current.path).absolute.path;

      print('creating directories...\n');

      //create aaset folder
      print('creating asset directory...');
      await Directory('$assetPath/$_assets').create();
      await Directory('$assetPath/$_assets/$_fonts').create();
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
      print('creating module directory based on repository pattern...');
      await Directory(absMvcPath).create();
      await Directory('$absMvcPath/$_moduleName').create();

      await Directory('$absMvcPath/$_moduleName/$_controller').create();
      await Directory('$absMvcPath/$_moduleName/$_controller/$_state').create();
      await Directory('$absMvcPath/$_moduleName/$_model').create();
      await Directory('$absMvcPath/$_moduleName/$_repository').create();
      await Directory('$absMvcPath/$_moduleName/$_views').create();
      await Directory('$absMvcPath/$_moduleName/$_views/$_components').create();

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
