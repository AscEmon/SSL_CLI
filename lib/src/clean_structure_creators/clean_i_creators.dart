import 'dart:io';

abstract class CleanISSLCreator {
  Future<void> create();
}

abstract class IDirectoryCreator {
  Future<bool> createDirectories();
  Directory get coreDir;
  Directory get featuresDir;
  Directory get assetsDir;
  Directory get l10nDir;
}

abstract class IFileCreator {
  Future<void> createNecessaryFiles();
}
