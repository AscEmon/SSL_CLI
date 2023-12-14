import 'dart:io';

abstract class AssetPathISSLCreator {
  Future<void> create();
}

abstract class AssetPathIDirectoryCreator {
  Future<bool> createDirectories();
  Directory get projectDir;
  Directory get assetsDir;
  Directory get utilsDir;
  Directory get stylesSubDir;
}

abstract class AssetPathIFileCreator {
  Future<void> createNecessaryFiles();
}
