import 'package:ssl_cli/src/clean_structure_creators/clean_i_creators.dart';
import 'package:ssl_cli/utils/enum.dart';
import 'package:ssl_cli/utils/extension.dart';

class CleanImplSSLCreator implements CleanISSLCreator {
  final IDirectoryCreator directoryCreator;
  final IFileCreator fileCreator;

  CleanImplSSLCreator({
    required this.directoryCreator,
    required this.fileCreator,
  });

  @override
  Future<void> create() async {
    final res = await directoryCreator.createDirectories();

    if (res) {
      await fileCreator.createNecessaryFiles();
    } else {
      'File creation cancelled!'.printWithColor(status: PrintType.error);
    }
  }
}
