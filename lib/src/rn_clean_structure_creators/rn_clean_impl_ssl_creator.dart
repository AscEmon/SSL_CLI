import 'package:ssl_cli/utils/enum.dart';
import 'package:ssl_cli/utils/extension.dart';
import 'rn_clean_i_creators.dart';

class RNCleanImplSSLCreator implements RNCleanISSLCreator {
  final RNIDirectoryCreator directoryCreator;
  final RNIFileCreator fileCreator;

  RNCleanImplSSLCreator({
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
