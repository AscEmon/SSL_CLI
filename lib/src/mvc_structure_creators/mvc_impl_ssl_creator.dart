import 'dart:io';

import 'package:ssl_cli/src/mvc_structure_creators/mvc_i_creators.dart';

class MvcImplSSLCreator implements MvcISSLCreator {
  final IDirectoryCreator directoryCreator;
  final IFileCreator fileCreator;

  MvcImplSSLCreator({
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
