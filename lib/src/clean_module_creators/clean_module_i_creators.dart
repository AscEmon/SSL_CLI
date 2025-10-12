import 'dart:io';

abstract class CleanModuleISSLCreator {
  Future<void> create();
}

abstract class CleanModuleIDirectoryCreator {
  Future<bool> createDirectories(); 
  Directory get moduleDir;
}

abstract class CleanModuleIFileCreator {
  Future<void> createNecessaryFiles();
}
