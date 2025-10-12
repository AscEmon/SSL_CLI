import 'dart:io';

import 'package:ssl_cli/src/clean_module_creators/clean_module_i_creators.dart';

class CleanModuleImplSSLCreator implements CleanModuleISSLCreator {
  final CleanModuleIDirectoryCreator directoryCreator;
  final CleanModuleIFileCreator fileCreator;

  CleanModuleImplSSLCreator({
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
