import '../impl_ssl_creator.dart';
import '../structure_creators/directory/impl_directory_creator.dart';
import '../structure_creators/file/impl_file_creator.dart';
import 'i_command.dart';

class CreateCommand implements ICommand {
  String projectName;
  CreateCommand({required this.projectName});
  @override
  Future<void> execute() async {
    final directoryCreator = ImplDirectoryCreator(projectName);
    final fileCreator = ImplFileCreator(directoryCreator, projectName);

    final sslCreator = ImplSSLCreator(
      directoryCreator: directoryCreator,
      fileCreator: fileCreator,
    );

    return sslCreator.create();
  }
}
