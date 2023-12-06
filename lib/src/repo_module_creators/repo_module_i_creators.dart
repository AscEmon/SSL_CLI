import 'dart:io';

abstract class RepoModuleISSLCreator {
  Future<void> create();
}

abstract class RepoModuleIDirectoryCreator {
  Future<bool> createDirectories(); 
  Directory get moduleDir;

}

abstract class RepoModuleIFileCreator {
  Future<void> createNecessaryFiles();
}
