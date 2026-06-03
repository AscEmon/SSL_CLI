import 'dart:io';
import 'rn_clean_module_i_creators.dart';

class RNCleanModuleImplSSLCreator implements RNCleanModuleISSLCreator {
  final RNCleanModuleIDirectoryCreator directoryCreator;
  final RNCleanModuleIFileCreator fileCreator;

  RNCleanModuleImplSSLCreator({
    required this.directoryCreator,
    required this.fileCreator,
  });

  @override
  Future<void> create() async {
    final res = await directoryCreator.createDirectories();

    if (res) {
      await fileCreator.createNecessaryFiles();
    } else {
      stderr.writeln('Module creation cancelled!');
    }
  }
}
