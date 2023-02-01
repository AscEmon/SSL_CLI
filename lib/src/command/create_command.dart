import 'package:ssl_cli/src/repo_structure_creators/directory/repo_impl_directory_creator.dart';
import 'package:ssl_cli/src/repo_structure_creators/file/repo_impl_file_creator.dart';
import 'package:ssl_cli/src/repo_structure_creators/repo_impl_ssl_creator.dart';

import '../mvc_structure_creators/mvc_impl_ssl_creator.dart';
import '../mvc_structure_creators/directory/mvc_impl_directory_creator.dart';
import '../mvc_structure_creators/file/mvc_impl_file_creator.dart';
import 'i_command.dart';

class CreateCommand implements ICommand {
  String projectName;
  String patternNumber;
  CreateCommand({
    required this.projectName,
    required this.patternNumber,
  });
  @override
  Future<void> execute() async {
    if (patternNumber == "1") {
      final directoryCreator = MvcImplDirectoryCreator(projectName);
      final fileCreator = MvcImplFileCreator(directoryCreator, projectName);

      final sslCreator = MvcImplSSLCreator(
        directoryCreator: directoryCreator,
        fileCreator: fileCreator,
      );
      return sslCreator.create();
    } else {
      final directoryCreator = RepoImplDirectoryCreator(projectName);
      final fileCreator = RepoImplFileCreator(directoryCreator, projectName);

      final sslCreator = RepoImplSSLCreator(
        directoryCreator: directoryCreator,
        fileCreator: fileCreator,
      );
      return sslCreator.create();
    }
  }
}
