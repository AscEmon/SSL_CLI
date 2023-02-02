import 'dart:io';
import '../repo_module_i_creators.dart';

class RepoModuleImplDirectoryCreator implements RepoModuleIDirectoryCreator {
  final _model = 'model';
  final _views = 'views';
  final _moduleName = 'module_name';
  final _controller = 'controller';
  final _components = 'components';
  final _module = 'module';
  final _repository = 'repository';
  final _state = 'state';

  final String projectName;
  RepoModuleImplDirectoryCreator(this.projectName);

  late final String basePath;
  late final String projectDirPath;

  @override
  Directory get moduleDir => Directory(basePath);

  @override
  Future<bool> createDirectories() async {
    try {
      final libDir = Directory("lib/$_module");

      if (await libDir.exists()) {
        basePath = libDir.absolute.path;
      } 
      // else {
      //   final res = await Directory("lib/$_moduleName").create(recursive: true);
      //   basePath = res.absolute.path;
      // }

      final absMvcPath = moduleDir.absolute.path;

      print('creating directories...\n');
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

      return true;
    } catch (e, s) {
      stderr.writeln(e);
      stderr.writeln(s);
      return false;
    }
  }
}
