import '../asset_path_creators/asset_path_impl_ssl_creator.dart';
import '../asset_path_creators/directory/asset_path_impl_directory_creator.dart';
import '../asset_path_creators/file/asset_path_impl_file_creator.dart';
import '../asset_path_creators/file/asset_path_themed_file_creator.dart';
import 'i_command.dart';

class AssetGenerationCommand implements ICommand {
  final bool isThemeBased;

  AssetGenerationCommand({this.isThemeBased = false});

  @override
  Future<void> execute() async {
    final directoryCreator = AssetPathImplDirectoryCreator();
    
    // Choose the appropriate file creator based on theme flag
    final fileCreator = isThemeBased
        ? AssetPathThemedFileCreator(directoryCreator, "")
        : AssetPathImplFileCreator(directoryCreator, "");

    final sslCreator = AssetPathImplSSLCreator(
      directoryCreator: directoryCreator,
      fileCreator: fileCreator,
    );
    return sslCreator.create();
  }
}
