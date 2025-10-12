import 'package:ssl_cli/src/repo_module_creators/file/repo_module_impl_file_creator.dart';
import 'package:ssl_cli/src/repo_module_creators/module_directory/repo_module_impl_directory_creator.dart';
import 'package:ssl_cli/src/repo_module_creators/repo_impl_ssl_creator.dart';
import 'package:ssl_cli/src/repo_structure_creators/directory/repo_impl_directory_creator.dart';
import 'package:ssl_cli/src/repo_structure_creators/file/repo_impl_file_creator.dart'
    as repo;
import 'package:ssl_cli/src/repo_structure_creators/repo_impl_ssl_creator.dart';

import '../bloc_structure_creators/bloc_impl_ssl_creator.dart';
import '../bloc_structure_creators/directory/bloc_impl_directory_creator.dart';
import '../bloc_structure_creators/file/bloc_impl_file_creator.dart';
import '../clean_module_creators/clean_module_impl_ssl_creator.dart';
import '../clean_module_creators/file/clean_module_impl_file_creator.dart';
import '../clean_module_creators/module_directory/clean_module_impl_directory_creator.dart';
import '../clean_structure_creators/clean_impl_ssl_creator.dart';
import '../clean_structure_creators/directory/clean_impl_directory_creator.dart';
import '../clean_structure_creators/file/clean_impl_file_creator.dart';
import '../mvc_structure_creators/directory/mvc_impl_directory_creator.dart';
import '../mvc_structure_creators/file/mvc_impl_file_creator.dart';
import '../mvc_structure_creators/mvc_impl_ssl_creator.dart';
import 'i_command.dart';

class CreateCommand implements ICommand {
  String? projectName;
  String? patternNumber;
  String? modulePattern;
  String? moduleName;
  String? stateManagement;
  CreateCommand({
    this.projectName,
    this.patternNumber,
    this.moduleName,
    this.modulePattern,
    this.stateManagement,
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
    } else if (moduleName != null && modulePattern != null && modulePattern == "3") {
      // Clean Architecture Module
      final directoryCreator = CleanModuleImplDirectoryCreator(moduleName!, stateManagement);
      final fileCreator = CleanModuleImplFileCreator(directoryCreator, moduleName!, stateManagement);

      final sslCreator = CleanModuleImplSSLCreator(
        directoryCreator: directoryCreator,
        fileCreator: fileCreator,
      );
      return sslCreator.create();
    } else if (moduleName != null && modulePattern != null) {
      // Bloc or Repository Module
      final directoryCreator =
          RepoModuleImplDirectoryCreator(moduleName!, modulePattern);
      final fileCreator = RepoModuleImplFileCreator(
          directoryCreator, moduleName!, modulePattern);

      final sslCreator = RepoModuleImplSSLCreator(
        directoryCreator: directoryCreator,
        fileCreator: fileCreator,
      );
      return sslCreator.create();
    } else if (projectName != null &&
        patternNumber != null &&
        patternNumber == "3") {
      final directoryCreator =
          BlocImplDirectoryCreator(projectName ?? "", patternNumber!);
      final fileCreator =
          BlocImplFileCreator(directoryCreator, projectName ?? "");

      final sslCreator = BlocImplSSLCreator(
        directoryCreator: directoryCreator,
        fileCreator: fileCreator,
      );
      return sslCreator.create();
    } else if (projectName != null &&
        patternNumber != null &&
        patternNumber == "4") {
      final directoryCreator = CleanImplDirectoryCreator(projectName ?? "");
      final fileCreator =
          CleanImplFileCreator(directoryCreator, projectName ?? "");

      final sslCreator = CleanImplSSLCreator(
        directoryCreator: directoryCreator,
        fileCreator: fileCreator,
      );
      return sslCreator.create();
    } else {
      final directoryCreator = RepoImplDirectoryCreator(projectName ?? "");
      final fileCreator =
          repo.RepoImplFileCreator(directoryCreator, projectName ?? "");

      final sslCreator = RepoImplSSLCreator(
        directoryCreator: directoryCreator,
        fileCreator: fileCreator,
      );
      return sslCreator.create();
    }
  }
}
