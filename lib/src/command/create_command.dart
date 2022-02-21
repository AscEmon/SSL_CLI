import '../impl_ssl_creator.dart';
import '../structure_creators/directory/impl_directory_creator.dart';
import '../structure_creators/file/impl_file_creator.dart';
import 'i_command.dart';

class CreateCommand implements ICommand {
  @override
  Future<void> execute() async {
    final directoryCreator = ImplDirectoryCreator();
    final fileCreator = ImplFileCreator(directoryCreator);

    final sslCreator = ImplSSLCreator(
      directoryCreator: directoryCreator,
      fileCreator: fileCreator,
    );

    return sslCreator.create();
  }
}
