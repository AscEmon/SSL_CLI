import 'dart:io';

import 'asset_path_i_creators.dart';

class AssetPathImplSSLCreator implements AssetPathISSLCreator {
  final AssetPathIDirectoryCreator directoryCreator;
  final AssetPathIFileCreator fileCreator;

  AssetPathImplSSLCreator({
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
