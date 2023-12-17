import 'package:ssl_cli/src/repo_structure_creators/repo_i_creators.dart';
import 'package:ssl_cli/utils/enum.dart';
import 'package:ssl_cli/utils/extension.dart';

class RepoImplSSLCreator implements RepoISSLCreator {
  final IDirectoryCreator directoryCreator;
  final IFileCreator fileCreator;

  RepoImplSSLCreator({
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
