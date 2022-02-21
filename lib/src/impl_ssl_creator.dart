import 'dart:io';

import 'structure_creators/i_creators.dart';

class ImplSSLCreator implements ISSLCreator {
  final IDirectoryCreator directoryCreator;
  final IFileCreator fileCreator;

  ImplSSLCreator({
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
