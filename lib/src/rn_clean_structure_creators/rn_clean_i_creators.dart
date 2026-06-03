import 'dart:io';

abstract class RNCleanISSLCreator {
  Future<void> create();
}

abstract class RNIDirectoryCreator {
  Future<bool> createDirectories();
  Directory get srcDir;
  Directory get coreDir;
  Directory get featuresDir;
}

abstract class RNIFileCreator {
  Future<void> createNecessaryFiles();
}
