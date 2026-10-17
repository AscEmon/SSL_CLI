import 'dart:io';
import 'package:ssl_cli/utils/extension.dart';
import '../../../utils/enum.dart';
import '../asset_path_i_creators.dart';
import 'asset_scanner.dart';

class AssetPathImplFileCreator implements AssetPathIFileCreator {
  final AssetPathIDirectoryCreator directoryCreator;
  final String moduleName;

  AssetPathImplFileCreator(this.directoryCreator, this.moduleName);

  @override
  Future<void> createNecessaryFiles() async {
    'creating necessary files...'.printWithColor();

    final assets =
        AssetScanner(directoryCreator.assetsDir, themeAware: false).scan();

    // if no asset found on any sub directories
    if (assets.isEmpty) {
      await _createFile(
        directoryCreator.stylesSubDir.path,
        'k_assets',
        content: "",
      );
      'No Assets found on any Sub directories'.printWithColor(
        status: PrintType.warning,
      );
      return;
    }

    final pathCode = StringBuffer('enum KAssetName {\n');
    for (final asset in assets) {
      pathCode.write('  ${asset.enumName},\n');
    }
    pathCode.write('}\n\n');
    pathCode.write('extension AssetsExtension on KAssetName {\n');
    pathCode.write('  String get imagePath {\n');
    pathCode.write('    const String rootPath = \'assets\';\n');
    final dirNames = <String, String>{};
    for (final asset in assets) {
      dirNames[_dirVarName(asset.rootFolder)] = asset.rootFolder;
    }
    dirNames.forEach((varName, folder) {
      pathCode.write('    const String $varName = \'\$rootPath/$folder\';\n');
    });
    pathCode.write('    switch (this) {\n');
    for (final asset in assets) {
      final subPath = asset.subPath.isEmpty ? '' : '/${asset.subPath}';
      pathCode.write('      case KAssetName.${asset.enumName}:\n');
      pathCode.write(
        '        return \'\$${_dirVarName(asset.rootFolder)}$subPath/${asset.fileName}\';\n',
      );
    }
    pathCode.write('    }\n');
    pathCode.write('  }\n');
    pathCode.write('}\n');

    await _createFile(
      directoryCreator.stylesSubDir.path,
      'k_assets',
      content: pathCode.toString(),
    );
    "Successfully generated image paths (${assets.length} assets)."
        .printWithColor(status: PrintType.success);
  }

  String _dirVarName(String folder) {
    final name = AssetScanner.toIdentifier([folder]);
    return '${name[0].toLowerCase()}${name.substring(1)}Dir';
  }

  Future<void> _createFile(
    String basePath,
    String fileName, {
    String? content,
    String? fileExtention = 'dart',
  }) async {
    String fileType;
    if (fileExtention == 'yaml') {
      fileType = 'yaml';
    } else if (fileExtention == 'arb') {
      fileType = 'arb';
    } else {
      fileType = 'dart';
    }
    try {
      late File file;

      if (await File('$basePath/$fileName.$fileType').exists()) {
        // Perform actions if the file exists
        file = File('$basePath/$fileName.$fileType');
      } else {
        // Perform actions if the file not exists
        file = await File('$basePath/$fileName.$fileType').create();
        "Successfully created $fileName.$fileType".printWithColor(
          status: PrintType.success,
        );
      }

      if (content != null) {
        await file.writeAsString(content, flush: true);
      }
    } catch (e) {
      e.toString().printWithColor(status: PrintType.error);
      stderr.write('creating $fileName.$fileType failed!');
      exit(2);
    }
  }
}
