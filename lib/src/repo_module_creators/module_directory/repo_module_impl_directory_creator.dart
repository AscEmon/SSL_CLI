import 'dart:io';
import '../repo_module_i_creators.dart';

class RepoModuleImplDirectoryCreator implements RepoModuleIDirectoryCreator {
  final _model = 'model';
  final _views = 'views';
  final _controller = 'controller';
  final _components = 'components';
  final _modules = 'modules';
  final _repository = 'repository';
  final _state = 'state';

  final String moduleName;
  RepoModuleImplDirectoryCreator(this.moduleName);

  late final String basePath;
  late final String projectDirPath;

  @override
  Directory get moduleDir => Directory(basePath);

  @override
  Future<bool> createDirectories() async {
    try {
      final libDir = Directory("lib/$_modules");

      if (await libDir.exists()) {
        basePath = libDir.absolute.path;
      }

      final absMvcPath = moduleDir.absolute.path;

      print('creating directories...\n');
      //module directory
      print('creating module directory based on repository pattern...');
      await Directory(absMvcPath).create();
      await Directory('$absMvcPath/$moduleName').create();

      await Directory('$absMvcPath/$moduleName/$_controller').create();
      await Directory('$absMvcPath/$moduleName/$_controller/$_state').create();
      await Directory('$absMvcPath/$moduleName/$_model').create();
      await Directory('$absMvcPath/$moduleName/$_repository').create();
      await Directory('$absMvcPath/$moduleName/$_views').create();
      await Directory('$absMvcPath/$moduleName/$_views/$_components').create();

      return true;
    } catch (e, s) {
      stderr.writeln(e);
      stderr.writeln(s);
      return false;
    }
  }
}
