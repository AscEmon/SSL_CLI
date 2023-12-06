import 'dart:io';

import 'package:ssl_cli/src/repo_module_creators/repo_module_i_creators.dart';

class RepoModuleImplSSLCreator implements RepoModuleISSLCreator {
  final RepoModuleIDirectoryCreator directoryCreator;
  final RepoModuleIFileCreator fileCreator;

  RepoModuleImplSSLCreator({
    required this.directoryCreator,
    required this.fileCreator,
  });

  @override
  Future<void> create() async {
    final res = await directoryCreator.createDirectories();

    if (res) {
      await fileCreator.createNecessaryFiles();
    } else {
      stderr.writeln('File creation cancelled!');
    }
  }
}
