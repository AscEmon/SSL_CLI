import 'dart:io';

abstract class RNCleanModuleISSLCreator {
  Future<void> create();
}

abstract class RNCleanModuleIDirectoryCreator {
  Future<bool> createDirectories();
  Directory get moduleDir;
}

abstract class RNCleanModuleIFileCreator {
  Future<void> createNecessaryFiles();
}
