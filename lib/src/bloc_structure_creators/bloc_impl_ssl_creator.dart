import 'package:ssl_cli/src/bloc_structure_creators/bloc_i_creators.dart';
import 'package:ssl_cli/utils/enum.dart';
import 'package:ssl_cli/utils/extension.dart';

class BlocImplSSLCreator implements BlocISSLCreator {
  final IDirectoryCreator directoryCreator;
  final IFileCreator fileCreator;

  BlocImplSSLCreator({
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
