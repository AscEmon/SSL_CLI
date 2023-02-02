import 'package:ssl_cli/src/repo_module_creators/file/repo_module_impl_file_creator.dart';
import 'package:ssl_cli/src/repo_module_creators/module_directory/repo_module_impl_directory_creator.dart';
import 'package:ssl_cli/src/repo_module_creators/repo_impl_ssl_creator.dart';
import 'package:ssl_cli/src/repo_structure_creators/directory/repo_impl_directory_creator.dart';
import 'package:ssl_cli/src/repo_structure_creators/file/repo_impl_file_creator.dart';
import 'package:ssl_cli/src/repo_structure_creators/repo_impl_ssl_creator.dart';

import '../mvc_structure_creators/mvc_impl_ssl_creator.dart';
import '../mvc_structure_creators/directory/mvc_impl_directory_creator.dart';
import '../mvc_structure_creators/file/mvc_impl_file_creator.dart';
import 'i_command.dart';

class CreateCommand implements ICommand {
  String? projectName;
  String? patternNumber;
  String? moduleName;
  CreateCommand({
    this.projectName,
    this.patternNumber,
    this.moduleName,
  });
  @override
  Future<void> execute() async {
    if (projectName != null && patternNumber != null && patternNumber == "1") {
      final directoryCreator = MvcImplDirectoryCreator(projectName!);
      final fileCreator = MvcImplFileCreator(directoryCreator, projectName!);

      final sslCreator = MvcImplSSLCreator(
        directoryCreator: directoryCreator,
        fileCreator: fileCreator,
      );
      return sslCreator.create();
    } else if (moduleName != null) {
      final directoryCreator = RepoModuleImplDirectoryCreator(moduleName!);
      final fileCreator =
          RepoModuleImplFileCreator(directoryCreator, moduleName!);

      final sslCreator = RepoModuleImplSSLCreator(
        directoryCreator: directoryCreator,
        fileCreator: fileCreator,
      );
      return sslCreator.create();
    } else {
      final directoryCreator = RepoImplDirectoryCreator(projectName ?? "");
      final fileCreator =
          RepoImplFileCreator(directoryCreator, projectName ?? "");

      final sslCreator = RepoImplSSLCreator(
        directoryCreator: directoryCreator,
        fileCreator: fileCreator,
      );
      return sslCreator.create();
    }
  }
}
