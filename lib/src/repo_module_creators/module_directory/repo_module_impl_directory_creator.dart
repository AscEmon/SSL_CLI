import 'dart:io';
import '../file/route_generation_create_module.dart';
import '../repo_module_i_creators.dart';

class RepoModuleImplDirectoryCreator implements RepoModuleIDirectoryCreator {
  final _model = 'model';
  final _views = 'views';
  final _controller = 'controller';
  final _bloc = "bloc";
  final _components = 'components';
  final _modules = 'modules';
  final _repository = 'repository';
  final _state = 'state';

  final String moduleName;
  final String? modulePattern;
  RepoModuleImplDirectoryCreator(this.moduleName, this.modulePattern);

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
      print(
          'creating module directory based on ${modulePattern == "1" ? "Bloc pattern" : "Repository pattern"} ...');
      await Directory(absMvcPath).create();
      await Directory('$absMvcPath/$moduleName').create();
      if (modulePattern == "1") {
        await Directory('$absMvcPath/$moduleName/$_bloc').create();
      } else {
        await Directory('$absMvcPath/$moduleName/$_controller').create();
        await Directory('$absMvcPath/$moduleName/$_controller/$_state')
            .create();
      }

      await Directory('$absMvcPath/$moduleName/$_model').create();
      await Directory('$absMvcPath/$moduleName/$_repository').create();
      await Directory('$absMvcPath/$moduleName/$_views').create();
      await Directory('$absMvcPath/$moduleName/$_views/$_components').create();

      String filePath = 'lib/utils/app_routes.dart';

      RouteGenerationCreateModule routeGenerate = RouteGenerationCreateModule();
      routeGenerate.moduleToRouteCreate(filePath, moduleName);

      return true;
    } catch (e, s) {
      stderr.writeln(e);
      stderr.writeln(s);
      return false;
    }
  }
}
