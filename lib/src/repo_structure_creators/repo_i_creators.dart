import 'dart:io';

abstract class RepoISSLCreator {
  Future<void> create();
}

abstract class IDirectoryCreator {
  Future<bool> createDirectories();
  Directory get constantDir;
  Directory get dataProviderDir;
  Directory get globalDir;
  Directory get l10nDir;
  Directory get moduleDir;
  Directory get utilsDir;
}

abstract class IFileCreator {
  Future<void> createNecessaryFiles();
}
