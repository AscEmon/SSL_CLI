import 'dart:io';
import '../repo_module_i_creators.dart';

class RepoModuleImplFileCreator implements RepoModuleIFileCreator {
  final RepoModuleIDirectoryCreator directoryCreator;
  final String projectName;
  RepoModuleImplFileCreator(
    this.directoryCreator,
    this.projectName,
  );

  @override
  Future<void> createNecessaryFiles() async {
    print('creating necessary files...');

  
    await _createFile(
      directoryCreator.moduleDir.path +
          '/module_name' +
          '/controller' +
          '/state',
      'module_name_state',
    );
    await _createFile(
      directoryCreator.moduleDir.path + '/module_name' + '/controller',
      'controller_name',
    );
    await _createFile(
      directoryCreator.moduleDir.path + '/module_name' + '/model',
      'model_class_name',
    );
    await _createFile(
        directoryCreator.moduleDir.path + '/module_name' + '/repository',
        'module_name_api',
        content: '''
import 'package:$projectName/data_provider/api_client.dart';
class ModuleNameApi {
  final ApiClient _apiClient = ApiClient();

  ModuleNameApi();

 
}

''');
    await _createFile(
        directoryCreator.moduleDir.path + '/module_name' + '/repository',
        'module_name_interface',
        content: '''
import 'package:flutter/material.dart';

@immutable
abstract class IModuleNameRepository {
  
}




''');
    await _createFile(
        directoryCreator.moduleDir.path + '/module_name' + '/repository',
        'module_name_repository',
        content: '''
import 'package:$projectName/module/module_name/repository/module_name_interface.dart';

class ModuleNameRepository implements IModuleNameRepository {}


''');

    await _createFile(
        directoryCreator.moduleDir.path + '/module_name' + '/views',
        'screen_name',
        content: """
import 'package:flutter/material.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: Center(child: Container(child: Text("Project Setup"),),),);
  }
}

""");
    await _createFile(
      directoryCreator.moduleDir.path +
          '/module_name' +
          '/views' +
          '/components',
      'widget_name',
    );

  }

  Future<void> _createFile(
    String basePath,
    String fileName, {
    String? content,
    String? fileExtention = 'dart',
  }) async {
    String fileType;
    if (fileExtention == 'yaml') {
      fileType = 'yaml';
    } else if (fileExtention == 'arb') {
      fileType = 'arb';
    } else {
      fileType = 'dart';
    }

    try {
      final file = await File('$basePath/$fileName.$fileType').create();

      if (content != null) {
        final writer = file.openWrite();
        writer.write(content);
        writer.close();
      }
    } catch (_) {
      stderr.write('creating $fileName.$fileType failed!');
      exit(2);
    }
  }
}
