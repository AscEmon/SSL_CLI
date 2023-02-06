import 'dart:io';
import '../repo_module_i_creators.dart';

class RepoModuleImplFileCreator implements RepoModuleIFileCreator {
  final RepoModuleIDirectoryCreator directoryCreator;
  final String moduleName;
  RepoModuleImplFileCreator(
    this.directoryCreator,
    this.moduleName,
  );

  @override
  Future<void> createNecessaryFiles() async {
    print('creating necessary files...');
    final List<String> split;
    split = moduleName.split("_");
    print("After Split: $split");
    String className = "";
    print("After Capitalize : $className");
    if (split.length > 1) {
      for (var element in split) {
        className += element.capitalize();
      }
    } else {
      className = split.first.capitalize();
    }
    print("Class nanme : $className");
    print("Module name: $moduleName");

    await _createFile(
      directoryCreator.moduleDir.path +
          "/$moduleName" +
          '/controller' +
          '/state',
      '${moduleName}_state',
    );
    await _createFile(
        directoryCreator.moduleDir.path + moduleName + '/controller',
        '${moduleName}_name',
        content: '''
import '../repository/${moduleName}_interface.dart';
import '../repository/${moduleName}_repository.dart';
class ${className}Controller  {
  final I${className}Repository _${className.toLowerCase()}Repository = ${className}Repository();
  
  }
''');
    await _createFile(
      directoryCreator.moduleDir.path + moduleName + '/model',
      'model_class_name',
    );
    await _createFile(
        directoryCreator.moduleDir.path + moduleName + '/repository',
        '${moduleName}_api',
        content: '''
import '/data_provider/api_client.dart';
class ${className}Api {
  final ApiClient _apiClient = ApiClient();

  ${className}Api();

 
}

''');
    await _createFile(
        directoryCreator.moduleDir.path + moduleName + '/repository',
        '${moduleName}_interface',
        content: '''
import 'package:flutter/material.dart';

@immutable
abstract class I${className}Repository {
  
}




''');
    await _createFile(
        directoryCreator.moduleDir.path + moduleName + '/repository',
        '${moduleName}_repository',
        content: '''
import '/module/$moduleName/repository/${moduleName}_interface.dart';

class ${className}Repository implements I${className}Repository {}


''');

    await _createFile(
        directoryCreator.moduleDir.path + '/$moduleName' + '/views',
        'screen_name',
        content: """
import 'package:flutter/material.dart';

class ${className}Screen extends StatelessWidget {
  const ${className}Screen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: Center(child: Container(child: Text("$moduleName Setup"),),),);
  }
}

""");
    await _createFile(
      directoryCreator.moduleDir.path +
          '/$moduleName' +
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
    } catch (e) {
      print(e.toString());
      stderr.write('creating $fileName.$fileType failed!');
      exit(2);
    }
  }
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1).toLowerCase()}";
  }
}
